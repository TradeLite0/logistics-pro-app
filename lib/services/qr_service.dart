import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/shipment_model.dart';
import '../models/user_model.dart';

/// خدمة QR Scanner للاتصال بالـ Backend
class QRService {
  // ✅ Railway Backend URL
  static const String baseUrl = 'https://longest-ice-production.up.railway.app/api';

  String? _authToken;

  void setToken(String token) {
    _authToken = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // ==================== QR SCANNER ====================

  /// مسح QR Code للشحنة
  /// [qrData] يمكن أن يكون رقم التتبع أو معرف الشحنة
  Future<Shipment> scanShipmentQR(String qrData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shipments/scan-qr'),
      headers: _headers,
      body: jsonEncode({'qr_data': qrData}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Shipment.fromJson(data['shipment']);
    } else if (response.statusCode == 404) {
      throw Exception('الشحنة غير موجودة');
    } else {
      throw Exception('فشل في مسح QR: ${response.body}');
    }
  }

  /// الحصول على تفاصيل الشحنة بواسطة رقم التتبع
  Future<Shipment> getShipmentByTracking(String trackingNumber) async {
    final response = await http.get(
      Uri.parse('$baseUrl/shipments/track/$trackingNumber'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Shipment.fromJson(data['shipment']);
    } else if (response.statusCode == 404) {
      throw Exception('الشحنة غير موجودة');
    } else {
      throw Exception('فشل في تحميل تفاصيل الشحنة');
    }
  }

  // ==================== ACTIONS ====================

  /// استلام الشحنة (Pickup)
  Future<Shipment> pickupShipment({
    required String shipmentId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shipments/$shipmentId/pickup'),
      headers: _headers,
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'location': '$latitude,$longitude',
        'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Shipment.fromJson(data['shipment']);
    } else {
      throw Exception('فشل في استلام الشحنة: ${response.body}');
    }
  }

  /// تسليم الشحنة (Deliver)
  Future<Shipment> deliverShipment({
    required String shipmentId,
    required double latitude,
    required double longitude,
    String? notes,
    String? recipientName,
    String? signatureUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shipments/$shipmentId/deliver'),
      headers: _headers,
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'location': '$latitude,$longitude',
        'notes': notes,
        'recipient_name': recipientName,
        'signature_url': signatureUrl,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Shipment.fromJson(data['shipment']);
    } else {
      throw Exception('فشل في تسليم الشحنة: ${response.body}');
    }
  }

  /// استرجاع الشحنة (Return)
  Future<Shipment> returnShipment({
    required String shipmentId,
    required double latitude,
    required double longitude,
    required String reason,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/shipments/$shipmentId/return'),
      headers: _headers,
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'location': '$latitude,$longitude',
        'reason': reason,
        'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Shipment.fromJson(data['shipment']);
    } else {
      throw Exception('فشل في استرجاع الشحنة: ${response.body}');
    }
  }

  /// تحديث حالة الشحنة العامة
  Future<Shipment> updateShipmentStatus({
    required String shipmentId,
    required String status,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/shipments/$shipmentId/status'),
      headers: _headers,
      body: jsonEncode({
        'status': status,
        'latitude': latitude,
        'longitude': longitude,
        'location': '$latitude,$longitude',
        'notes': notes,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Shipment.fromJson(data['shipment']);
    } else {
      throw Exception('فشل في تحديث حالة الشحنة: ${response.body}');
    }
  }

  // ==================== VALIDATION ====================

  /// التحقق من صلاحية الإجراء للمستخدم
  bool isActionValidForRole({
    required UserRole role,
    required QRAction action,
  }) {
    switch (role) {
      case UserRole.driver:
        // السائق يمكنه: استلام، تسليم، استرجاع
        return action == QRAction.pickup ||
               action == QRAction.deliver ||
               action == QRAction.return_;
      case UserRole.supervisor:
      case UserRole.admin:
        // المشرف والمدير يمكنهم: جميع الإجراءات
        return true;
      case UserRole.client:
        // العميل لا يمكنه استخدام ماسح QR
        return false;
    }
  }

  /// الحصول على قائمة الإجراءات المتاحة للدور
  List<QRAction> getAvailableActions(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return [QRAction.pickup, QRAction.deliver, QRAction.return_];
      case UserRole.supervisor:
      case UserRole.admin:
        return QRAction.values;
      case UserRole.client:
        return [];
    }
  }
}

/// أنواع الإجراءات المتاحة في QR Scanner
enum QRAction {
  pickup('استلام', 'Pickup', 'pickup'),
  deliver('تسليم', 'Deliver', 'deliver'),
  return_('استرجاع', 'Return', 'return'),
  viewDetails('عرض التفاصيل', 'View Details', 'view_details');

  final String labelAr;
  final String labelEn;
  final String key;

  const QRAction(this.labelAr, this.labelEn, this.key);

  String getLabel(bool isArabic) => isArabic ? labelAr : labelEn;

  static QRAction fromKey(String? key) {
    if (key == null) return QRAction.viewDetails;
    return QRAction.values.firstWhere(
      (a) => a.key == key.toLowerCase(),
      orElse: () => QRAction.viewDetails,
    );
  }
}