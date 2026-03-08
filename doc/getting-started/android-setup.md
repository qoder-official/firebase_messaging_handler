---
layout: page
title: Android Setup
---

# Android Setup

## Manifest permissions

For basic notification delivery, add:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

For Android 13+, request notification permission in app flow where appropriate.

## Notification icon

Provide a monochrome notification icon and pass it into package initialization:

```dart
await FirebaseMessagingHandler.instance.init(
  senderId: 'your_sender_id',
  androidNotificationIconPath: '@drawable/ic_notification',
);
```

## Gradle note

If your app uses scheduling or APIs that require Java 8+ backports, include core library desugaring as documented in the package README.
