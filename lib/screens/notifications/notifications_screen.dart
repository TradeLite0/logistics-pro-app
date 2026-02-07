import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';
import '../../utils/app_helpers.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<NotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإشعارات'),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              if (notificationProvider.unreadCount == 0) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () => notificationProvider.markAllAsRead(),
                child: const Text('قراءة الكل'),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _showClearAllDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20),
                    SizedBox(width: 8),
                    Text('مسح الكل', style: TextStyle(fontFamily: 'Cairo')),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading && notificationProvider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (notificationProvider.error != null && notificationProvider.notifications.isEmpty) {
            return _buildErrorWidget(notificationProvider.error!);
          }

          if (notificationProvider.notifications.isEmpty) {
            return _buildEmptyWidget();
          }

          return RefreshIndicator(
            onRefresh: () => notificationProvider.loadNotifications(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notificationProvider.notifications.length,
              itemBuilder: (context, index) {
                final notification = notificationProvider.notifications[index];
                return _NotificationItem(
                  notification: notification,
                  onTap: () => _handleNotificationTap(context, notification),
                  onDismiss: () => notificationProvider.deleteNotification(notification.id),
                  onMarkAsRead: () => notificationProvider.markAsRead(notification.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'سيتم عرض إشعاراتك هنا',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 18,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontFamily: 'Cairo',
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.read<NotificationProvider>().loadNotifications(),
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(BuildContext context, NotificationModel notification) {
    // Mark as read
    context.read<NotificationProvider>().markAsRead(notification.id);

    // Navigate based on notification type
    switch (notification.type) {
      case 'shipment_status':
      case 'shipment_assigned':
        final shipmentId = notification.data?['shipmentId'];
        if (shipmentId != null) {
          Navigator.of(context).pushNamed('/shipment-details', arguments: {'id': shipmentId});
        }
        break;
      case 'complaint_response':
        final complaintId = notification.data?['complaintId'];
        if (complaintId != null) {
          Navigator.of(context).pushNamed('/complaint-details', arguments: {'id': complaintId});
        }
        break;
      case 'chat_message':
        final chatId = notification.data?['chatId'];
        if (chatId != null) {
          Navigator.of(context).pushNamed('/chat', arguments: {'chatId': chatId});
        }
        break;
      default:
        // Stay on notifications screen
        break;
    }
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'مسح جميع الإشعارات',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد من مسح جميع الإشعارات؟',
          style: TextStyle(fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<NotificationProvider>().clearAll();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('مسح', style: TextStyle(fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final VoidCallback onMarkAsRead;

  const _NotificationItem({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          if (!notification.isRead)
            SlidableAction(
              onPressed: (_) => onMarkAsRead(),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.done,
              label: 'قراءة',
            ),
          SlidableAction(
            onPressed: (_) => onDismiss(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'حذف',
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead ? null : Colors.blue.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getIconColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _getIcon(),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 14,
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppHelpers.getRelativeTime(notification.createdAt),
                      style: TextStyle(
                        fontFamily: 'Cairo',
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getIcon() {
    switch (notification.type) {
      case 'shipment_status':
        return '📦';
      case 'shipment_assigned':
        return '🚚';
      case 'complaint_response':
        return '💬';
      case 'admin_announcement':
        return '📢';
      case 'chat_message':
        return '💬';
      default:
        return '🔔';
    }
  }

  Color _getIconColor() {
    switch (notification.type) {
      case 'shipment_status':
        return Colors.blue;
      case 'shipment_assigned':
        return Colors.green;
      case 'complaint_response':
        return Colors.orange;
      case 'admin_announcement':
        return Colors.purple;
      case 'chat_message':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
