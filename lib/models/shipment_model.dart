import 'package:flutter/foundation.dart';

class ShipmentModel {
  final String id;
  final String trackingNumber;
  final String status;
  final String? description;
  final double weight;
  final double? price;
  final String pickupAddress;
  final String deliveryAddress;
  final String? clientId;
  final String? driverId;
  final DateTime? pickupDate;
  final DateTime? deliveryDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final User? client;
  final Driver? driver;

  ShipmentModel({
    required this.id,
    required this.trackingNumber,
    required this.status,
    this.description,
    required this.weight,
    this.price,
    required this.pickupAddress,
    required this.deliveryAddress,
    this.clientId,
    this.driverId,
    this.pickupDate,
    this.deliveryDate,
    required this.createdAt,
    this.updatedAt,
    this.client,
    this.driver,
  });

  factory ShipmentModel.fromJson(Map<String, dynamic> json) {
    return ShipmentModel(
      id: json['id']?.toString() ?? '',
      trackingNumber: json['trackingNumber'] ?? '',
      status: json['status'] ?? 'pending',
      description: json['description'],
      weight: (json['weight'] ?? 0).toDouble(),
      price: json['price']?.toDouble(),
      pickupAddress: json['pickupAddress'] ?? '',
      deliveryAddress: json['deliveryAddress'] ?? '',
      clientId: json['clientId']?.toString(),
      driverId: json['driverId']?.toString(),
      pickupDate: json['pickupDate'] != null
          ? DateTime.parse(json['pickupDate'])
          : null,
      deliveryDate: json['deliveryDate'] != null
          ? DateTime.parse(json['deliveryDate'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      client: json['client'] != null ? User.fromJson(json['client']) : null,
      driver: json['driver'] != null ? Driver.fromJson(json['driver']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trackingNumber': trackingNumber,
      'status': status,
      'description': description,
      'weight': weight,
      'price': price,
      'pickupAddress': pickupAddress,
      'deliveryAddress': deliveryAddress,
      'clientId': clientId,
      'driverId': driverId,
      'pickupDate': pickupDate?.toIso8601String(),
      'deliveryDate': deliveryDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get statusArabic {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'قيد الانتظار';
      case 'assigned':
        return 'تم التعيين';
      case 'picked_up':
        return 'تم الاستلام';
      case 'in_transit':
        return 'في الطريق';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }

  String get statusColor {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'orange';
      case 'assigned':
        return 'blue';
      case 'picked_up':
        return 'purple';
      case 'in_transit':
        return 'indigo';
      case 'delivered':
        return 'green';
      case 'cancelled':
        return 'red';
      default:
        return 'grey';
    }
  }

  bool get isActive => 
      status.toLowerCase() != 'delivered' && 
      status.toLowerCase() != 'cancelled';
}

class User {
  final String id;
  final String name;
  final String? avatar;
  final String phone;

  User({
    required this.id,
    required this.name,
    this.avatar,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      phone: json['phone'] ?? '',
    );
  }
}

class Driver {
  final String id;
  final String name;
  final String? avatar;
  final String phone;
  final double? rating;

  Driver({
    required this.id,
    required this.name,
    this.avatar,
    required this.phone,
    this.rating,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      avatar: json['avatar'],
      phone: json['phone'] ?? '',
      rating: json['rating']?.toDouble(),
    );
  }
}
