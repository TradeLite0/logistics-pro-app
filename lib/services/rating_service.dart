import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/rating_model.dart';
import '../utils/constants.dart';

class RatingService {
  static final RatingService _instance = RatingService._internal();
  factory RatingService() => _instance;
  RatingService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<RatingModel>> getDriverRatings(String driverId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/ratings/driver/$driverId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ratings = (data['ratings'] ?? data['data'] ?? []) as List;
        return ratings.map((r) => RatingModel.fromJson(r)).toList();
      } else {
        throw Exception('Failed to load ratings: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching ratings: $e');
    }
  }

  Future<DriverRatingSummary> getDriverRatingSummary(String driverId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/ratings/driver/$driverId/summary'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return DriverRatingSummary.fromJson(data['summary'] ?? data);
      } else {
        throw Exception('Failed to load rating summary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching rating summary: $e');
    }
  }

  Future<RatingModel> createRating(CreateRatingRequest request) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/ratings'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return RatingModel.fromJson(data['rating'] ?? data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create rating');
      }
    } catch (e) {
      throw Exception('Error creating rating: $e');
    }
  }

  Future<bool> canRateDriver(String shipmentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/ratings/can-rate/$shipmentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['canRate'] ?? false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<RatingModel?> getMyRatingForShipment(String shipmentId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/ratings/shipment/$shipmentId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rating'] != null) {
          return RatingModel.fromJson(data['rating']);
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
