import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotification();
  await NotificationService.instance.showNotification(message);
}

@pragma('vm:entry-point')
void notificationTapBackgroundHandler(NotificationResponse details) {
  // TODO: Navigate to a specific screen using payload
  debugPrint('Notification tapped (background): ${details.payload}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _message = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isFlutterLocalNotificationsInitialized = false;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _setUpMessageHandler();
    await setupFlutterNotification();

    final token = await _message.getToken();
    if (token == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userID = user.uid;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userID);
    await userDoc.update({
      'fcmTokens': FieldValue.arrayUnion([token])
    });

    if (kDebugMode) {
      print('token: $token');
    }

    setupFcmTokenRefresh(userID);
    subscribeToTopic('all_device');
  }

  Future<void> _requestPermission() async {
    final settings = await _message.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    print('permission status: ${settings.authorizationStatus}');
  }

  Future<void> setupFlutterNotification() async {
    if (_isFlutterLocalNotificationsInitialized) return;

    const channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'Notification channel',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackgroundHandler,
    );

    _isFlutterLocalNotificationsInitialized = true;
  }

  Future<void> showNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'Notification Channel',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  Future<void> _setUpMessageHandler() async {
    FirebaseMessaging.onMessage.listen((message) {
      NotificationService.instance.showNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackGroundMessage);

    final initialMessage = await _message.getInitialMessage();
    if (initialMessage != null) {
      _handleBackGroundMessage(initialMessage);
    }
  }

  void _handleBackGroundMessage(RemoteMessage message) {
    if (message.data['type'] == 'something') {
      // TODO: Navigate to specific screen if needed
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessaging.instance.subscribeToTopic(topic);
  }

  void setupFcmTokenRefresh(String userId) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([newToken])
      });
    });
  }

  Future<void> sendPushNotification({
    required String recipientUserId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final url = Uri.parse('https://west-select-backend.onrender.com/push');

    if (kDebugMode) {
      print('sending push notification');
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'recipientUserId': recipientUserId,
          'title': title,
          'body': body,
          'data': data ?? {},
        }),
      );

      if (kDebugMode) {
        print('Push response: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending push: $e');
      }
    }
  }
}
