import '../models/complaint_model.dart';
import 'api_client.dart';

/// Response from complaint operations
class ComplaintResponse {
  final bool success;
  final String? message;
  final Complaint? complaint;
  final List<Complaint>? complaints;

  ComplaintResponse({
    required this.success,
    this.message,
    this.complaint,
    this.complaints,
  });
}

/// Service for managing complaints
class ComplaintService {
  static final ComplaintService _instance = ComplaintService._internal();
  factory ComplaintService() => _instance;
  ComplaintService._internal();

  final ApiClient _apiClient = ApiClient();

  // ==================== Create & Submit ====================

  /// Submit a new complaint
  Future<ComplaintResponse> submitComplaint({
    required String title,
    required String description,
    required ComplaintType type,
    ComplaintPriority priority = ComplaintPriority.medium,
    String? shipmentTrackingNumber,
    List<String>? images,
  }) async {
    try {
      final response = await _apiClient.post(
        '/complaints',
        body: {
          'title': title,
          'description': description,
          'type': type.key,
          'priority': priority.key,
          'shipment_tracking_number': shipmentTrackingNumber,
          'images': images,
        },
      );

      return ComplaintResponse(
        success: true,
        message: response['message'] ?? 'Complaint submitted successfully',
        complaint: response['data'] != null 
            ? Complaint.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return ComplaintResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ComplaintResponse(
        success: false,
        message: 'Failed to submit complaint: $e',
      );
    }
  }

  // ==================== Get Complaints ====================

  /// Get all complaints (for admins/supervisors)
  Future<ComplaintResponse> getAllComplaints({
    ComplaintStatus? status,
    ComplaintPriority? priority,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) {
        queryParams['status'] = status.key;
      }
      if (priority != null) {
        queryParams['priority'] = priority.key;
      }

      final response = await _apiClient.get(
        '/complaints',
        queryParams: queryParams,
      );

      final List<dynamic> data = response['data'] ?? [];
      final complaints = data.map((c) => Complaint.fromJson(c)).toList();

      return ComplaintResponse(
        success: true,
        complaints: complaints,
      );
    } on ApiException catch (e) {
      return ComplaintResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ComplaintResponse(
        success: false,
        message: 'Failed to load complaints: $e',
      );
    }
  }

  /// Get complaints for a specific user
  Future<ComplaintResponse> getUserComplaints(String userId) async {
    try {
      final response = await _apiClient.get('/complaints/user/$userId');

      final List<dynamic> data = response['data'] ?? [];
      final complaints = data.map((c) => Complaint.fromJson(c)).toList();

      return ComplaintResponse(
        success: true,
        complaints: complaints,
      );
    } on ApiException catch (e) {
      return ComplaintResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ComplaintResponse(
        success: false,
        message: 'Failed to load user complaints: $e',
      );
    }
  }

  /// Get my complaints (for current logged-in user)
  Future<ComplaintResponse> getMyComplaints() async {
    try {
      final response = await _apiClient.get('/complaints/my');

      final List<dynamic> data = response['data'] ?? [];
      final complaints = data.map((c) => Complaint.fromJson(c)).toList();

      return ComplaintResponse(
        success: true,
        complaints: complaints,
      );
    } on ApiException catch (e) {
      return ComplaintResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ComplaintResponse(
        success: false,
        message: 'Failed to load complaints: $e',
      );
    }
  }

  /// Get complaint details by ID
  Future<ComplaintResponse> getComplaintById(String complaintId) async {
    try {
      final response = await _apiClient.get('/complaints/$complaintId');

      return ComplaintResponse(
        success: true,
        complaint: response['data'] != null 
            ? Complaint.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return ComplaintResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ComplaintResponse(
        success: false,
        message: 'Failed to load complaint details: $e',
      );
    }
  }

  // ==================== Update ====================

  /// Update complaint status (admin/supervisor only)
  Future<ComplaintResponse> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
    String? adminResponse,
  }) async {
    try {
      final response = await _apiClient.patch(
        '/complaints/$complaintId/status',
        body: {
          'status': status.key,
          if (adminResponse != null) 'admin_response': adminResponse,
        },
      );

      return ComplaintResponse(
        success: true,
        message: response['message'] ?? 'Status updated successfully',
        complaint: response['data'] != null 
            ? Complaint.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return ComplaintResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ComplaintResponse(
        success: false,
        message: 'Failed to update status: $e',
      );
    }
  }

  /// Add admin response to complaint
  Future<ComplaintResponse> addAdminResponse({
    required String complaintId,
    required String response,
  }) async {
    try {
      final apiResponse = await _apiClient.post(
        '/complaints/$complaintId/response',
        body: {'response': response},
      );

      return ComplaintResponse(
        success: true,
        message: apiResponse['message'] ?? 'Response added successfully',
        complaint: apiResponse['data'] != null 
            ? Complaint.fromJson(apiResponse['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return ComplaintResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ComplaintResponse(
        success: false,
        message: 'Failed to add response: $e',
      );
    }
  }

  /// Update complaint (for owner)
  Future<ComplaintResponse> updateComplaint({
    required String complaintId,
    String? title,
    String? description,
    ComplaintPriority? priority,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (priority != null) body['priority'] = priority.key;

      final response = await _apiClient.put(
        '/complaints/$complaintId',
        body: body,
      );

      return ComplaintResponse(
        success: true,
        message: response['message'] ?? 'Complaint updated successfully',
        complaint: response['data'] != null 
            ? Complaint.fromJson(response['data']) 
            : null,
      );
    } on ApiException catch (e) {
      return ComplaintResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ComplaintResponse(
        success: false,
        message: 'Failed to update complaint: $e',
      );
    }
  }

  // ==================== Delete ====================

  /// Delete complaint
  Future<ComplaintResponse> deleteComplaint(String complaintId) async {
    try {
      final response = await _apiClient.delete('/complaints/$complaintId');

      return ComplaintResponse(
        success: true,
        message: response['message'] ?? 'Complaint deleted successfully',
      );
    } on ApiException catch (e) {
      return ComplaintResponse(
        success: false,
        message: e.message,
      );
    } catch (e) {
      return ComplaintResponse(
        success: false,
        message: 'Failed to delete complaint: $e',
      );
    }
  }
}
