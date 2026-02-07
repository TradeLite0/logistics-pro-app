import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../utils/constants.dart';

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();

  // Stream controllers for notification events
  final _notificationStreamController = 
      StreamController<NotificationModel>.broadcast();
  final _notificationTapController = 
      StreamController<NotificationModel>.broadcast();
  final _badgeCountController = StreamController<int>.broadcast();

  Stream<NotificationModel> get notificationStream => 
      _notificationStreamController.stream;
  Stream<NotificationModel> get notificationTapStream => 
      _notificationTapController.stream;
  Stream<int> get badgeCountStream => _badgeCountController.stream;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  // Callbacks for navigation
  Function(NotificationModel)? onNotificationTap;

  Future<void> initialize() async {
    // Request permissions
    await _requestPermissions();

    // Initialize local notifications
    await _initializeLocalNotifications();

    // Set up foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Handle notification open when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);

    // Check for initial message (app opened from terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpened(initialMessage);
    }

    // Get and save FCM token
    await _saveFcmToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_onTokenRefresh);
  }

  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Notification permission status: ${settings.authorizationStatus}');

    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'إشعارات مهمة',
        description: 'الإشعارات الهامة لتطبيق اللوجستيات',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.notification?.title}');

    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'إشعار جديد',
      body: message.notification?.body ?? '',
      type: message.data['type'] ?? 'general',
      data: message.data,
      createdAt: DateTime.now(),
    );

    // Show local notification
    _showLocalNotification(notification);

    // Add to stream
    _notificationStreamController.add(notification);

    // Update badge count
    _updateBadgeCount(1);
  }

  void _handleNotificationOpened(RemoteMessage message) {
    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      type: message.data['type'] ?? 'general',
      data: message.data,
      createdAt: DateTime.now(),
    );

    _notificationTapController.add(notification);

    if (onNotificationTap != null) {
      onNotificationTap!(notification);
    }
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      final notification = NotificationModel.fromJson(data);
      _notificationTapController.add(notification);

      if (onNotificationTap != null) {
        onNotificationTap!(notification);
      }
    }
  }

  Future<void> _showLocalNotification(NotificationModel notification) async {
    final AndroidNotificationDetails androidDetails = 
        AndroidNotificationDetails(
      'high_importance_channel',
      'إشعارات مهمة',
      channelDescription: 'الإشعارات الهامة لتطبيق اللوجستيات',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(notification.toJson()),
    );
  }

  Future<void> _saveFcmToken() async {
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('FCM Token: $token');
      await _sendTokenToServer(token);
    }
  }

  Future<void> _onTokenRefresh(String token) async {
    debugPrint('FCM Token refreshed: $token');
    await _sendTokenToServer(token);
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('token');

      if (authToken == null) return;

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/users/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM token sent to server successfully');
      } else {
        debugPrint('Failed to send FCM token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending FCM token: $e');
    }
  }

  void _updateBadgeCount(int delta) {
    _unreadCount += delta;
    if (_unreadCount < 0) _unreadCount = 0;
    _badgeCountController.add(_unreadCount);
  }

  Future<void> setBadgeCount(int count) async {
    _unreadCount = count;
    _badgeCountController.add(_unreadCount);
  }

  // Navigate based on notification type
  void navigateFromNotification(
    NotificationModel notification,
    Function(String route, {Map<String, dynamic>? args}) navigate,
  ) {
    switch (notification.type) {
      case 'shipment_status':
        final shipmentId = notification.data?['shipmentId'];
        if (shipmentId != null) {
          navigate('/shipment-details', args: {'id': shipmentId});
        }
        break;
      case 'shipment_assigned':
        final shipmentId = notification.data?['shipmentId'];
        if (shipmentId != null) {
          navigate('/shipment-details', args: {'id': shipmentId});
        }
        break;
      case 'complaint_response':
        final complaintId = notification.data?['complaintId'];
        if (complaintId != null) {
          navigate('/complaint-details', args: {'id': complaintId});
        }
        break;
      case 'chat_message':
        final chatId = notification.data?['chatId'];
        if (chatId != null) {
          navigate('/chat', args: {'chatId': chatId});
        }
        break;
      default:
        navigate('/notifications');
    }
  }

  void dispose() {
    _notificationStreamController.close();
    _notificationTapController.close();
    _badgeCountController.close();
  }
}
