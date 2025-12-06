import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../interfaces/fcm_service_interface.dart';
import '../utils/platform_utils.dart';

/// Firebase Cloud Messaging service implementation
class FCMService implements FCMServiceInterface {
  static FCMService? _instance;
  FirebaseMessaging? _firebaseMessaging;
  bool _isInitialized = false;

  // Cache for initial message (can only be called once per app launch)
  RemoteMessage? _cachedInitialMessage;
  bool _hasCheckedInitialMessage = false;

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
    int retryCount = 0;
    const int maxRetries = 3;

    while (retryCount <= maxRetries) {
      try {
        // Ensure Firebase Messaging is initialized
        if (!_isInitialized) {
          await initialize();
        }

        final String? token =
            await _firebaseMessaging!.getToken(vapidKey: vapidKey);

        // Handle APNs token error on iOS simulators
        if (token == null && isIOS) {
          _logMessage(
              '[FCMService] APNs token not available (normal on iOS simulators)');
          return 'mock_fcm_token_simulator_${DateTime.now().millisecondsSinceEpoch}';
        }

        if (token != null) {
          _logMessage(
              '[FCMService] FCM token retrieved: success');
          return token;
        }
      } catch (error, stack) {
        _logMessage('[FCMService] Token retrieval attempt ${retryCount + 1} failed: $error');
        
        // Handle APNs token error specifically - no point retrying this immediately if config is wrong
        if (isIOS && error.toString().contains('apns-token-not-set')) {
           _logMessage(
              '[FCMService] APNs token not set - this is normal on iOS simulators or when APNs is not configured');
          return 'mock_fcm_token_apns_not_set_${DateTime.now().millisecondsSinceEpoch}';
        }

        if (retryCount == maxRetries) {
          _logMessage('[FCMService] Token retrieval failed after $maxRetries retries.');
          _logMessage('[FCMService] Stack trace: $stack');
          return null;
        }

        // Exponential backoff: 1s, 2s, 4s
        final int delaySeconds = 1 << retryCount;
        _logMessage('[FCMService] Retrying token retrieval in ${delaySeconds}s...');
        await Future.delayed(Duration(seconds: delaySeconds));
        retryCount++;
      }
    }
    return null;
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
      // Return cached message if we've already checked
      if (_hasCheckedInitialMessage) {
        return _cachedInitialMessage;
      }

      // Ensure Firebase Messaging is initialized
      if (!_isInitialized) {
        await initialize();
      }

      final RemoteMessage? message =
          await _firebaseMessaging!.getInitialMessage();

      // Cache the result (even if null)
      _cachedInitialMessage = message;
      _hasCheckedInitialMessage = true;

      // If no message found and we're on iOS, try a different approach
      if (message == null && isIOS) {
        // Sometimes on iOS, we need to check if Firebase is properly initialized
        try {
          // Force a small delay and try again (iOS timing issue)
          await Future.delayed(const Duration(milliseconds: 100));
          final RemoteMessage? retryMessage =
              await _firebaseMessaging!.getInitialMessage();
          if (retryMessage != null) {
            // Update cache with retry result
            _cachedInitialMessage = retryMessage;
            return retryMessage;
          }
        } catch (retryError) {
          // iOS retry failed, continue with null result
        }
      }

      _logMessage(
          '[FCMService] Initial message: ${message != null ? 'found' : 'none'}');
      return message;
    } catch (error, stack) {
      _logMessage('[FCMService] Initial message error: $error');
      _logMessage('[FCMService] Stack trace: $stack');
      return null;
    }
  }

  /// Clears the cached initial message (useful for testing)
  void clearInitialMessageCache() {
    _cachedInitialMessage = null;
    _hasCheckedInitialMessage = false;
  }

  @override
  Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      FirebaseMessaging.onMessageOpenedApp;

  @override
  Stream<RemoteMessage> get onBackgroundMessage => const Stream.empty();

  @override
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      return await _firebaseMessaging!.getNotificationSettings();
    } catch (error, stack) {
      _logMessage('[FCMService] Get notification settings error: $error');
      _logMessage('[FCMService] Stack trace: $stack');
      return const NotificationSettings(
        alert: AppleNotificationSetting.notSupported,
        announcement: AppleNotificationSetting.notSupported,
        authorizationStatus: AuthorizationStatus.notDetermined,
        badge: AppleNotificationSetting.notSupported,
        carPlay: AppleNotificationSetting.notSupported,
        lockScreen: AppleNotificationSetting.notSupported,
        notificationCenter: AppleNotificationSetting.notSupported,
        showPreviews: AppleShowPreviewSetting.notSupported,
        timeSensitive: AppleNotificationSetting.notSupported,
        criticalAlert: AppleNotificationSetting.notSupported,
        sound: AppleNotificationSetting.notSupported,
        providesAppNotificationSettings: AppleNotificationSetting.notSupported,
      );
    }
  }

  @override
  Future<void> setBackgroundMessageHandler(
      Future<void> Function(RemoteMessage message) handler) async {
    FirebaseMessaging.onBackgroundMessage(handler);
  }

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
