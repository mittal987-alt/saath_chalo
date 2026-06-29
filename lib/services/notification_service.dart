import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize notifications
  Future<void> initialize() async {
    // Register background handler
    FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler);

    // Request permission
    await _requestPermission();

    // Get FCM token
    await _getToken();

    // Listen to foreground messages
    _listenToForegroundMessages();

    // Handle notification tap when app is terminated
    _handleInitialMessage();

    // Handle notification tap when app is in background
    _handleMessageOpenedApp();
  }

  // Request permission
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('Permission status: ${settings.authorizationStatus}');
  }

  // Get & Save FCM Token
  Future<void> _getToken() async {
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    if (token != null && _auth.currentUser != null) {
      await _db
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .update({'fcmToken': token});
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      if (_auth.currentUser != null) {
        await _db
            .collection('users')
            .doc(_auth.currentUser!.uid)
            .update({'fcmToken': newToken});
      }
    });
  }

  // Listen to foreground messages
  void _listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message: ${message.notification?.title}');
      // Show in-app notification
      _showInAppNotification(message);
    });
  }

  // Handle initial message (app terminated)
  Future<void> _handleInitialMessage() async {
    RemoteMessage? message = await _messaging.getInitialMessage();
    if (message != null) {
      print('Initial message: ${message.notification?.title}');
    }
  }

  // Handle message opened app (background)
  void _handleMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened app: ${message.notification?.title}');
    });
  }

  // Show in-app notification banner
  void _showInAppNotification(RemoteMessage message) {
    // We will show this via GlobalKey
    print('Show notification: ${message.notification?.title}');
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }
}