import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/shipment_model.dart';
import '../../services/location_service.dart';

/// شاشة تتبع الشحنة على الخريطة
class TrackShipmentMapScreen extends StatefulWidget {
  final Shipment shipment;

  const TrackShipmentMapScreen({
    super.key,
    required this.shipment,
  });

  @override
  State<TrackShipmentMapScreen> createState() => _TrackShipmentMapScreenState();
}

class _TrackShipmentMapScreenState extends State<TrackShipmentMapScreen> {
  GoogleMapController? _mapController;
  final LocationService _locationService = LocationService();
  
  // الماركرات والخطوط
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  
  // المواقع
  LatLng? _originPosition;
  LatLng? _destinationPosition;
  LatLng? _driverPosition;
  
  // حالة الشاشة
  bool _isLoading = true;
  bool _isSimulating = false;
  double _mapZoom = 6;
  
  // الموارد القابلة للإلغاء
  StreamSubscription<LatLng>? _driverMovementSubscription;
  Timer? _locationUpdateTimer;
  
  // أيقونات مخصصة
  BitmapDescriptor? _originIcon;
  BitmapDescriptor? _destinationIcon;
  BitmapDescriptor? _driverIcon;
  BitmapDescriptor? _truckIcon;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _driverMovementSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// تهيئة الخريطة
  Future<void> _initializeMap() async {
    await _loadCustomMarkers();
    await _setLocations();
    _startLocationSimulation();
    
    setState(() {
      _isLoading = false;
    });
  }

  /// تحميل الأيقونات المخصصة
  Future<void> _loadCustomMarkers() async {
    _originIcon = await _createCustomMarker(
      Icons.location_on,
      Colors.green,
      size: 80,
    );
    _destinationIcon = await _createCustomMarker(
      Icons.flag,
      Colors.red,
      size: 80,
    );
    _driverIcon = await _createCustomMarker(
      Icons.local_shipping,
      Colors.orange,
      size: 100,
    );
    _truckIcon = await _createCustomMarker(
      Icons.delivery_dining,
      const Color(0xFF2C3E50),
      size: 100,
    );
  }

  /// إنشاء ماركر مخصص
  Future<BitmapDescriptor> _createCustomMarker(
    IconData icon,
    Color color, {
    required int size,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    
    // رسم الدائرة الخلفية
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 4,
      paint,
    );
    
    // رسم الحدود البيضاء
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 4,
      borderPaint,
    );
    
    // رسم الأيقونة
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.5,
        fontFamily: icon.fontFamily,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );
    
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  /// تعيين المواقع
  Future<void> _setLocations() async {
    // الحصول على إحداثيات المصدر والوجهة
    _originPosition = LocationService.getCityCoordinates(widget.shipment.origin) ??
                      const LatLng(24.7136, 46.6753); // الرياض افتراضي
    
    _destinationPosition = LocationService.getCityCoordinates(widget.shipment.destination) ??
                           const LatLng(21.4858, 39.1925); // جدة افتراضي
    
    // موقع السائق الأولي (في نقطة البداية أو موقع حالي)
    _driverPosition = widget.shipment.latitude != null && widget.shipment.longitude != null
        ? LatLng(widget.shipment.latitude!, widget.shipment.longitude!)
        : _getInitialDriverPosition();

    _updateMarkers();
    _updatePolylines();
  }

  /// الحصول على موقع السائق الأولي
  LatLng _getInitialDriverPosition() {
    // إذا كانت الشحنة في الطريق، ضع السائق في منتصف الطريق
    if (widget.shipment.status == ShipmentStatus.inTransit && 
        _originPosition != null && _destinationPosition != null) {
      return LatLng(
        (_originPosition!.latitude + _destinationPosition!.latitude) / 2,
        (_originPosition!.longitude + _destinationPosition!.longitude) / 2,
      );
    }
    return _originPosition ?? const LatLng(24.7136, 46.6753);
  }

  /// تحديث الماركرات
  void _updateMarkers() {
    final markers = <Marker>{};

    // ماركر نقطة الاستلام
    if (_originPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('origin'),
          position: _originPosition!,
          icon: _originIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: 'نقطة الاستلام',
            snippet: widget.shipment.origin,
          ),
        ),
      );
    }

    // ماركر نقطة التسليم
    if (_destinationPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: _destinationPosition!,
          icon: _destinationIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'نقطة التسليم',
            snippet: widget.shipment.destination,
          ),
        ),
      );
    }

    // ماركر السائق
    if (_driverPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverPosition!,
          icon: _truckIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: widget.shipment.driverName ?? 'السائق',
            snippet: 'الموقع الحالي',
          ),
          rotation: _calculateRotation(),
          flat: true,
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  /// حساب زاوية دوران السائق
  double _calculateRotation() {
    if (_originPosition == null || _destinationPosition == null) return 0;
    
    final deltaLng = _destinationPosition!.longitude - _originPosition!.longitude;
    final deltaLat = _destinationPosition!.latitude - _originPosition!.latitude;
    
    return (deltaLng >= 0 ? 1 : -1) * 
           (deltaLat.abs() / (deltaLat.abs() + deltaLng.abs())) * 90;
  }

  /// تحديث خطوط الطريق
  void _updatePolylines() {
    if (_originPosition == null || _destinationPosition == null) return;

    final polylines = <Polyline>{};

    // خط الطريق الرئيسي
    polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: _generateSmoothRoute(_originPosition!, _destinationPosition!),
        color: const Color(0xFF2C3E50),
        width: 5,
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    );

    // خط المسار المقطوع (من البداية إلى السائق)
    if (_driverPosition != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('completed_route'),
          points: _generateSmoothRoute(_originPosition!, _driverPosition!),
          color: const Color(0xFF27AE60),
          width: 5,
          geodesic: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }

    setState(() {
      _polylines = polylines;
    });
  }

  /// توليد مسار ناعم بين نقطتين
  List<LatLng> _generateSmoothRoute(LatLng start, LatLng end) {
    final points = <LatLng>[];
    const steps = 50;
    
    for (int i = 0; i <= steps; i++) {
      final t = i / steps;
      
      // استخدام منحنى بيزيه للحصول على مسار منحنٍ
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      
      // إضافة انحناء طفيف
      final curve = (t * (1 - t)) * 0.5;
      final curvedLat = lat + curve;
      
      points.add(LatLng(curvedLat, lng));
    }
    
    return points;
  }

  /// بدء محاكاة حركة السائق
  void _startLocationSimulation() {
    if (_originPosition == null || _destinationPosition == null) return;
    if (widget.shipment.status != ShipmentStatus.inTransit) return;

    setState(() {
      _isSimulating = true;
    });

    // محاكاة الحركة باستخدام timer
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _simulateDriverMovement();
    });
  }

  /// محاكاة حركة السائق
  void _simulateDriverMovement() {
    if (_originPosition == null || _destinationPosition == null) return;
    if (_driverPosition == null) return;

    // حساب التقدم الحالي
    final totalDistance = _locationService.calculateDistance(_originPosition!, _destinationPosition!);
    final coveredDistance = _locationService.calculateDistance(_originPosition!, _driverPosition!);
    var progress = coveredDistance / totalDistance;
    
    // زيادة التقدم
    progress += 0.05; // 5% كل مرة
    if (progress >= 1) {
      progress = 1;
      _locationUpdateTimer?.cancel();
      setState(() {
        _isSimulating = false;
      });
    }

    // حساب الموقع الجديد
    final newLat = _originPosition!.latitude + 
                   (_destinationPosition!.latitude - _originPosition!.latitude) * progress;
    final newLng = _originPosition!.longitude + 
                   (_destinationPosition!.longitude - _originPosition!.longitude) * progress;
    
    // إضافة بعض العشوائية
    final random = (progress * 10).toInt();
    final offsetLat = (random % 2 == 0 ? 0.001 : -0.001) * (1 - progress);
    
    setState(() {
      _driverPosition = LatLng(newLat + offsetLat, newLng);
      _updateMarkers();
      _updatePolylines();
    });

    // تحريك الكاميرا لمرافقة السائق
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(_driverPosition!),
    );
  }

  /// تحريك الكاميرا لتظهر كل الماركرات
  void _fitBounds() {
    if (_originPosition == null || _destinationPosition == null) return;
    
    final bounds = LatLngBounds(
      southwest: LatLng(
        _originPosition!.latitude < _destinationPosition!.latitude
            ? _originPosition!.latitude
            : _destinationPosition!.latitude,
        _originPosition!.longitude < _destinationPosition!.longitude
            ? _originPosition!.longitude
            : _destinationPosition!.longitude,
      ),
      northeast: LatLng(
        _originPosition!.latitude > _destinationPosition!.latitude
            ? _originPosition!.latitude
            : _destinationPosition!.latitude,
        _originPosition!.longitude > _destinationPosition!.longitude
            ? _originPosition!.longitude
            : _destinationPosition!.longitude,
      ),
    );
    
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // الخريطة
          _buildMap(),
          
          // شريط العنوان
          _buildAppBar(),
          
          // أزرار التحكم
          _buildMapControls(),
          
          // بطاقة معلومات الشحنة
          _buildInfoCard(),
          
          // مؤشر التحميل
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// بناء الخريطة
  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _originPosition ?? const LatLng(24.7136, 46.6753),
        zoom: _mapZoom,
      ),
      markers: _markers,
      polylines: _polylines,
      mapType: MapType.normal,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      onMapCreated: (controller) {
        _mapController = controller;
        // تطبيق نمط مخصص للخريطة
        _setMapStyle();
        // ضبط الحدود بعد إنشاء الخريطة
        Future.delayed(const Duration(milliseconds: 500), _fitBounds);
      },
      onCameraMove: (position) {
        _mapZoom = position.zoom;
      },
    );
  }

  /// تعيين نمط الخريطة
  Future<void> _setMapStyle() async {
    const mapStyle = '''[
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "transit",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      }
    ]''';
    
    _mapController?.setMapStyle(mapStyle);
  }

  /// شريط العنوان
  Widget _buildAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50)),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'تتبع الشحنة',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    Text(
                      widget.shipment.trackingNumber,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.shipment.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.shipment.status.labelAr,
                  style: TextStyle(
                    color: _getStatusColor(widget.shipment.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// أزرار التحكم في الخريطة
  Widget _buildMapControls() {
    return Positioned(
      top: 100,
      right: 16,
      child: Column(
        children: [
          // زر تكبير
          _buildControlButton(
            icon: Icons.add,
            onTap: () {
              _mapController?.animateCamera(CameraUpdate.zoomIn());
            },
          ),
          const SizedBox(height: 8),
          // زر تصغير
          _buildControlButton(
            icon: Icons.remove,
            onTap: () {
              _mapController?.animateCamera(CameraUpdate.zoomOut());
            },
          ),
          const SizedBox(height: 8),
          // زر عرض الكل
          _buildControlButton(
            icon: Icons.fit_screen,
            onTap: _fitBounds,
            tooltip: 'عرض المسار كاملاً',
          ),
          const SizedBox(height: 8),
          // زر تحديث الموقع
          _buildControlButton(
            icon: Icons.my_location,
            onTap: () {
              if (_driverPosition != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_driverPosition!, 15),
                );
              }
            },
            tooltip: 'موقع السائق',
          ),
        ],
      ),
    );
  }

  /// زر تحكم
  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF2C3E50), size: 20),
        ),
      ),
    );
  }

  /// بطاقة معلومات الشحنة
  Widget _buildInfoCard() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // شريط السحب
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // معلومات السائق
                    if (widget.shipment.driverName != null)
                      _buildDriverInfo(),
                    
                    if (widget.shipment.driverName != null)
                      const Divider(height: 24),
                    
                    // مواقع الشحنة
                    _buildLocationsInfo(),
                    
                    const SizedBox(height: 16),
                    
                    // شريط التقدم
                    _buildProgressIndicator(),
                    
                    const SizedBox(height: 16),
                    
                    // معلومات إضافية
                    Row(
                      children: [
                        _buildInfoItem(
                          icon: Icons.access_time,
                          label: 'الوقت المتوقع',
                          value: _getEstimatedTime(),
                        ),
                        const SizedBox(width: 16),
                        _buildInfoItem(
                          icon: Icons.route,
                          label: 'المسافة المتبقية',
                          value: _getRemainingDistance(),
                        ),
                      ],
                    ),
                    
                    if (_isSimulating) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27AE60).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF27AE60),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'جاري التتبع المباشر',
                              style: TextStyle(
                                color: Color(0xFF27AE60),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// معلومات السائق
  Widget _buildDriverInfo() {
    return Row(
      children: [
        // صورة السائق
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        
        // معلومات السائق
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.shipment.driverName!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'مندوب التوصيل',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
              if (widget.shipment.driverPhone != null)
                Text(
                  widget.shipment.driverPhone!,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        
        // زر الاتصال
        if (widget.shipment.driverPhone != null)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF27AE60).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                // الاتصال بالسائق
              },
              icon: const Icon(Icons.phone, color: Color(0xFF27AE60)),
            ),
          ),
      ],
    );
  }

  /// معلومات المواقع
  Widget _buildLocationsInfo() {
    return Row(
      children: [
        // نقطة البداية
        Expanded(
          child: _buildLocationPoint(
            icon: Icons.location_on,
            color: Colors.green,
            title: 'نقطة الاستلام',
            address: widget.shipment.origin,
          ),
        ),
        
        // الخط الواصل
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E50),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: 2,
                height: 30,
                color: Colors.grey[300],
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        
        // نقطة الوصول
        Expanded(
          child: _buildLocationPoint(
            icon: Icons.flag,
            color: Colors.red,
            title: 'نقطة التسليم',
            address: widget.shipment.destination,
          ),
        ),
      ],
    );
  }

  /// نقطة موقع
  Widget _buildLocationPoint({
    required IconData icon,
    required Color color,
    required String title,
    required String address,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          address,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF2C3E50),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// شريط التقدم
  Widget _buildProgressIndicator() {
    final progress = _calculateProgress();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'تقدم الشحنة',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF2C3E50),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(_getStatusColor(widget.shipment.status)),
          ),
        ),
      ],
    );
  }

  /// عنصر معلومة
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[400]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFF2C3E50),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// حساب نسبة التقدم
  double _calculateProgress() {
    if (_originPosition == null || _destinationPosition == null) {
      return _getStatusProgress(widget.shipment.status);
    }
    
    if (_driverPosition == null) return 0;
    
    final total = _locationService.calculateDistance(_originPosition!, _destinationPosition!);
    final covered = _locationService.calculateDistance(_originPosition!, _driverPosition!);
    
    return (covered / total).clamp(0.0, 1.0);
  }

  /// الحصول على وقت الوصول المتوقع
  String _getEstimatedTime() {
    if (_driverPosition == null || _destinationPosition == null) return '--:--';
    
    final minutes = _locationService.estimateDurationMinutes(_driverPosition!, _destinationPosition!);
    if (minutes < 60) {
      return '$minutes دقيقة';
    }
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '$hours:${remainingMinutes.toString().padLeft(2, '0')} ساعة';
  }

  /// الحصول على المسافة المتبقية
  String _getRemainingDistance() {
    if (_driverPosition == null || _destinationPosition == null) return '-- كم';
    
    final distance = _locationService.calculateDistance(_driverPosition!, _destinationPosition!);
    return '${distance.toStringAsFixed(1)} كم';
  }

  /// لون الحالة
  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.received:
        return const Color(0xFF3498DB);
      case ShipmentStatus.customs:
        return const Color(0xFF9B59B6);
      case ShipmentStatus.port:
        return const Color(0xFF1ABC9C);
      case ShipmentStatus.loading:
        return const Color(0xFFF39C12);
      case ShipmentStatus.inTransit:
        return const Color(0xFFE67E22);
      case ShipmentStatus.arrived:
        return const Color(0xFF2ECC71);
      case ShipmentStatus.delivered:
        return const Color(0xFF27AE60);
    }
  }

  /// نسبة التقدم حسب الحالة
  double _getStatusProgress(ShipmentStatus status) {
    final index = ShipmentStatus.values.indexOf(status);
    return (index + 1) / ShipmentStatus.values.length;
  }
}
