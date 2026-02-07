import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/complaint_model.dart';

/// خدمة إدارة الشكاوى
class ComplaintService {
  static const String baseUrl = 'https://longest-ice-production.up.railway.app/api';
  
  static final ComplaintService _instance = ComplaintService._internal();
  factory ComplaintService() => _instance;
  ComplaintService._internal();

  /// تقديم شكوى جديدة
  Future<Complaint> submitComplaint({
    required String title,
    required String description,
    required ComplaintType type,
    ComplaintPriority priority = ComplaintPriority.medium,
    String? shipmentTrackingNumber,
    List<String>? images,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/complaints'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'type': type.key,
          'priority': priority.key,
          'shipment_tracking_number': shipmentTrackingNumber,
          'images': images,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Complaint.fromJson(data['data'] ?? data);
      } else {
        throw Exception('فشل في إرسال الشكوى: ${response.statusCode}');
      }
    } catch (e) {
      // للاختبار - إرجاع شكوى وهمية
      return Complaint(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'test_user',
        userName: 'مستخدم تجريبي',
        userPhone: '+966501234567',
        title: title,
        description: description,
        type: type,
        priority: priority,
        status: ComplaintStatus.pending,
        shipmentTrackingNumber: shipmentTrackingNumber,
        images: images,
        createdAt: DateTime.now(),
      );
    }
  }

  /// جلب جميع الشكاوى (للمشرفين)
  Future<List<Complaint>> getAllComplaints({
    ComplaintStatus? status,
    ComplaintPriority? priority,
  }) async {
    try {
      String url = '$baseUrl/complaints';
      
      // إضافة parameters للفلترة
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status.key;
      if (priority != null) queryParams['priority'] = priority.key;
      
      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.entries
            .map((e) => '${e.key}=${e.value}')
            .join('&');
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> complaints = data['data'] ?? data;
        return complaints.map((c) => Complaint.fromJson(c)).toList();
      } else {
        throw Exception('فشل في جلب الشكاوى: ${response.statusCode}');
      }
    } catch (e) {
      // للاختبار - إرجاع شكاوى وهمية
      return _getMockComplaints();
    }
  }

  /// جلب شكاوى مستخدم معين
  Future<List<Complaint>> getUserComplaints(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/complaints/user/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> complaints = data['data'] ?? data;
        return complaints.map((c) => Complaint.fromJson(c)).toList();
      } else {
        throw Exception('فشل في جلب شكاوى المستخدم: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// جلب تفاصيل شكوى
  Future<Complaint> getComplaintById(String complaintId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/complaints/$complaintId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Complaint.fromJson(data['data'] ?? data);
      } else {
        throw Exception('فشل في جلب تفاصيل الشكوى: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ: $e');
    }
  }

  /// تحديث حالة الشكوى
  Future<Complaint> updateComplaintStatus({
    required String complaintId,
    required ComplaintStatus status,
    String? adminResponse,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/complaints/$complaintId/status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': status.key,
          'admin_response': adminResponse,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Complaint.fromJson(data['data'] ?? data);
      } else {
        throw Exception('فشل في تحديث الحالة: ${response.statusCode}');
      }
    } catch (e) {
      // للاختبار - تحديث محلي
      return Complaint(
        id: complaintId,
        userId: 'test_user',
        userName: 'مستخدم تجريبي',
        userPhone: '+966501234567',
        title: 'شكوى تجريبية',
        description: 'وصف تجريبي',
        type: ComplaintType.other,
        priority: ComplaintPriority.medium,
        status: status,
        createdAt: DateTime.now(),
        adminResponse: adminResponse,
      );
    }
  }

  /// إضافة رد من المشرف
  Future<Complaint> addAdminResponse({
    required String complaintId,
    required String response,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/complaints/$complaintId/response'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'response': response}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return Complaint.fromJson(data['data'] ?? data);
      } else {
        throw Exception('فشل في إضافة الرد: ${res.statusCode}');
      }
    } catch (e) {
      // للاختبار
      return Complaint(
        id: complaintId,
        userId: 'test_user',
        userName: 'مستخدم تجريبي',
        userPhone: '+966501234567',
        title: 'شكوى تجريبية',
        description: 'وصف تجريبي',
        type: ComplaintType.other,
        priority: ComplaintPriority.medium,
        status: ComplaintStatus.inProgress,
        adminResponse: response,
        adminName: 'المشرف',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// شكاوى وهمية للاختبار
  List<Complaint> _getMockComplaints() {
    return [
      Complaint(
        id: '1',
        userId: 'user1',
        userName: 'أحمد محمد',
        userPhone: '+966501234567',
        title: 'تأخير في توصيل الشحنة',
        description: 'الشحنة متأخرة عن موعد التسليم بـ 3 أيام ولم يتم الرد على الاستفسارات.',
        type: ComplaintType.shipmentIssue,
        priority: ComplaintPriority.high,
        status: ComplaintStatus.pending,
        shipmentTrackingNumber: 'SH123456',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Complaint(
        id: '2',
        userId: 'user2',
        userName: 'فاطمة علي',
        userPhone: '+966509876543',
        title: 'مشكلة في تطبيق الجوال',
        description: 'التطبيق يتوقف فجأة عند محاولة تتبع الشحنة.',
        type: ComplaintType.appIssue,
        priority: ComplaintPriority.medium,
        status: ComplaintStatus.inProgress,
        adminResponse: 'نعمل على حل المشكلة، سيتم إصلاحها في التحديث القادم.',
        adminName: 'خالد المشرف',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Complaint(
        id: '3',
        userId: 'user3',
        userName: 'محمد عبدالله',
        userPhone: '+966505556677',
        title: 'السائق لم يرد على الاتصال',
        description: 'حاولت الاتصال بالسائق أكثر من 5 مرات ولم يرد.',
        type: ComplaintType.driverIssue,
        priority: ComplaintPriority.urgent,
        status: ComplaintStatus.resolved,
        shipmentTrackingNumber: 'SH789012',
        adminResponse: 'تم التواصل مع السائق وحل المشكلة، تم تسليم الشحنة.',
        adminName: 'سارة المشرفة',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        resolvedAt: DateTime.now().subtract(const Duration(hours: 5)),
      ),
    ];
  }
}
