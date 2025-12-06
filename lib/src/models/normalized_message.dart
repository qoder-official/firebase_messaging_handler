import 'package:firebase_messaging/firebase_messaging.dart';
import '../enums/notification_lifecycle_enum.dart';
import 'notification_data.dart';

class NormalizedMessage {
  final String id;
  final String? title;
  final String? body;
  final String? imageUrl;
  final Map<String, dynamic> data;
  final List<NotificationAction>? actions;
  final DateTime receivedAt;
  final String? origin;
  final String? channelId;
  final Map<String, dynamic>? analytics;
  final RemoteMessage? rawMessage;
  final NotificationLifecycle lifecycle;

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

