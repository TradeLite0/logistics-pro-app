import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

/// خدمة الموقع والخرائط
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // ==================== الموقع الحالي ====================

  /// طلب إذن الموقع
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
           permission != LocationPermission.deniedForever;
  }

  /// الحصول على الموقع الحالي
  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await requestPermission();
      if (!hasPermission) return null;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      return null;
    }
  }

  /// الحصول على دفق الموقع المباشر
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  // ==================== الترميز الجغرافي ====================

  /// تحويل العنوان إلى إحداثيات
  Future<LatLng?> geocodeAddress(String address) async {
    try {
      final locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations.first.latitude, locations.first.longitude);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// تحويل الإحداثيات إلى عنوان
  Future<String?> reverseGeocode(LatLng position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return '${place.street}, ${place.locality}, ${place.country}';
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== حسابات المسافة ====================

  /// حساب المسافة بين نقطتين بالكيلومتر
  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
      start.latitude,
      start.longitude,
      end.latitude,
      end.longitude,
    ) / 1000; // تحويل إلى كيلومتر
  }

  /// حساب المدة التقديرية بالدقائق (بافتراض متوسط سرعة 60 كم/ساعة)
  int estimateDurationMinutes(LatLng start, LatLng end) {
    final distanceKm = calculateDistance(start, end);
    return (distanceKm / 60 * 60).round(); // دقائق
  }

  // ==================== الرسم على الخريطة ====================

  /// إنشاء خط الطريق بين نقطتين
  Polyline createRoutePolyline({
    required String id,
    required LatLng origin,
    required LatLng destination,
    Color color = const Color(0xFF2C3E50),
    double width = 5,
  }) {
    return Polyline(
      polylineId: PolylineId(id),
      points: _generateRoutePoints(origin, destination),
      color: color,
      width: width.toInt(),
      geodesic: true,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }

  /// توليد نقاط خط الطريق (محاكاة)
  List<LatLng> _generateRoutePoints(LatLng start, LatLng end) {
    final points = <LatLng>[];
    const steps = 20;
    
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      
      // إضافة انحناء طفيف لجعل الخط أكثر طبيعية
      final curve = sin(t * pi) * 0.01;
      
      points.add(LatLng(lat + curve, lng));
    }
    
    return points;
  }

  /// تحريك الماركر تدريجياً
  Stream<LatLng> animateMarkerMovement({
    required LatLng start,
    required LatLng end,
    required Duration duration,
    int steps = 60,
  }) async* {
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      yield LatLng(lat, lng);
      await Future.delayed(Duration(milliseconds: duration.inMilliseconds ~/ steps));
    }
  }

  /// محاكاة حركة السائق بين نقطتين
  Stream<LatLng> simulateDriverMovement({
    required LatLng origin,
    required LatLng destination,
    double speedKmPerHour = 80,
  }) async* {
    final totalDistance = calculateDistance(origin, destination);
    final durationHours = totalDistance / speedKmPerHour;
    final durationMs = (durationHours * 60 * 60 * 1000).round();
    
    // تحديث كل ثانية
    const updateInterval = 1000;
    final steps = durationMs ~/ updateInterval;
    
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      final lat = origin.latitude + (destination.latitude - origin.latitude) * t;
      final lng = origin.longitude + (destination.longitude - origin.longitude) * t;
      
      // إضافة بعض العشوائية لجعل الحركة واقعية
      final randomOffset = (sin(i * 0.5) * 0.0005);
      
      yield LatLng(lat + randomOffset, lng + randomOffset);
      await Future.delayed(const Duration(milliseconds: updateInterval));
    }
  }

  // ==================== المواقع الافتراضية للمدن السعودية ====================

  static final Map<String, LatLng> saudiCities = {
    'الرياض': const LatLng(24.7136, 46.6753),
    'جدة': const LatLng(21.4858, 39.1925),
    'مكة': const LatLng(21.3891, 39.8579),
    'المدينة المنورة': const LatLng(24.5247, 39.5692),
    'الدمام': const LatLng(26.4207, 50.0888),
    'الخبر': const LatLng(26.2172, 50.1971),
    'تبوك': const LatLng(28.3835, 36.5662),
    'أبها': const LatLng(18.2164, 42.5053),
    ' الطائف': const LatLng(21.2854, 40.4262),
    'بريدة': const LatLng(26.3337, 43.9766),
  };

  /// الحصول على إحداثيات المدينة
  static LatLng? getCityCoordinates(String cityName) {
    // البحث عن المدينة في القائمة
    for (final entry in saudiCities.entries) {
      if (cityName.contains(entry.key) || entry.key.contains(cityName)) {
        return entry.value;
      }
    }
    return null;
  }

  /// إنشاء موقع عشوائي بالقرب من نقطة معينة
  LatLng generateRandomLocationNear(LatLng center, double radiusKm) {
    final random = Random();
    final radiusInDegrees = radiusKm / 111;
    
    final u = random.nextDouble();
    final v = random.nextDouble();
    final w = radiusInDegrees * sqrt(u);
    final t = 2 * pi * v;
    
    final x = w * cos(t);
    final y = w * sin(t);
    
    return LatLng(center.latitude + y, center.longitude + x);
  }
}

/// نموذج موقع الشحنة
class ShipmentLocation {
  final String id;
  final LatLng position;
  final String? address;
  final LocationType type;
  final String? label;

  ShipmentLocation({
    required this.id,
    required this.position,
    this.address,
    required this.type,
    this.label,
  });

  Marker toMarker({
    VoidCallback? onTap,
    BitmapDescriptor? icon,
  }) {
    return Marker(
      markerId: MarkerId(id),
      position: position,
      icon: icon ?? BitmapDescriptor.defaultMarker,
      infoWindow: InfoWindow(
        title: label ?? _getDefaultLabel(),
        snippet: address,
      ),
      onTap: onTap,
    );
  }

  String _getDefaultLabel() {
    switch (type) {
      case LocationType.origin:
        return 'نقطة الاستلام';
      case LocationType.destination:
        return 'نقطة التسليم';
      case LocationType.driver:
        return 'موقع السائق';
      case LocationType.waypoint:
        return 'نقطة توقف';
    }
  }
}

enum LocationType {
  origin,
  destination,
  driver,
  waypoint,
}
