// ignore_for_file: avoid_print

import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../test/helpers/fcm_test_sender.dart';

/// Real-FCM integration tests.
///
/// Prerequisites:
///   1. Place a Firebase service account key at:
///        test/firebase_config/service_account.json
///   2. Pass your Firebase Sender ID (project number) via --dart-define:
///        --dart-define=FCM_TEST_SENDER_ID=123456789012
///   3. Run on a physical device (not a simulator):
///        flutter test integration_test/real_push/real_push_test.dart \
///          --dart-define=FCM_TEST_SENDER_ID=123456789012 \
///          --device-id your-device-id
///
/// All tests self-skip in CI when the service account file is absent.
/// See integration_test/README.md for full instructions.

const _configPath = 'test/firebase_config/service_account.json';
const _skipReason =
    'No service_account.json found in test/firebase_config/ — skipping real-FCM tests.';

/// Sender ID = Firebase project number (not project ID).
/// Pass via: --dart-define=FCM_TEST_SENDER_ID=123456789012
const _senderId =
    String.fromEnvironment('FCM_TEST_SENDER_ID', defaultValue: '');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FcmTestSender? sender;
  late Stream<NotificationData?>? clickStream;
  late String? deviceToken;

  setUpAll(() async {
    sender = await FcmTestSender.fromFile(_configPath);
    if (sender == null) return;

    if (_senderId.isEmpty) {
      print(
        '[real_push] WARNING: FCM_TEST_SENDER_ID not set — '
        'token-dependent tests will skip. Pass via --dart-define.',
      );
    }

    clickStream = await FirebaseMessagingHandler.instance.init(
      senderId: _senderId.isEmpty ? '000000000000' : _senderId,
      androidChannelList: [
        NotificationChannelData(
          id: 'integration_test',
          name: 'Integration Tests',
          description: 'FCM real-push integration test channel',
        ),
      ],
      androidNotificationIconPath: '@mipmap/ic_launcher',
    );

    deviceToken = await FirebaseMessagingHandler.instance.getFcmToken();
  });

  // ── 1. Token retrieval ────────────────────────────────────────────────────
  test('FCM token is available on real device', () async {
    if (sender == null) {
      markTestSkipped(_skipReason);
      return;
    }

    expect(
      deviceToken,
      isNotNull,
      reason: FirebaseMessagingHandler.instance.lastTokenError ??
          'Token is null but no error was set',
    );
    expect(deviceToken, isNotEmpty);
    print('[real_push] FCM token: ${deviceToken!.substring(0, 20)}…');
  }, timeout: const Timeout(Duration(seconds: 30)));

  // ── 2. Permissions ────────────────────────────────────────────────────────
  test('Notification permissions are granted', () async {
    if (sender == null) {
      markTestSkipped(_skipReason);
      return;
    }

    final result =
        await FirebaseMessagingHandler.instance.requestPermissionsWizard();
    expect(
      result.overallStatus,
      anyOf('granted', 'provisional'),
      reason:
          'Expected granted or provisional, got: ${result.overallStatus}. '
          'Notes: ${result.notes.join(', ')}',
    );
  }, timeout: const Timeout(Duration(seconds: 15)));

  // ── 3. Foreground notification receipt ───────────────────────────────────
  testWidgets(
    'Foreground notification is delivered and emitted on click stream',
    (tester) async {
      if (sender == null) {
        markTestSkipped(_skipReason);
        return;
      }
      if (deviceToken == null) {
        markTestSkipped(
          'No FCM token available — cannot send foreground notification. '
          'Error: ${FirebaseMessagingHandler.instance.lastTokenError}',
        );
        return;
      }
      if (clickStream == null) {
        markTestSkipped('init() did not return a click stream.');
        return;
      }

      final received = <NotificationData?>[];
      final sub = clickStream!.listen(received.add);

      await sender!.send(
        deviceToken: deviceToken!,
        title: 'Integration Test',
        body: 'Foreground scenario ${DateTime.now().millisecondsSinceEpoch}',
      );

      // Wait up to 10 s for the message to arrive while keeping UI alive.
      await tester.pumpAndSettle(const Duration(seconds: 10));

      await sub.cancel();
      expect(
        received,
        isNotEmpty,
        reason: 'No click event received on stream within 10 s. '
            'Ensure the app is in the foreground and the user taps the notification.',
      );
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  // ── 4. Data-only / in-app trigger ────────────────────────────────────────
  test(
    'Data-only payload with fcmh_inapp key is processed without crashing',
    () async {
      if (sender == null) {
        markTestSkipped(_skipReason);
        return;
      }
      if (deviceToken == null) {
        markTestSkipped(
          'No FCM token available — cannot send data-only payload.',
        );
        return;
      }

      await expectLater(
        sender!.send(
          deviceToken: deviceToken!,
          data: {
            'fcmh_inapp':
                '{"template":"builtin_generic","type":"dialog","title":"Test","body":"Data payload"}',
          },
        ),
        completes,
        reason: 'FCM send() should not throw',
      );

      // Give the background handler time to process the silent push.
      await Future<void>.delayed(const Duration(seconds: 5));
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  // ── 5. Diagnostics surface token ─────────────────────────────────────────
  test(
    'runDiagnostics reports token available after initialization',
    () async {
      if (sender == null) {
        markTestSkipped(_skipReason);
        return;
      }

      final result =
          await FirebaseMessagingHandler.instance.runDiagnostics();

      expect(
        result.fcmTokenAvailable,
        isTrue,
        reason:
            'Diagnostics should report token available. Error: ${result.error}',
      );
      expect(
        result.permissionsGranted,
        isTrue,
        reason:
            'Diagnostics should report permissions granted. '
            'Status: ${result.authorizationStatus}',
      );

      print('[real_push] Diagnostics: ${result.toMap()}');
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
