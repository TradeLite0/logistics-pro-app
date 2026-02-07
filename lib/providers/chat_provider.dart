import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService = ChatService();

  List<ChatModel> _chats = [];
  List<Message> _messages = [];
  ChatModel? _selectedChat;
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  bool _isTyping = false;

  List<ChatModel> get chats => _chats;
  List<Message> get messages => _messages;
  ChatModel? get selectedChat => _selectedChat;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  bool get isTyping => _isTyping;
  int get totalUnreadCount => _chats.fold(0, (sum, chat) => sum + chat.unreadCount);

  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _typingSubscription;

  Future<void> loadChats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _chats = await _chatService.getMyChats();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadChatDetails(String chatId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedChat = await _chatService.getChatDetails(chatId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String chatId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await _chatService.getChatMessages(chatId);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> connectToChat(String chatId) async {
    try {
      await _chatService.connectWebSocket(chatId);

      // Listen to incoming messages
      _messageSubscription?.cancel();
      _messageSubscription = _chatService.messageStream.listen((message) {
        _messages.add(message);
        notifyListeners();
      });

      // Listen to typing status
      _typingSubscription?.cancel();
      _typingSubscription = _chatService.typingStream.listen((data) {
        _isTyping = data['isTyping'] ?? false;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void disconnectFromChat() {
    _chatService.disconnectWebSocket();
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _isTyping = false;
  }

  Future<void> sendMessage(String chatId, String content) async {
    if (content.trim().isEmpty) return;

    _isSending = true;
    notifyListeners();

    try {
      // Try WebSocket first
      _chatService.sendWebSocketMessage(content, chatId);

      // Fallback to HTTP
      final request = SendMessageRequest(
        chatId: chatId,
        content: content,
      );
      final message = await _chatService.sendMessage(request);
      _messages.add(message);
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  void sendTypingStatus(String chatId, bool isTyping) {
    _chatService.sendTypingStatus(chatId, isTyping);
  }

  Future<void> markMessagesAsRead(String chatId) async {
    try {
      await _chatService.markMessagesAsRead(chatId);
      
      // Update local chat unread count
      final index = _chats.indexWhere((c) => c.id == chatId);
      if (index != -1) {
        _chats[index] = ChatModel(
          id: _chats[index].id,
          type: _chats[index].type,
          title: _chats[index].title,
          shipmentId: _chats[index].shipmentId,
          participants: _chats[index].participants,
          lastMessage: _chats[index].lastMessage,
          unreadCount: 0,
          createdAt: _chats[index].createdAt,
          updatedAt: _chats[index].updatedAt,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<ChatModel> createSupportChat() async {
    _isLoading = true;
    notifyListeners();

    try {
      final chat = await _chatService.createSupportChat();
      _chats.insert(0, chat);
      _error = null;
      return chat;
    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedChat() {
    _selectedChat = null;
    _messages = [];
    disconnectFromChat();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disconnectFromChat();
    super.dispose();
  }
}
