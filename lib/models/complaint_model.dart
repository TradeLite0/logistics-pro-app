/// نوع الشكوى
enum ComplaintType {
  shipmentIssue('مشكلة في الشحنة', 'shipment_issue'),
  driverIssue('مشكلة مع السائق', 'driver_issue'),
  appIssue('مشكلة في التطبيق', 'app_issue'),
  paymentIssue('مشكلة في الدفع', 'payment_issue'),
  other('أخرى', 'other');

  final String labelAr;
  final String key;
  
  const ComplaintType(this.labelAr, this.key);

  static ComplaintType fromKey(String key) {
    return ComplaintType.values.firstWhere(
      (t) => t.key == key,
      orElse: () => ComplaintType.other,
    );
  }
}

/// أولوية الشكوى
enum ComplaintPriority {
  low('منخفضة', 'low', 1),
  medium('متوسطة', 'medium', 2),
  high('عالية', 'high', 3),
  urgent('عاجلة', 'urgent', 4);

  final String labelAr;
  final String key;
  final int level;
  
  const ComplaintPriority(this.labelAr, this.key, this.level);

  static ComplaintPriority fromKey(String key) {
    return ComplaintPriority.values.firstWhere(
      (p) => p.key == key,
      orElse: () => ComplaintPriority.medium,
    );
  }
}

/// حالة الشكوى
enum ComplaintStatus {
  pending('معلقة', 'pending'),
  inProgress('قيد المراجعة', 'in_progress'),
  resolved('تم الحل', 'resolved'),
  closed('مغلقة', 'closed');

  final String labelAr;
  final String key;
  
  const ComplaintStatus(this.labelAr, this.key);

  static ComplaintStatus fromKey(String key) {
    return ComplaintStatus.values.firstWhere(
      (s) => s.key == key,
      orElse: () => ComplaintStatus.pending,
    );
  }
}

/// نموذج الشكوى
class Complaint {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String title;
  final String description;
  final ComplaintType type;
  final ComplaintPriority priority;
  ComplaintStatus status;
  final String? shipmentTrackingNumber;
  final List<String>? images;
  String? adminResponse;
  String? adminId;
  String? adminName;
  final DateTime createdAt;
  DateTime? updatedAt;
  DateTime? resolvedAt;

  Complaint({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.title,
    required this.description,
    required this.type,
    this.priority = ComplaintPriority.medium,
    this.status = ComplaintStatus.pending,
    this.shipmentTrackingNumber,
    this.images,
    this.adminResponse,
    this.adminId,
    this.adminName,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  factory Complaint.fromJson(Map<String, dynamic> json) {
    return Complaint(
      id: json['id']?.toString() ?? '',
      userId: json['user_id'] ?? json['userId'] ?? '',
      userName: json['user_name'] ?? json['userName'] ?? '',
      userPhone: json['user_phone'] ?? json['userPhone'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: ComplaintType.fromKey(json['type'] ?? 'other'),
      priority: ComplaintPriority.fromKey(json['priority'] ?? 'medium'),
      status: ComplaintStatus.fromKey(json['status'] ?? 'pending'),
      shipmentTrackingNumber: json['shipment_tracking_number'] ?? json['shipmentTrackingNumber'],
      images: (json['images'] as List<dynamic>?)?.cast<String>(),
      adminResponse: json['admin_response'] ?? json['adminResponse'],
      adminId: json['admin_id'] ?? json['adminId'],
      adminName: json['admin_name'] ?? json['adminName'],
      createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? json['updatedAt'] ?? ''),
      resolvedAt: DateTime.tryParse(json['resolved_at'] ?? json['resolvedAt'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_phone': userPhone,
      'title': title,
      'description': description,
      'type': type.key,
      'priority': priority.key,
      'status': status.key,
      'shipment_tracking_number': shipmentTrackingNumber,
      'images': images,
      'admin_response': adminResponse,
      'admin_id': adminId,
      'admin_name': adminName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  Complaint copyWith({
    ComplaintStatus? status,
    String? adminResponse,
    String? adminId,
    String? adminName,
    DateTime? updatedAt,
    DateTime? resolvedAt,
  }) {
    return Complaint(
      id: id,
      userId: userId,
      userName: userName,
      userPhone: userPhone,
      title: title,
      description: description,
      type: type,
      priority: priority,
      status: status ?? this.status,
      shipmentTrackingNumber: shipmentTrackingNumber,
      images: images,
      adminResponse: adminResponse ?? this.adminResponse,
      adminId: adminId ?? this.adminId,
      adminName: adminName ?? this.adminName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
