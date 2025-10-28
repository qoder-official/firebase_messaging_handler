library firebase_messaging_handler;

import 'dart:async';
import 'src/export.dart';
import 'src/core/export.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
export 'src/enums/export.dart';
export 'src/models/export.dart';
export 'src/core/export.dart';
export 'src/in_app/export.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingHandlerBackgroundDispatcher(
    RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseMessagingHandler.handleBackgroundMessage(message);
}

/// A comprehensive Firebase Cloud Messaging handler for Flutter applications.
///
/// This class provides a one-stop solution for all FCM operations including:
/// - Notification handling (foreground, background, terminated)
/// - Token management and topic subscriptions
/// - Notification scheduling and actions
/// - Badge management and analytics
/// - Cross-platform support (Android, iOS, Web)
///
/// The handler uses a modular architecture with clear separation of concerns
/// for better maintainability, testability, and extensibility.
class FirebaseMessagingHandler {
  // Singleton instance
  static final FirebaseMessagingHandler instance =
      FirebaseMessagingHandler._internal();

  // Private constructor for internal use
  FirebaseMessagingHandler._internal();

  // Core manager for notification operations
  final NotificationManager _notificationManager = NotificationManager.instance;

  static bool _testModeEnabled = false;
  static StreamController<RemoteMessage>? _mockRemoteMessageController;
  static StreamController<NotificationData>? _mockClickController;

  /// Initializes the Firebase Cloud Messaging handler with necessary configurations.
  ///
  /// This method sets up all FCM services including:
  /// - Firebase Messaging initialization
  /// - Local notification service setup
  /// - Permission requests
  /// - Token management
  /// - Notification listeners
  ///
  /// Returns a stream of notification click events that can be listened to
  /// for handling user interactions with notifications.
  Future<Stream<NotificationData?>?> init({
    required final String senderId,
    required final List<NotificationChannelData> androidChannelList,
    required final String androidNotificationIconPath,
    final Future<bool> Function(String fcmToken)? updateTokenCallback,
    final bool includeInitialNotificationInStream = false,
  }) async {
    return await _notificationManager.initialize(
      senderId: senderId,
      androidChannels: androidChannelList,
      androidNotificationIconPath: androidNotificationIconPath,
      updateTokenCallback: updateTokenCallback,
      includeInitialNotificationInStream: includeInitialNotificationInStream,
    );
  }

  /// Gets the initial notification data if the app was launched from a notification.
  ///
  /// This is useful when you want to handle initial notifications separately from the stream.
  /// Returns null if the app was not launched from a notification.
  static Future<NotificationData?> checkInitial() async {
    // Try immediately first
    var result = await NotificationManager.getInitialNotificationDataStatic();
    if (result != null) {
      return result;
    }

    // If not found immediately, wait a bit and try again (iOS timing issue)
    await Future.delayed(const Duration(milliseconds: 500));

    result = await NotificationManager.getInitialNotificationDataStatic();
    return result;
  }

  /// Disposes of the notification handler resources.
  ///
  /// This method should be called when the app is being disposed to clean up
  /// resources and prevent memory leaks.
  Future<void> dispose() async {
    await _notificationManager.dispose();
  }

  /// Removes the stored FCM token.
  ///
  /// This will unsubscribe the device from all topics and clear the local token.
  Future<void> clearToken() async {
    await _notificationManager.clearToken();
  }

  /// Subscribes the device to the specified FCM topic.
  ///
  /// Topics allow you to send messages to multiple devices that have opted in
  /// to a particular topic. Use topics for user segments or interest-based messaging.
  Future<void> subscribeToTopic(String topic) async {
    await _notificationManager.subscribeToTopic(topic);
  }

  /// Unsubscribes the device from the specified FCM topic.
  ///
  /// This will stop the device from receiving messages sent to the specified topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await _notificationManager.unsubscribeFromTopic(topic);
  }

  /// Unsubscribes the device from all FCM topics and clears the token.
  ///
  /// This will stop the device from receiving all topic-based messages and
  /// clear the FCM token, effectively disabling all push notifications.
  Future<void> unsubscribeFromAllTopics() async {
    await _notificationManager.unsubscribeFromAllTopics();
  }

  /// Sets the badge count for iOS notifications.
  ///
  /// The badge count appears on the app icon and indicates the number of
  /// unread notifications or items requiring attention.
  Future<void> setIOSBadgeCount(int count) async {
    await _notificationManager.setIOSBadgeCount(count);
  }

  /// Gets the current badge count for iOS notifications.
  ///
  /// Returns the current badge count displayed on the app icon.
  Future<int?> getIOSBadgeCount() async {
    return await _notificationManager.getIOSBadgeCount();
  }

  /// Sets the badge count for Android notifications.
  ///
  /// Android badge support varies by device manufacturer and launcher.
  /// This method provides a consistent interface across platforms.
  Future<void> setAndroidBadgeCount(int count) async {
    await _notificationManager.setAndroidBadgeCount(count);
  }

  /// Gets the current badge count for Android notifications.
  ///
  /// Returns the current badge count if supported by the device.
  Future<int?> getAndroidBadgeCount() async {
    return await _notificationManager.getAndroidBadgeCount();
  }

  /// Clears the badge count for both platforms.
  ///
  /// This will remove the badge indicator from the app icon on both
  /// iOS and Android devices.
  Future<void> clearBadgeCount() async {
    await _notificationManager.clearBadgeCount();
  }

  /// Creates a notification channel with custom sound (Android)
  Future<void> createCustomSoundChannel({
    required String channelId,
    required String channelName,
    required String channelDescription,
    required String soundFileName,
    NotificationImportanceEnum importance = NotificationImportanceEnum.high,
    NotificationPriorityEnum priority = NotificationPriorityEnum.high,
    bool enableVibration = true,
    bool enableLights = true,
  }) async {
    await _notificationManager.createCustomSoundChannel(
      channelId: channelId,
      channelName: channelName,
      channelDescription: channelDescription,
      soundFileName: soundFileName,
      importance: importance,
      priority: priority,
      enableVibration: enableVibration,
      enableLights: enableLights,
    );
  }

  /// Gets available system notification sounds (iOS)
  Future<List<String>?> getAvailableSounds() async {
    return await _notificationManager.getAvailableSounds();
  }

  // ========== TESTING UTILITIES ==========

  /// Enables test mode for mocking Firebase messaging in tests
  static void setTestMode(bool enabled) {
    if (_testModeEnabled == enabled) {
      return;
    }

    _testModeEnabled = enabled;

    if (enabled) {
      _mockRemoteMessageController =
          StreamController<RemoteMessage>.broadcast();
      _mockClickController = StreamController<NotificationData>.broadcast();
    } else {
      unawaited(_mockRemoteMessageController?.close());
      unawaited(_mockClickController?.close());
      _mockRemoteMessageController = null;
      _mockClickController = null;
    }
  }

  /// Gets mock notification stream for testing
  static Stream<RemoteMessage>? getMockNotificationStream() {
    return _mockRemoteMessageController?.stream;
  }

  /// Adds a mock notification to the test stream
  static void addMockNotification(RemoteMessage message) {
    if (!_testModeEnabled) {
      throw StateError(
          'Test mode is not enabled. Call setTestMode(true) before adding mock notifications.');
    }

    _mockRemoteMessageController?.add(message);
    FirebaseMessagingHandler.instance._notificationManager
        .processNotification(message);
  }

  /// Gets mock click stream for testing
  static Stream<NotificationData>? getMockClickStream() {
    return _mockClickController?.stream;
  }

  /// Adds a mock click event to the test stream
  static void addMockClickEvent(NotificationData data) {
    if (!_testModeEnabled) {
      throw StateError(
          'Test mode is not enabled. Call setTestMode(true) before adding mock click events.');
    }
    _mockClickController?.add(data);
    FirebaseMessagingHandler.instance._notificationManager.emitTestClick(data);
  }

  /// Resets all mock data for clean test state
  static void resetMockData() {
    if (!_testModeEnabled) {
      return;
    }

    unawaited(_mockRemoteMessageController?.close());
    unawaited(_mockClickController?.close());

    _mockRemoteMessageController = StreamController<RemoteMessage>.broadcast();
    _mockClickController = StreamController<NotificationData>.broadcast();
  }

  /// Creates a mock RemoteMessage for testing
  static RemoteMessage createMockRemoteMessage({
    String? messageId,
    String? title,
    String? body,
    Map<String, dynamic>? data,
    String? category,
    String? collapseKey,
    String? senderId,
    int? ttl,
  }) {
    final Map<String, dynamic> map = {
      'messageId':
          messageId ?? 'mock_message_${DateTime.now().millisecondsSinceEpoch}',
      'data': data ?? <String, dynamic>{},
      'sentTime': DateTime.now().millisecondsSinceEpoch,
      'category': category,
      'collapseKey': collapseKey,
      'senderId': senderId,
      'ttl': ttl,
      'notification': {
        'title': title,
        'body': body,
      },
    };

    map.removeWhere((_, value) => value == null);
    final Map<String, dynamic> notification =
        map['notification'] as Map<String, dynamic>;
    notification.removeWhere((_, value) => value == null);

    if (notification.isEmpty) {
      map.remove('notification');
    }

    return RemoteMessage.fromMap(map);
  }

  /// Creates a mock NotificationData for testing
  static NotificationData createMockNotificationData({
    Map<String, dynamic>? payload,
    String? title,
    String? body,
    String? imageUrl,
    NotificationTypeEnum type = NotificationTypeEnum.foreground,
    bool isFromTerminated = false,
    String? messageId,
    String? category,
    List<NotificationAction>? actions,
  }) {
    return NotificationData(
      payload: payload ?? <String, dynamic>{},
      title: title,
      body: body,
      imageUrl: imageUrl,
      type: type,
      isFromTerminated: isFromTerminated,
      messageId: messageId,
      category: category,
      actions: actions,
      timestamp: DateTime.now(),
    );
  }

  /// Shows a local notification with interactive actions.
  ///
  /// This method displays a notification with action buttons that users can tap.
  /// Actions allow users to interact with notifications without opening the app.
  Future<void> showNotificationWithActions({
    required String title,
    required String body,
    required List<NotificationAction> actions,
    Map<String, dynamic>? payload,
    String? channelId,
    int? notificationId,
  }) async {
    await _notificationManager.showNotificationWithActions(
      title: title,
      body: body,
      actions: actions,
      payload: payload,
      channelId: channelId,
      notificationId: notificationId,
    );
  }

  /// Schedules a notification to be shown at a specific time.
  ///
  /// This method allows you to schedule a local notification to be displayed
  /// at a future date and time. The notification will be shown even if the
  /// app is not running.
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? channelId,
    Map<String, dynamic>? payload,
    List<NotificationAction>? actions,
    bool allowWhileIdle = false,
  }) async {
    return await _notificationManager.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      channelId: channelId,
      payload: payload,
      actions: actions,
      allowWhileIdle: allowWhileIdle,
    );
  }

  /// Schedules a recurring notification (daily, weekly, etc.) - Simplified
  Future<bool> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required String repeatInterval, // 'daily', 'weekly', etc.
    required int hour,
    required int minute,
    String? channelId,
    Map<String, dynamic>? payload,
    List<NotificationAction>? actions,
  }) async {
    try {
      // Convert string to enum
      RepeatIntervalEnum interval;
      switch (repeatInterval.toLowerCase()) {
        case 'daily':
          interval = RepeatIntervalEnum.daily;
          break;
        case 'weekly':
          interval = RepeatIntervalEnum.weekly;
          break;
        case 'monthly':
          interval = RepeatIntervalEnum.monthly;
          break;
        case 'yearly':
          interval = RepeatIntervalEnum.yearly;
          break;
        case 'hourly':
          interval = RepeatIntervalEnum.hourly;
          break;
        case 'minutely':
          interval = RepeatIntervalEnum.minutely;
          break;
        default:
          interval = RepeatIntervalEnum.daily;
      }

      await _notificationManager.scheduleRecurringNotification(
        id: id,
        title: title,
        body: body,
        repeatInterval: interval,
        hour: hour,
        minute: minute,
        channelId: channelId,
        payload: payload,
        actions: actions,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Cancels a scheduled notification.
  ///
  /// This method cancels a previously scheduled notification by its ID.
  /// If the notification has already been shown, this method has no effect.
  Future<bool> cancelScheduledNotification(int id) async {
    return await _notificationManager.cancelScheduledNotification(id);
  }

  /// Cancels all scheduled notifications.
  ///
  /// This method cancels all pending scheduled notifications.
  /// Use this method to clear all scheduled notifications at once.
  Future<bool> cancelAllScheduledNotifications() async {
    return await _notificationManager.cancelAllScheduledNotifications();
  }

  /// Gets all pending scheduled notifications.
  ///
  /// Returns a list of all notifications that are scheduled to be shown
  /// in the future. This is primarily supported on Android.
  Future<List<dynamic>?> getPendingNotifications() async {
    return await _notificationManager.getPendingNotifications();
  }

  /// Shows a grouped notification (Android notification groups)
  Future<void> showGroupedNotification({
    required String title,
    required String body,
    required String groupKey,
    String? groupTitle,
    String? channelId,
    Map<String, dynamic>? payload,
    bool isSummary = false,
    int? notificationId,
  }) async {
    await _notificationManager.showGroupedNotification(
      title: title,
      body: body,
      groupKey: groupKey,
      groupTitle: groupTitle ?? 'Group',
      channelId: channelId,
      payload: payload,
      isSummary: isSummary,
      notificationId: notificationId,
    );
  }

  /// Creates a notification group with multiple notifications
  Future<void> createNotificationGroup({
    required String groupKey,
    required String groupTitle,
    required List<NotificationData> notifications,
    String? channelId,
  }) async {
    await _notificationManager.createNotificationGroup(
      groupKey: groupKey,
      groupTitle: groupTitle,
      notifications: notifications,
      channelId: channelId,
    );
  }

  /// Dismisses a notification group (Android)
  Future<void> dismissNotificationGroup(String groupKey) async {
    await _notificationManager.dismissNotificationGroup(groupKey);
  }

  /// Shows a threaded notification (iOS conversation threads)
  Future<void> showThreadedNotification({
    required String title,
    required String body,
    required String threadIdentifier,
    String? channelId,
    Map<String, dynamic>? payload,
    int? notificationId,
  }) async {
    await _notificationManager.showThreadedNotification(
      title: title,
      body: body,
      threadIdentifier: threadIdentifier,
      channelId: channelId,
      payload: payload,
      notificationId: notificationId,
    );
  }

  /// Gets the current FCM token.
  ///
  /// The FCM token is a unique identifier for the app instance on a device.
  /// This token is used by your server to send messages to this specific
  /// app instance.
  Future<String?> getFcmToken() async {
    return await _notificationManager.getFcmToken();
  }

  /// Sets the analytics callback function to track notification events.
  ///
  /// This callback will be invoked whenever a notification event occurs,
  /// allowing you to integrate with your analytics service of choice.
  void setAnalyticsCallback(
      void Function(String event, Map<String, dynamic> data) callback) {
    _notificationManager.setAnalyticsCallback(callback);
  }

  /// Manually tracks an analytics event.
  ///
  /// Use this method to track custom events related to notifications
  /// or FCM operations.
  void trackAnalyticsEvent(String event, Map<String, dynamic> data) {
    _notificationManager.trackAnalyticsEvent(event, data);
  }

  /// Overrides default foreground notification presentation behavior.
  ///
  /// Use this to inject rich styles (images, large icons, attachments) or
  /// disable the automatic fallback notification entirely.
  void setForegroundNotificationOptions(ForegroundNotificationOptions options) {
    _notificationManager.setForegroundNotificationOptions(options);
  }

  /// Registers in-app notification templates that can be invoked by silent pushes.
  void registerInAppNotificationTemplates(
      Map<String, InAppNotificationTemplate> templates) {
    _notificationManager.registerInAppTemplates(templates);
  }

  /// Clears all registered in-app templates.
  void clearInAppNotificationTemplates() {
    _notificationManager.clearInAppTemplates();
  }

  /// Sets a fallback handler for in-app payloads that reference unknown templates.
  void setInAppFallbackDisplayHandler(
      InAppNotificationDisplayCallback? fallbackHandler) {
    _notificationManager.setInAppFallbackDisplayHandler(fallbackHandler);
  }

  /// Exposes stream of in-app notification payloads ready to be rendered.
  Stream<InAppNotificationData> getInAppNotificationStream({
    bool includePendingStorageItems = true,
  }) {
    return _notificationManager.getInAppMessageStream(
      includePendingStorageItems: includePendingStorageItems,
    );
  }

  /// Flushes any stored in-app notifications (e.g. delivered while app was backgrounded).
  Future<void> flushPendingInAppNotifications() async {
    await _notificationManager.flushPendingInAppMessages();
  }

  /// Clears stored in-app notifications. Optionally target a single message by ID.
  Future<void> clearPendingInAppNotifications({String? id}) async {
    await _notificationManager.clearPendingInAppMessages(id: id);
  }

  /// Configures the navigator key used for advanced in-app template presentation.
  void setInAppNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _notificationManager.setInAppNavigatorKey(navigatorKey);
  }

  /// Applies delivery throttling, quiet hours, and frequency caps for in-app templates.
  Future<void> setInAppDeliveryPolicy(InAppDeliveryPolicy policy) async {
    await _notificationManager.setInAppDeliveryPolicy(policy);
  }

  /// Registers a background message handler. The handler must be a top-level or
  /// static function as required by Firebase Messaging.
  Future<void> configureBackgroundMessageHandler(
      Future<void> Function(RemoteMessage message) handler) async {
    await _notificationManager.setBackgroundMessageHandler(handler);
  }

  /// Handles a background message using the plugin's internal pipeline. This can
  /// be invoked from your top-level handler before executing custom logic.
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    await NotificationManager.instance.handleBackgroundMessage(message);
  }

  /// Registers a background processing callback that runs after the handler
  /// hydrates internal queues. Return `true` to mark the message handled, or
  /// `false` to enqueue it for retry when the app resumes.
  Future<void> configureBackgroundProcessingCallback(
      Future<bool> Function(RemoteMessage message)? callback) async {
    await _notificationManager.setBackgroundProcessingCallback(callback);
  }

  /// Sets a custom bridge for data-only messages (no notification payload).
  void setDataOnlyMessageBridge(
      Future<void> Function(RemoteMessage message)? bridge) {
    _notificationManager.setDataOnlyMessageBridge(bridge);
  }

  /// Enables the built-in bridge that promotes data-only messages to local
  /// notifications so users still see a banner.
  void enableDefaultDataOnlyBridge({
    String? channelId,
    String titleKey = 'title',
    String bodyKey = 'body',
  }) {
    _notificationManager.enableDefaultDataOnlyBridge(
      channelId: channelId,
      titleKey: titleKey,
      bodyKey: bodyKey,
    );
  }

  /// Generates a diagnostic snapshot summarizing permission status, token
  /// availability, badge support, and other platform readiness checks.
  Future<NotificationDiagnosticsResult> runDiagnostics() async {
    return await _notificationManager.runDiagnostics();
  }
}
