import 'package:flutter/material.dart';
import '../../models/complaint_model.dart';
import '../../services/complaint_service.dart';
import 'complaint_details_screen.dart';
import 'submit_complaint_screen.dart';

/// شاشة قائمة الشكاوى (للمشرفين والمديرين)
class ComplaintsListScreen extends StatefulWidget {
  final String? userId; // If provided, show only this user's complaints

  const ComplaintsListScreen({
    super.key,
    this.userId,
  });

  @override
  State<ComplaintsListScreen> createState() => _ComplaintsListScreenState();
}

class _ComplaintsListScreenState extends State<ComplaintsListScreen> {
  List<Complaint> _complaints = [];
  bool _isLoading = true;
  String? _error;
  
  ComplaintStatus? _filterStatus;
  ComplaintPriority? _filterPriority;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      ComplaintResponse response;
      
      if (widget.userId != null) {
        // Load specific user's complaints
        response = await ComplaintService().getUserComplaints(widget.userId!);
      } else {
        // Load all complaints (admin view)
        response = await ComplaintService().getAllComplaints(
          status: _filterStatus,
          priority: _filterPriority,
        );
      }
      
      if (mounted) {
        if (response.success) {
          setState(() {
            _complaints = response.complaints ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = response.message ?? 'فشل في جلب الشكاوى';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'خطأ: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshComplaints() async {
    await _loadComplaints();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text(widget.userId != null ? 'شكاوى المستخدم' : 'قسم الشكاوى'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // زر التحديث
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshComplaints,
          ),
          // زر الفلتر
          if (widget.userId == null)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
            ),
        ],
      ),
      body: Column(
        children: [
          // ملخص الشكاوى
          _buildSummaryCard(),
          
          // قائمة الشكاوى
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorView()
                    : _complaints.isEmpty
                        ? _buildEmptyView()
                        : _buildComplaintsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const SubmitComplaintScreen(),
            ),
          ).then((_) => _loadComplaints());
        },
        backgroundColor: const Color(0xFF27AE60),
        icon: const Icon(Icons.add),
        label: const Text('شكوى جديدة'),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final pendingCount = _complaints.where((c) => c.status == ComplaintStatus.pending).length;
    final inProgressCount = _complaints.where((c) => c.status == ComplaintStatus.inProgress).length;
    final urgentCount = _complaints.where((c) => c.priority == ComplaintPriority.urgent).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF34495E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'الكل',
              _complaints.length.toString(),
              Icons.inbox,
              Colors.white,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _buildStatItem(
              'معلقة',
              pendingCount.toString(),
              Icons.pending_actions,
              Colors.orange,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _buildStatItem(
              'عاجلة',
              urgentCount.toString(),
              Icons.flag,
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintsList() {
    return RefreshIndicator(
      onRefresh: _refreshComplaints,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _complaints.length,
        itemBuilder: (context, index) {
          final complaint = _complaints[index];
          return _buildComplaintCard(complaint);
        },
      ),
    );
  }

  Widget _buildComplaintCard(Complaint complaint) {
    Color statusColor;
    IconData statusIcon;
    
    switch (complaint.status) {
      case ComplaintStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case ComplaintStatus.inProgress:
        statusColor = Colors.blue;
        statusIcon = Icons.timelapse;
        break;
      case ComplaintStatus.resolved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case ComplaintStatus.closed:
        statusColor = Colors.grey;
        statusIcon = Icons.archive;
        break;
    }

    Color priorityColor;
    switch (complaint.priority) {
      case ComplaintPriority.urgent:
        priorityColor = Colors.red;
        break;
      case ComplaintPriority.high:
        priorityColor = Colors.orange;
        break;
      case ComplaintPriority.medium:
        priorityColor = Colors.yellow.shade700;
        break;
      case ComplaintPriority.low:
        priorityColor = Colors.green;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openComplaintDetails(complaint),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          complaint.status.labelAr,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, size: 14, color: priorityColor),
                        const SizedBox(width: 4),
                        Text(
                          complaint.priority.labelAr,
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(complaint.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                complaint.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                complaint.type.labelAr,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    complaint.userName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.phone, size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    complaint.userPhone,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              if (complaint.shipmentTrackingNumber != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.local_shipping, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'شحنة: ${complaint.shipmentTrackingNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 100,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد شكاوى',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SubmitComplaintScreen(),
                ),
              ).then((_) => _loadComplaints());
            },
            icon: const Icon(Icons.add),
            label: const Text('تقديم شكوى جديدة'),
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
            size: 64,
            color: Colors.red.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'فشل في تحميل الشكاوى',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadComplaints,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تصفية الشكاوى'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الحالة:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('الكل'),
                      selected: _filterStatus == null,
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() => _filterStatus = null);
                        }
                      },
                    ),
                    ...ComplaintStatus.values.map((status) => FilterChip(
                      label: Text(status.labelAr),
                      selected: _filterStatus == status,
                      onSelected: (selected) {
                        setDialogState(() => 
                          _filterStatus = selected ? status : null
                        );
                      },
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('الأولوية:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('الكل'),
                      selected: _filterPriority == null,
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() => _filterPriority = null);
                        }
                      },
                    ),
                    ...ComplaintPriority.values.map((priority) => FilterChip(
                      label: Text(priority.labelAr),
                      selected: _filterPriority == priority,
                      onSelected: (selected) {
                        setDialogState(() => 
                          _filterPriority = selected ? priority : null
                        );
                      },
                    )),
                  ],
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadComplaints();
            },
            child: const Text('تطبيق'),
          ),
        ],
      ),
    );
  }

  void _openComplaintDetails(Complaint complaint) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ComplaintDetailsScreen(complaint: complaint),
      ),
    ).then((result) {
      // Refresh if complaint was updated
      if (result == true) {
        _loadComplaints();
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
