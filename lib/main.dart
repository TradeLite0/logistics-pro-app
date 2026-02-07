import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'screens/company/update_status_screen.dart';
import 'screens/client/track_shipment_screen.dart';
import 'screens/gps_lock_screen.dart';
import 'models/shipment_model.dart';

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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Choose Interface',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
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
}
