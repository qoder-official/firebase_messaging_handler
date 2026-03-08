/// Rich result returned by the permission wizard helper.
class PermissionWizardResult {
  /// Creates a permission wizard result.
  const PermissionWizardResult({
    required this.overallStatus,
    this.androidPostNotifications,
    this.androidExactAlarmNote,
    this.iosAuthorizationStatus,
    this.webPermission,
    this.notes = const <String>[],
  });

  /// Overall result such as `granted`, `denied`, `web_prompt`, or
  /// `desktop_local_mode`.
  final String overallStatus;

  /// Android 13+ notification permission result when applicable.
  final bool? androidPostNotifications;

  /// Guidance for exact-alarm behavior on Android when relevant.
  final String? androidExactAlarmNote;

  /// iOS authorization status string when relevant.
  final String? iosAuthorizationStatus;

  /// Current browser permission state when running on web.
  final String? webPermission;

  /// Additional actionable notes for the host app or user.
  final List<String> notes;
}
