import 'package:flutter/foundation.dart';
import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/notification_provider.dart';

/// Example service demonstrating the new Firebase Messaging Handler architecture
///
/// This service showcases how to use the refactored plugin with:
/// - Modular architecture with clear separation of concerns
/// - Comprehensive error handling and logging
/// - Analytics integration
/// - Cross-platform notification management
/// - Backward compatibility with existing APIs
class NotificationService {
  final FirebaseMessagingHandler _messagingHandler =
      FirebaseMessagingHandler.instance;
  final NotificationProvider _notificationProvider;

  NotificationService(this._notificationProvider);

  Future<void> initialize() async {
    try {
      // Initialize with notification channels using the new architecture
      final Stream<NotificationData?>? clickStream = await _messagingHandler
          .init(
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
              NotificationChannelData(
                id: 'actions_channel',
                name: 'Action Notifications',
                description: 'Notifications with interactive buttons',
                importance: NotificationImportanceEnum.max,
                priority: NotificationPriorityEnum.max,
                playSound: true,
                enableVibration: true,
                enableLights: true,
              ),
              NotificationChannelData(
                id: 'scheduled_channel',
                name: 'Scheduled Notifications',
                description: 'Scheduled notification channel',
                importance: NotificationImportanceEnum.high,
                priority: NotificationPriorityEnum.high,
                playSound: true,
                enableVibration: false,
              ),
            ],
            androidNotificationIconPath: '@drawable/ic_notification',
            senderId: '123456789012', // Replace with your actual sender ID
            updateTokenCallback: (String fcmToken) async {
              debugPrint('FCM Token: $fcmToken');
              _notificationProvider.setFcmToken(fcmToken);

              // In a real app, send this token to your backend
              // For demo purposes, we'll just print it
              return true;
            },
          );

      // Handle initial notification separately (recommended approach)
      final NotificationData? initialData = await _messagingHandler
          .checkInitial();
      if (initialData != null) {
        _notificationProvider.setInitialNotification(initialData);
        _handleNotificationClick(initialData, isInitial: true);
      }

      // Listen to notification clicks
      clickStream?.listen((NotificationData? data) {
        if (data != null) {
          _handleNotificationClick(data);
        }
      });

      // Set up analytics callback using the new architecture
      _messagingHandler.setAnalyticsCallback((event, data) {
        debugPrint('Analytics Event: $event - $data');
        // In a real app, you would send this to your analytics service
        // Examples: Firebase Analytics, Mixpanel, Amplitude, etc.
      });

      _notificationProvider.setInitialized(true);
      debugPrint('Firebase Messaging Handler initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase Messaging Handler: $e');
      _notificationProvider.setInitialized(false);
    }
  }

  void _handleNotificationClick(
    NotificationData data, {
    bool isInitial = false,
  }) {
    // Add to notifications list
    _notificationProvider.addNotification(data);

    // Handle notification actions
    if (data.payload['is_action'] == true) {
      final actionId = data.payload['action_id'];
      final actionPayload = data.payload['action_payload'];

      switch (actionId) {
        case 'reply':
          _showReplyDialog(actionPayload);
          break;
        case 'view':
          _navigateToProfile(actionPayload);
          break;
        case 'call':
          _makePhoneCall(actionPayload);
          break;
        case 'dismiss':
          // Just dismiss, no action needed
          break;
      }
      return;
    }

    // Handle regular notification clicks based on type
    switch (data.type) {
      case NotificationTypeEnum.foreground:
        _showInAppNotification(data);
        break;
      case NotificationTypeEnum.background:
      case NotificationTypeEnum.terminated:
        if (!isInitial) {
          _navigateToScreen(data);
        }
        break;
    }

    // Handle specific notification categories
    if (data.category == 'promotion') {
      _showPromotionDialog(data);
    } else if (data.category == 'message') {
      _showMessageDialog(data);
    }
  }

  void _showInAppNotification(NotificationData data) {
    debugPrint('Showing in-app notification: ${data.title}');
    // In a real app, you might show a snackbar or overlay
  }

  void _navigateToScreen(NotificationData data) {
    debugPrint('Navigating to screen for notification: ${data.title}');
    // In a real app, you would navigate to the appropriate screen
  }

  void _showReplyDialog(Map<String, dynamic>? payload) {
    debugPrint('Showing reply dialog for payload: $payload');
    // In a real app, show a dialog for replying
  }

  void _navigateToProfile(Map<String, dynamic>? payload) {
    debugPrint('Navigating to profile for payload: $payload');
    // In a real app, navigate to user profile
  }

  void _makePhoneCall(Map<String, dynamic>? payload) async {
    final phoneNumber = payload?['phone_number'];
    if (phoneNumber != null) {
      final Uri url = Uri.parse('tel:$phoneNumber');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    }
  }

  void _showPromotionDialog(NotificationData data) {
    debugPrint('Showing promotion dialog: ${data.title}');
    // In a real app, show promotion details
  }

  void _showMessageDialog(NotificationData data) {
    debugPrint('Showing message dialog: ${data.title}');
    // In a real app, show message details
  }

  // ===== DEMO METHODS FOR SHOWCASING FEATURES =====

  Future<void> sendTestNotification() async {
    await _messagingHandler.showNotificationWithActions(
      title: 'Test Notification',
      body: 'This is a test notification with actions',
      actions: [
        NotificationAction(
          id: 'reply',
          title: 'Reply',
          payload: {'action': 'reply', 'message_id': 'test_123'},
        ),
        NotificationAction(
          id: 'view',
          title: 'View Details',
          destructive: false,
        ),
      ],
      payload: {'test': true, 'timestamp': DateTime.now().toIso8601String()},
      channelId: 'actions_channel',
    );
  }

  Future<void> scheduleTestNotification() async {
    final scheduledTime = DateTime.now().add(const Duration(minutes: 1));
    await _messagingHandler.scheduleNotification(
      id: 1,
      title: 'Scheduled Notification',
      body: 'This notification was scheduled 1 minute ago',
      scheduledDate: scheduledTime,
      channelId: 'scheduled_channel',
      payload: {
        'scheduled': true,
        'scheduled_time': scheduledTime.toIso8601String(),
      },
    );
  }

  Future<void> scheduleRecurringNotification() async {
    await _messagingHandler.scheduleRecurringNotification(
      id: 2,
      title: 'Daily Reminder',
      body: 'This is your daily reminder',
      repeatInterval: 'daily',
      hour: 9,
      minute: 0,
      channelId: 'scheduled_channel',
      payload: {'recurring': true, 'type': 'daily_reminder'},
    );
  }

  Future<void> createNotificationGroup() async {
    final notifications = [
      NotificationData(
        title: 'Message 1',
        body: 'Hello from user 1',
        payload: {'message_id': '1', 'user': 'user1'},
      ),
      NotificationData(
        title: 'Message 2',
        body: 'Hello from user 2',
        payload: {'message_id': '2', 'user': 'user2'},
      ),
      NotificationData(
        title: 'Message 3',
        body: 'Hello from user 3',
        payload: {'message_id': '3', 'user': 'user3'},
      ),
    ];

    await _messagingHandler.createNotificationGroup(
      groupKey: 'messages_demo',
      groupTitle: 'Demo Messages',
      notifications: notifications,
      channelId: 'default_channel',
    );
  }

  Future<void> updateBadges() async {
    await _messagingHandler.setIOSBadgeCount(5);
    await _messagingHandler.setAndroidBadgeCount(3);
    _notificationProvider.setIOSBadgeCount(5);
    _notificationProvider.setAndroidBadgeCount(3);
  }

  Future<void> clearAllNotifications() async {
    await _messagingHandler.cancelAllScheduledNotifications();
    _notificationProvider.clearNotifications();
    await _messagingHandler.clearBadgeCount();
    _notificationProvider.clearBadges();
  }

  Future<String?> getCurrentFcmToken() async {
    return await _messagingHandler.getFcmToken();
  }

  Future<void> dispose() async {
    await _messagingHandler.dispose();
  }

  // Public accessor for messaging handler (for advanced usage)
  FirebaseMessagingHandler get messagingHandler => _messagingHandler;
}
