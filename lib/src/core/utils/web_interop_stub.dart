/// Stub implementations for non-web platforms.
/// All functions return safe defaults since web APIs are unavailable.
library;

String getWebNotificationPermission() => 'unavailable';

Future<bool> requestWebNotificationPermission() async => false;

Map<String, dynamic> getWebRuntimeDiagnostics() =>
    {'supported': false, 'reason': 'unavailable'};

Future<void> showWebNotification({
  required String title,
  required String body,
  required String icon,
  required Map<String, dynamic> data,
}) async {}
