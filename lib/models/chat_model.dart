import 'package:flutter/foundation.dart';

class ChatModel {
  final String id;
  final String type;
  final String? title;
  final String? shipmentId;
  final List<ChatParticipant> participants;
  final Message? lastMessage;
  final int unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatModel({
    required this.id,
    required this.type,
    this.title,
    this.shipmentId,
    required this.participants,
    this.lastMessage,
    this.unreadCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? 'direct',
      title: json['title'],
      shipmentId: json['shipmentId']?.toString(),
      participants: json['participants'] != null
          ? (json['participants'] as List)
              .map((p) => ChatParticipant.fromJson(p))
              .toList()
          : [],
      lastMessage: json['lastMessage'] != null
          ? Message.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  String get chatTitle {
    if (title != null && title!.isNotEmpty) return title!;
    final otherParticipants = participants.where((p) => !p.isMe).toList();
    if (otherParticipants.isEmpty) return 'محادثة';
    return otherParticipants.map((p) => p.name).join(', ');
  }

  String? get otherParticipantAvatar {
    final otherParticipants = participants.where((p) => !p.isMe).toList();
    if (otherParticipants.isNotEmpty) {
      return otherParticipants.first.avatar;
    }
    return null;
  }
}

class ChatParticipant {
  final String id;
  final String name;
  final String? avatar;
  final String role;
  final bool isMe;

  ChatParticipant({
    required this.id,
    required this.name,
    this.avatar,
    required this.role,
    this.isMe = false,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      role: json['role'] ?? 'client',
      isMe: json['isMe'] ?? false,
    );
  }
}

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String content;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final User? sender;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    this.type = 'text',
    this.isRead = false,
    required this.createdAt,
    this.sender,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      chatId: json['chatId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'text',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class User {
  final String id;
  final String name;
  final String? avatar;

  User({
    required this.id,
    required this.name,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
    );
  }
}

class SendMessageRequest {
  final String chatId;
  final String content;
  final String type;

  SendMessageRequest({
    required this.chatId,
    required this.content,
    this.type = 'text',
  });

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'content': content,
      'type': type,
    };
  }
}
