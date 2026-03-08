# Integration Tests

This directory contains two categories of integration tests:

| File | Type | Firebase required? |
|------|------|--------------------|
| `handlers_integration_test.dart` | Synthetic (no real FCM) | No |
| `real_push/real_push_test.dart` | Real FCM end-to-end | Yes |

---

## Synthetic tests (`handlers_integration_test.dart`)

No credentials or physical device required. Uses `RemoteMessage` objects to
exercise the handler pipeline without touching Firebase infrastructure.

```bash
flutter test integration_test/handlers_integration_test.dart
```

---

## Real-FCM tests (`real_push/real_push_test.dart`)

Sends actual FCM payloads to a connected device and asserts receipt in-process.
All five tests **self-skip** when the service account file is absent (CI-safe).

### Prerequisites

1. **Service account key** — place at `test/firebase_config/service_account.json`
   Generate: Firebase Console → Project Settings → Service Accounts → Generate new private key

2. **Sender ID** — your Firebase project number (not project name)
   Find: Firebase Console → Project Settings → General → "Project number"

3. **Physical device** — plugged in and unlocked

4. **App in foreground** during test 3 (foreground notification receipt)

### Run (from `example/` directory)

```bash
# 1. Base64-encode the service account (from package root)
BASE64=$(base64 -i test/firebase_config/service_account.json | tr -d '\n')

# 2. Run from example/
cd example
flutter test integration_test/real_push_test.dart \
  --dart-define=FCM_TEST_SENDER_ID=<your-project-number> \
  --dart-define=FCM_SERVICE_ACCOUNT_B64=$BASE64 \
  --device-id <device-id>
```

> **Note:** Tests must run from the `example/` directory — the package root has
> no Android/iOS app to deploy to device. The test APK authenticates with Google
> OAuth2 and POSTs FCM messages to itself via `fcm.googleapis.com`.

### Test scenarios

| # | Test | What it verifies |
|---|------|------------------|
| 1 | Token retrieval | `getFcmToken()` returns a non-null, non-empty string |
| 2 | Permissions | `requestPermissionsWizard()` returns `granted` or `provisional` |
| 3 | Foreground notification | Message sent → click emitted on the stream returned by `init()` |
| 4 | Data-only payload | Silent push with `fcmh_inapp` key processes without crashing |
| 5 | Diagnostics | `runDiagnostics()` reports `fcmTokenAvailable` and `permissionsGranted` |

### Limitations

| Scenario | Status | Notes |
|----------|--------|-------|
| Foreground receipt | ✅ Tested | App must be in foreground; user taps notification |
| Data-only (silent push) | ✅ Tested | In-process handler; no UI interaction needed |
| Token retrieval | ✅ Tested | Direct SDK call |
| Permissions | ✅ Tested | Direct SDK call |
| Background handler (app backgrounded) | ⚠️ Partial | Handler registration is tested; app cannot be backgrounded from inside the test runner |
| Terminated state (cold start) | ❌ Manual only | See `test/firebase_config/terminated_state_manual.sh` |
| Windows/Linux desktop local mode | ❌ Manual only | Validate with the example app and Notification Doctor on actual desktop runners |

### Terminated-state manual test

For cold-start scenarios, use the manual shell helper:

```bash
bash test/firebase_config/terminated_state_manual.sh \
  --token <fcm-token> \
  --project <firebase-project-id> \
  --key-file test/firebase_config/service_account.json
```

---

## CI integration

There is no automated CI pipeline. All tests are run manually.

When `test/firebase_config/service_account.json` is absent, all real-FCM
tests emit `SKIP` rather than `FAIL` — so running the full test suite locally
without credentials is always safe.
