import 'package:flutter/material.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';

/// شاشة تقديم شكوى جديدة
class SubmitComplaintScreen extends StatefulWidget {
  final String? shipmentTrackingNumber;

  const SubmitComplaintScreen({
    super.key,
    this.shipmentTrackingNumber,
  });

  @override
  State<SubmitComplaintScreen> createState() => _SubmitComplaintScreenState();
}

class _SubmitComplaintScreenState extends State<SubmitComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _trackingController = TextEditingController();
  
  ComplaintType _selectedType = ComplaintType.other;
  ComplaintPriority _selectedPriority = ComplaintPriority.medium;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.shipmentTrackingNumber != null) {
      _trackingController.text = widget.shipmentTrackingNumber!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _trackingController.dispose();
    super.dispose();
  }

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final complaint = await ComplaintService().submitComplaint(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        priority: _selectedPriority,
        shipmentTrackingNumber: _trackingController.text.trim().isNotEmpty
            ? _trackingController.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الشكوى بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, complaint);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('تقديم شكوى'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // نوع الشكوى
              _buildSectionTitle('نوع الشكوى'),
              const SizedBox(height: 8),
              _buildTypeSelector(),
              const SizedBox(height: 20),

              // الأولوية
              _buildSectionTitle('أولوية الشكوى'),
              const SizedBox(height: 8),
              _buildPrioritySelector(),
              const SizedBox(height: 20),

              // عنوان الشكوى
              _buildSectionTitle('عنوان الشكوى'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: _inputDecoration(
                  hint: 'مثال: تأخير في توصيل الشحنة',
                  icon: Icons.title,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال عنوان الشكوى';
                  }
                  if (value.trim().length < 5) {
                    return 'العنوان قصير جداً (5 أحرف على الأقل)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // رقم الشحنة (اختياري)
              _buildSectionTitle('رقم الشحنة (اختياري)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _trackingController,
                decoration: _inputDecoration(
                  hint: 'مثال: SH123456',
                  icon: Icons.local_shipping,
                ),
              ),
              const SizedBox(height: 20),

              // تفاصيل الشكوى
              _buildSectionTitle('تفاصيل الشكوى'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: _inputDecoration(
                  hint: 'اشرح المشكلة بالتفصيل...',
                  icon: Icons.description,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء إدخال تفاصيل الشكوى';
                  }
                  if (value.trim().length < 20) {
                    return 'التفاصيل قصيرة جداً (20 حرف على الأقل)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // زر الإرسال
              SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitComplaint,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isSubmitting ? 'جاري الإرسال...' : 'إرسال الشكوى',
                    style: const TextStyle(fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3E50),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ComplaintType.values.map((type) {
        final isSelected = _selectedType == type;
        return ChoiceChip(
          label: Text(type.labelAr),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedType = type);
            }
          },
          selectedColor: const Color(0xFF3498DB),
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? const Color(0xFF3498DB) : Colors.grey.shade300,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrioritySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ComplaintPriority.values.map((priority) {
        final isSelected = _selectedPriority == priority;
        Color chipColor;
        switch (priority) {
          case ComplaintPriority.urgent:
            chipColor = Colors.red;
            break;
          case ComplaintPriority.high:
            chipColor = Colors.orange;
            break;
          case ComplaintPriority.medium:
            chipColor = Colors.yellow.shade700;
            break;
          case ComplaintPriority.low:
            chipColor = Colors.green;
            break;
        }

        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flag,
                size: 16,
                color: isSelected ? Colors.white : chipColor,
              ),
              const SizedBox(width: 4),
              Text(priority.labelAr),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() => _selectedPriority = priority);
            }
          },
          selectedColor: chipColor,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : chipColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isSelected ? chipColor : Colors.grey.shade300,
            ),
          ),
        );
      }).toList(),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
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
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF3498DB)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}
