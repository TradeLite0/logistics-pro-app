import '../models/shipment_model.dart';
import 'api_client.dart';

/// Response from shipment operations
class ShipmentResponse {
  final bool success;
  final String? message;
  final Shipment? shipment;
  final List<Shipment>? shipments;
  final Map<String, dynamic>? trackingInfo;
  final Map<String, dynamic>? driverLocation;

  ShipmentResponse({
    required this.success,
    this.message,
    this.shipment,
    this.shipments,
    this.trackingInfo,
    this.driverLocation,
  });
}

/// Service for shipment operations and tracking
class ShipmentService {
  static final ShipmentService _instance = ShipmentService._internal();
  factory ShipmentService() => _instance;
  ShipmentService._internal();

  final ApiClient _apiClient = ApiClient();

  // ==================== List Shipments ====================

  /// Get all shipments
  Future<ShipmentResponse> getShipments({
    String? status,
    String? driverId,
    String? companyId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) queryParams['status'] = status;
      if (driverId != null) queryParams['driver_id'] = driverId;
      if (companyId != null) queryParams['company_id'] = companyId;
      if (fromDate != null) queryParams['from'] = fromDate.toIso8601String();
      if (toDate != null) queryParams['to'] = toDate.toIso8601String();

      final response = await _apiClient.get(
        '/shipments',
        queryParams: queryParams,
      );

      final List<dynamic> data = response['data'] ?? [];
      final shipments = data.map((s) => Shipment.fromJson(s)).toList();

      return ShipmentResponse(
        success: true,
        shipments: shipments,
      );
    } on ApiException catch (e) {
      return ShipmentResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ShipmentResponse(
        success: false,
        message: 'Failed to load shipments: $e',
      );
    }
  }

  /// Get shipments assigned to current driver
  Future<ShipmentResponse> getDriverShipments({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) queryParams['status'] = status;

      final response = await _apiClient.get(
        '/shipments/driver/my',
        queryParams: queryParams,
      );

      final List<dynamic> data = response['data'] ?? [];
      final shipments = data.map((s) => Shipment.fromJson(s)).toList();

      return ShipmentResponse(
        success: true,
        shipments: shipments,
      );
    } on ApiException catch (e) {
      return ShipmentResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ShipmentResponse(
        success: false,
        message: 'Failed to load driver shipments: $e',
      );
    }
  }

  /// Get shipments for a specific client
  Future<ShipmentResponse> getClientShipments(String clientId) async {
    try {
      final response = await _apiClient.get('/shipments/client/$clientId');

      final List<dynamic> data = response['data'] ?? [];
      final shipments = data.map((s) => Shipment.fromJson(s)).toList();

      return ShipmentResponse(
        success: true,
        shipments: shipments,
      );
    } on ApiException catch (e) {
      return ShipmentResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ShipmentResponse(
        success: false,
        message: 'Failed to load client shipments: $e',
      );
    }
  }

  // ==================== Shipment Details ====================

  /// Get shipment by ID
  Future<ShipmentResponse> getShipment(String shipmentId) async {
    try {
      final response = await _apiClient.get('/shipments/$shipmentId');

      return ShipmentResponse(
        success: true,
        shipment: response['data'] != null 
            ? Shipment.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return ShipmentResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ShipmentResponse(
        success: false,
        message: 'Failed to load shipment: $e',
      );
    }
  }

  /// Track shipment by tracking number
  Future<ShipmentResponse> trackShipment(String trackingNumber) async {
    try {
      final response = await _apiClient.get(
        '/shipments/$trackingNumber/track',
      );

      return ShipmentResponse(
        success: true,
        trackingInfo: response['data'],
        shipment: response['data'] != null && response['data']['shipment'] != null
            ? Shipment.fromJson(response['data']['shipment'])
            : null,
      );
    } on ApiException catch (e) {
      return ShipmentResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ShipmentResponse(
        success: false,
        message: 'Failed to track shipment: $e',
      );
    }
  }

  // ==================== Create & Update ====================

  /// Create new shipment
  Future<ShipmentResponse> createShipment({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    required String origin,
    required String destination,
    required String serviceType,
    required double weight,
    required double cost,
    String? notes,
    String? companyId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/shipments',
        body: {
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'customer_email': customerEmail,
          'origin': origin,
          'destination': destination,
          'service_type': serviceType,
          'weight': weight,
          'cost': cost,
          'notes': notes,
          'company_id': companyId,
        },
      );

      return ShipmentResponse(
        success: true,
        message: response['message'] ?? 'Shipment created successfully',
        shipment: response['data'] != null 
            ? Shipment.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return ShipmentResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ShipmentResponse(
        success: false,
        message: 'Failed to create shipment: $e',
      );
    }
  }

  /// Update shipment
  Future<ShipmentResponse> updateShipment({
    required String shipmentId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? origin,
    String? destination,
    String? serviceType,
    double? weight,
    double? cost,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (customerName != null) body['customer_name'] = customerName;
      if (customerPhone != null) body['customer_phone'] = customerPhone;
      if (customerEmail != null) body['customer_email'] = customerEmail;
      if (origin != null) body['origin'] = origin;
      if (destination != null) body['destination'] = destination;
      if (serviceType != null) body['service_type'] = serviceType;
      if (weight != null) body['weight'] = weight;
      if (cost != null) body['cost'] = cost;
      if (notes != null) body['notes'] = notes;

      final response = await _apiClient.put(
        '/shipments/$shipmentId',
        body: body,
      );

      return ShipmentResponse(
        success: true,
        message: response['message'] ?? 'Shipment updated successfully',
        shipment: response['data'] != null 
            ? Shipment.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return ShipmentResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ShipmentResponse(
        success: false,
        message: 'Failed to update shipment: $e',
      );
    }
  }

  /// Update shipment status with location
  Future<ShipmentResponse> updateStatus({
    required String shipmentId,
    required ShipmentStatus status,
    String? location,
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final body = <String, dynamic>{
        'status': status.key,
      };
      if (location != null) body['location'] = location;
      if (notes != null) body['notes'] = notes;
      if (latitude != null) body['latitude'] = latitude;
      if (longitude != null) body['longitude'] = longitude;

      final response = await _apiClient.patch(
        '/shipments/$shipmentId/status',
        body: body,
      );

      return ShipmentResponse(
        success: true,
        message: response['message'] ?? 'Status updated successfully',
        shipment: response['data'] != null 
            ? Shipment.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return ShipmentResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ShipmentResponse(
        success: false,
        message: 'Failed to update status: $e',
      );
    }
  }

  // ==================== Driver Assignment ====================

  /// Assign driver to shipment
  Future<ShipmentResponse> assignDriver({
    required String shipmentId,
    required String driverId,
  }) async {
    try {
      final response = await _apiClient.post(
        '/shipments/$shipmentId/assign',
        body: {'driver_id': driverId},
      );

      return ShipmentResponse(
        success: true,
        message: response['message'] ?? 'Driver assigned successfully',
        shipment: response['data'] != null 
            ? Shipment.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return ShipmentResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ShipmentResponse(
        success: false,
        message: 'Failed to assign driver: $e',
      );
    }
  }

  /// Unassign driver from shipment
  Future<ShipmentResponse> unassignDriver(String shipmentId) async {
    try {
      final response = await _apiClient.post(
        '/shipments/$shipmentId/unassign',
      );

      return ShipmentResponse(
        success: true,
        message: response['message'] ?? 'Driver unassigned successfully',
        shipment: response['data'] != null 
            ? Shipment.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return ShipmentResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ShipmentResponse(
        success: false,
        message: 'Failed to unassign driver: $e',
      );
    }
  }

  // ==================== Driver Location ====================

  /// Get driver location
  Future<ShipmentResponse> getDriverLocation(String driverId) async {
    try {
      final response = await _apiClient.get('/drivers/$driverId/location');

      return ShipmentResponse(
        success: true,
        driverLocation: response['data'],
      );
    } on ApiException catch (e) {
      return ShipmentResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ShipmentResponse(
        success: false,
        message: 'Failed to get driver location: $e',
      );
    }
  }

  /// Update driver location (for drivers)
  Future<ShipmentResponse> updateDriverLocation({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _apiClient.post(
        '/drivers/location',
        body: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      return ShipmentResponse(
        success: true,
        message: response['message'] ?? 'Location updated',
      );
    } on ApiException catch (e) {
      return ShipmentResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ShipmentResponse(
        success: false,
        message: 'Failed to update location: $e',
      );
    }
  }

  // ==================== Delete ====================

  /// Delete shipment
  Future<ShipmentResponse> deleteShipment(String shipmentId) async {
    try {
      final response = await _apiClient.delete('/shipments/$shipmentId');

      return ShipmentResponse(
        success: true,
        message: response['message'] ?? 'Shipment deleted successfully',
      );
    } on ApiException catch (e) {
      return ShipmentResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ShipmentResponse(
        success: false,
        message: 'Failed to delete shipment: $e',
      );
    }
  }
}
