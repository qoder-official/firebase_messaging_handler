class NotificationDiagnosticsResult {
  final bool success;
  final bool permissionsGranted;
  final String authorizationStatus;
  final bool fcmTokenAvailable;
  final bool badgeSupported;
  final bool webNotificationsAllowed;
  final int pendingNotificationCount;
  final String platform;
  final List<String> recommendations;
  final Map<String, dynamic> metadata;
  final String? error;

  const NotificationDiagnosticsResult({
    required this.success,
    required this.permissionsGranted,
    required this.authorizationStatus,
    required this.fcmTokenAvailable,
    required this.badgeSupported,
    required this.webNotificationsAllowed,
    required this.pendingNotificationCount,
    required this.platform,
    required this.recommendations,
    required this.metadata,
    this.error,
  });

  factory NotificationDiagnosticsResult.failure({
    required String platform,
    required String error,
  }) {
    return NotificationDiagnosticsResult(
      success: false,
      permissionsGranted: false,
      authorizationStatus: 'unknown',
      fcmTokenAvailable: false,
      badgeSupported: false,
      webNotificationsAllowed: false,
      pendingNotificationCount: 0,
      platform: platform,
      recommendations: const [],
      metadata: const {},
      error: error,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'permissionsGranted': permissionsGranted,
      'authorizationStatus': authorizationStatus,
      'fcmTokenAvailable': fcmTokenAvailable,
      'badgeSupported': badgeSupported,
      'webNotificationsAllowed': webNotificationsAllowed,
      'pendingNotificationCount': pendingNotificationCount,
      'platform': platform,
      'recommendations': recommendations,
      'metadata': metadata,
      'error': error,
    };
  }
}
