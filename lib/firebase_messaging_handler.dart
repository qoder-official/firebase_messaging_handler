library firebase_messaging_handler;

import 'dart:async';
import 'src/index.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
export 'src/enums/index.dart';
export 'src/models/index.dart';

/// A utility class for managing notifications, ensuring a single instance
/// through the application lifecycle using the Singleton pattern.
class FirebaseMessagingHandler {
  // Singleton instance
  static final FirebaseMessagingHandler instance =
      FirebaseMessagingHandler._internal();

  // Private constructor for internal use
  FirebaseMessagingHandler._internal();

  /// Initializes the notification utility with necessary configurations.
  Future<Stream<NotificationData?>?> init({
    required final String senderId,
    required final List<NotificationChannelData> androidChannelList,
    required final String androidNotificationIconPath,
    final Future<bool> Function(String fcmToken)? updateTokenCallback,
    final bool includeInitialNotificationInStream = false,
  }) async {
    return await FirebaseMessagingUtility.instance.init(
      senderId: senderId,
      androidChannelList: androidChannelList,
      androidNotificationIconPath: androidNotificationIconPath,
      updateTokenCallback: updateTokenCallback,
      includeInitialNotificationInStream: includeInitialNotificationInStream,
    );
  }

  Future<void> checkInitial() async {
    await FirebaseMessagingUtility.instance.checkInitial();
  }

  /// Gets the initial notification data if the app was launched from a notification.
  /// This is useful when you want to handle initial notifications separately from the stream.
  Future<NotificationData?> getInitialNotificationData() async {
    return await FirebaseMessagingUtility.instance.getInitialNotificationData();
  }

  /// Disposes of the notification utility resources.
  Future<void> dispose() async {
    await FirebaseMessagingUtility.instance.dispose();
  }

  /// Removes the stored FCM token.
  Future<void> clearToken() async {
    await FirebaseMessagingUtility.instance.clearToken();
  }

  /// Subscribes the device to the specified FCM topic.
  Future<void> subscribeToTopic(String topic) async {
    await FirebaseMessagingUtility.instance.subscribeToTopic(topic);
  }

  /// Unsubscribes the device from the specified FCM topic.
  Future<void> unsubscribeFromTopic(String topic) async {
    await FirebaseMessagingUtility.instance.unsubscribeFromTopic(topic);
  }

  /// Unsubscribes the device from all FCM topics and clears the token.
  Future<void> unsubscribeFromAllTopics() async {
    await FirebaseMessagingUtility.instance.unsubscribeFromAllTopics();
  }

  /// Sets the badge count for iOS notifications.
  Future<void> setIOSBadgeCount(int count) async {
    await FirebaseMessagingUtility.instance.setIOSBadgeCount(count);
  }

  /// Gets the current badge count for iOS notifications.
  Future<int?> getIOSBadgeCount() async {
    return await FirebaseMessagingUtility.instance.getIOSBadgeCount();
  }

  /// Sets the badge count for Android notifications.
  Future<void> setAndroidBadgeCount(int count) async {
    await FirebaseMessagingUtility.instance.setAndroidBadgeCount(count);
  }

  /// Gets the current badge count for Android notifications.
  Future<int?> getAndroidBadgeCount() async {
    return await FirebaseMessagingUtility.instance.getAndroidBadgeCount();
  }

  /// Clears the badge count for both platforms.
  Future<void> clearBadgeCount() async {
    await FirebaseMessagingUtility.instance.clearBadgeCount();
  }

  /// Shows a notification with custom sound
  Future<void> showNotificationWithCustomSound({
    required String title,
    required String body,
    required String soundFileName,
    String? channelId,
    Map<String, dynamic>? payload,
    int? notificationId,
  }) async {
    await FirebaseMessagingUtility.instance.showNotificationWithCustomSound(
      title: title,
      body: body,
      soundFileName: soundFileName,
      channelId: channelId,
      payload: payload,
      notificationId: notificationId,
    );
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
    await FirebaseMessagingUtility.instance.createCustomSoundChannel(
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
    return await FirebaseMessagingUtility.instance.getAvailableSounds();
  }

  // ========== TESTING UTILITIES ==========

  /// Enables test mode for mocking Firebase messaging in tests
  static void setTestMode(bool enabled) {
    FirebaseMessagingUtility.setTestMode(enabled);
  }

  /// Gets mock notification stream for testing
  static Stream<RemoteMessage>? getMockNotificationStream() {
    return FirebaseMessagingUtility.getMockNotificationStream();
  }

  /// Adds a mock notification to the test stream
  static void addMockNotification(RemoteMessage message) {
    FirebaseMessagingUtility.addMockNotification(message);
  }

  /// Gets mock click stream for testing
  static Stream<NotificationData>? getMockClickStream() {
    return FirebaseMessagingUtility.getMockClickStream();
  }

  /// Adds a mock click event to the test stream
  static void addMockClickEvent(NotificationData data) {
    FirebaseMessagingUtility.addMockClickEvent(data);
  }

  /// Resets all mock data for clean test state
  static void resetMockData() {
    FirebaseMessagingUtility.resetMockData();
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
    return FirebaseMessagingUtility.createMockRemoteMessage(
      messageId: messageId,
      title: title,
      body: body,
      data: data,
      category: category,
      collapseKey: collapseKey,
      senderId: senderId,
      ttl: ttl,
    );
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
    return FirebaseMessagingUtility.createMockNotificationData(
      payload: payload,
      title: title,
      body: body,
      imageUrl: imageUrl,
      type: type,
      isFromTerminated: isFromTerminated,
      messageId: messageId,
      category: category,
      actions: actions,
    );
  }

  /// Shows a local notification with interactive actions
  Future<void> showNotificationWithActions({
    required String title,
    required String body,
    required List<NotificationAction> actions,
    Map<String, dynamic>? payload,
    String? channelId,
    int? notificationId,
  }) async {
    await FirebaseMessagingUtility.instance.showNotificationWithActions(
      title: title,
      body: body,
      actions: actions,
      payload: payload,
      channelId: channelId,
      notificationId: notificationId,
    );
  }

  /// Schedules a notification to be shown at a specific time
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
    return await FirebaseMessagingUtility.instance.scheduleNotification(
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
    return await FirebaseMessagingUtility.instance
        .scheduleRecurringNotification(
      id: id,
      title: title,
      body: body,
      repeatInterval: repeatInterval,
      hour: hour,
      minute: minute,
      channelId: channelId,
      payload: payload,
      actions: actions,
    );
  }

  /// Cancels a scheduled notification
  Future<bool> cancelScheduledNotification(int id) async {
    return await FirebaseMessagingUtility.instance
        .cancelScheduledNotification(id);
  }

  /// Cancels all scheduled notifications
  Future<bool> cancelAllScheduledNotifications() async {
    return await FirebaseMessagingUtility.instance
        .cancelAllScheduledNotifications();
  }

  /// Gets all pending scheduled notifications (Android only) - Simplified
  Future<List<dynamic>?> getPendingNotifications() async {
    return await FirebaseMessagingUtility.instance.getPendingNotifications();
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
    await FirebaseMessagingUtility.instance.showGroupedNotification(
      title: title,
      body: body,
      groupKey: groupKey,
      groupTitle: groupTitle,
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
    await FirebaseMessagingUtility.instance.createNotificationGroup(
      groupKey: groupKey,
      groupTitle: groupTitle,
      notifications: notifications,
      channelId: channelId,
    );
  }

  /// Dismisses a notification group (Android)
  Future<void> dismissNotificationGroup(String groupKey) async {
    await FirebaseMessagingUtility.instance.dismissNotificationGroup(groupKey);
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
    await FirebaseMessagingUtility.instance.showThreadedNotification(
      title: title,
      body: body,
      threadIdentifier: threadIdentifier,
      channelId: channelId,
      payload: payload,
      notificationId: notificationId,
    );
  }

  /// Sets the analytics callback function to track notification events
  void setAnalyticsCallback(
      void Function(String event, Map<String, dynamic> data) callback) {
    FirebaseMessagingUtility.instance.onAnalyticsEvent = callback;
  }

  /// Manually tracks an analytics event (for custom tracking)
  void trackAnalyticsEvent(String event, Map<String, dynamic> data) {
    FirebaseMessagingUtility.instance.trackAnalyticsEvent(event, data);
  }

  /// Gets the current FCM token
  Future<String?> getFcmToken() async {
    return await FirebaseMessagingUtility.instance.getFcmToken();
  }
}
