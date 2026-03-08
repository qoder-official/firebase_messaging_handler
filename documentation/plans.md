# Master Plan — #1 Notification Package on pub.dev

_Last updated: 2026-03-08 (v1.0.1 live on pub.dev)_

---

## Why We're Building This

Most Flutter developers using Firebase Cloud Messaging end up writing the same 500 lines of boilerplate in every project: lifecycle routing, click stream setup, background isolate wiring, permission requests, badge management. Then they discover it's brittle — terminated-state notifications get dropped, APNs errors are opaque, web push silently fails.

Commercial alternatives (OneSignal, Braze, Airship) solve this but require vendor lock-in, monthly fees, and a dashboard you don't control. `awesome_notifications` solves part of it but doesn't touch FCM. `flutter_local_notifications` is excellent but is a low-level primitive.

**The gap:** a production-ready, open-source, FCM-native Flutter package that handles the full notification lifecycle — foreground, background, terminated — with in-app messaging, inbox, scheduling, badges, diagnostics, and real cross-platform support, zero SaaS lock-in, zero backend dependency.

**The pitch:** "Everything firebase_messaging should have been, nothing you don't need, zero SaaS lock-in."

---

## Competitive Position

| vs. | Their weakness | Our answer |
|-----|----------------|------------|
| `awesome_notifications` 0.10.1 | No FCM, complex setup, no web | FCM-native, doctor auto-setup, web support |
| `onesignal_flutter` 5.3.4 | SaaS lock-in, dashboard required | Zero backend dependency, BSD-3, FCM-native |
| `flutter_local_notifications` 21.0.0 | No FCM, no in-app, no inbox | Full FCM + in-app kit + inbox on top of their scheduling |
| `braze_plugin` 16.0.0 | Enterprise SaaS, expensive | Free, BSD-3, same UX patterns |
| `firebase_messaging` (raw) | No in-app, no inbox, no scheduling | We are the production-ready layer on top |
| `airship_flutter` 10.10.1 | SaaS lock-in | Open source, self-hosted compatible |

---

## What's Shipped (Sprint 0–4 Complete)

All initial sprints are done. See `status.md` for the full breakdown.

**Core engine:** unified click stream, token retry with diagnostics, background dispatcher, in-app pipeline, inbox, scheduling, badges, diagnostics, permission wizard.

**Platform support:** Android, iOS, macOS, Web (declared + implemented), Linux + Windows (local mode).

**Infrastructure:** Setup doctor, CONTRIBUTING, SECURITY, issue templates. GitHub Actions removed — deployment is manual via `dart pub publish`.

**Testing:** unit tests, synthetic integration tests, real-FCM integration harness with CI-safe self-skip.

**Documentation:** `doc/` with 14 pages across getting-started and features; README with quick start + feature matrix; internal strategy docs.

---

## Pub.dev Score (Projected at 1.0.0)

| Category | Score |
|----------|-------|
| Dart conventions | 30/30 |
| Documentation | 30/30 |
| Platform support | 20/20 |
| Static analysis | 50/50 |
| Dependencies | 40/40 |
| **Total** | **160/160** |

---

## Sprint 5 — Publish & Stabilise ✅ COMPLETE

- `1.0.0` and `1.0.1` live on pub.dev
- Git history squashed to single root commit (leaked API key removed)
- `dev` and `develop` branches deleted — `main` only
- GitHub Actions removed — manual `dart pub publish` workflow
- Homepage updated to `https://qoder.in/resources/firebase-messaging-handler`
- pub.dev score: **160/160**

---

## Sprint 6 — Discoverability & Community (NEXT)

**Goal**: build organic discovery and trust signals.

### 6A. pub.dev listing polish
- Add `screenshots:` entries to pubspec.yaml (pub.dev renders them in listing)
  - GIF 1: in-app dialog appearing from a silent push
  - GIF 2: notification inbox with swipe-to-delete
  - GIF 3: token diagnostic error card
  - Screenshot 4: diagnostics sheet
- Punch up the pubspec `description` for keyword density

### 6B. Community presence
- [ ] "Why we built this" post on Medium / Dev.to / Hashnode
- [ ] Post in r/FlutterDev with showcase GIF
- [ ] Flutter Discord `#packages` channel
- [ ] Register on [Flutter Gems](https://fluttergems.dev)
- [ ] Submit to [FlutterAwesome](https://flutterawesome.com)
- [ ] Twitter/X announcement thread

### 6C. Physical validation blog post
Document the end-to-end FCM setup process (Android + iOS + web) with screenshots — this becomes SEO content and the most useful guide in the Flutter ecosystem for this problem space.

---

## Sprint 7 — Feature Completeness (4–8 weeks)

**Goal**: more features than any competitor, still open source.

### 7A. Web — Make It Actually Work
Currently declared but unvalidated in real browsers.
- Test: Chrome, Safari, Firefox — real FCM tokens and notification receipt
- Pre-permission explainer overlay (custom UI before OS prompt)
- Service worker validator: check registration, scope, icon presence
- Evaluate dropping `universal_html` if scope allows (currently heavy)
- **Target**: be the only Flutter package with documented, tested web FCM support

### 7B. macOS Support — First OSS Package With Real macOS Push
`firebase_messaging` supports macOS. We declared it. Now validate it.
- Token retrieval on macOS
- Foreground/background delivery on macOS
- macOS example app target
- Entitlements + capabilities documentation
- **Win**: only OSS Flutter package with working macOS push notifications

### 7C. Rich Android Notification Styles
The biggest gap vs `awesome_notifications`:
- Big Picture style (image in expanded notification)
- Inbox style (list of messages in one notification)
- Progress bar (file download, upload tracking)
- Media style (album art, playback controls in notification)
- Expose via `AndroidNotificationStyle` enum on `showNotificationWithActions`

### 7D. Server Recipes — Complete the DX Story
Backend developers need payload examples. The `server_recipes/` directory is started.
Complete:
```
server_recipes/
├── README.md                       # Payload schema reference
├── cloud_functions/
│   ├── send_basic.js
│   ├── send_data_only.js           # Trigger in-app template
│   ├── send_with_actions.js        # Interactive buttons
│   ├── send_rich_media.js          # Image + big picture
│   └── scheduled_campaign.js      # Topic-based scheduled push
└── rest_api/
    ├── curl_examples.sh            # FCM v1 REST API
    └── postman_collection.json     # Importable collection
```

### 7E. In-App Template Expansion
Currently: dialog, banner, bottom_sheet, snackbar, tooltip, carousel, html_modal.
Add:
- **Survey/NPS**: multi-step rating flow with configurable questions
- **App Update Prompt**: "New Version Available" with store link CTA
- **Celebration/Confetti**: reward notification with visual animation
- **Custom Animation Presets**: slide_down, fade_in, bounce for all templates

### 7F. Remote Notification Cancel
Allow backend to cancel local notifications via data-only payload:
- Payload schema: `{ "fcmh_action": "cancel", "id": "...", "group": "...", "channel": "..." }`
- Handled in background dispatcher before user callback
- Surface count in diagnostics

---

## Sprint 8 — Desktop & Advanced Platform Reach (8–16 weeks)

### 8A. Windows & Linux — Full Local Mode
`firebase_messaging` doesn't support Windows/Linux — correct. But we can make local features fully first-class:
- Scheduling: fully supported by `flutter_local_notifications`
- Quiet hours, frequency caps, inbox: pure Dart
- In-app templates: pure Flutter
- REST API helper: let apps receive from their own backend via polling/WebSocket
- Full documentation and example app targets for Windows/Linux

### 8B. User Tagging & Segmentation Hooks
- `setUserAttribute(key, value)` / `removeUserAttribute(key)` — local state only
- `onAttributeChanged` callback — host app pushes to their backend
- Used for targeting: `{ "plan": "premium", "locale": "en-US" }`
- No backend dependency — client-side state + sync callback pattern

### 8C. Scheduling Test Coverage
- Fake clock integration tests for one-time and recurring notifications
- Quiet hours edge cases (boundary conditions, DST)
- Regression protection for all scheduling features

---

## Sprint 9 — Documentation Excellence (Ongoing)

### 9A. GitHub Pages / Documentation Site
- Jekyll or Docusaurus site from `doc/` directory
- Search, versioning, dark mode
- API reference auto-generated from dartdoc

### 9B. README Restructure
Current README is 1800+ lines. Restructure:
- Above the fold (≤100 lines): one-liner pitch + feature table + install
- Quick start: 15 lines of code
- "Why this package?" comparison table
- Links to docs site for everything else
- GIFs/screenshots inline (pub.dev renders them)

### 9C. 100% API Doc Coverage
Current: ~65% coverage.
Target: every public class, method, property, and enum has a `///` doc comment.
Use `dart doc --validate-links` in CI.

---

## Success Metrics

| Metric | Now | 1 month | 3 months | 6 months |
|--------|-----|---------|----------|----------|
| pub.dev score | 120/160 | 160/160 | 160/160 | 160/160 |
| Platforms declared | 6/6 | 6/6 | 6/6 | 6/6 |
| Likes | 22 | 100 | 500 | 1,500 |
| Weekly downloads | ~30 | 200 | 1,000 | 5,000 |
| GitHub stars | ~10 | 100 | 500 | 1,500 |
| Test coverage | ~45% | 60% | 75% | 90% |
| Static analysis issues | 0 | 0 | 0 | 0 |

---

## The Win Formula

```
#1 on pub.dev = 160/160 pub score               ← achieved at 1.0.0
              + Regular releases (monthly)
              + 6/6 platform support             ← done
              + More features than everyone      ← Sprint 7
              + Best docs in the space           ← Sprint 9
              + Community presence               ← Sprint 6
              + Zero breaking changes            ← semver discipline always
```
