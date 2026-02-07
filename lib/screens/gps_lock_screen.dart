import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../main.dart';

/// Screen shown when location permission is denied or GPS is disabled.
/// Blocks access to the app until location services are enabled.
class GPSLockScreen extends StatefulWidget {
  const GPSLockScreen({super.key});

  @override
  State<GPSLockScreen> createState() => _GPSLockScreenState();
}

class _GPSLockScreenState extends State<GPSLockScreen> {
  bool _isChecking = false;

  /// Checks location permission and service status
  Future<bool> _checkLocationStatus() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // Check permission status
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Handles retry button press - checks location again
  Future<void> _onRetryPressed() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final hasLocation = await _checkLocationStatus();
      if (hasLocation && mounted) {
        // Location is now available, navigate to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      debugPrint('Error checking location: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  /// Opens device location settings
  Future<void> _openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Opens app settings for permission
  Future<void> _openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Location Icon
              Icon(
                Icons.location_off_outlined,
                size: 100,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 32),

              // Main Arabic message
              const Text(
                'يجب تفعيل الموقع للمتابعة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // English translation/subtitle
              Text(
                'Location services are required to use this app',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 48),

              // Instructions card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildInstructionItem(
                      icon: Icons.gps_fixed,
                      text: 'Enable GPS/Location services',
                      arabicText: 'تفعيل خدمة تحديد الموقع',
                    ),
                    const SizedBox(height: 16),
                    _buildInstructionItem(
                      icon: Icons.app_settings_alt,
                      text: 'Allow location permission',
                      arabicText: 'السماح بالوصول للموقع',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Retry button
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isChecking ? null : _onRetryPressed,
                  icon: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    _isChecking ? 'جاري التحقق...' : 'إعادة المحاولة',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Settings buttons row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openLocationSettings,
                      icon: const Icon(Icons.settings),
                      label: const Text('GPS'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _openAppSettings,
                      icon: const Icon(Icons.app_settings_alt),
                      label: const Text('Permissions'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: const BorderSide(color: Colors.blue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem({
    required IconData icon,
    required String text,
    required String arabicText,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                arabicText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
