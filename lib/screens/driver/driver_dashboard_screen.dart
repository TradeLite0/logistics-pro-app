import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/shipment_model.dart';
import '../../services/qr_service.dart';
import '../qr/qr_scanner_screen.dart';

/// لوحة تحكم السائق - مع زر QR Scanner
class DriverDashboardScreen extends StatefulWidget {
  final User driver;

  const DriverDashboardScreen({
    super.key,
    required this.driver,
  });

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  final QRService _qrService = QRService();
  bool _isLoading = false;
  List<Shipment> _assignedShipments = [];

  @override
  void initState() {
    super.initState();
    _loadAssignedShipments();
  }

  Future<void> _loadAssignedShipments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Load driver shipments from API
      // final shipments = await _qrService.getDriverShipments(widget.driver.id);
      // setState(() {
      //   _assignedShipments = shipments;
      // });
      
      // محاكاة البيانات مؤقتاً
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _assignedShipments = [];
      });
    } catch (e) {
      _showError('فشل في تحميل الشحنات: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openQRScanner() {
    // التحقق من صلاحية استخدام QR
    if (!widget.driver.role.canUseQRScanner) {
      _showError('غير مصرح لك باستخدام ماسح QR');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          currentUser: widget.driver,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('لوحة تحكم السائق'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAssignedShipments,
        child: _isLoading && _assignedShipments.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
      // زر ماسح QR العائم
      floatingActionButton: widget.driver.role.canUseQRScanner
          ? FloatingActionButton.extended(
              onPressed: _openQRScanner,
              backgroundColor: const Color(0xFF27AE60),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('مسح QR'),
            )
          : null,
    );
  }

  Widget _buildContent() {
    return CustomScrollView(
      slivers: [
        // معلومات السائق
        SliverToBoxAdapter(
          child: _buildDriverInfoCard(),
        ),

        // عنوان قسم الشحنات
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الشحنات المسندة',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _loadAssignedShipments,
                  icon: const Icon(Icons.refresh),
                  label: const Text('تحديث'),
                ),
              ],
            ),
          ),
        ),

        // قائمة الشحنات
        if (_assignedShipments.isEmpty)
          SliverToBoxAdapter(
            child: _buildEmptyState(),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return _buildShipmentCard(_assignedShipments[index]);
              },
              childCount: _assignedShipments.length,
            ),
          ),

        // زر ماسح QR البديل (في أسفل الصفحة)
        if (widget.driver.role.canUseQRScanner)
          SliverToBoxAdapter(
            child: _buildQRScannerButton(),
          ),
      ],
    );
  }

  /// بطاقة معلومات السائق
  Widget _buildDriverInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C3E50).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.person,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.driver.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.driver.role.labelAr,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.local_shipping,
                value: _assignedShipments.length.toString(),
                label: 'شحنة نشطة',
              ),
              _buildStatItem(
                icon: Icons.check_circle,
                value: '0',
                label: 'تم التسليم',
              ),
              _buildStatItem(
                icon: Icons.schedule,
                value: '0',
                label: 'في الانتظار',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// عنصر إحصائي
  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// حالة فارغة
  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد شحنات مسندة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك مسح QR code على أي شحنة لاستلامها',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// بطاقة شحنة
  Widget _buildShipmentCard(Shipment shipment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // TODO: Navigate to shipment details
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    shipment.trackingNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(shipment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      shipment.status.labelAr,
                      style: TextStyle(
                        color: _getStatusColor(shipment.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(shipment.customerName),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.route_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('${shipment.origin} → ${shipment.destination}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// زر ماسح QR البديل
  Widget _buildQRScannerButton() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: _openQRScanner,
        icon: const Icon(Icons.qr_code_scanner, size: 24),
        label: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'فتح ماسح QR',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF27AE60),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.received:
        return Colors.blue;
      case ShipmentStatus.customs:
        return Colors.purple;
      case ShipmentStatus.port:
        return Colors.teal;
      case ShipmentStatus.loading:
        return Colors.orange;
      case ShipmentStatus.inTransit:
        return Colors.indigo;
      case ShipmentStatus.arrived:
        return Colors.amber;
      case ShipmentStatus.delivered:
        return Colors.green;
    }
  }
}