import 'dart:async';

import 'in_app_notification_data.dart';

typedef InAppNotificationDisplayCallback = FutureOr<void> Function(
    InAppNotificationData data);

class InAppNotificationTemplate {
  final String id;
  final String description;
  final InAppNotificationDisplayCallback onDisplay;
  final Duration? autoDismissDuration;
  final bool barrierDismissible;

  const InAppNotificationTemplate({
    required this.id,
    required this.description,
    required this.onDisplay,
    this.autoDismissDuration,
    this.barrierDismissible = true,
  });
}
