import 'package:flutter/material.dart';
import '../models/shipment_model.dart';
import 'company/update_status_screen.dart';

/// شاشة إضافة شحنة جديدة - واجهة الشركة
class AddShipmentScreen extends StatefulWidget {
  final Function(Shipment) onShipmentAdded;

  const AddShipmentScreen({super.key, required this.onShipmentAdded});

  @override
  State<AddShipmentScreen> createState() => _AddShipmentScreenState();
}

class _AddShipmentScreenState extends State<AddShipmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();
  final _weightController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();

  String _serviceType = 'شحن سريع';
  bool _isLoading = false;

  final List<String> _serviceTypes = [
    'شحن سريع',
    'شحن عادي',
    'شحن مبرد',
    'شحن ثقيل',
  ];

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Generate tracking number
    final trackingNumber = 'SH${DateTime.now().millisecondsSinceEpoch.toString().substring(5, 13)}';

    final shipment = Shipment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      trackingNumber: trackingNumber,
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text,
      customerEmail: _customerEmailController.text,
      origin: _originController.text,
      destination: _destinationController.text,
      serviceType: _serviceType,
      weight: double.parse(_weightController.text),
      cost: double.parse(_costController.text),
      status: ShipmentStatus.received,
      createdAt: DateTime.now(),
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      companyId: 'comp1',
      companyName: 'شركة السريع',
    );

    await Future.delayed(const Duration(seconds: 1));

    widget.onShipmentAdded(shipment);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إضافة الشحنة بنجاح - رقم التتبع: $trackingNumber'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('إضافة شحنة جديدة'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('بيانات العميل'),
              _buildTextField(
                controller: _customerNameController,
                label: 'اسم العميل',
                icon: Icons.person_outline,
                validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              _buildTextField(
                controller: _customerPhoneController,
                label: 'رقم الهاتف',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              _buildTextField(
                controller: _customerEmailController,
                label: 'البريد الإلكتروني (اختياري)',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              _buildSectionTitle('تفاصيل الشحنة'),
              _buildTextField(
                controller: _originController,
                label: 'نقطة الانطلاق',
                icon: Icons.location_on_outlined,
                validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              _buildTextField(
                controller: _destinationController,
                label: 'نقطة الوصول',
                icon: Icons.place_outlined,
                validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
              ),
              const SizedBox(height: 16),

              // نوع الخدمة
              DropdownButtonFormField<String>(
                value: _serviceType,
                decoration: InputDecoration(
                  labelText: 'نوع الخدمة',
                  prefixIcon: const Icon(Icons.local_shipping_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _serviceTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _serviceType = value!),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _weightController,
                      label: 'الوزن (كجم)',
                      icon: Icons.scale_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _costController,
                      label: 'التكلفة (ريال)',
                      icon: Icons.attach_money_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _notesController,
                label: 'ملاحظات (اختياري)',
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('إضافة الشحنة', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF2C3E50),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
