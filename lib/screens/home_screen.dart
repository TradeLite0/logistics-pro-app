import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/shipments/my_shipments_screen.dart';
import 'screens/shipments/driver_shipments_screen.dart';
import 'screens/chat/chat_list_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'widgets/notifications/notification_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<UserProvider>().loadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final isDriver = userProvider.user?.isDriver ?? false;

        final screens = [
          isDriver ? const DriverShipmentsScreen() : const MyShipmentsScreen(),
          const ChatListScreen(),
          const NotificationsScreen(),
          const ProfileScreen(),
        ];

        final items = [
          const BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'الشحنات',
          ),
          BottomNavigationBarItem(
            icon: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return NotificationBadge(
                  count: chatProvider.totalUnreadCount,
                  child: const Icon(Icons.chat_bubble_outline),
                );
              },
            ),
            activeIcon: const Icon(Icons.chat_bubble),
            label: 'المحادثات',
          ),
          BottomNavigationBarItem(
            icon: Consumer<NotificationProvider>(
              builder: (context, notificationProvider, child) {
                return NotificationBadge(
                  count: notificationProvider.unreadCount,
                  child: const Icon(Icons.notifications_outlined),
                );
              },
            ),
            activeIcon: const Icon(Icons.notifications),
            label: 'الإشعارات',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'الملف الشخصي',
          ),
        ];

        return Scaffold(
          body: screens[_currentIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: items,
          ),
        );
      },
    );
  }
}
