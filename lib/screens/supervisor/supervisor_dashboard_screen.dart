import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/shipment_model.dart';
import '../../services/qr_service.dart';
import '../qr/qr_scanner_screen.dart';

/// لوحة تحكم المشرف والمدير - مع زر QR Scanner وميزات إضافية
class SupervisorDashboardScreen extends StatefulWidget {
  final User user;

  const SupervisorDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<SupervisorDashboardScreen> createState() => _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  final QRService _qrService = QRService();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        centerTitle: true,
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        actions: [
          // زر ماسح QR في AppBar
          if (widget.user.role.canUseQRScanner)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: _openQRScanner,
              tooltip: 'ماسح QR',
            ),
          // قائمة المزيد
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  // TODO: Navigate to profile
                  break;
                case 'settings':
                  // TODO: Navigate to settings
                  break;
                case 'logout':
                  // TODO: Logout
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('الملف الشخصي'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('الإعدادات'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF2C3E50),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'الشحنات',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'السائقين',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'التقارير',
          ),
        ],
      ),
      // زر ماسح QR العائم
      floatingActionButton: widget.user.role.canUseQRScanner
          ? FloatingActionButton.extended(
              onPressed: _openQRScanner,
              backgroundColor: const Color(0xFF27AE60),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('مسح QR'),
            )
          : null,
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'لوحة التحكم';
      case 1:
        return 'الشحنات';
      case 2:
        return 'السائقين';
      case 3:
        return 'التقارير';
      default:
        return 'لوحة التحكم';
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildShipmentsTab();
      case 2:
        return _buildDriversTab();
      case 3:
        return _buildReportsTab();
      default:
        return _buildDashboardTab();
    }
  }

  void _openQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QRScannerScreen(
          currentUser: widget.user,
        ),
      ),
    );
  }

  /// تبويب لوحة التحكم الرئيسية
  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معلومات المستخدم
          _buildUserInfoCard(),
          const SizedBox(height: 24),

          // الإحصائيات
          const Text(
            'إحصائيات سريعة',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatsGrid(),
          const SizedBox(height: 24),

          // أزرار الوصول السريع
          const Text(
            'وصول سريع',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickActions(),
        ],
      ),
    );
  }

  /// تبويب الشحنات
  Widget _buildShipmentsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_shipping, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'قائمة الشحنات',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك استخدام ماسح QR لإضافة شحنة جديدة',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openQRScanner,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('فتح ماسح QR'),
          ),
        ],
      ),
    );
  }

  /// تبويب السائقين
  Widget _buildDriversTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'إدارة السائقين',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك متابعة السائقين وتتبع مواقعهم',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// تبويب التقارير
  Widget _buildReportsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.analytics, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'التقارير والتحليلات',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'عرض تقارير أداء الشحنات والسائقين',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// بطاقة معلومات المستخدم
  Widget _buildUserInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: widget.user.role == UserRole.admin
              ? [const Color(0xFF8E44AD), const Color(0xFF9B59B6)]
              : [const Color(0xFF2C3E50), const Color(0xFF34495E)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
                radius: 35,
                backgroundColor: Colors.white24,
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 35,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.user.role.labelAr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            children: [
              const Icon(Icons.phone, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.user.phone,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          if (widget.user.email != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.email, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  widget.user.email!,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// شبكة الإحصائيات
  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(
          icon: Icons.local_shipping,
          title: 'إجمالي الشحنات',
          value: '150',
          color: Colors.blue,
        ),
        _buildStatCard(
          icon: Icons.check_circle,
          title: 'تم التسليم',
          value: '98',
          color: Colors.green,
        ),
        _buildStatCard(
          icon: Icons.pending,
          title: 'قيد الانتظار',
          value: '32',
          color: Colors.orange,
        ),
        _buildStatCard(
          icon: Icons.people,
          title: 'السائقين النشطين',
          value: '12',
          color: Colors.purple,
        ),
      ],
    );
  }

  /// بطاقة إحصائية
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// أزرار الوصول السريع
  Widget _buildQuickActions() {
    return Column(
      children: [
        // زر ماسح QR
        _buildActionButton(
          icon: Icons.qr_code_scanner,
          title: 'ماسح QR',
          subtitle: 'مسح شحنة جديدة',
          color: const Color(0xFF27AE60),
          onTap: _openQRScanner,
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.add_circle,
          title: 'إضافة شحنة',
          subtitle: 'إنشاء شحنة جديدة',
          color: Colors.blue,
          onTap: () {
            // TODO: Navigate to add shipment
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          icon: Icons.map,
          title: 'تتبع السائقين',
          subtitle: 'عرض مواقع السائقين على الخريطة',
          color: Colors.orange,
          onTap: () {
            // TODO: Navigate to drivers map
          },
        ),
      ],
    );
  }

  /// زر إجراء
  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}