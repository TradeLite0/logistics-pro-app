import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/app_helpers.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          final user = userProvider.user;

          if (userProvider.isLoading && user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (user == null) {
            return const Center(
              child: Text(
                'لم يتم العثور على المستخدم',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => userProvider.loadUser(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Avatar Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 3,
                          ),
                          image: user.avatar != null
                              ? DecorationImage(
                                  image: NetworkImage(user.avatar!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: user.avatar == null
                            ? Icon(
                                Icons.person,
                                size: 60,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showImagePicker(context, userProvider),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // User Name
                Center(
                  child: Text(
                    user.name,
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      user.isClient ? 'عميل' : user.isDriver ? 'سائق' : 'إداري',
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Info Cards
                _buildInfoCard(
                  context,
                  icon: Icons.email_outlined,
                  title: 'البريد الإلكتروني',
                  value: user.email,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  icon: Icons.phone_outlined,
                  title: 'رقم الهاتف',
                  value: user.phone,
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  icon: Icons.calendar_today_outlined,
                  title: 'تاريخ التسجيل',
                  value: AppHelpers.formatDate(user.createdAt),
                ),
                const SizedBox(height: 12),
                _buildInfoCard(
                  context,
                  icon: Icons.verified_user_outlined,
                  title: 'حالة الحساب',
                  value: user.isActive ? 'نشط' : 'غير نشط',
                  valueColor: user.isActive ? Colors.green : Colors.red,
                ),

                const SizedBox(height: 32),

                // Change Password Button
                OutlinedButton.icon(
                  onPressed: () => _showChangePasswordDialog(context, userProvider),
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('تغيير كلمة المرور'),
                ),
                const SizedBox(height: 12),

                // Delete Account Button
                OutlinedButton.icon(
                  onPressed: () => _showDeleteAccountDialog(context, userProvider),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text(
                    'حذف الحساب',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: valueColor,
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

  Future<void> _showImagePicker(BuildContext context, UserProvider userProvider) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('التقاط صورة', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () async {
                Navigator.of(context).pop();
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.camera);
                if (pickedFile != null) {
                  await _uploadAvatar(context, userProvider, File(pickedFile.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('اختيار من المعرض', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () async {
                Navigator.of(context).pop();
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  await _uploadAvatar(context, userProvider, File(pickedFile.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadAvatar(BuildContext context, UserProvider userProvider, File file) async {
    AppHelpers.showLoadingDialog(context, message: 'جاري رفع الصورة...');
    try {
      await userProvider.uploadAvatar(file);
      AppHelpers.hideLoadingDialog(context);
      AppHelpers.showSnackBar(context, 'تم رفع الصورة بنجاح');
    } catch (e) {
      AppHelpers.hideLoadingDialog(context);
      AppHelpers.showSnackBar(context, 'فشل رفع الصورة: $e', isError: true);
    }
  }

  void _showChangePasswordDialog(BuildContext context, UserProvider userProvider) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'تغيير كلمة المرور',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الحالية',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) => AppHelpers.validateRequired(value, fieldName: 'كلمة المرور الحالية'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: AppHelpers.validatePassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'تأكيد كلمة المرور الجديدة',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) => AppHelpers.validateConfirmPassword(
                  value,
                  newPasswordController.text,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop();
                AppHelpers.showLoadingDialog(context);
                try {
                  await userProvider.changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                    confirmPasswordController.text,
                  );
                  AppHelpers.hideLoadingDialog(context);
                  AppHelpers.showSnackBar(context, 'تم تغيير كلمة المرور بنجاح');
                } catch (e) {
                  AppHelpers.hideLoadingDialog(context);
                  AppHelpers.showSnackBar(context, 'فشل تغيير كلمة المرور: $e', isError: true);
                }
              }
            },
            child: const Text('حفظ', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'حذف الحساب',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: const Text(
          'هل أنت متأكد من حذف حسابك؟ لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              AppHelpers.showLoadingDialog(context);
              try {
                await userProvider.deleteAccount();
                AppHelpers.hideLoadingDialog(context);
                // Navigate to login screen
              } catch (e) {
                AppHelpers.hideLoadingDialog(context);
                AppHelpers.showSnackBar(context, 'فشل حذف الحساب: $e', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}
