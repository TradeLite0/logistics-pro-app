import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/qr_service.dart';
import '../../services/location_service.dart';
import '../../models/user_model.dart';
import '../../models/shipment_model.dart';
import 'scan_result_screen.dart';

/// شاشة ماسح QR للسائقين والمشرفين والمديرين
class QRScannerScreen extends StatefulWidget {
  final User currentUser;

  const QRScannerScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final QRService _qrService = QRService();
  final LocationService _locationService = LocationService();
  
  bool _isLoading = false;
  bool _gpsEnabled = false;
  String? _errorMessage;

  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _checkGPSStatus();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  /// التحقق من حالة GPS
  Future<void> _checkGPSStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // التحقق من تفعيل خدمة الموقع
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (!serviceEnabled) {
        setState(() {
          _gpsEnabled = false;
          _errorMessage = 'يجب تفعيل خدمة تحديد الموقع (GPS) لاستخدام الماسح';
          _isLoading = false;
        });
        return;
      }

      // التحقق من صلاحية الموقع
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _gpsEnabled = false;
            _errorMessage = 'يجب السماح بالوصول إلى الموقع لاستخدام الماسح';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _gpsEnabled = false;
          _errorMessage = 'تم رفض إذن الموقع بشكل دائم. يرجى تفعيله من إعدادات التطبيق';
          _isLoading = false;
        });
        return;
      }

      // التحقق من الحصول على موقع فعلي
      Position? position = await _locationService.getCurrentPosition();
      
      if (position == null) {
        setState(() {
          _gpsEnabled = false;
          _errorMessage = 'تعذر الحصول على الموقع. تأكد من تشغيل GPS';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _gpsEnabled = true;
        _errorMessage = null;
        _isLoading = false;
      });

      // تهيئة الماسح
      _initializeScanner();

    } catch (e) {
      setState(() {
        _gpsEnabled = false;
        _errorMessage = 'حدث خطأ في التحقق من الموقع: $e';
        _isLoading = false;
      });
    }
  }

  /// تهيئة كاميرا الماسح
  void _initializeScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  /// معالجة نتيجة مسح QR
  Future<void> _handleQRScan(BarcodeCapture capture) async {
    if (_isLoading) return;

    final List<Barcode> barcodes = capture.barcodes;
    
    if (barcodes.isEmpty) return;

    final String? qrData = barcodes.first.rawValue;
    
    if (qrData == null || qrData.isEmpty) {
      _showError('لا يمكن قراءة QR code');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // إيقاف الماسح مؤقتاً
    await _scannerController?.stop();

    try {
      // مسح الشحنة
      final response = await _qrService.scanShipmentQR(qrData);

      if (!mounted) return;

      if (response.success && response.shipment != null) {
        // الانتقال لشاشة النتائج
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScanResultScreen(
              shipment: response.shipment!,
              currentUser: widget.currentUser,
            ),
          ),
        ).then((_) {
          // إعادة تشغيل الماسح بعد العودة
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _scannerController?.start();
          }
        });
      } else {
        // Show error
        setState(() {
          _isLoading = false;
        });
        _showError(response.message ?? 'فشل في مسح QR');
        _scannerController?.start();
      }

    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      _showError('خطأ في مسح QR: $e');
      
      // إعادة تشغيل الماسح
      _scannerController?.start();
    }
  }

  /// عرض رسالة خطأ
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ماسح QR'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          // زر الإضاءة
          if (_gpsEnabled && _scannerController != null)
            IconButton(
              icon: ValueListenableBuilder(
                valueListenable: _scannerController!.torchState,
                builder: (context, state, child) {
                  return Icon(
                    state == TorchState.on
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: Colors.white,
                  );
                },
              ),
              onPressed: () => _scannerController?.toggleTorch(),
            ),
          // زر تبديل الكاميرا
          if (_gpsEnabled && _scannerController != null)
            IconButton(
              icon: ValueListenableBuilder(
                valueListenable: _scannerController!.cameraFacingState,
                builder: (context, state, child) {
                  return Icon(
                    state == CameraFacing.front
                        ? Icons.camera_front
                        : Icons.camera_rear,
                    color: Colors.white,
                  );
                },
              ),
              onPressed: () => _scannerController?.switchCamera(),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && !_gpsEnabled) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('جاري التحقق من الموقع...'),
          ],
        ),
      );
    }

    if (!_gpsEnabled) {
      return _buildGPSErrorView();
    }

    return _buildScannerView();
  }

  /// عرض خطأ GPS
  Widget _buildGPSErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'الموقع مطلوب',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'يجب تفعيل خدمة تحديد الموقع (GPS) لاستخدام الماسح',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _checkGPSStatus,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Geolocator.openLocationSettings();
              },
              child: const Text('فتح إعدادات الموقع'),
            ),
          ],
        ),
      ),
    );
  }

  /// عرض الماسح
  Widget _buildScannerView() {
    return Stack(
      children: [
        // كاميرا الماسح
        MobileScanner(
          controller: _scannerController!,
          onDetect: _handleQRScan,
        ),

        // Overlay للإطار
        CustomPaint(
          size: MediaQuery.of(context).size,
          painter: ScannerOverlayPainter(),
        ),

        // نص التعليمات
        Positioned(
          top: 100,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: const Text(
              'وجه الكاميرا نحو QR code على الشحنة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),

        // مؤشر التحميل
        if (_isLoading)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ),
      ],
    );
  }
}

/// رسم overlay للماسح
class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    // حجم الإطار
    final scanAreaSize = size.width * 0.7;
    final scanAreaLeft = (size.width - scanAreaSize) / 2;
    final scanAreaTop = (size.height - scanAreaSize) / 2;
    final scanAreaRect = Rect.fromLTWH(
      scanAreaLeft,
      scanAreaTop,
      scanAreaSize,
      scanAreaSize,
    );

    // رسم الخلفية المظللة
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(scanAreaRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // رسم إطار المسح
    final borderPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // زوايا الإطار
    const cornerLength = 30.0;
    
    // الزاوية العلوية اليسرى
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + cornerLength),
      Offset(scanAreaLeft, scanAreaTop),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop),
      Offset(scanAreaLeft + cornerLength, scanAreaTop),
      borderPaint,
    );

    // الزاوية العلوية اليمنى
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize - cornerLength, scanAreaTop),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + cornerLength),
      borderPaint,
    );

    // الزاوية السفلية اليسرى
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaSize - cornerLength),
      Offset(scanAreaLeft, scanAreaTop + scanAreaSize),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft, scanAreaTop + scanAreaSize),
      Offset(scanAreaLeft + cornerLength, scanAreaTop + scanAreaSize),
      borderPaint,
    );

    // الزاوية السفلية اليمنى
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize - cornerLength, scanAreaTop + scanAreaSize),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize),
      borderPaint,
    );
    canvas.drawLine(
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize - cornerLength),
      Offset(scanAreaLeft + scanAreaSize, scanAreaTop + scanAreaSize),
      borderPaint,
    );

    // خط المسح المتحرك
    final scanLinePaint = Paint()
      ..color = Colors.green.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final scanLineY = scanAreaTop + (scanAreaSize * 0.5);
    canvas.drawLine(
      Offset(scanAreaLeft + 10, scanLineY),
      Offset(scanAreaLeft + scanAreaSize - 10, scanLineY),
      scanLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
