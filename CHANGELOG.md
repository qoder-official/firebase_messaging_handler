## 1.0.0-beta.1
- Beta preview of the FCM superpack:
  - Auto initial-notification emission onto the unified click stream (opt-out available).
  - Unified handler (FG/BG/terminated) with normalized payloads.
  - Inbox storage + inbox widget (theming, swipe-to-delete, paging) wired in example.
  - Data-only bridge, payload validator, and diagnostics improvements.
  - Expanded README onboarding and pubspec topics for discoverability.
  - New tests (validator, inbox storage, click queue, goldens) and alchemist harness.

## 0.1.0
- Initial release on pub.dev.
## Unreleased

- Added `InAppOverlayHost`/`InAppOverlayController` for plugin-managed overlays.
- Introduced built-in `BuiltInInAppTemplates.versionPrompt` dialog template.
- Example app now registers built-in templates and demonstrates manual triggering.
- Added helper `InAppMessageManager.triggerInAppNotification` for local testing.

## 1.0.0 - Production Ready Release

### 🎭 **Engagement Layer (Phase 3) – Foundations Delivered**
- Silent push ingestion pipeline with template registry
- Foreground notification customization hooks
- Showcase example app with scenario inspector & activity timeline
- Advanced feature cards + instructions in example app

### 🔜 **Upcoming Work (Post-1.0 Roadmap)**
- Prebuilt in-app template kit (version prompts, promos, surveys)
- Lifecycle-aware throttling, quiet hours & campaign caps
- Background silent-message listener guidance
- Payload cookbook and server-side recipes
- Notification “doctor” diagnostics panel & setup tooling

#### **In-App Notification Templates**
- Silent push ingestion pipeline
- Template registry & stream API
- Foreground notification customization hooks
- Prebuilt UI template kit (banners, modals, tooltips)
- Lifecycle-aware presentation helpers
- Campaign frequency caps & quiet hours

#### **Example App Enhancements**
- Rebuilt as "FCM Showcase" with guided testing
- Scenario inspector and comprehensive showcase
- README restructure for feature-by-feature walkthrough

### ⚡ **Phase 2: Advanced Features** (COMPLETED)

#### **Interactive Notifications**
- Notification actions with custom buttons
- Action payload handling
- Cross-platform action support

#### **Scheduling & Management**
- Time-based notification scheduling
- Recurring notification support
- Calendar-based notifications

#### **Badge & Grouping**
- Cross-platform badge management
- Android notification groups
- iOS conversation threads

#### **Sound & Analytics**
- Custom notification sounds
- Built-in analytics integration
- Performance optimizations

### 🔧 **Phase 1: Core Improvements** (COMPLETED)

#### **Platform Support**
- Enhanced iOS support with APNs integration
- Web platform support with browser notifications
- Rich notification data model

#### **Core Functionality**
- Fixed initial notification handling
- Comprehensive documentation
- Zero breaking changes

## 0.1.0

* TODO: Terminated state fixes and added subscription methods for topics
