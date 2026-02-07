/// أنواع المستخدمين
enum UserRole {
  client('عميل', 'Client', 'client'),
  driver('سائق', 'Driver', 'driver'),
  supervisor('مشرف', 'Supervisor', 'supervisor'),
  admin('مدير', 'Admin', 'admin');

  final String labelAr;
  final String labelEn;
  final String key;

  const UserRole(this.labelAr, this.labelEn, this.key);

  String getLabel(bool isArabic) => isArabic ? labelAr : labelEn;

  static UserRole fromKey(String? key) {
    if (key == null) return UserRole.client;
    return UserRole.values.firstWhere(
      (r) => r.key == key.toLowerCase(),
      orElse: () => UserRole.client,
    );
  }

  /// التحقق إذا كان المستخدم يمكنه استخدام ماسح QR
  bool get canUseQRScanner => 
      this == UserRole.driver || 
      this == UserRole.supervisor || 
      this == UserRole.admin;

  /// التحقق إذا كان المستخدم يمكنه رؤية تفاصيل إضافية
  bool get canViewDetails => 
      this == UserRole.supervisor || 
      this == UserRole.admin;

  /// التحقق إذا كان المستخدم يمكنه تنفيذ جميع الإجراءات
  bool get canPerformAllActions => 
      this == UserRole.supervisor || 
      this == UserRole.admin;
}

/// نموذج المستخدم
class User {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final UserRole role;
  final String? token;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  User({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.token,
    this.fcmToken,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      role: UserRole.fromKey(json['type'] ?? json['role']),
      token: json['token'],
      fcmToken: json['fcm_token'] ?? json['fcmToken'],
      createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? json['updatedAt'] ?? ''),
      isActive: json['is_active'] ?? json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'type': role.key,
      'token': token,
      'fcm_token': fcmToken,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  User copyWith({
    String? name,
    String? phone,
    String? email,
    UserRole? role,
    String? token,
    String? fcmToken,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return User(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      token: token ?? this.token,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}