import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shipment_model.dart';
import '../utils/constants.dart';

class ShipmentService {
  static final ShipmentService _instance = ShipmentService._internal();
  factory ShipmentService() => _instance;
  ShipmentService._internal();

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<ShipmentModel>> getMyShipments({
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('${AppConstants.apiBaseUrl}/shipments/my')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final shipments = (data['shipments'] ?? data['data'] ?? []) as List;
        return shipments.map((s) => ShipmentModel.fromJson(s)).toList();
      } else {
        throw Exception('Failed to load shipments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching shipments: $e');
    }
  }

  Future<List<ShipmentModel>> getDriverShipments({
    String? status,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final uri = Uri.parse('${AppConstants.apiBaseUrl}/shipments/driver')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final shipments = (data['shipments'] ?? data['data'] ?? []) as List;
        return shipments.map((s) => ShipmentModel.fromJson(s)).toList();
      } else {
        throw Exception('Failed to load shipments: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching driver shipments: $e');
    }
  }

  Future<ShipmentModel> getShipmentDetails(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/shipments/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ShipmentModel.fromJson(data['shipment'] ?? data);
      } else {
        throw Exception('Failed to load shipment details: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching shipment details: $e');
    }
  }

  Future<ShipmentModel> createShipment(Map<String, dynamic> shipmentData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/shipments'),
        headers: headers,
        body: jsonEncode(shipmentData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ShipmentModel.fromJson(data['shipment'] ?? data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to create shipment');
      }
    } catch (e) {
      throw Exception('Error creating shipment: $e');
    }
  }

  Future<void> updateShipmentStatus(String id, String status) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('${AppConstants.apiBaseUrl}/shipments/$id/status'),
        headers: headers,
        body: jsonEncode({'status': status}),
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update status');
      }
    } catch (e) {
      throw Exception('Error updating shipment status: $e');
    }
  }

  Future<ShipmentModel?> trackShipment(String trackingNumber) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.apiBaseUrl}/shipments/track/$trackingNumber'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ShipmentModel.fromJson(data['shipment'] ?? data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to track shipment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error tracking shipment: $e');
    }
  }
}
