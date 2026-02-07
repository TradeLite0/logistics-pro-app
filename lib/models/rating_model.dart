import 'package:flutter/foundation.dart';

class RatingModel {
  final String id;
  final String shipmentId;
  final String driverId;
  final String clientId;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  final User? client;

  RatingModel({
    required this.id,
    required this.shipmentId,
    required this.driverId,
    required this.clientId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.client,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id']?.toString() ?? '',
      shipmentId: json['shipmentId']?.toString() ?? '',
      driverId: json['driverId']?.toString() ?? '',
      clientId: json['clientId']?.toString() ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      comment: json['comment'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      client: json['client'] != null ? User.fromJson(json['client']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shipmentId': shipmentId,
      'driverId': driverId,
      'clientId': clientId,
      'rating': rating,
      'comment': comment,
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

class DriverRatingSummary {
  final String driverId;
  final double averageRating;
  final int totalRatings;
  final Map<int, int> ratingDistribution;

  DriverRatingSummary({
    required this.driverId,
    required this.averageRating,
    required this.totalRatings,
    required this.ratingDistribution,
  });

  factory DriverRatingSummary.fromJson(Map<String, dynamic> json) {
    final distribution = <int, int>{};
    if (json['ratingDistribution'] != null) {
      json['ratingDistribution'].forEach((key, value) {
        distribution[int.parse(key)] = value;
      });
    }

    return DriverRatingSummary(
      driverId: json['driverId']?.toString() ?? '',
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      ratingDistribution: distribution,
    );
  }
}

class CreateRatingRequest {
  final String shipmentId;
  final String driverId;
  final double rating;
  final String? comment;

  CreateRatingRequest({
    required this.shipmentId,
    required this.driverId,
    required this.rating,
    this.comment,
  });

  Map<String, dynamic> toJson() {
    return {
      'shipmentId': shipmentId,
      'driverId': driverId,
      'rating': rating,
      'comment': comment,
    };
  }
}
