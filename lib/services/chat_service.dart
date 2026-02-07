import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/chat_model.dart';
import '../utils/constants.dart';

class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  WebSocketChannel? _webSocketChannel;
  final _messageStreamController = StreamController<Message>.broadcast();
  final _typingStreamController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Message> get messageStream => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingStreamController.stream;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // HTTP Methods
  Future<List<ChatModel>> getMyChats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/chats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final chats = (data['chats'] ?? data['data'] ?? []) as List;
        return chats.map((c) => ChatModel.fromJson(c)).toList();
      } else {
        throw Exception('Failed to load chats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching chats: $e');
    }
  }

  Future<ChatModel> getChatDetails(String chatId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/chats/$chatId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatModel.fromJson(data['chat'] ?? data);
      } else {
        throw Exception('Failed to load chat: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching chat details: $e');
    }
  }

  Future<List<Message>> getChatMessages(
    String chatId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${AppConstants.apiBaseUrl}/chats/$chatId/messages')
          .replace(queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messages = (data['messages'] ?? data['data'] ?? []) as List;
        return messages.map((m) => Message.fromJson(m)).toList();
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching messages: $e');
    }
  }

  Future<ChatModel> createSupportChat() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/chats/support'),
        headers: headers,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatModel.fromJson(data['chat'] ?? data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create support chat');
      }
    } catch (e) {
      throw Exception('Error creating support chat: $e');
    }
  }

  Future<Message> sendMessage(SendMessageRequest request) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/messages'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Message.fromJson(data['message'] ?? data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to send message');
      }
    } catch (e) {
      throw Exception('Error sending message: $e');
    }
  }

  Future<void> markMessagesAsRead(String chatId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/chats/$chatId/read'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark messages as read');
      }
    } catch (e) {
      throw Exception('Error marking messages as read: $e');
    }
  }

  // WebSocket Methods
  Future<void> connectWebSocket(String chatId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Convert HTTP URL to WebSocket URL
      final wsUrl = AppConstants.apiBaseUrl
          .replaceFirst('https://', 'wss://')
          .replaceFirst('http://', 'ws://');

      _webSocketChannel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/ws/chats/$chatId?token=$token'),
      );

      _webSocketChannel!.stream.listen(
        (message) {
          _handleWebSocketMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      throw Exception('Error connecting to WebSocket: $e');
    }
  }

  void _handleWebSocketMessage(String message) {
    try {
      final data = jsonDecode(message);
      final type = data['type'];

      switch (type) {
        case 'message':
          final msg = Message.fromJson(data['data']);
          _messageStreamController.add(msg);
          break;
        case 'typing':
          _typingStreamController.add(data['data']);
          break;
        default:
          print('Unknown WebSocket message type: $type');
      }
    } catch (e) {
      print('Error handling WebSocket message: $e');
    }
  }

  void sendWebSocketMessage(String content, String chatId) {
    if (_webSocketChannel != null) {
      _webSocketChannel!.sink.add(jsonEncode({
        'type': 'message',
        'chatId': chatId,
        'content': content,
      }));
    }
  }

  void sendTypingStatus(String chatId, bool isTyping) {
    if (_webSocketChannel != null) {
      _webSocketChannel!.sink.add(jsonEncode({
        'type': 'typing',
        'chatId': chatId,
        'isTyping': isTyping,
      }));
    }
  }

  void disconnectWebSocket() {
    _webSocketChannel?.sink.close();
    _webSocketChannel = null;
  }

  void dispose() {
    disconnectWebSocket();
    _messageStreamController.close();
    _typingStreamController.close();
  }
}
