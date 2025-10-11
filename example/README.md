# Firebase Messaging Handler Example App

A comprehensive showcase application demonstrating all the features of the **Firebase Messaging Handler** plugin.

## 🚀 **What This Example Demonstrates**

This example app showcases every feature of our Firebase messaging handler plugin:

### ✅ **Core Features**
- **Unified notification stream** handling all notification types
- **Flexible initial notification control** (stream or separate handling)
- **Smart token management** with single backend call optimization
- **Cross-platform support** (Android, iOS, Web)

### ✅ **Advanced Features**
- **Interactive notification actions** with custom payloads
- **Notification scheduling** (one-time and recurring)
- **Badge management** (iOS and Android)
- **Notification grouping** and threading
- **Custom sound support**
- **Built-in analytics** tracking
- **Testing utilities** with mock data

## 📋 **How to Use This Example**

### **1. Setup Firebase Project**

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add your Android and iOS apps to the project
3. Download and place `google-services.json` in `android/app/`
4. Download and place `GoogleService-Info.plist` in `ios/Runner/`

### **2. Get Your Sender ID**

Find your project's **Sender ID** in:
- Firebase Console > Project Settings > Cloud Messaging
- Look for "Sender ID" (usually a 12-digit number)

### **3. Update Configuration**

Update the sender ID in `lib/services/notification_service.dart`:
```dart
senderId: 'YOUR_SENDER_ID', // Replace with your actual sender ID
```

### **4. Run the Example**

```bash
# Install dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Or run on specific platform
flutter run -d android
flutter run -d ios
```

## 🎮 **Using the Example App**

### **Main Screen Features:**

#### **📊 Status Dashboard**
- Shows initialization status
- Displays FCM token
- Badge count indicators

#### **🚀 Feature Showcase**
- **Send Test Notification**: Interactive notification with action buttons
- **Schedule Notification**: Schedule a notification for 1 minute from now
- **Schedule Recurring**: Daily recurring notifications
- **Create Notification Group**: Group multiple notifications together
- **Update Badges**: Update badge counts for both platforms
- **Custom Sounds**: Create notification channels with custom sounds

#### **📨 Notification History**
- View recent notifications with rich metadata
- See notification types (foreground, background, terminated)
- Check notification actions and payloads

#### **🚀 Initial Notification**
- Shows the notification that launched the app (if any)
- Demonstrates separate handling approach

### **🧪 Testing Scenarios**

#### **Test Interactive Actions**
1. Tap "Send Test Notification"
2. You'll see a notification with "Reply", "View Details", and "Dismiss" buttons
3. Tap any button to see the action handling in action

#### **Test Notification Scheduling**
1. Tap "Schedule Notification" - notification will appear in 1 minute
2. Tap "Schedule Recurring" - daily notifications at 9:00 AM
3. Check "Recent Notifications" to see scheduled notifications

#### **Test Badge Management**
1. Tap "Update Badges" - sets iOS badge to 5, Android badge to 3
2. See badge counts update in the dashboard

#### **Test Notification Grouping**
1. Tap "Create Notification Group" - creates a group of 3 notifications
2. See how notifications are organized together

## 📱 **Platform-Specific Testing**

### **Android**
- Test notification channels and custom sounds
- Verify badge management
- Check notification grouping behavior
- Test scheduled notifications

### **iOS**
- Test badge management (requires proper APNs setup)
- Verify notification threading
- Check sound customization
- Test scheduled notifications

### **Web**
- Test browser notification permissions
- Verify notification display in browser
- Check service worker integration

## 🔧 **Configuration Options**

The example demonstrates various configuration options:

```dart
// Different notification channels
NotificationChannelData(
  id: 'default_channel',
  name: 'Default Notifications',
  importance: NotificationImportanceEnum.high,
  priority: NotificationPriorityEnum.high,
  playSound: true,
  enableVibration: true,
  enableLights: true,
),

// Interactive actions
NotificationAction(
  id: 'reply',
  title: 'Reply',
  payload: {'action': 'reply', 'user_id': 'user123'},
),

// Scheduling options
scheduleNotification(
  id: 1,
  title: 'Meeting Reminder',
  body: 'Team meeting in 30 minutes',
  scheduledDate: DateTime.now().add(Duration(minutes: 30)),
),

// Analytics tracking
messagingHandler.setAnalyticsCallback((event, data) {
  print('Analytics: $event - $data');
});
```

## 🐛 **Troubleshooting**

### **Common Issues**

**Notifications not showing:**
- Check Firebase configuration files are in place
- Verify sender ID is correct
- Check AndroidManifest.xml permissions

**Scheduled notifications not working:**
- Ensure broadcast receivers are added to AndroidManifest.xml
- Check scheduled time is in the future

**iOS badges not updating:**
- Requires proper APNs certificate configuration
- May not work in simulator

**Custom sounds not playing:**
- Add sound files to correct platform directories
- Create notification channels before using sounds

## 📊 **Analytics Events**

The example logs all analytics events to the console:

- `notification_received` - When notifications arrive
- `notification_clicked` - When notifications are tapped
- `notification_action` - When action buttons are pressed
- `notification_scheduled` - When notifications are scheduled
- `fcm_token` - Token events (fetched, updated, error)

## 🎯 **What This Proves**

This example app proves that our Firebase messaging handler plugin:

1. **✅ Works exactly as documented** - Every feature works as described
2. **✅ Handles all edge cases** - Initial notifications, scheduling, actions, etc.
3. **✅ Provides excellent developer experience** - Simple APIs that "just work"
4. **✅ Is production-ready** - Comprehensive error handling and logging
5. **✅ Supports all platforms** - Android, iOS, and Web
6. **✅ Offers advanced features** - Beyond basic Firebase messaging capabilities

## 🚀 **Next Steps**

After testing this example:

1. **Customize for your app** - Modify the notification channels and handlers
2. **Add your Firebase config** - Replace placeholder values with real Firebase project
3. **Implement your logic** - Add your app's specific notification handling
4. **Test thoroughly** - Use the testing utilities to ensure reliability
5. **Deploy with confidence** - Our plugin is production-ready!

## 📝 **Integration Guide**

To integrate into your app:

1. **Copy the notification service** structure
2. **Customize notification channels** for your use case
3. **Implement your handlers** for different notification types
4. **Add analytics tracking** for your metrics
5. **Test with your Firebase project**

**The example serves as both a showcase and a starting point for your own implementation!** 🎉