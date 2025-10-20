import 'package:flutter/foundation.dart';
import '../interfaces/analytics_service_interface.dart';
import '../utils/platform_utils.dart';

/// Analytics service implementation
class AnalyticsService implements AnalyticsServiceInterface {
  static AnalyticsService? _instance;
  void Function(String event, Map<String, dynamic> data)? _callback;

  /// Singleton instance
  static AnalyticsService get instance {
    _instance ??= AnalyticsService._internal();
    return _instance!;
  }

  AnalyticsService._internal();

  @override
  void trackEvent(String event, Map<String, dynamic> data) {
    try {
      // Add timestamp and common metadata
      final enrichedData = {
        'event': event,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': getCurrentPlatform(),
        ...data,
      };

      // Call user-provided analytics callback if available
      _callback?.call(event, enrichedData);

      _logMessage('[AnalyticsService] Event tracked: $event');
    } catch (error, stack) {
      _logMessage('[AnalyticsService] Track event error: $error');
      _logMessage('[AnalyticsService] Stack trace: $stack');
    }
  }

  @override
  void setCallback(
      void Function(String event, Map<String, dynamic> data) callback) {
    _callback = callback;
    _logMessage('[AnalyticsService] Analytics callback set');
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
  void trackNotificationReceived(dynamic message) {
    try {
      final Map<String, dynamic> data = {
        'message_id': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'category': message.category,
        'sender_id': message.senderId,
        'ttl': message.ttl,
        'collapse_key': message.collapseKey,
      };

      trackEvent('notification_received', data);
    } catch (error, stack) {
      _logMessage(
          '[AnalyticsService] Track notification received error: $error');
      _logMessage('[AnalyticsService] Stack trace: $stack');
    }
  }

  @override
  void trackNotificationClicked(dynamic notificationData) {
    try {
      final Map<String, dynamic> data = {
        'title': notificationData.title,
        'body': notificationData.body,
        'type': notificationData.type.name,
        'is_from_terminated': notificationData.isFromTerminated,
        'message_id': notificationData.messageId,
        'category': notificationData.category,
      };

      trackEvent('notification_clicked', data);
    } catch (error, stack) {
      _logMessage(
          '[AnalyticsService] Track notification clicked error: $error');
      _logMessage('[AnalyticsService] Stack trace: $stack');
    }
  }

  @override
  void trackNotificationScheduled(String type, Map<String, dynamic> data) {
    try {
      final Map<String, dynamic> enrichedData = {
        'schedule_type': type,
        ...data,
      };

      trackEvent('notification_scheduled', enrichedData);
    } catch (error, stack) {
      _logMessage(
          '[AnalyticsService] Track notification scheduled error: $error');
      _logMessage('[AnalyticsService] Stack trace: $stack');
    }
  }

  @override
  void trackTokenEvent(String event, String? token) {
    try {
      final Map<String, dynamic> data = {
        'event': event,
        'has_token': token != null && token.isNotEmpty,
      };

      trackEvent('fcm_token', data);
    } catch (error, stack) {
      _logMessage('[AnalyticsService] Track token event error: $error');
      _logMessage('[AnalyticsService] Stack trace: $stack');
    }
  }

  void _logMessage(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
}
