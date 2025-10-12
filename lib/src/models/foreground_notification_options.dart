import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ForegroundNotificationContext {
  final RemoteMessage message;
  final String? title;
  final String? body;
  final Map<String, dynamic> data;

  ForegroundNotificationContext({
    required this.message,
  })  : title = message.notification?.title,
        body = message.notification?.body,
        data = Map<String, dynamic>.unmodifiable(message.data);
}

typedef AndroidForegroundNotificationBuilder
    = FutureOr<AndroidNotificationDetails?> Function(
  ForegroundNotificationContext context,
);

typedef IOSForegroundNotificationBuilder = FutureOr<DarwinNotificationDetails?>
    Function(
  ForegroundNotificationContext context,
);

class ForegroundNotificationOptions {
  final bool enabled;
  final AndroidNotificationDetails? androidDefaults;
  final DarwinNotificationDetails? iosDefaults;
  final AndroidForegroundNotificationBuilder? androidBuilder;
  final IOSForegroundNotificationBuilder? iosBuilder;

  const ForegroundNotificationOptions({
    this.enabled = true,
    this.androidDefaults,
    this.iosDefaults,
    this.androidBuilder,
    this.iosBuilder,
  });

  static const ForegroundNotificationOptions defaults =
      ForegroundNotificationOptions(
    enabled: true,
    androidDefaults: AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      channelDescription:
          'Default notification channel for foreground messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    ),
    iosDefaults: DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    ),
  );
}
