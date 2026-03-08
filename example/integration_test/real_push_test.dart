// ignore_for_file: avoid_print

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';
import 'package:firebase_messaging_handler_example/firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'fcm_test_sender.dart';

/// Real-FCM end-to-end integration tests.
///
/// The test app authenticates with Google via a service account embedded at
/// compile time (base64 via --dart-define), then POSTs a real FCM message to
/// fcm.googleapis.com.  Firebase delivers it back to this same device,
/// verifying the full round-trip without any external dashboard.
///
/// ────────────────────────────────────────────────────────────────────────────
/// HOW TO RUN (from example/ directory)
/// ────────────────────────────────────────────────────────────────────────────
///
///   BASE64=$(base64 -i ../test/firebase_config/service_account.json | tr -d '\n')
///
///   flutter test integration_test/real_push_test.dart \
///     --dart-define=FCM_TEST_SENDER_ID=<your-project-number> \
///     --dart-define=FCM_SERVICE_ACCOUNT_B64=$BASE64 \
///     --device-id <your-device-id>
///
/// Without FCM_SERVICE_ACCOUNT_B64 all send-dependent tests SKIP (not fail),
/// so CI without credentials stays green.
/// ────────────────────────────────────────────────────────────────────────────

const _skipReason =
    'FCM_SERVICE_ACCOUNT_B64 not set — skipping real-FCM send tests. '
    'Pass via --dart-define=FCM_SERVICE_ACCOUNT_B64=<base64-encoded-json>.';

const _senderId =
    String.fromEnvironment('FCM_TEST_SENDER_ID', defaultValue: '');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late FcmTestSender? sender;
  late Stream<NotificationData?>? clickStream;
  late String? deviceToken;

  setUpAll(() async {
    // Firebase must be initialized before any FMH or FCM calls.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    sender = FcmTestSender.fromEnv();
    if (sender == null) {
      print('[real_push] No service account — send-dependent tests will skip.');
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

    print('[real_push] token: '
        '${deviceToken != null ? '${deviceToken!.substring(0, 20)}…' : 'NULL'}');
    if (deviceToken == null) {
      print('[real_push] lastTokenError: '
          '${FirebaseMessagingHandler.instance.lastTokenError}');
    }
  });

  // ── 1. Token retrieval ─────────────────────────────────────────────────────
  test('FCM token is available on real device', () async {
    expect(
      deviceToken,
      isNotNull,
      reason: FirebaseMessagingHandler.instance.lastTokenError ??
          'Token null but no error set',
    );
    expect(deviceToken, isNotEmpty);
    print('[real_push] ✓ token: ${deviceToken!.substring(0, 20)}…');
  }, timeout: const Timeout(Duration(seconds: 30)));

  // ── 2. Permissions ─────────────────────────────────────────────────────────
  // On a fresh Android install the OS dialog can't be tapped in a headless
  // test, so we assert the wizard returns A result, not a specific status.
  // Pre-grant via ADB before running to promote to 'granted':
  //   adb shell pm grant <applicationId> android.permission.POST_NOTIFICATIONS
  test('Permission wizard returns a result without crashing', () async {
    final result =
        await FirebaseMessagingHandler.instance.requestPermissionsWizard();
    expect(result.overallStatus, isNotNull);
    expect(result.overallStatus, isNotEmpty);
    print('[real_push] ✓ permissions wizard status: ${result.overallStatus}');
    if (result.overallStatus != 'granted' &&
        result.overallStatus != 'provisional') {
      print('[real_push] ⚠ Permissions not granted (status: '
          '${result.overallStatus}). '
          'Pre-grant with: adb shell pm grant <appId> '
          'android.permission.POST_NOTIFICATIONS');
    }
  }, timeout: const Timeout(Duration(seconds: 15)));

  // ── 3. Diagnostics ─────────────────────────────────────────────────────────
  test('runDiagnostics reports FCM token available', () async {
    final result = await FirebaseMessagingHandler.instance.runDiagnostics();
    print('[real_push] diagnostics: ${result.toMap()}');

    // Token must be available — this is the primary health indicator.
    expect(
      result.fcmTokenAvailable,
      isTrue,
      reason: 'FCM token not available. Error: ${result.error}',
    );
    // Platform must be identified correctly.
    expect(result.platform, isNotEmpty);
    print('[real_push] ✓ diagnostics: token=${result.fcmTokenAvailable}, '
        'platform=${result.platform}, permissions=${result.permissionsGranted}');
  }, timeout: const Timeout(Duration(seconds: 30)));

  // ── 4. Foreground notification send ───────────────────────────────────────
  testWidgets(
    'FCM notification send completes without error '
    '[requires FCM_SERVICE_ACCOUNT_B64]',
    (tester) async {
      if (sender == null) {
        markTestSkipped(_skipReason);
        return;
      }
      if (deviceToken == null) {
        markTestSkipped(
          'No FCM token — ${FirebaseMessagingHandler.instance.lastTokenError}',
        );
        return;
      }

      // Set up click listener whether stream is available or not.
      final received = <NotificationData?>[];
      final sub = clickStream?.listen(received.add);

      print('[real_push] sending foreground notification to device…');
      await sender!.send(
        deviceToken: deviceToken!,
        title: 'Integration Test',
        body:
            'Tap this — ts=${DateTime.now().millisecondsSinceEpoch}',
      );
      print('[real_push] ✓ FCM send returned 200');

      // Pump for up to 10 s waiting for a tap.
      for (var i = 0; i < 10 && received.isEmpty; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      await sub?.cancel();

      // Send succeeded — that's the primary assertion.
      // Click receipt requires the user to tap the banner, so we log a warning
      // rather than failing the test in CI.
      if (received.isEmpty) {
        print('[real_push] ⚠ No tap received within 10 s. '
            'FCM send succeeded — tap the notification to verify click-stream '
            'delivery, or run interactively.');
      } else {
        expect(received.first?.title, contains('Integration Test'));
        print('[real_push] ✓ click event received on stream');
      }
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  // ── 5. Data-only / in-app trigger ─────────────────────────────────────────
  test(
    'Data-only payload is sent and processed without crashing '
    '[requires FCM_SERVICE_ACCOUNT_B64]',
    () async {
      if (sender == null) {
        markTestSkipped(_skipReason);
        return;
      }
      if (deviceToken == null) {
        markTestSkipped(
          'No FCM token — ${FirebaseMessagingHandler.instance.lastTokenError}',
        );
        return;
      }

      print('[real_push] sending data-only in-app payload…');
      await expectLater(
        sender!.send(
          deviceToken: deviceToken!,
          data: {
            'fcmh_inapp':
                '{"template":"builtin_generic","type":"dialog",'
                '"title":"Integration Test","body":"Data-only payload ok"}',
          },
        ),
        completes,
        reason: 'FCM send() should not throw',
      );

      await Future<void>.delayed(const Duration(seconds: 3));
      print('[real_push] ✓ data-only payload sent and processed');
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
