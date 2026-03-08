import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Authenticates via a Firebase service account and POSTs messages to the
/// FCM HTTP v1 REST API.
///
/// Usage:
/// ```dart
/// final sender = await FcmTestSender.fromFile('test/firebase_config/service_account.json');
/// if (sender == null) return markTestSkipped('No service_account.json found.');
/// await sender.send(deviceToken: token, title: 'Test', body: 'Hello');
/// ```
class FcmTestSender {
  static const _scope = 'https://www.googleapis.com/auth/firebase.messaging';

  final String projectId;
  final Map<String, dynamic> _serviceAccount;

  FcmTestSender._({required this.projectId, required Map<String, dynamic> sa})
      : _serviceAccount = sa;

  /// Returns `null` if [path] does not exist (CI-safe skip signal).
  static Future<FcmTestSender?> fromFile(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;
    final sa = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    return FcmTestSender._(projectId: sa['project_id'] as String, sa: sa);
  }

  /// Sends an FCM message to [deviceToken].
  ///
  /// Supply [title] + [body] for a visible notification, [data] for a
  /// data-only (silent) payload, or both.
  Future<void> send({
    required String deviceToken,
    String? title,
    String? body,
    Map<String, String> data = const {},
  }) async {
    final creds = ServiceAccountCredentials.fromJson(_serviceAccount);
    final client = await clientViaServiceAccount(
      creds,
      [_scope],
      baseClient: http.Client(),
    );
    try {
      final url = Uri.parse(
        'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
      );
      final payload = {
        'message': {
          'token': deviceToken,
          if (title != null || body != null)
            'notification': {
              if (title != null) 'title': title,
              if (body != null) 'body': body,
            },
          if (data.isNotEmpty) 'data': data,
        },
      };
      final response = await client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode != 200) {
        throw Exception(
            'FCM send failed ${response.statusCode}: ${response.body}');
      }
    } finally {
      client.close();
    }
  }
}
