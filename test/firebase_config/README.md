# Firebase Test Config

Place your Firebase service account JSON here as:

    test/firebase_config/service_account.json

Generate it at:
  Firebase Console → Project Settings → Service Accounts → Generate new private key

This directory is gitignored. Never commit credentials.

## Additional setup

The integration tests also need your Firebase project's **Sender ID** (the numeric
project number, not the project name). Pass it at run-time via `--dart-define`:

```bash
flutter test integration_test/real_push/real_push_test.dart \
  --dart-define=FCM_TEST_SENDER_ID=123456789012 \
  --device-id <device-id>
```

Find your Sender ID at:
  Firebase Console → Project Settings → General → "Project number"

## Files in this directory

| File | Purpose | Committed? |
|------|---------|------------|
| `service_account.json` | Service account key for FCM HTTP v1 API | **NO** — gitignored |
| `README.md` | This file | Yes |
| `terminated_state_manual.sh` | Manual cold-start test helper | Yes |

## Security reminder

- Never commit `service_account.json` or any file containing private keys
- Rotate your service account key immediately if accidentally pushed
- Use short-lived keys for CI; prefer Workload Identity Federation in production
