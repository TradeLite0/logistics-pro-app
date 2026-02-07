import 'package:flutter/foundation.dart';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'general',
      data: json['data'],
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum NotificationType {
  shipmentStatus,
  shipmentAssigned,
  complaintResponse,
  adminAnnouncement,
  chatMessage,
  general,
}

extension NotificationTypeExtension on NotificationType {
  String get value {
    switch (this) {
      case NotificationType.shipmentStatus:
        return 'shipment_status';
      case NotificationType.shipmentAssigned:
        return 'shipment_assigned';
      case NotificationType.complaintResponse:
        return 'complaint_response';
      case NotificationType.adminAnnouncement:
        return 'admin_announcement';
      case NotificationType.chatMessage:
        return 'chat_message';
      case NotificationType.general:
        return 'general';
    }
  }

  String get arabicTitle {
    switch (this) {
      case NotificationType.shipmentStatus:
        return 'تحديث حالة الشحنة';
      case NotificationType.shipmentAssigned:
        return 'شحنة جديدة';
      case NotificationType.complaintResponse:
        return 'رد على الشكوى';
      case NotificationType.adminAnnouncement:
        return 'إعلان إداري';
      case NotificationType.chatMessage:
        return 'رسالة جديدة';
      case NotificationType.general:
        return 'إشعار';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.shipmentStatus:
        return '📦';
      case NotificationType.shipmentAssigned:
        return '🚚';
      case NotificationType.complaintResponse:
        return '💬';
      case NotificationType.adminAnnouncement:
        return '📢';
      case NotificationType.chatMessage:
        return '💬';
      case NotificationType.general:
        return '🔔';
    }
  }
}
