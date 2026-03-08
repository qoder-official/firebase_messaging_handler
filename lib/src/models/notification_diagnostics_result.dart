/// Snapshot returned by `runDiagnostics()` summarizing notification readiness.
class NotificationDiagnosticsResult {
  /// Whether diagnostics completed without throwing.
  final bool success;

  /// Whether notification permissions are effectively available.
  final bool permissionsGranted;

  /// Raw platform authorization status string.
  final String authorizationStatus;

  /// Whether an FCM token is currently cached locally.
  final bool fcmTokenAvailable;

  /// Whether app badges are supported on the current platform/launcher.
  final bool badgeSupported;

  /// Whether browser notifications are currently allowed on web.
  final bool webNotificationsAllowed;

  /// Number of locally pending scheduled notifications.
  final int pendingNotificationCount;

  /// Current platform name used in diagnostics output.
  final String platform;

  /// Actionable next steps derived from the current state.
  final List<String> recommendations;

  /// Extended per-platform metadata and raw diagnostic details.
  final Map<String, dynamic> metadata;

  /// Error string when diagnostics fail.
  final String? error;

  /// Creates a diagnostics snapshot.
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

  /// Convenience constructor for failed diagnostic runs.
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

  /// Converts the diagnostics object into a serializable map.
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
