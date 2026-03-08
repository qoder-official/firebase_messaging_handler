# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.3] - 2026-03-08

### Added
- **Swift Package Manager (SPM) support** — `ios/Package.swift` added; iOS plugin now resolves via SPM in addition to CocoaPods

### Changed
- **WASM compatibility** — replaced `universal_html` dependency with `dart:js_interop`-based abstraction; package now passes WASM analysis
- iOS native stub simplified — removed unused `FirebaseCore`/`FirebaseMessaging` imports (FCM is handled entirely by `firebase_messaging`)

---

## [1.0.2] - 2026-03-08

### Changed
- `flutter_local_notifications` lower bound tightened to `^21.0.0` — aligns constraint with the v21 named parameter API the package actually requires

---

## [1.0.1] - 2026-03-08

### Changed
- `flutter_local_notifications` constraint widened to `>=18.0.1 <22.0.0` — now fully compatible with v21 (named parameter API)

### Fixed
- Updated all `flutter_local_notifications` call sites to v21 named parameter API (`show`, `initialize`, `zonedSchedule`, `periodicallyShow`, `cancel`)
- Removed deprecated `uiLocalNotificationDateInterpretation` parameter from `zonedSchedule` calls
- Removed broken CI and codecov badges from README

---

## [1.0.0] - 2026-03-08

### Added
- **Android & macOS platform support** — both platforms now fully declared
- **`lastTokenError`** on `FirebaseMessagingHandler.instance` — surfaces the exact reason an FCM token could not be retrieved (e.g. APNs not configured, simulator)

### Changed
- **`flutter_local_notifications` constraint** widened to `>=18.0.1 <22.0.0` — compatible with v19, v20, and v21
- **FCM token failures now return `null`** instead of silent mock tokens — check `lastTokenError` for the reason

---

## [0.1.1-beta.1]

### Added
- **Modular architecture** — complete rewrite into `core/managers`, `core/services`, `core/interfaces`, `core/utils` layers; clean separation of concerns
- **Unified handler API** — single `Future<bool> Function(NormalizedMessage, NotificationLifecycle)` callback that works across foreground, background, and terminated states without manual `@pragma` wiring
- **`NormalizedMessage` model** — consistent `title`, `body`, `imageUrl`, `data`, `actions`, `receivedAt`, `origin`, `channelId`, `raw` across all lifecycles
- **`NotificationLifecycle` enum** — `foreground`, `background`, `terminated`, `resume`, `initial`
- **Auto initial-notification emission** — terminated-launch notifications automatically queued and emitted onto the unified click stream; opt-out available
- **In-app messaging engine** — silent FCM push (`fcmh_inapp` key) triggers in-app templates registered via `registerInAppNotificationTemplates`
- **`builtin_generic` renderer** — seven layout variants driven by `layout:` key: `dialog`, `banner` (top/bottom), `bottom_sheet`, `snackbar`, `tooltip`, `carousel`, `html_modal`
- **Frequency caps and quiet hours** — lifecycle-aware presentation throttling; configurable quiet windows
- **Notification inbox** — `NotificationInboxView` widget with swipe-to-delete, mark-as-read, pagination; `NotificationInboxStorageInterface` for swappable persistence (SharedPrefs default + in-memory test impl)
- **`BridgingPayloadValidator`** — validates data-only payloads before bridging; rejects missing `title`/`body`, type errors, script injection; increments `diagnostics.invalidPayloadCount`
- **Data-only bridging** — configurable key mapping to promote silent payloads to local notifications; web suppression with once-per-session log
- **`BadgeManager`** — unified badge abstraction over `flutter_local_notifications` (iOS) and notification channels (Android); local persistence
- **`PermissionWizardService`** — `requestAllPermissions()` with rich `PermissionWizardResult` covering Android (POST_NOTIFICATIONS) and iOS (alert/badge/sound/provisional)
- **`runDiagnostics()`** on `FirebaseMessagingHandler.instance` — returns `NotificationDiagnosticsResult` with permission status, token availability, badge support, background handler registration state, pending count, web permission, invalid payload count
- **`bin/setup.dart` doctor script** — checks `google-services.json`, `GoogleService-Info.plist`, AndroidManifest permissions; auto-patches `INTERNET` and `POST_NOTIFICATIONS`
- **Smart default channel** — auto-creates a high-importance channel at init if none exist, preventing silent foreground notifications on Android
- **Background dispatcher helper** — `@pragma('vm:entry-point')`-safe entry point; hydrates storage and queues before user handler runs
- **`FmhAnalyticsService`** — pluggable analytics callback tracking received, click, action, schedule, and token events
- **`InAppOverlayHost` / `InAppOverlayController`** — managed overlay stack for presenting in-app templates above all other widgets
- **`BuiltInInAppTemplates.versionPrompt`** — pre-built app update prompt template
- **`NotificationInboxView`** — full inbox widget with theming knobs, avatar/image support, swipe gestures, empty state, and action chips
- **Pending click queue** — click events delivered to late stream subscribers (background/terminated taps before `listen` call)
- **Web platform registration** — `FirebaseMessagingHandlerWeb` Dart plugin class via `flutter_web_plugins`
- **Platform utilities** — conditional `platform_utils.dart` with IO and web stubs; `js_compat.dart` for web JS interop
- **New tests** — click-stream queue delivery, `BridgingPayloadValidator` accept/reject matrix, `InboxStorageService` upsert/paging/markRead/delete, golden harness (alchemist)
- **`flutter_widget_from_html_core`** dependency for `html_modal` template layout
- **`timezone`** dependency for accurate scheduled notification delivery

### Changed
- Public API facade (`FirebaseMessagingHandler`) fully preserved; all new APIs are additive
- Example app rebuilt as **FCM Showcase** — scenario inspector, activity timeline, inbox screen, template trigger demos, APNs setup guidance, diagnostics sheet, token copy overlay
- README restructured with feature-by-feature walkthrough, quick-start, and payload cookbook

### Fixed
- Foreground click stream on Android — events were silently dropped when the stream had no listener at the time of tap
- iOS duplicate foreground notifications — the package now prevents showing a local notification when Firebase already delivered it in the foreground
- iOS initial message detection — added 100 ms retry for iOS timing edge case on cold start
- `app_badger` / `flutter_app_badger` namespace conflicts — removed; badge management now handled via `flutter_local_notifications` and platform channel fallback

---

## [0.1.0]

### Added
- `subscribeToTopic(String topic)` — subscribe to an FCM topic
- `unsubscribeFromTopic(String topic)` — unsubscribe from a topic
- `unsubscribeFromAllTopics()` — bulk topic unsubscription
- `NotificationStreamExtensions` — stream utility extensions
- Terminated-state notification fix — initial message now correctly retrieved on cold start via `getInitialMessage()`

### Changed
- Removed native Android and iOS plugin stubs — package now relies entirely on `firebase_messaging` and `flutter_local_notifications` for native work (pure-Dart approach)
- `firebase_messaging` minimum constraint raised to `>=15.1.4`
- Dropped Linux, macOS, Windows example targets — focused on Android and iOS

### Fixed
- Click stream not delivering terminated-state notification on first launch
- Example app not handling notification tap navigation correctly

---

## [0.0.8]

### Fixed
- Dependency version constraints causing resolution failures with newer `firebase_messaging` and `flutter_local_notifications` releases

---

## [0.0.7]

### Changed
- Loosened all dependency version constraints to improve compatibility

### Fixed
- Stream controller changed to `broadcast()` — previously only one listener was supported; multiple listeners now work correctly

---

## [0.0.6]

### Changed
- Example app updated to demonstrate stream restart and handler re-initialization

---

## [0.0.5]

### Added
- Stream disposal — `dispose()` now properly closes the notification stream controller and cancels all subscriptions

---

## [0.0.4]

### Changed
- README improvements with setup instructions and usage examples

---

## [0.0.3]

### Added
- "Clear token" button in example app for testing token refresh flows

### Fixed
- Minor static analysis issues — removed unused imports, tightened linting

---

## [0.0.2]

### Added
- MIT license file
- Flutter SDK constraint added (`>=2.12.0`)
- Broader dependency compatibility — lowered minimum SDK requirements

### Changed
- README expanded with installation and basic usage guide
- `NotificationChannelData` model fields clarified

---

## [0.0.1]

### Added
- Initial release
- `FirebaseMessagingHandler` singleton with `init()` — sets up FCM, requests permissions, creates Android notification channels, returns a click stream
- `NotificationData` model — wraps incoming FCM payloads with `title`, `body`, `payload`, `type`
- `NotificationChannelData` — configurable Android notification channel (importance, priority, sound, vibration, lights)
- `NotificationImportanceEnum`, `NotificationPriorityEnum`, `NotificationTypeEnum` — type-safe enums
- `AndroidNotificationChannelExtensions` — converts `NotificationChannelData` to `flutter_local_notifications` channel objects
- `FirebaseMessagingHandlerSharedPreferences` — local storage for FCM token caching
- Foreground and background notification handling via `firebase_messaging`
- Local notification display via `flutter_local_notifications`
- Example app demonstrating basic setup and notification receipt
