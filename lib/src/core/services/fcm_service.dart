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
  bool _loggedUnsupportedPlatform = false;

  /// Stores the human-readable reason the last [getToken] call returned null.
  /// Callers can surface this in the UI instead of a generic "no token" message.
  String? _lastTokenError;

  // Cache for initial message (can only be called once per app launch)
  RemoteMessage? _cachedInitialMessage;
  bool _hasCheckedInitialMessage = false;

  /// Singleton instance
  static FCMService get instance {
    _instance ??= FCMService._internal();
    return _instance!;
  }

  FCMService._internal();

  /// The reason the last [getToken] call returned null, or null if it succeeded.
  String? get lastTokenError => _lastTokenError;

  /// Whether Firebase Messaging is available on the current platform.
  bool get isSupportedOnCurrentPlatform => !(isWindows || isLinux);

  /// Human-readable explanation for platforms where Firebase Messaging is disabled.
  String? get unsupportedPlatformReason => isSupportedOnCurrentPlatform
      ? null
      : 'Firebase Cloud Messaging is not supported on $currentPlatformName. '
          'This package remains usable for local notifications, scheduling, inbox, quiet hours, and in-app templates on desktop.';

  @override
  Future<bool> initialize() async {
    try {
      if (!isSupportedOnCurrentPlatform) {
        _isInitialized = true;
        _lastTokenError = unsupportedPlatformReason;
        _logUnsupportedPlatformOnce('initialize');
        return true;
      }

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
      if (!isSupportedOnCurrentPlatform) {
        await initialize();
        _logUnsupportedPlatformOnce('requestPermissions');
        return true;
      }

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
    if (!isSupportedOnCurrentPlatform) {
      await initialize();
      _lastTokenError = unsupportedPlatformReason;
      _logUnsupportedPlatformOnce('getToken');
      return null;
    }

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

        if (token == null && isIOS) {
          // Firebase returned null without throwing — likely running on a simulator
          // that has no real APNs device token. This is expected on iOS simulators.
          const String reason =
              'FCM token unavailable: iOS simulator does not have a real APNs device token. '
              'Run on a physical device and ensure APNs is configured in Firebase Console '
              '(Project Settings → Cloud Messaging → APNs Authentication Key).';
          _logMessage('[FCMService] $reason');
          _lastTokenError = reason;
          return null;
        }

        if (token != null) {
          _lastTokenError = null;
          _logMessage('[FCMService] FCM token retrieved: success');
          return token;
        }
      } catch (error, stack) {
        _logMessage('[FCMService] Token retrieval attempt ${retryCount + 1} failed: $error');

        // APNs token not set — retrying immediately won't help; surface a clear message.
        if (isIOS && error.toString().contains('apns-token-not-set')) {
          const String reason =
              'FCM token unavailable: APNs token not set. '
              'Upload an APNs Authentication Key (.p8) to Firebase Console → '
              'Project Settings → Cloud Messaging → iOS app → APNs Authentication Key. '
              'This is required on real iOS devices; simulators cannot receive APNs tokens.';
          _logMessage('[FCMService] $reason');
          _lastTokenError = reason;
          return null;
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
      if (!isSupportedOnCurrentPlatform) {
        await initialize();
        _logUnsupportedPlatformOnce('subscribeToTopic');
        return;
      }

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
      if (!isSupportedOnCurrentPlatform) {
        await initialize();
        _logUnsupportedPlatformOnce('unsubscribeFromTopic');
        return;
      }

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
      if (!isSupportedOnCurrentPlatform) {
        await initialize();
        _lastTokenError = unsupportedPlatformReason;
        _logUnsupportedPlatformOnce('deleteToken');
        return;
      }

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
      if (!isSupportedOnCurrentPlatform) {
        await initialize();
        return null;
      }

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
  Stream<RemoteMessage> get onMessage =>
      isSupportedOnCurrentPlatform
          ? FirebaseMessaging.onMessage
          : const Stream<RemoteMessage>.empty();

  @override
  Stream<RemoteMessage> get onMessageOpenedApp =>
      isSupportedOnCurrentPlatform
          ? FirebaseMessaging.onMessageOpenedApp
          : const Stream<RemoteMessage>.empty();

  @override
  Stream<RemoteMessage> get onBackgroundMessage => const Stream.empty();

  @override
  Stream<String> get onTokenRefresh =>
      isSupportedOnCurrentPlatform
          ? FirebaseMessaging.instance.onTokenRefresh
          : const Stream<String>.empty();

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    try {
      if (!isSupportedOnCurrentPlatform) {
        await initialize();
        return _desktopLocalModeSettings();
      }

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
    if (!isSupportedOnCurrentPlatform) {
      await initialize();
      _logUnsupportedPlatformOnce('setBackgroundMessageHandler');
      return;
    }
    FirebaseMessaging.onBackgroundMessage(handler);
  }

  @override
  Future<void> setForegroundNotificationPresentationOptions({
    bool alert = true,
    bool badge = true,
    bool sound = true,
  }) async {
    try {
      if (!isSupportedOnCurrentPlatform) {
        await initialize();
        return;
      }

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

  NotificationSettings _desktopLocalModeSettings() {
    return const NotificationSettings(
      alert: AppleNotificationSetting.notSupported,
      announcement: AppleNotificationSetting.notSupported,
      authorizationStatus: AuthorizationStatus.authorized,
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

  void _logUnsupportedPlatformOnce(String operation) {
    if (_loggedUnsupportedPlatform) {
      return;
    }
    _loggedUnsupportedPlatform = true;
    _logMessage(
      '[FCMService] $operation skipped: ${unsupportedPlatformReason ?? 'unsupported platform'}',
    );
  }
}
