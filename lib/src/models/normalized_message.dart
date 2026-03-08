import 'package:firebase_messaging/firebase_messaging.dart';
import '../enums/notification_lifecycle_enum.dart';
import 'notification_data.dart';

/// Lifecycle-agnostic representation of an incoming notification event.
class NormalizedMessage {
  /// Stable message identifier used by the handler.
  final String id;

  /// Notification title, if present.
  final String? title;

  /// Notification body, if present.
  final String? body;

  /// Image URL extracted from the notification payload when available.
  final String? imageUrl;

  /// Unified data payload map.
  final Map<String, dynamic> data;

  /// Parsed interactive actions when the payload includes them.
  final List<NotificationAction>? actions;

  /// Timestamp when the handler normalized the message.
  final DateTime receivedAt;

  /// Optional origin/source marker.
  final String? origin;

  /// Notification channel identifier when available.
  final String? channelId;

  /// Parsed analytics metadata attached to the message.
  final Map<String, dynamic>? analytics;

  /// Original Firebase message for callers that need raw platform details.
  final RemoteMessage? rawMessage;

  /// App lifecycle stage in which the message was observed.
  final NotificationLifecycle lifecycle;

  /// Creates a normalized message for unified handling callbacks.
  const NormalizedMessage({
    required this.id,
    required this.data,
    required this.receivedAt,
    required this.lifecycle,
    this.title,
    this.body,
    this.imageUrl,
    this.actions,
    this.origin,
    this.channelId,
    this.analytics,
    this.rawMessage,
  });
}
