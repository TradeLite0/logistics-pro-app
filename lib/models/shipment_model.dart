/// مراحل الشحن
enum ShipmentStatus {
  received('استلام', 'Received', 'received'),
  customs('إجراءات جمركية', 'Customs Clearance', 'customs'),
  port('الميناء', 'At Port', 'port'),
  loading('التحميل', 'Loading', 'loading'),
  inTransit('في الطريق', 'In Transit', 'in_transit'),
  arrived('الوصول', 'Arrived', 'arrived'),
  delivered('تسليم نهائي', 'Delivered', 'delivered');

  final String labelAr;
  final String labelEn;
  final String key;
  
  const ShipmentStatus(this.labelAr, this.labelEn, this.key);

  String getLabel(bool isArabic) => isArabic ? labelAr : labelEn;
  
  static ShipmentStatus fromKey(String key) {
    return ShipmentStatus.values.firstWhere(
      (s) => s.key == key,
      orElse: () => ShipmentStatus.received,
    );
  }
}

/// نموذج الشحنة
class Shipment {
  final String id;
  final String trackingNumber;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String origin;
  final String destination;
  final String serviceType;
  final double weight;
  final double cost;
  final ShipmentStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final String companyId;
  final String companyName;
  final List<StatusUpdate> statusHistory;
  final String? currentLocation;
  final double? latitude;
  final double? longitude;
  final String? driverName;
  final String? driverPhone;

  Shipment({
    required this.id,
    required this.trackingNumber,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail = '',
    required this.origin,
    required this.destination,
    required this.serviceType,
    required this.weight,
    required this.cost,
    this.status = ShipmentStatus.received,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    required this.companyId,
    required this.companyName,
    this.statusHistory = const [],
    this.currentLocation,
    this.latitude,
    this.longitude,
    this.driverName,
    this.driverPhone,
  });

  factory Shipment.fromJson(Map<String, dynamic> json) {
    return Shipment(
      id: json['id']?.toString() ?? '',
      trackingNumber: json['tracking_number'] ?? json['trackingNumber'] ?? '',
      customerName: json['customer_name'] ?? json['customerName'] ?? '',
      customerPhone: json['customer_phone'] ?? json['customerPhone'] ?? '',
      customerEmail: json['customer_email'] ?? json['customerEmail'] ?? '',
      origin: json['origin'] ?? '',
      destination: json['destination'] ?? '',
      serviceType: json['service_type'] ?? json['serviceType'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
      cost: (json['cost'] ?? 0).toDouble(),
      status: ShipmentStatus.fromKey(json['status'] ?? 'received'),
      createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? json['updatedAt'] ?? ''),
      notes: json['notes'],
      companyId: json['company_id'] ?? json['companyId'] ?? '',
      companyName: json['company_name'] ?? json['companyName'] ?? '',
      statusHistory: (json['status_history'] ?? json['statusHistory'] as List<dynamic>?)
          ?.map((e) => StatusUpdate.fromJson(e))
          .toList() ?? [],
      currentLocation: json['current_location'] ?? json['currentLocation'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      driverName: json['driver_name'] ?? json['driverName'],
      driverPhone: json['driver_phone'] ?? json['driverPhone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tracking_number': trackingNumber,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'origin': origin,
      'destination': destination,
      'service_type': serviceType,
      'weight': weight,
      'cost': cost,
      'status': status.key,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'notes': notes,
      'company_id': companyId,
      'company_name': companyName,
      'status_history': statusHistory.map((e) => e.toJson()).toList(),
      'current_location': currentLocation,
      'latitude': latitude,
      'longitude': longitude,
      'driver_name': driverName,
      'driver_phone': driverPhone,
    };
  }

  Shipment copyWith({
    ShipmentStatus? status,
    DateTime? updatedAt,
    String? currentLocation,
    List<StatusUpdate>? statusHistory,
    String? notes,
  }) {
    return Shipment(
      id: id,
      trackingNumber: trackingNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      customerEmail: customerEmail,
      origin: origin,
      destination: destination,
      serviceType: serviceType,
      weight: weight,
      cost: cost,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      companyId: companyId,
      companyName: companyName,
      statusHistory: statusHistory ?? this.statusHistory,
      currentLocation: currentLocation ?? this.currentLocation,
      latitude: latitude,
      longitude: longitude,
      driverName: driverName,
      driverPhone: driverPhone,
    );
  }
}

/// تحديث الحالة
class StatusUpdate {
  final ShipmentStatus status;
  final DateTime timestamp;
  final String? location;
  final String? notes;
  final String updatedBy;

  StatusUpdate({
    required this.status,
    required this.timestamp,
    this.location,
    this.notes,
    required this.updatedBy,
  });

  factory StatusUpdate.fromJson(Map<String, dynamic> json) {
    return StatusUpdate(
      status: ShipmentStatus.fromKey(json['status'] ?? 'received'),
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      location: json['location'],
      notes: json['notes'],
      updatedBy: json['updated_by'] ?? json['updatedBy'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status.key,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'notes': notes,
      'updated_by': updatedBy,
    };
  }
}
