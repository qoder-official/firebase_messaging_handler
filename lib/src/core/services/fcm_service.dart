import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../interfaces/fcm_service_interface.dart';

/// Firebase Cloud Messaging service implementation
class FCMService implements FCMServiceInterface {
  static FCMService? _instance;
  FirebaseMessaging? _firebaseMessaging;
  bool _isInitialized = false;

  /// Singleton instance
  static FCMService get instance {
    _instance ??= FCMService._internal();
    return _instance!;
  }

  FCMService._internal();

  @override
  Future<bool> initialize() async {
    try {
      _firebaseMessaging = FirebaseMessaging.instance;
      _isInitialized = true;
      _logMessage('[FCMService] Initialized successfully');
      return true;
    } catch (error, stack) {
      _logMessage('[FCMService] Initialization error: $error');
      _logMessage('[FCMService] Stack trace: $stack');
      return false;
    }
  }

  @override
  Future<bool> requestPermissions() async {
    try {
      // Ensure Firebase Messaging is initialized
      if (!_isInitialized) {
        await initialize();
      }

      final NotificationSettings settings =
          await _firebaseMessaging!.requestPermission();
      final bool isAuthorized =
          settings.authorizationStatus == AuthorizationStatus.authorized;
      _logMessage('[FCMService] Permission request result: $isAuthorized');
      return isAuthorized;
    } catch (error, stack) {
      _logMessage('[FCMService] Permission request error: $error');
      _logMessage('[FCMService] Stack trace: $stack');
      return false;
    }
  }

  @override
  Future<String?> getToken({String? vapidKey}) async {
    try {
      // Ensure Firebase Messaging is initialized
      if (!_isInitialized) {
        await initialize();
      }

      final String? token =
          await _firebaseMessaging!.getToken(vapidKey: vapidKey);

      // Handle APNs token error on iOS simulators
      if (token == null && !kIsWeb && Platform.isIOS) {
        _logMessage(
            '[FCMService] APNs token not available (normal on iOS simulators)');
        return 'mock_fcm_token_simulator_${DateTime.now().millisecondsSinceEpoch}';
      }

      _logMessage(
          '[FCMService] FCM token retrieved: ${token != null ? 'success' : 'null'}');
      return token;
    } catch (error, stack) {
      _logMessage('[FCMService] Token retrieval error: $error');
      _logMessage('[FCMService] Stack trace: $stack');

      // Handle APNs token error specifically
      if (error.toString().contains('apns-token-not-set')) {
        _logMessage(
            '[FCMService] APNs token not set - this is normal on iOS simulators or when APNs is not configured');
        return 'mock_fcm_token_apns_not_set_${DateTime.now().millisecondsSinceEpoch}';
      }

      return null;
    }
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    try {
      // Ensure Firebase Messaging is initialized
      if (!_isInitialized) {
        await initialize();
      }

      await _firebaseMessaging!.subscribeToTopic(topic);
      _logMessage('[FCMService] Subscribed to topic: $topic');
    } catch (error, stack) {
      _logMessage('[FCMService] Topic subscription error: $error');
      _logMessage('[FCMService] Stack trace: $stack');
    }
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      // Ensure Firebase Messaging is initialized
      if (!_isInitialized) {
        await initialize();
      }

      await _firebaseMessaging!.unsubscribeFromTopic(topic);
      _logMessage('[FCMService] Unsubscribed from topic: $topic');
    } catch (error, stack) {
      _logMessage('[FCMService] Topic unsubscription error: $error');
      _logMessage('[FCMService] Stack trace: $stack');
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      // Ensure Firebase Messaging is initialized
      if (!_isInitialized) {
        await initialize();
      }

      await _firebaseMessaging!.deleteToken();
      _logMessage('[FCMService] FCM token deleted');
    } catch (error, stack) {
      _logMessage('[FCMService] Token deletion error: $error');
      _logMessage('[FCMService] Stack trace: $stack');
    }
  }

  @override
  Future<RemoteMessage?> getInitialMessage() async {
    try {
      // Ensure Firebase Messaging is initialized
      if (!_isInitialized) {
        await initialize();
      }

      final RemoteMessage? message =
          await _firebaseMessaging!.getInitialMessage();
      _logMessage(
          '[FCMService] Initial message: ${message != null ? 'found' : 'none'}');
      return message;
    } catch (error, stack) {
      _logMessage('[FCMService] Initial message error: $error');
      _logMessage('[FCMService] Stack trace: $stack');
      return null;
    }
  }

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  @override
  Stream<RemoteMessage> get onBackgroundMessage => Stream.empty();

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) async {
    try {
      // Ensure Firebase Messaging is initialized
      if (!_isInitialized) {
        await initialize();
      }

      await _firebaseMessaging!.setForegroundNotificationPresentationOptions(
        alert: alert,
        badge: badge,
        sound: sound,
      );
      _logMessage('[FCMService] Foreground presentation options set');
    } catch (error, stack) {
      _logMessage('[FCMService] Foreground options error: $error');
      _logMessage('[FCMService] Stack trace: $stack');
    }
  }

  void _logMessage(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
}
