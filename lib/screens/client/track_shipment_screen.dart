import 'package:flutter/material.dart';
import '../../models/shipment_model.dart';

/// شاشة تتبع الشحنة - واجهة العميل
class ClientTrackScreen extends StatefulWidget {
  final String? initialTrackingNumber;

  const ClientTrackScreen({super.key, this.initialTrackingNumber});

  @override
  State<ClientTrackScreen> createState() => _ClientTrackScreenState();
}

class _ClientTrackScreenState extends State<ClientTrackScreen> {
  final _trackingController = TextEditingController();
  Shipment? _shipment;
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialTrackingNumber != null) {
      _trackingController.text = widget.initialTrackingNumber!;
      _searchShipment();
    }
  }

  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  void _searchShipment() async {
    if (_trackingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل رقم التتبع')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    // محاكاة API call
    await Future.delayed(const Duration(seconds: 1));

    // بيانات تجريبية للاختبار
    if (_trackingController.text == 'TEST123' || 
        _trackingController.text.startsWith('SH')) {
      setState(() {
        _shipment = _getMockShipment();
        _isLoading = false;
      });
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'لم يتم العثور على شحنة بهذا الرقم';
        _isLoading = false;
      });
    }
  }

  Shipment _getMockShipment() {
    return Shipment(
      id: '1',
      trackingNumber: _trackingController.text,
      customerName: 'أحمد محمد',
      customerPhone: '+966501234567',
      origin: 'الرياض، السعودية',
      destination: 'جدة، السعودية',
      serviceType: 'شحن سريع',
      weight: 5.5,
      cost: 150.0,
      status: ShipmentStatus.inTransit,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
      companyId: 'comp1',
      companyName: 'شركة السريع للشحن',
      currentLocation: 'في الطريق إلى جدة',
      driverName: 'محمد علي',
      driverPhone: '+966509876543',
      statusHistory: [
        StatusUpdate(
          status: ShipmentStatus.received,
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          location: 'الرياض',
          updatedBy: 'System',
        ),
        StatusUpdate(
          status: ShipmentStatus.customs,
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          location: 'الرياض',
          notes: 'تم التخليص الجمركي',
          updatedBy: 'Admin',
        ),
        StatusUpdate(
          status: ShipmentStatus.port,
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          location: 'مستودع الرياض',
          updatedBy: 'Admin',
        ),
        StatusUpdate(
          status: ShipmentStatus.loading,
          timestamp: DateTime.now().subtract(const Duration(hours: 8)),
          location: 'مستودع الرياض',
          notes: 'تم التحميل على الشاحنة',
          updatedBy: 'Admin',
        ),
        StatusUpdate(
          status: ShipmentStatus.inTransit,
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          location: 'طريق الرياض - جدة',
          notes: 'الشحنة في الطريق',
          updatedBy: 'Driver',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('تتبع شحنتك'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header with search
          _buildSearchHeader(isArabic),

          // Content
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _hasError
                ? _buildErrorView()
                : _shipment == null
                  ? _buildEmptyView()
                  : _buildShipmentDetails(isArabic),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF2C3E50),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const Text(
            'أدخل رقم التتبع',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _trackingController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    decoration: InputDecoration(
                      hintText: 'مثال: SH123456',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _searchShipment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Icon(Icons.search),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          Text(
            'أدخل رقم التتبع لمعرفة حالة شحنتك',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك إيجاد الرقم في رسالة التأكيد',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 20),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => setState(() => _hasError = false),
            icon: const Icon(Icons.arrow_back),
            label: const Text('محاولة مرة أخرى'),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentDetails(bool isArabic) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // حالة الشحنة الحالية
          _buildCurrentStatusCard(isArabic),
          const SizedBox(height: 20),

          // شريط التقدم
          _buildProgressTimeline(isArabic),
          const SizedBox(height: 24),

          // معلومات الشحنة
          _buildShipmentInfoSection(),
          const SizedBox(height: 20),

          // معلومات السائق
          if (_shipment!.driverName != null)
            _buildDriverInfoSection(),
          const SizedBox(height: 20),

          // سجل التحديثات
          _buildHistorySection(isArabic),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusCard(bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(_shipment!.status),
            _getStatusColor(_shipment!.status).withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(_shipment!.status).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _shipment!.trackingNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.local_shipping, color: Colors.white, size: 32),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _shipment!.status.getLabel(isArabic),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_shipment!.currentLocation != null)
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  _shipment!.currentLocation!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: _getProgressValue(),
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTimeline(bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'رحلة الشحنة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(ShipmentStatus.values.length, (index) {
            final status = ShipmentStatus.values[index];
            final isCompleted = _getStatusIndex(_shipment!.status) >= index;
            final isCurrent = _shipment!.status == status;

            return _buildTimelineItem(
              status: status,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              isLast: index == ShipmentStatus.values.length - 1,
              isArabic: isArabic,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required ShipmentStatus status,
    required bool isCompleted,
    required bool isCurrent,
    required bool isLast,
    required bool isArabic,
  }) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isCompleted ? _getStatusColor(status) : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: isCurrent
                    ? Border.all(color: _getStatusColor(status), width: 4)
                    : null,
                  boxShadow: isCurrent
                    ? [
                        BoxShadow(
                          color: _getStatusColor(status).withOpacity(0.4),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
                ),
                child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? _getStatusColor(status) : Colors.grey[300],
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrent ? _getStatusColor(status).withOpacity(0.1) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: isCurrent
                  ? Border.all(color: _getStatusColor(status).withOpacity(0.3))
                  : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.getLabel(isArabic),
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      color: isCurrent ? _getStatusColor(status) : Colors.grey[700],
                    ),
                  ),
                  if (isCurrent && _shipment!.updatedAt != null)
                    Text(
                      'تم التحديث: ${_formatDate(_shipment!.updatedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'معلومات الشحنة',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.business, 'الشركة', _shipment!.companyName),
          _buildInfoRow(Icons.category, 'نوع الخدمة', _shipment!.serviceType),
          _buildInfoRow(Icons.route, 'من', _shipment!.origin),
          _buildInfoRow(Icons.place, 'إلى', _shipment!.destination),
          _buildInfoRow(Icons.scale, 'الوزن', '${_shipment!.weight} كجم'),
          _buildInfoRow(Icons.attach_money, 'التكلفة', '${_shipment!.cost} ريال'),
        ],
      ),
    );
  }

  Widget _buildDriverInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              Text(
                'مندوب التوصيل',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_shipment!.driverName!, style: const TextStyle(fontSize: 16)),
          if (_shipment!.driverPhone != null)
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.phone, size: 18),
              label: Text(_shipment!.driverPhone!),
            ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'سجل التحديثات',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          ..._shipment!.statusHistory.reversed.map((update) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(update.status),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(update.status.getLabel(isArabic)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (update.location != null)
                    Text(update.location!, style: const TextStyle(fontSize: 12)),
                  Text(
                    _formatDate(update.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text('$label: ', style: TextStyle(color: Colors.grey[600])),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

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

  int _getStatusIndex(ShipmentStatus status) {
    return ShipmentStatus.values.indexOf(status);
  }

  double _getProgressValue() {
    return (_getStatusIndex(_shipment!.status) + 1) / ShipmentStatus.values.length;
  }
}
