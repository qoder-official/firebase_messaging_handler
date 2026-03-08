# Project Status — Honest Reality Check

_Last updated: 2026-03-08 (post v1.0.1 publish)_

---

## Package Version

| Location | Version |
|----------|---------|
| `pubspec.yaml` | `1.0.1` |
| `ios/firebase_messaging_handler.podspec` | `1.0.0` |
| `CHANGELOG.md` | v1.0.1 entry present |
| pub.dev (latest stable) | **`1.0.1`** ✅ live |
| pub.dev (previous) | `1.0.0` — superseded |
| pub.dev (beta) | `0.1.1-beta.1` — superseded |

---

## What's Shipped

### Sprint 0 — Ship 1.0.0 ✅
- Static analysis: `dart analyze lib/` → **0 issues**
- Android native stub registered (`FirebaseMessagingHandlerPlugin.kt`)
- macOS Dart stub registered (`firebase_messaging_handler_macos.dart`)
- Linux + Windows Dart stubs registered
- `flutter_local_notifications` constraint widened to `<22.0.0`
- Mock FCM tokens removed — `lastTokenError` surfaces exact diagnostic
- All 6 platforms declared in `flutter.plugin.platforms`

### Sprint 1 — Repository Hygiene ✅
- `CONTRIBUTING.md`, `SECURITY.md`, `.github/ISSUE_TEMPLATE/`
- `bin/setup.dart` — setup doctor
- `server_recipes/` — Cloud Functions + REST API payload examples
- `doc/` public documentation (Dart pub convention)

### Sprint 2 — Core Feature Completeness ✅
- Unified handler: `setUnifiedMessageHandler(Future<bool> Function(NormalizedMessage, NotificationLifecycle))`
- `NormalizedMessage` model, `NotificationLifecycle` enum
- In-app messaging pipeline — 7 layout variants
- `InAppDeliveryPolicy` — quiet hours, frequency caps
- `NotificationInboxView` widget + `NotificationInboxStorageInterface`
- `runDiagnostics()` → `NotificationDiagnosticsResult`
- `requestPermissionsWizard()` → `PermissionWizardResult`
- `BridgingPayloadValidator`, data-only bridge
- Windows/Linux desktop local-mode fallback

### Sprint 3 — Documentation Excellence ✅
- `doc/` — 14 pages across getting-started and features (all 6 platforms)
- Public API doc comments expanded
- Internal `documentation/` strategy docs

### Sprint 4 — Integration Test Harness ✅
- `integration_test/handlers_integration_test.dart` — synthetic FG/BG/terminated
- `integration_test/real_push/real_push_test.dart` — real FCM, 5 scenarios, CI-safe self-skip
- `test/helpers/fcm_test_sender.dart` — OAuth2 + FCM HTTP v1 sender
- `test/firebase_config/terminated_state_manual.sh` — cold-start manual script

### Sprint 5 — Publish & Stabilise ✅
- `1.0.0` published to pub.dev manually via `dart pub publish`
- `1.0.1` patch published — removed broken CI/codecov badges from README
- `homepage` updated to `https://qoder.in/resources/firebase-messaging-handler`
- pub.dev topics trimmed to 5 (platform limit)
- CHANGELOG shortened to user-facing changes only
- Git history squashed to single root commit — leaked API key removed from history
- `dev` and `develop` branches deleted — only `main` remains
- GitHub Actions workflows removed — deployment is manual via `dart pub publish`

### Code Quality ✅
- `@visibleForTesting` on all test-mode methods in facade
- `dart analyze lib/ test/ integration_test/` → **0 issues**

---

## What Is Still Missing or Incomplete

### High Priority
| Gap | Impact | Effort |
|-----|--------|--------|
| Web validation in real browsers | Silent failures for web users | 2–3 hours |
| Android physical device badge validation | `setAndroidBadgeCount` end-to-end unknown | 1 hour |
| macOS physical device validation | Declared, not validated | 1–2 hours |
| Scheduling tests (fake clock) | No regression protection | 1 hour |

### Medium Priority
| Gap | Impact | Effort |
|-----|--------|--------|
| Quiet hours integration test | Throttle logic untested | 1 hour |
| Survey/NPS in-app template | Engagement feature incomplete | Medium |
| `UserAttributesManager` | Targeting hook for backend | Medium |
| Community launch (blog, social, Flutter Gems) | Discovery | Low effort, high impact |
| pub.dev screenshots/GIFs | Discovery polish | Low |

---

## Test Coverage Reality

| Layer | Status | Notes |
|-------|--------|-------|
| Unit — BridgingPayloadValidator | ✅ | Accept/reject matrix |
| Unit — InboxStorageService | ✅ | CRUD + pagination |
| Unit — click-stream queue | ✅ | Late subscriber delivery |
| Widget/Golden — inbox | ✅ | Alchemist harness |
| Integration — FG click stream | ✅ | Synthetic |
| Integration — BG/terminated | ✅ | Synthetic |
| Integration — real FCM (5 scenarios) | ✅ | Physical device, self-skips without credentials |
| Integration — data-only bridge | ⚠️ | Partial |
| Integration — scheduling fake clock | ❌ | Missing |
| Integration — quiet hours | ❌ | Missing |

---

## Pub.dev Score

| Category | Score |
|----------|-------|
| Dart conventions | 30/30 |
| Documentation | 30/30 |
| Platform support | 20/20 |
| Static analysis | 50/50 |
| Dependencies | 40/40 |
| **Total** | **160/160** |

---

## Release Process

Deployment is fully manual. No GitHub Actions.

```bash
# 1. Bump version in pubspec.yaml + update CHANGELOG.md
# 2. Commit and push to main
# 3. Publish
dart pub publish --dry-run   # verify 0 warnings
dart pub publish             # release
```
