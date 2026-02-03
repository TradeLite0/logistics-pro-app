import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shipment_model.dart';

/// خدمة API للاتصال بالـ Backend
class ApiService {
  // ✅ Railway Backend URL
  static const String baseUrl = 'https://logistics-v2-api-production.up.railway.app/api';

  String? _authToken;

  void setToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // ==================== AUTH ====================

  Future<Map<String, dynamic>> login(String phone, String password, {String? fcmToken}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({
        'phone': phone,
        'password': password,
        'fcm_token': fcmToken,
      }),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> register({
    required String phone,
    required String password,
    required String name,
    String type = 'client',
    String? email,
    String? fcmToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({
        'phone': phone,
        'password': password,
        'name': name,
        'type': type,
        'email': email,
        'fcm_token': fcmToken,
      }),
    );

    return jsonDecode(response.body);
  }

  // ==================== SHIPMENTS ====================

  Future<List<Shipment>> getShipments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/shipments'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['shipments'] as List)
          .map((s) => Shipment.fromJson(s))
          .toList();
    }
    throw Exception('Failed to load shipments');
  }

  Future<Shipment> createShipment(Map<String, dynamic> shipmentData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shipments'),
      headers: _headers,
      body: jsonEncode(shipmentData),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Shipment.fromJson(data['shipment']);
    }
    throw Exception('Failed to create shipment');
  }

  Future<Shipment> getShipment(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/shipments/$id'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Shipment.fromJson(data['shipment']);
    }
    throw Exception('Failed to load shipment');
  }

  Future<Shipment> trackShipment(String trackingNumber) async {
    final response = await http.get(
      Uri.parse('$baseUrl/shipments/track/$trackingNumber'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Shipment.fromJson(data['shipment']);
    }
    throw Exception('Shipment not found');
  }

  Future<void> updateShipmentStatus({
    required String shipmentId,
    required String status,
    String? location,
    String? notes,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/shipments/$shipmentId/status'),
      headers: _headers,
      body: jsonEncode({
        'status': status,
        'location': location,
        'notes': notes,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update status');
    }
  }

  // ==================== NOTIFICATIONS ====================

  Future<void> saveFcmToken(String token) async {
    await http.post(
      Uri.parse('$baseUrl/notifications/token'),
      headers: _headers,
      body: jsonEncode({'fcm_token': token}),
    );
  }

  Future<List<dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['notifications'];
    }
    return [];
  }
}
