import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'screens/company/update_status_screen.dart';
import 'screens/client/track_shipment_screen.dart';
import 'screens/driver/driver_dashboard_screen.dart';
import 'screens/supervisor/supervisor_dashboard_screen.dart';
import 'screens/qr/qr_scanner_screen.dart';
import 'screens/gps_lock_screen.dart';
import 'models/shipment_model.dart';
import 'models/user_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LogisticsApp());
}

class LogisticsApp extends StatelessWidget {
  const LogisticsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logistics Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Cairo', // افتراضي للغة العربية
      ),
      home: const LocationCheckScreen(),
    );
  }
}

/// Initial screen that checks location permission and services.
/// Shows GPSLockScreen if location is not available, otherwise shows HomeScreen.
class LocationCheckScreen extends StatefulWidget {
  const LocationCheckScreen({super.key});

  @override
  State<LocationCheckScreen> createState() => _LocationCheckScreenState();
}

class _LocationCheckScreenState extends State<LocationCheckScreen> {
  late Future<bool> _locationCheckFuture;

  @override
  void initState() {
    super.initState();
    _locationCheckFuture = _checkLocationAccess();
  }

  /// Checks if location services are enabled and permission is granted
  Future<bool> _checkLocationAccess() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      // Request permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permission permanently denied
      return false;
    }

    // Location is enabled and permission granted
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _locationCheckFuture,
      builder: (context, snapshot) {
        // Show loading while checking
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // Location check complete
        if (snapshot.hasData && snapshot.data == true) {
          // Location granted - show main app
          return const HomeScreen();
        } else {
          // Location denied or error - show GPS lock screen
          return const GPSLockScreen();
        }
      },
    );
  }
}

/// Simple splash screen shown while checking location
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo/icon
            Icon(
              Icons.local_shipping,
              size: 80,
              color: Colors.blue.shade700,
            ),
            const SizedBox(height: 24),
            // App name
            const Text(
              'Logistics Pro',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Arabic subtitle
            Text(
              'نظام إدارة الشحن والتتبع',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'جاري التحقق من الموقع...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logistics Pro'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // عنوان رئيسي
            const Text(
              'اختر واجهة المستخدم',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'نظام QR Scanner متاح للسائقين والمشرفين والمديرين',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // قسم السائق
            _buildSectionTitle('واجهة السائق'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // سائق تجريبي
                final driver = User(
                  id: '1',
                  name: 'محمد السائق',
                  phone: '+966501234567',
                  role: UserRole.driver,
                  createdAt: DateTime.now(),
                );
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverDashboardScreen(driver: driver),
                  ),
                );
              },
              icon: const Icon(Icons.drive_eta),
              label: const Text('لوحة تحكم السائق'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // قسم المشرف
            _buildSectionTitle('واجهة المشرف'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // مشرف تجريبي
                final supervisor = User(
                  id: '2',
                  name: 'أحمد المشرف',
                  phone: '+966501234568',
                  role: UserRole.supervisor,
                  createdAt: DateTime.now(),
                );
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SupervisorDashboardScreen(user: supervisor),
                  ),
                );
              },
              icon: const Icon(Icons.supervisor_account),
              label: const Text('لوحة تحكم المشرف'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // قسم المدير
            _buildSectionTitle('واجهة المدير'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // مدير تجريبي
                final admin = User(
                  id: '3',
                  name: 'خالد المدير',
                  phone: '+966501234569',
                  role: UserRole.admin,
                  createdAt: DateTime.now(),
                );
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SupervisorDashboardScreen(user: admin),
                  ),
                );
              },
              icon: const Icon(Icons.admin_panel_settings),
              label: const Text('لوحة تحكم المدير'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // قسم مباشر للماسح
            _buildSectionTitle('اختبار QR Scanner مباشرة'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // فتح الماسح مباشرة كسائق
                final driver = User(
                  id: '1',
                  name: 'محمد السائق',
                  phone: '+966501234567',
                  role: UserRole.driver,
                  createdAt: DateTime.now(),
                );
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QRScannerScreen(currentUser: driver),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('فتح QR Scanner (كـ سائق)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
              ),
            ),
            
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // فتح الماسح مباشرة كمشرف
                final supervisor = User(
                  id: '2',
                  name: 'أحمد المشرف',
                  phone: '+966501234568',
                  role: UserRole.supervisor,
                  createdAt: DateTime.now(),
                );
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QRScannerScreen(currentUser: supervisor),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_2),
              label: const Text('فتح QR Scanner (كـ مشرف)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3498DB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(20),
              ),
            ),
            
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            
            // الواجهات الأخرى
            const Text(
              'واجهات أخرى',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Company Button
            ElevatedButton.icon(
              onPressed: () {
                final testShipment = Shipment(
                  id: '1',
                  trackingNumber: 'SH123456',
                  customerName: 'Ahmed Mohamed',
                  customerPhone: '+966501234567',
                  origin: 'Riyadh',
                  destination: 'Jeddah',
                  serviceType: 'Express',
                  weight: 5.5,
                  cost: 150,
                  status: ShipmentStatus.loading,
                  createdAt: DateTime.now(),
                  companyId: 'comp1',
                  companyName: 'Fast Logistics',
                );
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompanyUpdateStatusScreen(
                      shipment: testShipment,
                      onStatusUpdated: (s) => print('Updated: ${s.status}'),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.business),
              label: const Text('Company Dashboard'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Client Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClientTrackScreen()),
                );
              },
              icon: const Icon(Icons.person),
              label: const Text('Client Track Shipment'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }
}