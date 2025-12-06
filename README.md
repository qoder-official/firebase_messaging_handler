# Firebase Messaging Handler Plugin

> **🎯 One-Stop Push & In-App Messaging for Firebase Cloud Messaging** – Handle everything from reliable click streams to scheduling, actions, quiet hours, and rich in-app templates. Zero breaking changes, maximum flexibility!

[![pub package](https://img.shields.io/pub/v/firebase_messaging_handler.svg)](https://pub.dev/packages/firebase_messaging_handler)
[![beta](https://img.shields.io/badge/beta-1.0.0--beta.1-orange)](https://pub.dev/packages/firebase_messaging_handler/versions/1.0.0-beta.1)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 📋 **Table of Contents**

- [🚀 Quick Start](#-quick-start)
- [✨ Key Features](#-key-features)
- [🧰 What You Get](#-what-you-get)
- [📦 Installation](#-installation)
- [🔧 Setup](#-setup)
- [📖 Usage Examples](#-usage-examples)
- [🎛️ Advanced Features](#️-advanced-features)
- [🪄 In-App Messaging](#-in-app-messaging)
- [🛡️ Foreground Notification Customization](#-foreground-notification-customization)
- [📊 Analytics Integration](#-analytics-integration)
- [🩺 Notification Diagnostics](#-notification-diagnostics)
- [🌙 Quiet Hours & Throttling](#-quiet-hours--throttling)
- [🔄 Data-Only Bridging](#-data-only-bridging)
- [🧪 Testing Utilities](#-testing-utilities)
- [📦 Payload Cookbook](#-payload-cookbook)
- [📚 API Reference](#-api-reference)
- [🔧 Configuration](#-configuration)
- [🐛 Troubleshooting](#-troubleshooting)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)
- [🆘 Support](#-support)
- [🎉 What's Next?](#-whats-next)

## 🚀 **Quick Start**

```dart
import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';

// Initialize the plugin
final Stream<NotificationData?>? clickStream = await FirebaseMessagingHandler.instance.init(
  senderId: 'your_sender_id',
  androidChannelList: [
    NotificationChannelData(
      id: 'default_channel',
      name: 'Default Notifications',
      description: 'Default notification channel',
      importance: NotificationImportanceEnum.high,
      priority: NotificationPriorityEnum.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    ),
  ],
  androidNotificationIconPath: '@drawable/ic_notification',
  updateTokenCallback: (fcmToken) async {
    // Send token to your backend
    print('FCM Token: $fcmToken');
    return true;
  },
);

// Listen to notification clicks
clickStream?.listen((NotificationData? data) {
  if (data != null) {
    print('Notification clicked: ${data.title}');
    // Handle notification click
  }
});
```

## ✨ **Key Features**

### **🎯 Core Features**
- **📱 Cross-Platform Support** - Android, iOS, and Web
- **🔄 Unified Notification Stream** - Handle all notification types in one place
- **🎛️ Flexible Initial Notification Control** - Stream or separate handling
- **🔑 Smart Token Management** - Automatic optimization with single backend call
- **🛡️ Robust Error Handling** - Comprehensive error recovery and logging

### **🎨 Advanced Features**
- **⚡ Interactive Notification Actions** - Custom buttons with payload handling
- **⏰ Notification Scheduling** - One-time and recurring notifications
- **🔢 Badge Management** - Cross-platform badge count management
- **📦 Notification Grouping** - Android groups and iOS conversation threads
- **🔊 Custom Sound Support** - Platform-specific sound customization
- **📊 Built-in Analytics** - Track all notification events automatically
- **🧪 Testing Utilities** - Mock data and streams for comprehensive testing
- **🩺 Notification Doctor** - Diagnose permissions, tokens, badges, and background wiring in seconds
- **🌐 Web-Safe Fallbacks** - Gracefully degrade scheduling/actions/badges when unsupported in browsers
- **🌙 Quiet Hours & Frequency Caps** - Control delivery cadence with lifecycle-aware helpers
- **🔄 Data-Only Bridging** - Promote silent payloads into local notifications when needed
- **📥 Inbox Storage** - Typed inbox model with SharedPreferences default and
  in-memory test store for read/delete flows
- **🔁 Unified Handler** - Single callback for foreground/background/terminated with normalized payloads
- **🪄 In-App Messaging** - Trigger rich in-app templates from silent FCM payloads
- **🛡️ Foreground Controls** - Fully customize fallback foreground notifications
- **🎭 In-App Templates** - Welcome, promotion, alert, success, and info templates
- **📋 Activity Timeline** - Persistent notification history with detailed timestamps
- **🔄 Smart Retry Logic** - Intelligent Firebase setup retry based on error type
- **🛠️ Professional Setup** - Guided Firebase configuration with package name guidance

## 🧰 **What You Get**

Your app starts simple and scales only when you opt in. Every capability ships with safe defaults and a straightforward toggle.

- **Core (always on)**: unified click stream, terminated-notification getter, token lifecycle management, platform badge helpers.
- **Optional power-ups**: scheduling, recurring rules, grouping, custom sounds, analytics callbacks, in-app templates, foreground overrides, mock/testing utilities.
- **Zero extra deps**: the plugin bundles `firebase_messaging` for you—add one dependency and you are ready for push, scheduling, analytics, and in-app flows.
- **Progressive adoption**: wire up the click stream today, add interactive actions or in-app templates later without touching existing code.
- **Configuration-at-callsite**: all advanced APIs expose per-call parameters so you can tailor a single notification without changing global settings.
- **Navigation flexibility**: Showcase example routes via a root `Navigator` key, demonstrating payload-driven navigation without relying on a BuildContext.

### **Beta channel**
- Install the beta: `firebase_messaging_handler: 1.0.0-beta.1`
- Includes: auto initial-notification stream, unified handler, inbox widget + storage, data-only bridge, payload validator, refreshed docs, and new tests/goldens.
- Stable users can stay pinned to `0.1.0` until ready to adopt the beta line.

### **🏗️ Architecture Benefits**
- **🔧 Modular Design** - Clean separation of concerns
- **🧪 Better Testability** - Interface-based design enables easy mocking
- **📈 Enhanced Scalability** - Easy to extend and maintain
- **🔄 Backward Compatible** - Existing code works unchanged
- **⚡ Better Performance** - Optimized service interactions

## 📦 **Installation**

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  firebase_messaging_handler: ^latest_version
```

## 🔧 **Setup**

### **⚡ Quick Setup (5 Minutes)**

1. **Add dependency:**
   ```yaml
   dependencies:
     firebase_messaging_handler: ^latest_version
   ```

2. **Add basic permissions to `android/app/src/main/AndroidManifest.xml`:**
   ```xml
   <!-- Basic Firebase Messaging -->
   <uses-permission android:name="android.permission.INTERNET" />
   <uses-permission android:name="android.permission.WAKE_LOCK" />
   <uses-permission android:name="android.permission.VIBRATE" />
   <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
   ```
   
   **💡 Need more features?** See the [Detailed Permissions Guide](#android-setup) below.

3. **Initialize in your app:**
   ```dart
   await FirebaseMessagingHandler.instance.init(
     senderId: 'your_sender_id',
     androidChannelList: [/* channels */],
     androidNotificationIconPath: '@drawable/ic_notification',
   );
   ```

4. **(Optional) Wire the background handler:**
   ```dart
   await FirebaseMessagingHandler.instance.configureBackgroundMessageHandler(
     firebaseMessagingHandlerBackgroundDispatcher,
   );
   ```
   > Use your own top-level handler if you need custom logic—just remember to call `FirebaseMessagingHandler.handleBackgroundMessage(message)` first.

### **Unified Handler (all lifecycles)**
```dart
await FirebaseMessagingHandler.instance.setUnifiedMessageHandler(
  (NormalizedMessage message, NotificationLifecycle lifecycle) async {
    debugPrint('[unified] lifecycle=$lifecycle title=${message.title}');
    // Return true to mark handled and skip default rendering; false to let the plugin render/queue.
    if (lifecycle == NotificationLifecycle.foreground) {
      // e.g., custom in-app banner instead of system notification
      return true;
    }
    return false;
  },
);
```
Handler receives normalized fields (id, title, body, data, channelId, analytics, lifecycle, rawMessage). Works for foreground, background, resume, and terminated paths.

5. **Done!** Your app now handles Firebase notifications.

### **🎯 Minimal Setup (Basic Notifications Only)**

**For apps that only need basic push notifications:**

```xml
<!-- Minimal permissions for basic notifications -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
```

**What you get:**
- ✅ Push notifications from Firebase
- ✅ Background message handling
- ✅ Notification vibration
- ❌ No scheduled notifications
- ❌ No foreground notifications
- ❌ No advanced features

### **📋 Detailed Setup**

### **1. Firebase Project Setup**

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add your Android and iOS apps to the project
3. Download configuration files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

### **2. Platform Configuration**

#### **Android Setup**

Add to `android/app/build.gradle`:

```gradle
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

**🔑 Android Permissions Guide**

**Choose only the permissions you need based on your features:**

### **📱 Basic Notifications (Most Apps Need This)**

```xml
<!-- REQUIRED: Basic Firebase Messaging -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />

<!-- REQUIRED: Notification Display -->
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

**When to use:** Basic push notifications, message handling, foreground notifications

### **⏰ Scheduled Notifications (Optional)**

```xml
<!-- REQUIRED: Scheduled Notifications -->
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

**When to use:** Only if you use `scheduleNotification()` or `scheduleRecurringNotification()`

### **🔔 Advanced Features (Optional)**

```xml
<!-- REQUIRED: Background Processing -->
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />

<!-- REQUIRED: Notification Actions -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

**When to use:** Interactive notifications, background processing, notification actions

**📋 Quick Decision Guide:**

| Feature | Permissions Needed |
|---------|-------------------|
| **Basic push notifications** | `INTERNET` + `WAKE_LOCK` + `VIBRATE` + `FOREGROUND_SERVICE` |
| **Scheduled notifications** | Add `SCHEDULE_EXACT_ALARM` + `USE_EXACT_ALARM` + `RECEIVE_BOOT_COMPLETED` |
| **Interactive notifications** | Add `FOREGROUND_SERVICE` (already included in basic) |
| **Background processing** | Add `RECEIVE_BOOT_COMPLETED` |

**💡 Pro Tip:** Start with basic permissions, then add more as you implement features!

**❓ Why These Permissions?**

| Permission | Why We Need It | What Happens Without It |
|------------|----------------|------------------------|
| `INTERNET` | Firebase messaging requires internet connection | ❌ No push notifications |
| `WAKE_LOCK` | Keeps device awake to process background messages | ❌ Messages lost when device sleeps |
| `VIBRATE` | Makes notifications noticeable | ❌ Silent notifications only |
| `FOREGROUND_SERVICE` | Shows notifications when app is active | ❌ No foreground notifications |
| `SCHEDULE_EXACT_ALARM` | Allows precise notification timing | ❌ Scheduled notifications fail |
| `USE_EXACT_ALARM` | Required for exact alarm scheduling | ❌ Scheduled notifications fail |
| `RECEIVE_BOOT_COMPLETED` | Restores scheduled notifications after reboot | ❌ Scheduled notifications lost after reboot |

#### **iOS Setup**

Add to `ios/Runner/AppDelegate.swift`:

```swift
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

**🔑 iOS APNs Setup Required:**

For iOS notifications to work properly, you **MUST** configure APNs:

1. **Generate APNs Key:**
   - Go to [Apple Developer Console](https://developer.apple.com/)
   - Navigate to Certificates, Identifiers & Profiles
   - Go to Keys section
   - Create a new key with "Apple Push Notifications service (APNs)" enabled
   - Download the `.p8` key file

2. **Upload to Firebase:**
   - Go to Firebase Console > Project Settings > Cloud Messaging
   - Scroll to "Apple app configuration"
   - Upload your APNs key (`.p8` file)
   - Enter your Key ID and Team ID
   - Choose environment: Sandbox (development) or Production

3. **Without APNs setup:**
   - iOS notifications will NOT work
   - FCM tokens will show "APNs token not set" error
   - This is normal behavior until APNs is configured

**⚠️ This is a Firebase requirement, not our plugin limitation!**

#### **Web Setup (Optional)**

Add to `web/index.html`:

```html
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-app.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging.js"></script>
```

> **Browser caveats:** Browsers do not support local scheduling, notification action buttons, or app-icon badges. Calls to those APIs are safely ignored and surfaced by the diagnostics helper.

## 📖 **Usage Examples**

### **🎯 Complete Working Example**

```dart
import 'package:flutter/material.dart';
import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Firebase Messaging Handler
  final Stream<NotificationData?>? clickStream = await FirebaseMessagingHandler.instance.init(
    senderId: 'your_sender_id',
    androidChannelList: [
      NotificationChannelData(
        id: 'default_channel',
        name: 'Default Notifications',
        description: 'Default notification channel',
        importance: NotificationImportanceEnum.high,
        priority: NotificationPriorityEnum.high,
        playSound: true,
        enableVibration: true,
      ),
    ],
    androidNotificationIconPath: '@drawable/ic_notification',
    updateTokenCallback: (fcmToken) async {
      print('FCM Token: $fcmToken');
      // Send token to your backend
      return true;
    },
  );

  // Listen to notification clicks
  clickStream?.listen((NotificationData? data) {
    if (data != null) {
      print('Notification clicked: ${data.title}');
      // Handle notification click
    }
  });

  // Initial launch notifications are emitted onto the same stream by default.
  // Set includeInitialNotificationInStream: false to opt out if you need to
  // defer handling (e.g., until after auth).

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Messaging Handler Demo',
      home: MyHomePage(),
    );
  }
}

### **🎓 Showcase Example App**

The `example/` directory doubles as an FCM showcase powered entirely by this plugin:

- **Guided onboarding banner** – copy your FCM token, open the Firebase console, and follow the three-step testing loop.
- **Quick start scenarios** – fire interactive pushes, schedule one-time or recurring notifications, and generate Android groups with a tap.
- **Power utilities** – update badges, register custom sound channels, and clear demo data while analytics events stream in.
- **Scenario detail screen** – every notification routes to a dedicated inspector showing payloads, actions, badges, and metadata.
- **Activity timeline** – watch a running log of everything the handler does (initialization, scheduling, clears, custom actions).
- **Template playground** – paste sample silent payloads to preview the generic template renderer in real time.

Run `flutter run` inside `example/` to explore the full experience.

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('FCM Handler Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // Show a test notification
                await FirebaseMessagingHandler.instance.showNotificationWithActions(
                  title: 'Test Notification',
                  body: 'This is a test notification',
                  actions: [
                    NotificationAction(
                      id: 'reply',
                      title: 'Reply',
                      payload: {'action': 'reply'},
                    ),
                    NotificationAction(
                      id: 'dismiss',
                      title: 'Dismiss',
                      payload: {'action': 'dismiss'},
                    ),
                  ],
                );
              },
              child: Text('Send Test Notification'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Schedule a notification
                await FirebaseMessagingHandler.instance.scheduleNotification(
                  id: 1,
                  title: 'Scheduled Notification',
                  body: 'This notification was scheduled',
                  scheduledDate: DateTime.now().add(Duration(minutes: 1)),
                );
              },
              child: Text('Schedule Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### **Basic Setup**

```dart
// Initialize the plugin
final Stream<NotificationData?>? clickStream = await FirebaseMessagingHandler.instance.init(
  senderId: 'your_sender_id',
  androidChannelList: channels,
  androidNotificationIconPath: '@drawable/ic_notification',
  updateTokenCallback: (fcmToken) async {
    // Send token to your backend
    return true;
  },
);

// Listen to notification clicks
clickStream?.listen((NotificationData? data) {
  if (data != null) {
    // Handle notification click
  }
});
```

### **Interactive Notifications**

```dart
// Show notification with action buttons
await FirebaseMessagingHandler.instance.showNotificationWithActions(
  title: 'New Message',
  body: 'You have a new message from John',
  actions: [
    NotificationAction(
      id: 'reply',
      title: 'Reply',
      payload: {'action': 'reply', 'user_id': '123'},
    ),
    NotificationAction(
      id: 'view',
      title: 'View',
      payload: {'action': 'view', 'message_id': '456'},
    ),
    NotificationAction(
      id: 'dismiss',
      title: 'Dismiss',
      payload: {'action': 'dismiss'},
    ),
  ],
);
```

### **📥 Inbox Storage (typed, persistent)**

Use the default SharedPreferences-backed inbox store to fuel a history or inbox
UI with read/delete support.

```dart
final inbox = InboxStorageService();

await inbox.upsert(
  NotificationInboxItem(
    id: 'welcome',
    title: 'Welcome!',
    body: 'Thanks for installing the app.',
    timestamp: DateTime.now(),
    data: {'origin': 'campaign_welcome'},
  ),
);

final List<NotificationInboxItem> page =
    await inbox.fetch(page: 0, pageSize: 20);

await inbox.markRead([page.first.id]);
await inbox.delete([page.first.id]);
```

> For tests or ephemeral state, use `InMemoryInboxStorage`, which keeps items
> purely in memory.

#### Inbox UI widget

```dart
NotificationInboxView(
  storage: InboxStorageService(),
  onItemTap: (item) {
    // Navigate or open detail
  },
  onActionTap: (actionId, item) {
    // Handle custom buttons stored in item.actions
  },
  onDelete: (ids) async {
    // Optional: sync deletions to backend
  },
);
```

### **Notification Scheduling**

```dart
// Schedule a one-time notification
await FirebaseMessagingHandler.instance.scheduleNotification(
  id: 1,
  title: 'Meeting Reminder',
  body: 'Team meeting in 30 minutes',
  scheduledDate: DateTime.now().add(Duration(minutes: 30)),
);

// Schedule a recurring notification
await FirebaseMessagingHandler.instance.scheduleRecurringNotification(
  id: 2,
  title: 'Daily Reminder',
  body: 'Don\'t forget to check your tasks',
  repeatInterval: 'daily',
  hour: 9,
  minute: 0,
);
```

### **Badge Management**

```dart
// Set badge count
await FirebaseMessagingHandler.instance.setIOSBadgeCount(5);
await FirebaseMessagingHandler.instance.setAndroidBadgeCount(3);

// Get badge count
final int iosBadge = await FirebaseMessagingHandler.instance.getIOSBadgeCount();
final int androidBadge = await FirebaseMessagingHandler.instance.getAndroidBadgeCount();

// Clear badge count
await FirebaseMessagingHandler.instance.clearBadgeCount();
```

### **Notification Grouping**

```dart
// Show grouped notifications
await FirebaseMessagingHandler.instance.showGroupedNotification(
  title: 'New Messages',
  body: 'You have 3 new messages',
  groupKey: 'messages',
  groupTitle: 'Messages',
  isSummary: true,
);

// Create notification group
await FirebaseMessagingHandler.instance.createNotificationGroup(
  groupKey: 'messages',
  groupTitle: 'Messages',
  notifications: [
    NotificationData(
      title: 'Message 1',
      body: 'Hello from John',
      payload: {'message_id': '1'},
    ),
    NotificationData(
      title: 'Message 2',
      body: 'Hello from Jane',
      payload: {'message_id': '2'},
    ),
  ],
);
```

### **Custom Sounds**

```dart
// Create custom sound channel
await FirebaseMessagingHandler.instance.createCustomSoundChannel(
  channelId: 'custom_sound',
  channelName: 'Custom Sound Notifications',
  channelDescription: 'Notifications with custom sounds',
  soundFileName: 'custom_sound.mp3',
  importance: NotificationImportanceEnum.high,
  priority: NotificationPriorityEnum.high,
);

// Show notification with custom sound
await FirebaseMessagingHandler.instance.showNotificationWithCustomSound(
  title: 'Custom Sound Notification',
  body: 'This notification has a custom sound',
  soundFileName: 'custom_sound.mp3',
);
```

### **Analytics Integration**

```dart
// Set up analytics callback
FirebaseMessagingHandler.instance.setAnalyticsCallback((event, data) {
  print('Analytics Event: $event');
  print('Event Data: $data');
  
  // Send to your analytics service
  // FirebaseAnalytics.instance.logEvent(name: event, parameters: data);
});

// Track custom events
FirebaseMessagingHandler.instance.trackAnalyticsEvent('custom_event', {
  'user_id': '123',
  'action': 'notification_clicked',
});
```

## 🎛️ **Advanced Features**

### **Notification Actions**

Create interactive notifications with custom action buttons:

```dart
NotificationAction(
  id: 'reply',
  title: 'Reply',
  destructive: false,
  payload: {
    'action': 'reply',
    'user_id': '123',
    'thread_id': '456',
  },
)
```

### **Scheduling Options**

Schedule notifications with various options:

```dart
// One-time notification
await FirebaseMessagingHandler.instance.scheduleNotification(
  id: 1,
  title: 'One-time Notification',
  body: 'This will show once',
  scheduledDate: DateTime.now().add(Duration(hours: 1)),
  allowWhileIdle: true,
);

// Recurring notification
await FirebaseMessagingHandler.instance.scheduleRecurringNotification(
  id: 2,
  title: 'Daily Reminder',
  body: 'Daily task reminder',
  repeatInterval: 'daily',
  hour: 9,
  minute: 0,
);
```

### **Badge Management**

Cross-platform badge count management:

```dart
// iOS badge management
await FirebaseMessagingHandler.instance.setIOSBadgeCount(5);
final int iosBadge = await FirebaseMessagingHandler.instance.getIOSBadgeCount();

// Android badge management
await FirebaseMessagingHandler.instance.setAndroidBadgeCount(3);
final int androidBadge = await FirebaseMessagingHandler.instance.getAndroidBadgeCount();

// Clear all badges
await FirebaseMessagingHandler.instance.clearBadgeCount();
```

### **Notification Grouping**

Organize notifications into groups:

```dart
// Android notification groups
await FirebaseMessagingHandler.instance.showGroupedNotification(
  title: 'Group Summary',
  body: '3 new notifications',
  groupKey: 'messages',
  groupTitle: 'Messages',
  isSummary: true,
);

// iOS conversation threads
await FirebaseMessagingHandler.instance.showThreadedNotification(
  title: 'New Message',
  body: 'Hello from John',
  threadIdentifier: 'conversation_123',
);
```

### **Custom Sound Support**

Platform-specific sound customization:

```dart
// Create custom sound channel
await FirebaseMessagingHandler.instance.createCustomSoundChannel(
  channelId: 'custom_sound',
  channelName: 'Custom Sound Notifications',
  channelDescription: 'Notifications with custom sounds',
  soundFileName: 'custom_sound.mp3',
  importance: NotificationImportanceEnum.high,
  priority: NotificationPriorityEnum.high,
  enableVibration: true,
  enableLights: true,
);

// Get available sounds (iOS)
final List<String>? sounds = await FirebaseMessagingHandler.instance.getAvailableSounds();
```

## 🪄 **In-App Messaging**

Deliver rich in-app experiences using silent/data-only FCM payloads that map to reusable templates.

### **Register Templates**

```dart
FirebaseMessagingHandler.instance.registerInAppNotificationTemplates({
  'promo_banner': InAppNotificationTemplate(
    id: 'promo_banner',
    description: 'Lightweight promotional banner',
    onDisplay: (inAppData) {
      inAppOverlayController.showBanner(
        title: inAppData.content['title'] as String?,
        body: inAppData.content['body'] as String?,
        imageUrl: inAppData.content['image'] as String?,
        ctaLabel: inAppData.content['cta_label'] as String?,
        deeplink: inAppData.content['deeplink'] as String?,
      );
    },
  ),
});

FirebaseMessagingHandler.instance.setInAppFallbackDisplayHandler((payload) {
  debugPrint('Unhandled in-app template: ${payload.templateId}');
});
```

### **Listen for Ready Messages**

```dart
FirebaseMessagingHandler.instance
    .getInAppNotificationStream()
    .listen((inAppData) {
  inAppLogger.debug('Render template ${inAppData.templateId}');
  campaignAnalytics.track('in_app_impression', inAppData.analytics);
});
```

Need to hydrate pending payloads after a cold start? Call:

```dart
await FirebaseMessagingHandler.instance.flushPendingInAppNotifications();
```

### **Sample FCM Payload**

```json
{
  "message": {
    "token": "{{deviceToken}}",
    "data": {
      "fcmh_inapp": "{ \"id\": \"winter_sale_2025\", \"templateId\": \"promo_banner\", \"trigger\": \"immediate\", \"content\": { \"title\": \"Winter Sale\", \"body\": \"Take 25% off today only\", \"cta_label\": \"Shop now\", \"deeplink\": \"app://store/sale\" }, \"analytics\": { \"campaignId\": \"winter_flash\", \"variant\": \"A\" } }"
    }
  }
}
```

Supported triggers:

- `immediate` → render as soon as the payload arrives (foreground or via queued stream)
- `next_foreground` → store until the next time you listen to the stream
- `app_launch` → store until `flushPendingInAppNotifications` is called
- `custom` → surface the payload immediately and let the host decide when to display

Use `clearPendingInAppNotifications()` to drop queued payloads (optionally targeting a specific `id`).

### **Built-in Templates & Overlay Support**

**🎯 Perfect Use Cases for In-App Templates:**
- **Feature announcements** - Introduce new capabilities
- **User onboarding** - Guide users through app features  
- **Feedback collection** - Gather user ratings and suggestions
- **Promotional content** - Showcase offers and campaigns
- **Educational content** - Tips, tutorials, and help
- **User engagement** - Surveys, polls, and interactive content
- **Quick notifications** - Snackbars for non-intrusive messages

**❌ Avoid for Critical Updates:**
- **App updates** - Use system-level update prompts instead
- **Security alerts** - Use push notifications for immediate attention
- **Payment confirmations** - Use dedicated UI flows
- **Emergency notifications** - Use push notifications for reliability

**🚀 Template Flexibility:**
These built-in templates are just **examples**! The plugin provides a flexible foundation where you can:
- **Register custom templates** with your own layouts and animations
- **Create any UI component** - modals, sheets, cards, overlays, etc.
- **Define custom interactions** - gestures, animations, transitions
- **Build brand-specific experiences** - match your app's design system
- **Implement complex workflows** - multi-step processes, wizards, etc.

The plugin handles the infrastructure (overlay management, navigation, analytics) while you build the experience!

Provide a navigator key so the handler can present rich layouts:

```dart
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FirebaseMessagingHandler.instance.setInAppNavigatorKey(rootNavigatorKey);
  runApp(MaterialApp(
    navigatorKey: rootNavigatorKey,
    home: const ShowcaseHome(),
  ));
}
```

Register the generic template and handle button callbacks:

```dart
void _registerTemplates() {
  FirebaseMessagingHandler.instance.registerInAppNotificationTemplates({
    'builtin_generic': BuiltInInAppTemplates.generic(
      onAction: (actionId, data) {
        debugPrint('Template action: $actionId payload=${data.payload}');
      },
    ),
  });
}
```

Trigger locally (useful for testing) or remotely via a silent FCM payload:

```dart
InAppMessageManager.instance.triggerInAppNotification(
  InAppNotificationData(
    id: 'demo_${DateTime.now().millisecondsSinceEpoch}',
    templateId: 'builtin_generic',
    triggerType: InAppTriggerTypeEnum.immediate,
    content: {
      'layout': 'dialog',
      'title': 'New Feature Available',
      'subtitle': 'Enhanced notification controls',
      'body': 'We\'ve added smart scheduling and quiet hours. Try them out!',
      'imageUrl': 'https://via.placeholder.com/600x320/059669/ffffff?text=New+Feature',
      'blurSigma': 16,
      'cornerRadius': 20,
      'buttons': [
        {'id': 'try_now', 'label': 'Try Now', 'style': 'filled'},
        {'id': 'learn_more', 'label': 'Learn More', 'style': 'outlined'},
        {'id': 'dismiss', 'label': 'Not now', 'style': 'text', 'dismissOnly': true}
      ],
    },
    analytics: {'source': 'docs_demo'},
    rawPayload: const {},
    receivedAt: DateTime.now(),
  ),
);
```

Supported layouts include `dialog`, `full_screen`, `bottom_sheet`, `banner`, `tooltip`, `carousel`, and `snackbar`. Configure blur, barrier color, size factors, button styles, and HTML content directly from the payload.

Key payload fields:

- `layout`: dialog | full_screen | bottom_sheet | banner | snackbar
- `widthFactor` / `heightFactor`: fractions of the screen size (dialog + full screen)
- `blurSigma` & `barrierColor`: backdrop styling for dialogs/full screens
- `backgroundColor` / `textColor`: hex (`#RRGGBB` or `#AARRGGBB`) or RGB maps
- `html`: optional HTML body rendered with `flutter_widget_from_html_core`
- `buttons`: array of `{ id, label, style (filled|outlined|text|link), dismissOnly }`
- `autoDismissSeconds`: auto-dismiss duration for banners/snackbars
- `position`: `top` or `bottom` for banner layout
- `pages`: list of page maps (carousel) each supporting `title`, `body`, `html`, `imageUrl`, and `buttons`

### **Custom Template Registration**

Create your own templates with complete control over UI and behavior:

```dart
// Register a custom template
FirebaseMessagingHandler.instance.registerInAppNotificationTemplates({
  'my_custom_template': InAppNotificationTemplate(
    id: 'my_custom_template',
    description: 'Custom onboarding flow',
    autoDismissDuration: null, // Manual dismiss
    onDisplay: (data) {
      // Your custom UI logic here
      showDialog(
        context: context,
        builder: (context) => MyCustomOnboardingDialog(
          title: data.content['title'],
          steps: data.content['steps'],
          onComplete: () => data.onAction?.call('completed', data),
        ),
      );
    },
  ),
  
  'my_animated_banner': InAppNotificationTemplate(
    id: 'my_animated_banner',
    description: 'Animated promotional banner',
    autoDismissDuration: const Duration(seconds: 5),
    onDisplay: (data) {
      // Custom animated banner with your branding
      showAnimatedBanner(
        message: data.content['message'],
        backgroundColor: data.content['color'],
        animation: SlideAnimation.fromTop(),
      );
    },
  ),
});
```

**Custom Template Benefits:**
- **Complete UI control** - Use any Flutter widget
- **Brand consistency** - Match your app's design system
- **Advanced animations** - Custom transitions and effects
- **Complex interactions** - Multi-step flows, gestures, etc.
- **Platform-specific behavior** - Different UIs per platform
- **Integration flexibility** - Connect to your existing components

## 🛡️ **Foreground Notification Customization**

Own the fallback notification UI that appears while your app is active. The plugin includes smart fallback logic to ensure notifications always display, even when no channel ID is provided.

### **Smart Channel Fallback**

The plugin automatically handles Android notification channels with intelligent fallback:

- **Channel Specified**: If a notification includes a channel ID, that specific channel is used
- **Channel Not Found**: If the specified channel doesn't exist, falls back to the first available channel
- **No Channel Provided**: If no channel ID is specified, uses the first available channel
- **No Channels Available**: Logs an error and skips the notification (prevents crashes)

This ensures your Android foreground notifications always display, regardless of Firebase Console configuration.

### **Override Once, Anywhere**

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

FirebaseMessagingHandler.instance.setForegroundNotificationOptions(
  ForegroundNotificationOptions(
    androidBuilder: (context) {
      final imageAsset = context.data['image_asset'] as String?;
      if (imageAsset != null) {
        return AndroidNotificationDetails(
          'promo_channel',
          'Promotions',
          channelDescription: 'Foreground promos',
          importance: Importance.max,
          priority: Priority.high,
          styleInformation: BigPictureStyleInformation(
            DrawableResourceAndroidBitmap(imageAsset),
            largeIcon: DrawableResourceAndroidBitmap(imageAsset),
          ),
        );
      }
      return const AndroidNotificationDetails(
        'default_channel',
        'Default Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
    },
    iosBuilder: (context) {
      final imageName = context.data['image_asset'] as String?;
      if (imageName == null) {
        return const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: true,
        );
      }

      return DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
        attachments: [
          DarwinNotificationAttachment('resource:///$imageName'),
        ],
      );
    },
  ),
);
```

The builders receive the real `RemoteMessage`, so you can map any data payload to advanced styles, media, icons, or badges. Return `null` to fall back to the plugin defaults, or set `enabled: false` to suppress the automatic notification entirely when you prefer a custom in-app surface.

Prefer static overrides? Use `androidDefaults` / `iosDefaults` to plug in prebuilt `AndroidNotificationDetails` or `DarwinNotificationDetails` instances without writing builders.

### **🔊 Configure Default Custom Sounds**

Set custom sounds once—they'll apply to all foreground notifications automatically:

```dart
// Step 1: Configure default sounds for foreground notifications
FirebaseMessagingHandler.instance.setForegroundNotificationOptions(
  ForegroundNotificationOptions(
    // Android: Place sound file in android/app/src/main/res/raw/custom_sound.mp3
    androidSoundFileName: 'custom_sound', // Without extension
    
    // iOS: Place sound file in project (Runner/Sounds/custom_sound.aiff)
    iosSoundFileName: 'custom_sound.aiff', // With extension
    
    androidDefaults: const AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      importance: Importance.max,
      priority: Priority.high,
    ),
    iosDefaults: const DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    ),
  ),
);
```

**Platform-Specific Sound Configuration:**

**Android (Two Options):**

**Option 1:** Default sound for all foreground notifications (shown above)
```dart
ForegroundNotificationOptions(
  androidSoundFileName: 'custom_sound', // Applied to all foreground notifications
)
```

**Option 2:** Per-channel sounds (configured during init)
```dart
await FirebaseMessagingHandler.instance.init(
  senderId: 'your_sender_id',
  androidChannelList: [
    NotificationChannelData(
      id: 'default_channel',
      name: 'Default Notifications',
      soundFileName: 'default_sound', // Sound for this channel only
    ),
    NotificationChannelData(
      id: 'urgent_channel',
      name: 'Urgent Alerts',
      soundFileName: 'urgent_sound', // Different sound for urgent channel
    ),
  ],
  androidNotificationIconPath: '@drawable/ic_notification',
);
```

**iOS:**

iOS doesn't have channels, so configure the default sound through `ForegroundNotificationOptions`:
```dart
ForegroundNotificationOptions(
  iosSoundFileName: 'custom_sound.aiff', // Applied to ALL iOS notifications
)
```

**⚠️ Important iOS Limitation:**

**Foreground Notifications (App Active):**
- ✅ **Custom sounds work** - Via `ForegroundNotificationOptions.iosSoundFileName`
- ✅ **Full control** - Our plugin handles these notifications

**Background Notifications (App Killed/Backgrounded):**
- ❌ **Custom sounds DON'T work** - iOS system handles these directly
- ❌ **No control** - System uses default notification sound

**💡 Workaround for Background Sounds:**

For background notifications, configure the sound in your **Firebase Console payload**:

```json
{
  "notification": {
    "title": "Background Notification",
    "body": "This will use system default sound",
    "sound": "custom_sound.aiff"  // iOS will use this if file exists in app bundle
  },
  "apns": {
    "payload": {
      "aps": {
        "sound": "custom_sound.aiff"  // Alternative APNs-specific sound
      }
    }
  }
}
```

**Requirements for Background Sounds:**
1. Sound file must be in your iOS app bundle (added via Xcode)
2. Sound file must be ≤ 30 seconds
3. Supported formats: AIFF, CAF, WAV
4. If file doesn't exist, iOS falls back to default sound

**Sound File Setup:**

**Android:**
1. Place sound file in `android/app/src/main/res/raw/`
2. Use filename **without** extension (e.g., `custom_sound` for `custom_sound.mp3`)
3. Supported formats: MP3, OGG

**iOS:**
1. Add sound file to Xcode project (via Xcode > Add Files)
2. Ensure it's added to the target (check "Copy items if needed")
3. Use filename **with** extension (e.g., `custom_sound.aiff`)
4. Supported formats: AIFF, CAF, WAV (up to 30 seconds)

> 💡 **Pro Tip:** 
> - **Android**: Use `NotificationChannelData.soundFileName` for per-channel sounds, or `ForegroundNotificationOptions.androidSoundFileName` for all foreground notifications
> - **iOS**: Use `ForegroundNotificationOptions.iosSoundFileName` - this is the ONLY way to set default sounds on iOS since iOS doesn't have channels

> ℹ️ Use `DrawableResourceAndroidBitmap`, `ByteArrayAndroidBitmap`, or `FilePathAndroidBitmap` depending on where your assets live. For iOS, `DarwinNotificationAttachment` expects a local resource URI—download remote media before attaching it.

## 📊 **Analytics Integration**

### **Built-in Event Tracking**

The plugin automatically tracks these events:

- `notification_received` - When notifications arrive
- `notification_clicked` - When notifications are tapped
- `notification_action` - When action buttons are pressed
- `notification_scheduled` - When notifications are scheduled
- `fcm_token` - Token events (fetched, updated, error)

### **Custom Analytics**

```dart
// Set up analytics callback
FirebaseMessagingHandler.instance.setAnalyticsCallback((event, data) {
  // Send to your analytics service
  FirebaseAnalytics.instance.logEvent(
    name: event,
    parameters: data,
  );
});

// Track custom events
FirebaseMessagingHandler.instance.trackAnalyticsEvent('custom_event', {
  'user_id': '123',
  'action': 'notification_clicked',
  'timestamp': DateTime.now().toIso8601String(),
});
```

## 🩺 **Notification Diagnostics**

Stay ahead of production issues with a built-in "notification doctor". It inspects permissions, token state, badge capabilities, web support, and background wiring in one call.

### **Run the Doctor**

```dart
final diagnostics = await FirebaseMessagingHandler.instance.runDiagnostics();

debugPrint('Notification diagnostics: ${diagnostics.toMap()}');

if (!diagnostics.success || diagnostics.recommendations.isNotEmpty) {
  for (final recommendation in diagnostics.recommendations) {
    debugPrint('Recommendation → $recommendation');
  }
}
```

**What you get:**

- `permissionsGranted` and `authorizationStatus` – current notification permission state.
- `fcmTokenAvailable` – whether a token is cached via `updateTokenCallback`.
- `badgeSupported` – launcher/platform badge capability (best-effort on Android).
- `webNotificationsAllowed` / `metadata['webPermission']` – browser permission string.
- `metadata['backgroundHandlerRegistered']` – confirms `configureBackgroundMessageHandler` has been invoked.
- `pendingNotificationCount` – number of locally scheduled notifications.
- `metadata['invalidPayloadCount']` – how many malformed data-only payloads were rejected by the bridge/schema guard.

### **Background Message Helper**

Register a top-level handler once and reuse the plugin’s pipeline inside the isolate:

```dart
@pragma('vm:entry-point')
Future<void> myBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseMessagingHandler.handleBackgroundMessage(message);

  // Custom logic: update analytics, hydrate local cache, etc.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseMessagingHandler.instance.configureBackgroundMessageHandler(
    myBackgroundHandler,
  );

  runApp(const MyApp());
}
```

> **Tip:** Prefer the built-in `firebaseMessagingHandlerBackgroundDispatcher` if you simply want to hydrate the plugin without extra logic:
>
> ```dart
> await FirebaseMessagingHandler.instance.configureBackgroundMessageHandler(
>   firebaseMessagingHandlerBackgroundDispatcher,
> );
> ```

### **Web Safeguards**

Scheduling, interactive actions, and app-icon badges are not available in browsers. The doctor highlights these limitations and the runtime API logs “ignored” warnings so you can branch logic per platform.

## 🌙 **Quiet Hours & Throttling**

Control when in-app messages surface and how frequently campaigns fire.

```dart
await FirebaseMessagingHandler.instance.setInAppDeliveryPolicy(
  const InAppDeliveryPolicy(
    globalInterval: Duration(seconds: 30),
    perTemplateInterval: Duration(minutes: 2),
    perTemplateDailyCap: 5,
    quietHours: InAppQuietHours(startHour: 22, endHour: 7),
  ),
);
```

- `globalInterval` enforces a cool-down between any two in-app presentations.
- `perTemplateInterval` keeps the same template from spamming the timeline.
- `perTemplateDailyCap` limits impressions per template per day.
- `quietHours` defers delivery until the configured window closes. Deferred payloads are re-queued automatically with the diagnostics report showing their status.

## 🔄 **Data-Only Bridging**

Promote silent payloads into local notifications (or custom flows) so users still see timely updates.

```dart
// Promote data-only FCM payloads to local notifications automatically
FirebaseMessagingHandler.instance.enableDefaultDataOnlyBridge(
  channelId: 'actions_channel',
  titleKey: 'title',
  bodyKey: 'body',
);

// Or wire your own handler and decide when work is complete
await FirebaseMessagingHandler.instance.configureBackgroundProcessingCallback(
  (RemoteMessage message) async {
    if (message.data['should_defer'] == 'true') {
      return false; // enqueue for retry when app wakes up
    }

    // Custom processing…
    return true;
  },
);
```

Use `FirebaseMessagingHandler.handleBackgroundMessage(message)` inside your top-level background function to hydrate local queues before running custom logic.

## 🧪 **Testing Utilities**

### **Mock Data Generation**

```dart
// Create mock notification data
final NotificationData mockData = FirebaseMessagingHandler.createMockNotificationData(
  title: 'Mock Notification',
  body: 'This is a mock notification',
  payload: {'test': 'data'},
  type: NotificationTypeEnum.foreground,
);

// Create mock remote message
final RemoteMessage mockMessage = FirebaseMessagingHandler.createMockRemoteMessage(
  title: 'Mock Message',
  body: 'This is a mock message',
  data: {'test': 'data'},
);
```

### **Test Mode**

```dart
// Enable test mode
FirebaseMessagingHandler.setTestMode(true);

// Get mock streams
final Stream<RemoteMessage>? mockNotificationStream = 
    FirebaseMessagingHandler.getMockNotificationStream();

final Stream<NotificationData>? mockClickStream = 
    FirebaseMessagingHandler.getMockClickStream();

// Add mock events
FirebaseMessagingHandler.addMockNotification(mockMessage);
FirebaseMessagingHandler.addMockClickEvent(mockData);

// Reset mock data
FirebaseMessagingHandler.resetMockData();
```

## 📦 **Payload Cookbook**

Jump-start backend integration with ready-to-send payloads:

### **Interactive Notification (Actions + Analytics)**

```json
{
  "message": {
    "token": "<device-token>",
    "notification": {
      "title": "New Support Ticket",
      "body": "Tap Reply to follow up without opening the app."
    },
    "data": {
      "is_action": true,
      "action_id": "reply",
      "action_payload": {"ticket_id": "12345"},
      "analytics": {"campaign": "support_reengage"}
    }
  }
}
```

### **Data-Only → Local Notification Bridge**

```json
{
  "message": {
    "token": "<device-token>",
    "data": {
      "title": "Inventory Update",
      "body": "SKU #48319 is back in stock!",
      "deep_link": "app://inventory/48319"
    }
  }
}
```

### **In-App Template Trigger**

```json
{
  "message": {
    "token": "<device-token>",
    "data": {
      "fcmh_inapp": {
        "id": "promo-2025",
        "templateId": "builtin_generic",
        "trigger": "immediate",
        "content": {
          "layout": "html_modal",
          "title": "Spring Launch",
          "html": "<h2>Fresh features</h2><p>Try quiet hours + notification doctor today.</p>",
          "buttons": [{"id": "explore", "label": "Explore", "style": "filled"}]
        }
      }
    }
  }
}
```

## 📚 **API Reference**

### **Core Methods**

#### **Initialization**
```dart
Future<Stream<NotificationData?>?> init({
  required String senderId,
  required List<NotificationChannelData> androidChannelList,
  required String androidNotificationIconPath,
  Future<bool> Function(String fcmToken)? updateTokenCallback,
  bool includeInitialNotificationInStream = true,
})
```

#### **Initial Notification Handling**
```dart
Future<NotificationData?> checkInitial() // optional fallback; auto-handled by default
```

#### **Notification Display**
```dart
Future<void> showNotificationWithActions({
  required String title,
  required String body,
  required List<NotificationAction> actions,
  Map<String, dynamic>? payload,
  String? channelId,
  int? notificationId,
})

Future<void> showNotificationWithCustomSound({
  required String title,
  required String body,
  required String soundFileName,
  String? channelId,
  Map<String, dynamic>? payload,
  int? notificationId,
})
```

#### **Scheduling**
```dart
Future<bool> scheduleNotification({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
  String? channelId,
  Map<String, dynamic>? payload,
  List<NotificationAction>? actions,
  bool allowWhileIdle = false,
})

Future<bool> scheduleRecurringNotification({
  required int id,
  required String title,
  required String body,
  required String repeatInterval,
  required int hour,
  required int minute,
  String? channelId,
  Map<String, dynamic>? payload,
  List<NotificationAction>? actions,
})
```

#### **Background Handling & Diagnostics**
```dart
Future<void> configureBackgroundMessageHandler(
  Future<void> Function(RemoteMessage message) handler,
)

static Future<void> handleBackgroundMessage(RemoteMessage message)

Future<NotificationDiagnosticsResult> runDiagnostics()

Future<void> setUnifiedMessageHandler(
  Future<bool> Function(NormalizedMessage message, NotificationLifecycle lifecycle) handler,
)
```

#### **Inbox Storage**

- `fetch({int page = 0, int pageSize = 20})` →
  `Future<List<NotificationInboxItem>>`
- `upsert(NotificationInboxItem item)`
- `upsertAll(List<NotificationInboxItem> items)`
- `markRead(List<String> ids, {bool isRead = true})`
- `delete(List<String> ids)`
- `clear()`
- `count({bool unreadOnly = false})`

Implementations:

- `InboxStorageService` – SharedPreferences-backed persistence.
- `InMemoryInboxStorage` – memory-only, ideal for tests.

#### **Badge Management**
```dart
Future<void> setIOSBadgeCount(int count)
Future<int> getIOSBadgeCount()
Future<void> setAndroidBadgeCount(int count)
Future<int> getAndroidBadgeCount()
Future<void> clearBadgeCount()
```

#### **Token Management**
```dart
Future<String?> getFcmToken()
Future<void> clearToken()
Future<void> subscribeToTopic(String topic)
Future<void> unsubscribeFromTopic(String topic)
Future<void> unsubscribeFromAllTopics()
```

#### **Analytics**
```dart
void setAnalyticsCallback(Function(String, Map<String, dynamic>) callback)
void trackAnalyticsEvent(String event, Map<String, dynamic> data)
```

### **Data Models**

#### **NotificationData**
```dart
class NotificationData {
  final Map<String, dynamic> payload;
  final String? title;
  final String? body;
  final String? imageUrl;
  final String? icon;
  final String? category;
  final List<NotificationAction>? actions;
  final DateTime? timestamp;
  final NotificationTypeEnum type;
  final bool isFromTerminated;
  final String? messageId;
  final String? senderId;
  final int? badgeCount;
}
```

#### **NotificationAction**
```dart
class NotificationAction {
  final String id;
  final String title;
  final bool destructive;
  final Map<String, dynamic>? payload;
}
```

#### **NotificationChannelData**
```dart
class NotificationChannelData {
  final String id;
  final String name;
  final String? description;
  final String? groupId;
  final NotificationImportanceEnum importance;
  final bool playSound;
  final String? soundPath;
  final String? soundFileName;
  final bool enableVibration;
  final bool enableLights;
  final Int64List? vibrationPattern;
  final Color? ledColor;
  final bool showBadge;
  final NotificationPriorityEnum priority;
  final List<NotificationAction>? actions;
}
```

## 🔧 **Configuration**

### **Notification Channels**

Create custom notification channels for different types of notifications:

```dart
final List<NotificationChannelData> channels = [
  NotificationChannelData(
    id: 'default_channel',
    name: 'Default Notifications',
    description: 'Default notification channel',
    importance: NotificationImportanceEnum.high,
    priority: NotificationPriorityEnum.high,
    playSound: true,
    enableVibration: true,
    enableLights: true,
  ),
  NotificationChannelData(
    id: 'silent_channel',
    name: 'Silent Notifications',
    description: 'Silent notification channel',
    importance: NotificationImportanceEnum.low,
    priority: NotificationPriorityEnum.low,
    playSound: false,
    enableVibration: false,
    enableLights: false,
  ),
];
```

### **Platform-Specific Settings**

#### **Android**
```dart
NotificationChannelData(
  id: 'android_channel',
  name: 'Android Notifications',
  description: 'Android-specific notifications',
  importance: NotificationImportanceEnum.max,
  priority: NotificationPriorityEnum.max,
  playSound: true,
  enableVibration: true,
  enableLights: true,
  vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
  ledColor: Color(0xFFFF0000),
  showBadge: true,
)
```

#### **iOS**
```dart
NotificationChannelData(
  id: 'ios_channel',
  name: 'iOS Notifications',
  description: 'iOS-specific notifications',
  importance: NotificationImportanceEnum.high,
  priority: NotificationPriorityEnum.high,
  playSound: true,
  enableVibration: true,
  enableLights: false,
  showBadge: true,
)
```

## 🐛 **Troubleshooting**

### **Common Issues**

#### **Notifications not showing:**
- Check Firebase configuration files are in place
- Verify sender ID is correct
- Check AndroidManifest.xml permissions
- Ensure notification channels are created

#### **Scheduled notifications not working:**
- **Android 12+ (API 31+)**: Add `SCHEDULE_EXACT_ALARM` and `USE_EXACT_ALARM` permissions
- **Android 13+ (API 33+)**: Request `SCHEDULE_EXACT_ALARM` permission at runtime
- Ensure broadcast receivers are added to AndroidManifest.xml
- Check scheduled time is in the future
- Verify notification permissions are granted

**🔧 Android 13+ Runtime Permission:**

For Android 13+ devices, you need to request the exact alarm permission at runtime:

```dart
import 'package:permission_handler/permission_handler.dart';

// Request exact alarm permission (Android 13+)
if (Platform.isAndroid) {
  final status = await Permission.scheduleExactAlarm.request();
  if (status.isGranted) {
    // Permission granted, you can schedule notifications
  } else {
    // Permission denied, handle gracefully
    print('Exact alarm permission denied');
  }
}
```

#### **Permission-related issues:**

**❌ "Exact alarms are not permitted"**
- **Cause**: Missing `SCHEDULE_EXACT_ALARM` permission
- **Fix**: Add permission to AndroidManifest.xml
- **Alternative**: Use `scheduleNotification()` without exact timing

**❌ "No push notifications received"**
- **Cause**: Missing `INTERNET` or `WAKE_LOCK` permission
- **Fix**: Add basic permissions to AndroidManifest.xml

**❌ "Notifications don't vibrate"**
- **Cause**: Missing `VIBRATE` permission
- **Fix**: Add `VIBRATE` permission to AndroidManifest.xml

**❌ "Foreground notifications not showing"**
- **Cause**: Missing `FOREGROUND_SERVICE` permission
- **Fix**: Add `FOREGROUND_SERVICE` permission to AndroidManifest.xml

#### **iOS badges not updating:**
- Requires proper APNs certificate configuration
- May not work in simulator
- **Must upload APNs key to Firebase Console**

#### **APNs token not set error:**
- This is **NORMAL** until APNs is configured
- Generate APNs key in Apple Developer Console
- Upload `.p8` key file to Firebase Console
- Choose correct environment (Sandbox/Production)
- **This is a Firebase requirement, not a plugin issue**

#### **Custom sounds not playing:**
- Add sound files to correct platform directories
- Create notification channels before using sounds
- Check file permissions and formats

#### **Analytics not tracking:**
- Ensure analytics callback is set
- Check event names and data format
- Verify analytics service integration

### **Debug Mode**

Enable debug mode for detailed logging:

```dart
// The plugin automatically logs detailed information in debug mode
// Check console output for initialization and operation logs
```

### **Error Handling**

The plugin provides comprehensive error handling:

```dart
try {
  await FirebaseMessagingHandler.instance.init(
    senderId: 'your_sender_id',
    androidChannelList: channels,
    androidNotificationIconPath: '@drawable/ic_notification',
  );
} catch (e) {
  print('Initialization failed: $e');
  // Handle error appropriately
}
```

## 🤝 **Contributing**

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### **Development Setup**

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

### **Code Style**

- Follow Dart/Flutter conventions
- Add comprehensive documentation
- Include unit tests
- Ensure backward compatibility

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 **Support**

- **Documentation:** [Complete API Reference](https://pub.dev/documentation/firebase_messaging_handler/latest/)
- **Examples:** [Example App](example/) – guided FCM showcase experience
- **Issues:** [GitHub Issues](https://github.com/your-repo/firebase_messaging_handler/issues)

## 🎉 **What's Next?**

- **In-App UX Kit v1** – survey carousel, tooltip, edge-to-edge banner, HTML modal with safe defaults.
- **Notification Inbox Widget** – themable list with read/delete and storage abstraction.
- **Unified Handler + Schema Guard** – single callback across lifecycles with strict data-only validator.
- **Permission Wizard & Quiet Hours** – guided POST_NOTIFICATIONS/exact alarm/APNs readiness plus defer/cap policies.
- **Web Polish** – permission overlay, custom icons/badges, service worker validator with actionable logs.
- **Journeys & Server Recipes** – ready payloads (welcome, win-back, NPS) plus Cloud Functions/REST examples under `server_recipes/`.
- **Example App Upgrades** – Notification Doctor tab, payload simulator, inbox + in-app demos.

---

**Made with ❤️ for the Flutter community**
