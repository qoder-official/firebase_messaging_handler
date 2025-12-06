import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../interfaces/analytics_service_interface.dart';
import '../utils/platform_utils.dart';

/// Analytics service implementation
class FmhAnalyticsService implements AnalyticsServiceInterface {
  static FmhAnalyticsService? _instance;
  AnalyticsCallback? _analyticsCallback;

  /// Singleton instance
  static FmhAnalyticsService get instance {
    _instance ??= FmhAnalyticsService._internal();
    return _instance!;
  }

  FmhAnalyticsService._internal();

  @override
  Future<void> trackEvent(String event, Map<String, dynamic> properties) async {
    try {
      if (_analyticsCallback != null) {
        await _analyticsCallback!(event, properties);
      }
      _logMessage('[FmhAnalyticsService] Event tracked: $event');
    } catch (error, stack) {
      _logMessage('[FmhAnalyticsService] Track event error: $error');
      _logMessage('[FmhAnalyticsService] Stack trace: $stack');
    }
  }

  @override
  void setCallback(AnalyticsCallback callback) {
    _analyticsCallback = callback;
    _logMessage('[FmhAnalyticsService] Analytics callback set');
  }

  @override
  String getCurrentPlatform() {
    if (isWeb) return 'web';
    if (isAndroid) return 'android';
    if (isIOS) return 'ios';
    if (isMacOS) return 'macos';
    if (isWindows) return 'windows';
    if (isLinux) return 'linux';
    if (isFuchsia) return 'fuchsia';
    return isWeb ? 'web' : 'unknown';
  }

  @override
  Future<void> trackNotificationReceived(RemoteMessage message) async {
    try {
      final Map<String, dynamic> properties = {
        'message_id': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
        'sent_time': message.sentTime?.toIso8601String(),
      };

      await trackEvent('notification_received', properties);
    } catch (error, stack) {
      _logMessage(
          '[FmhAnalyticsService] Track notification received error: $error');
      _logMessage('[FmhAnalyticsService] Stack trace: $stack');
    }
  }

  @override
  Future<void> trackNotificationClicked(RemoteMessage message) async {
    try {
      final Map<String, dynamic> properties = {
        'message_id': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
        'sent_time': message.sentTime?.toIso8601String(),
        'action': 'click',
      };

      await trackEvent('notification_clicked', properties);
    } catch (error, stack) {
      _logMessage(
          '[FmhAnalyticsService] Track notification clicked error: $error');
      _logMessage('[FmhAnalyticsService] Stack trace: $stack');
    }
  }

  @override
  Future<void> trackNotificationScheduled(Map<String, dynamic> data) async =>
      trackEvent('notification_scheduled', data);

  @override
  Future<void> trackTokenEvent(String eventType, String? token) async {
    try {
      final Map<String, dynamic> properties = {
        'token': token, // Be careful with PII
        'event_type': eventType,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await trackEvent('token_event', properties);
    } catch (error, stack) {
      _logMessage('[FmhAnalyticsService] Track token event error: $error');
      _logMessage('[FmhAnalyticsService] Stack trace: $stack');
    }
  }

  void _logMessage(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
}
