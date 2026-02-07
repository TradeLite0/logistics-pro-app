import '../models/shipment_model.dart';
import '../models/user_model.dart';
import 'api_client.dart';

/// Response from QR operations
class QRResponse {
  final bool success;
  final String? message;
  final Shipment? shipment;

  QRResponse({
    required this.success,
    this.message,
    this.shipment,
  });
}

/// Service for QR Scanner operations
class QRService {
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;
  QRService._internal();

  final ApiClient _apiClient = ApiClient();

  // ==================== QR Scanning ====================

  /// Scan QR code for shipment
  /// [qrData] can be tracking number or shipment ID
  Future<QRResponse> scanShipmentQR(String qrData) async {
    try {
      final response = await _apiClient.post(
        '/shipments/scan-qr',
        body: {'qr_data': qrData},
      );

      return QRResponse(
        success: true,
        message: response['message'] ?? 'QR scanned successfully',
        shipment: response['data'] != null 
            ? Shipment.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return QRResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return QRResponse(
        success: false,
        message: 'Failed to scan QR: $e',
      );
    }
  }

  /// Get shipment by tracking number
  Future<QRResponse> getShipmentByTracking(String trackingNumber) async {
    try {
      final response = await _apiClient.get(
        '/shipments/track/$trackingNumber',
      );

      return QRResponse(
        success: true,
        shipment: response['data'] != null 
            ? Shipment.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return QRResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return QRResponse(
        success: false,
        message: 'Failed to get shipment: $e',
      );
    }
  }

  /// Get shipment details by ID
  Future<QRResponse> getShipmentById(String shipmentId) async {
    try {
      final response = await _apiClient.get('/shipments/$shipmentId');

      return QRResponse(
        success: true,
        shipment: response['data'] != null 
            ? Shipment.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return QRResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return QRResponse(
        success: false,
        message: 'Failed to get shipment: $e',
      );
    }
  }

  // ==================== Shipment Actions ====================

  /// Pickup shipment (scan at pickup)
  Future<QRResponse> pickupShipment({
    required String shipmentId,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        '/shipments/$shipmentId/pickup',
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'location': '$latitude,$longitude',
          'notes': notes,
        },
      );

      return QRResponse(
        success: true,
        message: response['message'] ?? 'Shipment picked up successfully',
        shipment: response['data'] != null 
            ? Shipment.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return QRResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return QRResponse(
        success: false,
        message: 'Failed to pickup shipment: $e',
      );
    }
  }

  /// Mark shipment as delivered
  Future<QRResponse> deliverShipment({
    required String shipmentId,
    required double latitude,
    required double longitude,
    String? notes,
    String? recipientName,
    String? signatureUrl,
  }) async {
    try {
      final response = await _apiClient.post(
        '/shipments/$shipmentId/deliver',
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'location': '$latitude,$longitude',
          'notes': notes,
          'recipient_name': recipientName,
          'signature_url': signatureUrl,
        },
      );

      return QRResponse(
        success: true,
        message: response['message'] ?? 'Shipment delivered successfully',
        shipment: response['data'] != null 
            ? Shipment.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return QRResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return QRResponse(
        success: false,
        message: 'Failed to deliver shipment: $e',
      );
    }
  }

  /// Return shipment
  Future<QRResponse> returnShipment({
    required String shipmentId,
    required double latitude,
    required double longitude,
    required String reason,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.post(
        '/shipments/$shipmentId/return',
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'location': '$latitude,$longitude',
          'reason': reason,
          'notes': notes,
        },
      );

      return QRResponse(
        success: true,
        message: response['message'] ?? 'Shipment returned successfully',
        shipment: response['data'] != null 
            ? Shipment.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return QRResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return QRResponse(
        success: false,
        message: 'Failed to return shipment: $e',
      );
    }
  }

  /// Update shipment status (general)
  Future<QRResponse> updateShipmentStatus({
    required String shipmentId,
    required String status,
    required double latitude,
    required double longitude,
    String? notes,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/shipments/$shipmentId/status',
        body: {
          'status': status,
          'latitude': latitude,
          'longitude': longitude,
          'location': '$latitude,$longitude',
          'notes': notes,
        },
      );

      return QRResponse(
        success: true,
        message: response['message'] ?? 'Status updated successfully',
        shipment: response['data'] != null 
            ? Shipment.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return QRResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return QRResponse(
        success: false,
        message: 'Failed to update status: $e',
      );
    }
  }

  // ==================== Role Validation ====================

  /// Check if action is valid for user role
  bool isActionValidForRole({
    required UserRole role,
    required QRAction action,
  }) {
    switch (role) {
      case UserRole.driver:
        // Driver can: pickup, deliver, return
        return action == QRAction.pickup ||
               action == QRAction.deliver ||
               action == QRAction.return_;
      case UserRole.supervisor:
      case UserRole.admin:
        // Supervisor and admin can: all actions
        return true;
      case UserRole.client:
        // Client cannot use QR scanner
        return false;
    }
  }

  /// Get available actions for role
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

/// Available QR actions
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
