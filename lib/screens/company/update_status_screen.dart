import 'package:flutter/material.dart';
import '../../models/shipment_model.dart';

/// شاشة تحديث حالة الشحنة - واجهة الشركة
class CompanyUpdateStatusScreen extends StatefulWidget {
  final Shipment shipment;
  final Function(Shipment) onStatusUpdated;

  const CompanyUpdateStatusScreen({
    super.key,
    required this.shipment,
    required this.onStatusUpdated,
  });

  @override
  State<CompanyUpdateStatusScreen> createState() => _CompanyUpdateStatusScreenState();
}

class _CompanyUpdateStatusScreenState extends State<CompanyUpdateStatusScreen> {
  late ShipmentStatus _selectedStatus;
  final _locationController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _notifyCustomer = true;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.shipment.status;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateStatus() async {
    if (_selectedStatus == widget.shipment.status && _notesController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم إجراء أي تغييرات')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // محاكاة الاتصال بالـ API
    await Future.delayed(const Duration(seconds: 1));

    final newUpdate = StatusUpdate(
      status: _selectedStatus,
      timestamp: DateTime.now(),
      location: _locationController.text.isNotEmpty ? _locationController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      updatedBy: 'Company Admin',
    );

    final updatedShipment = widget.shipment.copyWith(
      status: _selectedStatus,
      updatedAt: DateTime.now(),
      currentLocation: _locationController.text.isNotEmpty ? _locationController.text : widget.shipment.currentLocation,
      statusHistory: [...widget.shipment.statusHistory, newUpdate],
    );

    widget.onStatusUpdated(updatedShipment);

    // إرسال إشعار للعميل (محاكاة)
    if (_notifyCustomer) {
      _sendPushNotification(updatedShipment);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_notifyCustomer 
            ? 'تم تحديث الحالة وإرسال الإشعار للعميل' 
            : 'تم تحديث الحالة'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _sendPushNotification(Shipment shipment) {
    // هنا هنرسل Push Notification للعميل
    // Firebase Cloud Messaging (FCM)
    debugPrint('🔔 إرسال إشعار للعميل ${shipment.customerPhone}');
    debugPrint('📦 شحنة ${shipment.trackingNumber}');
    debugPrint('📍 الحالة الجديدة: ${shipment.status.labelAr}');
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('تحديث حالة الشحنة'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // معلومات الشحنة
            _buildShipmentInfoCard(isArabic),
            const SizedBox(height: 20),

            // عنوان القسم
            Text(
              'اختر الحالة الجديدة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),

            // شبكة المراحل
            _buildStatusGrid(isArabic),
            const SizedBox(height: 24),

            // الموقع الحالي
            _buildTextField(
              controller: _locationController,
              label: 'الموقع الحالي (اختياري)',
              hint: 'مثال: ميناء جدة',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 16),

            // ملاحظات
            _buildTextField(
              controller: _notesController,
              label: 'ملاحظات (اختياري)',
              hint: 'أضف أي ملاحظات هنا...',
              icon: Icons.notes_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // خيار إرسال الإشعار
            _buildNotificationToggle(),
            const SizedBox(height: 30),

            // زر التحديث
            _buildUpdateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildShipmentInfoCard(bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'رقم التتبع',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    widget.shipment.trackingNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.shipment.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.shipment.status.getLabel(isArabic),
                  style: TextStyle(
                    color: _getStatusColor(widget.shipment.status),
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
              Text(widget.shipment.customerName),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.route_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text('${widget.shipment.origin} → ${widget.shipment.destination}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusGrid(bool isArabic) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: ShipmentStatus.values.length,
      itemBuilder: (context, index) {
        final status = ShipmentStatus.values[index];
        final isSelected = _selectedStatus == status;
        final isCurrent = widget.shipment.status == status;

        return InkWell(
          onTap: () => setState(() => _selectedStatus = status),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? _getStatusColor(status) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                  ? _getStatusColor(status) 
                  : isCurrent 
                    ? _getStatusColor(status) 
                    : Colors.grey[300]!,
                width: isCurrent ? 2 : 1,
              ),
              boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _getStatusColor(status).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      status.getLabel(isArabic),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                    if (isCurrent)
                      Text(
                        '(الحالي)',
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2C3E50), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Color(0xFF2196F3)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إرسال إشعار للعميل',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'سيتم إرسال إشعار فوري للعميل عند تحديث الحالة',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Switch(
            value: _notifyCustomer,
            onChanged: (value) => setState(() => _notifyCustomer = value),
            activeColor: const Color(0xFF2196F3),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateStatus,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF27AE60),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: const Color(0xFF27AE60).withOpacity(0.4),
        ),
        child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.update),
                SizedBox(width: 8),
                Text(
                  'تحديث الحالة',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
      ),
    );
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
}
