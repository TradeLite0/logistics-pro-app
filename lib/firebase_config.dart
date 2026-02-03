import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';

/// Initialize Firebase and Notifications
class FirebaseConfig {
  static Future<void> initialize() async {
    // Initialize Firebase
    await Firebase.initializeApp(
      // options: DefaultFirebaseOptions.currentPlatform, // فعل لما تضيف Firebase
    );

    // Initialize Notifications
    await NotificationService().initialize();

    // Request permission for notifications
    await _requestPermission();

    // Get FCM token
    final token = await FirebaseMessaging.instance.getToken();
    debugPrint('🔔 FCM Token: $token');

    // Listen for token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('🔔 FCM Token refreshed: $newToken');
      // TODO: Send new token to your backend
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification open
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  static Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('🔔 Notification permission: ${settings.authorizationStatus}');
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 Foreground message received:');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    debugPrint('Data: ${message.data}');

    // Show local notification
    NotificationService().showLocalNotification(
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      payload: message.data,
    );
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('📨 Notification clicked:');
    debugPrint('Data: ${message.data}');
    // TODO: Navigate to specific screen based on data
  }
}

/// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('📨 Background message: ${message.messageId}');
}
