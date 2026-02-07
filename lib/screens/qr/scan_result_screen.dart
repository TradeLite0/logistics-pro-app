import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/shipment_model.dart';
import '../../models/user_model.dart';
import '../../services/qr_service.dart';
import '../../services/location_service.dart';

/// شاشة نتيجة المسح - عرض تفاصيل الشحنة والإجراءات المتاحة
class ScanResultScreen extends StatefulWidget {
  final Shipment shipment;
  final User currentUser;

  const ScanResultScreen({
    super.key,
    required this.shipment,
    required this.currentUser,
  });

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final QRService _qrService = QRService();
  final LocationService _locationService = LocationService();

  bool _isLoading = false;
  Shipment? _currentShipment;

  @override
  void initState() {
    super.initState();
    _currentShipment = widget.shipment;
  }

  /// الحصول على الموقع الحالي
  Future<Position?> _getCurrentLocation() async {
    return await _locationService.getCurrentPosition();
  }

  /// تنفيذ إجراء على الشحنة
  Future<void> _performAction(QRAction action) async {
    // التحقق من صلاحية الإجراء للدور
    if (!_qrService.isActionValidForRole(
      role: widget.currentUser.role,
      action: action,
    )) {
      _showError('غير مصرح لك بتنفيذ هذا الإجراء');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // الحصول على الموقع الحالي
      final Position? position = await _getCurrentLocation();

      if (position == null) {
        _showError('تعذر الحصول على الموقع. تأكد من تشغيل GPS');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Shipment? updatedShipment;

      // تنفيذ الإجراء المناسب
      switch (action) {
        case QRAction.pickup:
          updatedShipment = await _qrService.pickupShipment(
            shipmentId: _currentShipment!.id,
            latitude: position.latitude,
            longitude: position.longitude,
          );
          break;

        case QRAction.deliver:
          // عرض حوار تأكيد التسليم
          final confirmed = await _showDeliveryConfirmationDialog();
          if (confirmed != true) {
            setState(() {
              _isLoading = false;
            });
            return;
          }
          updatedShipment = await _qrService.deliverShipment(
            shipmentId: _currentShipment!.id,
            latitude: position.latitude,
            longitude: position.longitude,
          );
          break;

        case QRAction.return_:
          // عرض حوار سبب الاسترجاع
          final reason = await _showReturnReasonDialog();
          if (reason == null || reason.isEmpty) {
            setState(() {
              _isLoading = false;
            });
            return;
          }
          updatedShipment = await _qrService.returnShipment(
            shipmentId: _currentShipment!.id,
            latitude: position.latitude,
            longitude: position.longitude,
            reason: reason,
          );
          break;

        case QRAction.viewDetails:
          // لا شيء، فقط عرض التفاصيل
          break;
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        if (updatedShipment != null) {
          _currentShipment = updatedShipment;
        }
      });

      if (action != QRAction.viewDetails) {
        _showSuccess('تم تنفيذ الإجراء بنجاح');
      }

    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      _showError('فشل في تنفيذ الإجراء: $e');
    }
  }

  /// عرض حوار تأكيد التسليم
  Future<bool?> _showDeliveryConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد التسليم'),
        content: const Text(
          'هل أنت متأكد من تسليم هذه الشحنة؟\nسيتم تحديث حالة الشحنة إلى "تم التسليم"',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  /// عرض حوار سبب الاسترجاع
  Future<String?> _showReturnReasonDialog() async {
    final TextEditingController reasonController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('سبب الاسترجاع'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('يرجى تحديد سبب استرجاع الشحنة:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'أدخل السبب هنا...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, reasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  /// عرض رسالة نجاح
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// عرض رسالة خطأ
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// الحصول على لون حالة الشحنة
  Color _getStatusColor(ShipmentStatus status) {
    switch (status) {
      case ShipmentStatus.received:
        return Colors.blue;
      case ShipmentStatus.customs:
        return Colors.orange;
      case ShipmentStatus.port:
        return Colors.purple;
      case ShipmentStatus.loading:
        return Colors.amber;
      case ShipmentStatus.inTransit:
        return Colors.indigo;
      case ShipmentStatus.arrived:
        return Colors.teal;
      case ShipmentStatus.delivered:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipment = _currentShipment!;
    final availableActions = _qrService.getAvailableActions(widget.currentUser.role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الشحنة'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // رقم التتبع
                  _buildTrackingSection(shipment),
                  
                  const SizedBox(height: 16),
                  
                  // معلومات العميل
                  _buildCustomerSection(shipment),
                  
                  const SizedBox(height: 16),
                  
                  // معلومات الشحنة
                  _buildShipmentDetailsSection(shipment),
                  
                  const SizedBox(height: 16),
                  
                  // حالة الشحنة
                  _buildStatusSection(shipment),
                  
                  // تاريخ محفوظات الحالة (للمدير والمشرف فقط)
                  if (widget.currentUser.role.canViewDetails) ...[
                    const SizedBox(height: 16),
                    _buildStatusHistorySection(shipment),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // أزرار الإجراءات
                  _buildActionButtons(availableActions, shipment),
                ],
              ),
            ),
    );
  }

  /// قسم رقم التتبع
  Widget _buildTrackingSection(Shipment shipment) {
    return Card(
      elevation: 2,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF2C3E50),
              const Color(0xFF2C3E50).withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            const Text(
              'رقم التتبع',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              shipment.trackingNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// قسم معلومات العميل
  Widget _buildCustomerSection(Shipment shipment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: Color(0xFF2C3E50)),
                SizedBox(width: 8),
                Text(
                  'معلومات العميل',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('الاسم:', shipment.customerName),
            _buildInfoRow('الهاتف:', shipment.customerPhone),
            if (shipment.customerEmail.isNotEmpty)
              _buildInfoRow('البريد:', shipment.customerEmail),
          ],
        ),
      ),
    );
  }

  /// قسم تفاصيل الشحنة
  Widget _buildShipmentDetailsSection(Shipment shipment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_shipping, color: Color(0xFF2C3E50)),
                SizedBox(width: 8),
                Text(
                  'تفاصيل الشحنة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('من:', shipment.origin),
            _buildInfoRow('إلى:', shipment.destination),
            _buildInfoRow('نوع الخدمة:', shipment.serviceType),
            _buildInfoRow('الوزن:', '${shipment.weight} كجم'),
            _buildInfoRow('التكلفة:', '${shipment.cost.toStringAsFixed(2)} ريال'),
            _buildInfoRow('الشركة:', shipment.companyName),
          ],
        ),
      ),
    );
  }

  /// قسم الحالة
  Widget _buildStatusSection(Shipment shipment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.update, color: Color(0xFF2C3E50)),
                SizedBox(width: 8),
                Text(
                  'حالة الشحنة',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getStatusColor(shipment.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getStatusColor(shipment.status),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.circle,
                    color: _getStatusColor(shipment.status),
                    size: 12,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    shipment.status.labelAr,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(shipment.status),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// قسم تاريخ الحالة
  Widget _buildStatusHistorySection(Shipment shipment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: Color(0xFF2C3E50)),
                SizedBox(width: 8),
                Text(
                  'سجل التحديثات',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            if (shipment.statusHistory.isEmpty)
              const Text(
                'لا يوجد سجل تحديثات',
                style: TextStyle(color: Colors.grey),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shipment.statusHistory.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final update = shipment.statusHistory[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.check_circle,
                      color: _getStatusColor(update.status),
                    ),
                    title: Text(update.status.labelAr),
                    subtitle: Text(
                      '${update.timestamp.toLocal()}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: update.location != null
                        ? Tooltip(
                            message: update.location!,
                            child: const Icon(Icons.location_on, size: 16),
                          )
                        : null,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// أزرار الإجراءات
  Widget _buildActionButtons(List<QRAction> actions, Shipment shipment) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'الإجراءات المتاحة',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ...actions.map((action) => _buildActionButton(action, shipment)),
      ],
    );
  }

  /// زر إجراء واحد
  Widget _buildActionButton(QRAction action, Shipment shipment) {
    IconData icon;
    Color color;
    String label;

    switch (action) {
      case QRAction.pickup:
        icon = Icons.login;
        color = Colors.blue;
        label = 'استلام الشحنة';
        break;
      case QRAction.deliver:
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'تسليم الشحنة';
        break;
      case QRAction.return_:
        icon = Icons.assignment_return;
        color = Colors.orange;
        label = 'استرجاع الشحنة';
        break;
      case QRAction.viewDetails:
        icon = Icons.visibility;
        color = Colors.purple;
        label = 'عرض التفاصيل الكاملة';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: () => _performAction(action),
        icon: Icon(icon),
        label: Text(
          label,
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// صف معلومات
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// أنواع الإجراءات
enum QRAction {
  pickup('استلام', 'Pickup', 'pickup'),
  deliver('تسليم', 'Deliver', 'deliver'),
  return_('استرجاع', 'Return', 'return'),
  viewDetails('عرض التفاصيل', 'View Details', 'view_details');

  final String labelAr;
  final String labelEn;
  final String key;

  const QRAction(this.labelAr, this.labelEn, this.key);

  String getLabel(bool isArabic) => isArabic ? labelAr : labelEn;
}