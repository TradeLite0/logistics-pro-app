class AppConstants {
  // API Base URL
  static const String apiBaseUrl = 'https://longest-ice-production.up.railway.app/api';
  
  // App Info
  static const String appName = 'شحناتي';
  static const String appVersion = '1.0.0';
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Cache Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String fcmTokenKey = 'fcm_token';
  
  // Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
}

class AppColors {
  static const int primary = 0xFF1E88E5;
  static const int primaryDark = 0xFF1565C0;
  static const int accent = 0xFF00BCD4;
  static const int background = 0xFFF5F5F5;
  static const int surface = 0xFFFFFFFF;
  static const int error = 0xFFE53935;
  static const int success = 0xFF43A047;
  static const int warning = 0xFFFFB300;
  static const int textPrimary = 0xFF212121;
  static const int textSecondary = 0xFF757575;
  static const int divider = 0xFFE0E0E0;
}

class ShipmentStatus {
  static const String pending = 'pending';
  static const String assigned = 'assigned';
  static const String pickedUp = 'picked_up';
  static const String inTransit = 'in_transit';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';
  
  static const Map<String, String> arabicNames = {
    pending: 'قيد الانتظار',
    assigned: 'تم التعيين',
    pickedUp: 'تم الاستلام',
    inTransit: 'في الطريق',
    delivered: 'تم التوصيل',
    cancelled: 'ملغي',
  };
}
