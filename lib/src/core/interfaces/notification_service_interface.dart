import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../models/export.dart';

/// Interface for local notification service operations
abstract class NotificationServiceInterface {
  /// Initializes the local notification service
  Future<bool> initialize({
    required List<NotificationChannelData> androidChannels,
    required String androidIconPath,
  });

  /// Shows a local notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String? channelId,
    String? groupKey,
    String? sortKey,
    String? category,
    AndroidNotificationDetails? androidDetailsOverride,
    DarwinNotificationDetails? iosDetailsOverride,
  });

  /// Shows a notification with actions
  Future<void> showNotificationWithActions({
    required int id,
    required String title,
    required String body,
    required List<NotificationAction> actions,
    Map<String, dynamic>? payload,
    String? channelId,
  });

  /// Schedules a notification
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? payload,
    String? channelId,
    List<NotificationAction>? actions,
  });

  /// Cancels a notification
  Future<void> cancelNotification(int id);

  /// Cancels all notifications
  Future<void> cancelAllNotifications();

  /// Gets pending notifications
  Future<List<dynamic>> getPendingNotifications();

  /// Creates a notification channel
  Future<void> createNotificationChannel(NotificationChannelData channel);

  /// Gets notification app launch details
  Future<dynamic> getNotificationAppLaunchDetails();
}
