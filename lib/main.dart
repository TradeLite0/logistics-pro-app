import 'package:flutter/material.dart';
import 'screens/company/update_status_screen.dart';
import 'screens/client/track_shipment_screen.dart';
import 'models/shipment_model.dart';

void main() {
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
      home: const HomeScreen(),
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
