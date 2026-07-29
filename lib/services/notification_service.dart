import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import '../core/constants/app_colors.dart';

// Handle background messages
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message: ${message.notification?.title}');
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

    debugPrint('Permission status: ${settings.authorizationStatus}');
  }

  // Get & Save FCM Token
  Future<void> _getToken() async {
    String? token = await _messaging.getToken();
    debugPrint('FCM Token: $token');

    if (token != null && _auth.currentUser != null) {
      await updateToken(token);
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      if (_auth.currentUser != null) {
        await updateToken(newToken);
      }
    });
  }

  // Update FCM Token in Firestore
  Future<void> updateToken(String? token) async {
    token ??= await _messaging.getToken();
    if (token != null && _auth.currentUser != null) {
      await _db
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .set(
        {
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
  }

  // Listen to foreground messages
  void _listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message: ${message.notification?.title}');
      // Show in-app notification
      _showInAppNotification(message);
    });
  }

  // Handle initial message (app terminated)
  Future<void> _handleInitialMessage() async {
    RemoteMessage? message = await _messaging.getInitialMessage();
    if (message != null) {
      debugPrint('Initial message: ${message.notification?.title}');
    }
  }

  // Handle message opened app (background)
  void _handleMessageOpenedApp() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened app: ${message.notification?.title}');
    });
  }

  // Show in-app notification banner
  void _showInAppNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    SaathChaloApp.scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title ?? 'New Notification',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(notification.body ?? ''),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Logic to navigate based on message type
          },
        ),
      ),
    );
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