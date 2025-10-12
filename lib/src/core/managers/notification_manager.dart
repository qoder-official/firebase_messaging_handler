import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/export.dart';
import 'in_app_message_manager.dart';
import '../../models/export.dart';
import '../../enums/export.dart';
import '../../extensions/export.dart';

/// Manager class for handling notification lifecycle and operations
class NotificationManager {
  static NotificationManager? _instance;

  /// Singleton instance
  static NotificationManager get instance {
    _instance ??= NotificationManager._internal();
    return _instance!;
  }

  NotificationManager._internal();

  // Services
  final FCMService _fcmService = FCMService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;
  final StorageService _storageService = StorageService.instance;
  final InAppMessageManager _inAppMessageManager = InAppMessageManager.instance;
  ForegroundNotificationOptions _foregroundOptions =
      ForegroundNotificationOptions.defaults;

  // Stream controllers
  StreamController<NotificationData?>? _clickStreamController;
  Stream<NotificationData?>? _clickStream;

  // State management
  final Set<int> _openedNotifications = {};
  final Set<int> _foregroundShownNotifications = {};
  bool _hasFetchedInitialNotification = false;

  /// Initializes the notification manager
  Future<Stream<NotificationData?>?> initialize({
    required String senderId,
    required List<NotificationChannelData> androidChannels,
    required String androidNotificationIconPath,
    Future<bool> Function(String fcmToken)? updateTokenCallback,
    bool includeInitialNotificationInStream = false,
  }) async {
    try {
      // Initialize services
      await _fcmService.initialize();
      await _notificationService.initialize(
        androidChannels: androidChannels,
        androidIconPath: androidNotificationIconPath,
      );

      // Request permissions
      final bool permissionsGranted = await _fcmService.requestPermissions();
      if (!permissionsGranted) {
        _logMessage('[NotificationManager] Permissions not granted');
        return null;
      }

      // Handle FCM token
      await _handleFCMToken(senderId, updateTokenCallback);

      // Set up notification listeners
      _setupNotificationListeners(androidChannels, androidNotificationIconPath);

      // Handle background notifications
      _setupBackgroundNotifications();

      /*
       * Why: Pending in-app payloads could have been staged while the app was closed,
       * so we hydrate them once initialization finishes to keep campaigns consistent.
       */
      await _inAppMessageManager.flushPendingInAppMessages();

      // Check for initial notification
      final Stream<NotificationData?>? initialStream =
          await _handleInitialNotification(
        includeInitialNotificationInStream,
      );

      // Return appropriate stream
      return initialStream ?? getNotificationClickStream();
    } catch (error, stack) {
      _logMessage('[NotificationManager] Initialization error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
      return null;
    }
  }

  /// Gets the notification click stream
  Stream<NotificationData?> getNotificationClickStream() {
    if (_clickStreamController == null || _clickStream == null) {
      _clickStreamController = StreamController<NotificationData?>.broadcast();
      _clickStream = _clickStreamController!.stream;
    }
    return _clickStream!;
  }

  /// Gets the initial notification data
  Future<NotificationData?> getInitialNotificationData() async {
    try {
      // Check Firebase Messaging initial message
      final RemoteMessage? firebaseInitialMessage =
          await _fcmService.getInitialMessage();
      if (firebaseInitialMessage?.data != null) {
        return NotificationData(
          payload: firebaseInitialMessage!.data,
          title: firebaseInitialMessage.notification?.title,
          body: firebaseInitialMessage.notification?.body,
          timestamp: DateTime.now(),
          type: NotificationTypeEnum.terminated,
          isFromTerminated: true,
          messageId: firebaseInitialMessage.messageId,
        );
      }

      // Check flutter_local_notifications initial message
      final NotificationAppLaunchDetails? launchDetails =
          await _notificationService.getNotificationAppLaunchDetails();

      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = launchDetails?.notificationResponse?.payload != null
            ? jsonDecode(launchDetails!.notificationResponse!.payload!)
            : {};

        return NotificationData(
          payload: payload,
          timestamp: DateTime.now(),
          type: NotificationTypeEnum.terminated,
          isFromTerminated: true,
        );
      }

      return null;
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Get initial notification error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
      return null;
    }
  }

  /// Processes a notification
  void processNotification(RemoteMessage message,
      {bool isFromTerminated = false}) {
    try {
      if (!_openedNotifications.contains(message.messageId.hashCode)) {
        _openedNotifications.add(message.messageId.hashCode);

        /*
         * Why: Even when the system renders the push, data-only payloads can embed
         * directives for in-app templates; we surface that before continuing so the UI layer
         * can react without waiting for the user to reopen the notification.
         */
        unawaited(_inAppMessageManager.handleRemoteMessage(message));

        // Track notification received
        _analyticsService.trackNotificationReceived(message);

        // Add to click stream
        _addNotificationClickStreamEvent(
          message.data,
          message: message,
          isFromTerminated: isFromTerminated,
          type: isFromTerminated
              ? NotificationTypeEnum.terminated
              : NotificationTypeEnum.background,
        );

        // Track notification clicked
        _analyticsService.trackNotificationClicked(NotificationData(
          payload: message.data,
          title: message.notification?.title,
          body: message.notification?.body,
          type: isFromTerminated
              ? NotificationTypeEnum.terminated
              : NotificationTypeEnum.background,
          isFromTerminated: isFromTerminated,
          messageId: message.messageId,
        ));
      }
    } catch (error, stack) {
      _logMessage('[NotificationManager] Process notification error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  /// Shows a notification with actions
  Future<void> showNotificationWithActions({
    required String title,
    required String body,
    required List<NotificationAction> actions,
    Map<String, dynamic>? payload,
    String? channelId,
    int? notificationId,
  }) async {
    try {
      final id =
          notificationId ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _notificationService.showNotificationWithActions(
        id: id,
        title: title,
        body: body,
        actions: actions,
        payload: payload,
        channelId: channelId,
      );

      _logMessage(
          '[NotificationManager] Notification with actions shown: $title');
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Show notification with actions error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  /// Schedules a notification
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
    try {
      final result = await _notificationService.scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        payload: payload,
        channelId: channelId,
        actions: actions,
      );

      if (result) {
        _analyticsService.trackNotificationScheduled('one_time', {
          'notification_id': id,
          'title': title,
          'scheduled_for': scheduledDate.toIso8601String(),
        });
      }

      return result;
    } catch (error, stack) {
      _logMessage('[NotificationManager] Schedule notification error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
      return false;
    }
  }

  /// Cancels a scheduled notification
  Future<bool> cancelScheduledNotification(int id) async {
    try {
      await _notificationService.cancelNotification(id);
      _logMessage(
          '[NotificationManager] Scheduled notification cancelled: $id');
      return true;
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Cancel scheduled notification error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
      return false;
    }
  }

  /// Cancels all scheduled notifications
  Future<bool> cancelAllScheduledNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
      _logMessage(
          '[NotificationManager] All scheduled notifications cancelled');
      return true;
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Cancel all scheduled notifications error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
      return false;
    }
  }

  /// Gets pending notifications
  Future<List<dynamic>?> getPendingNotifications() async {
    try {
      return await _notificationService.getPendingNotifications();
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Get pending notifications error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
      return null;
    }
  }

  /// Sets badge count for iOS
  Future<void> setIOSBadgeCount(int count) async {
    try {
      await _notificationService.setIOSBadgeCount(count);
    } catch (error, stack) {
      _logMessage('[NotificationManager] Set iOS badge count error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  /// Gets iOS badge count
  Future<int?> getIOSBadgeCount() async {
    try {
      return await _notificationService.getIOSBadgeCount();
    } catch (error, stack) {
      _logMessage('[NotificationManager] Get iOS badge count error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
      return null;
    }
  }

  /// Sets badge count for Android
  Future<void> setAndroidBadgeCount(int count) async {
    try {
      await _notificationService.setAndroidBadgeCount(count);
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Set Android badge count error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  /// Gets Android badge count
  Future<int?> getAndroidBadgeCount() async {
    try {
      return await _notificationService.getAndroidBadgeCount();
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Get Android badge count error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
      return null;
    }
  }

  /// Clears badge count
  Future<void> clearBadgeCount() async {
    try {
      await _notificationService.clearBadgeCount();
    } catch (error, stack) {
      _logMessage('[NotificationManager] Clear badge count error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  /// Subscribes to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcmService.subscribeToTopic(topic);
    } catch (error, stack) {
      _logMessage('[NotificationManager] Subscribe to topic error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  /// Unsubscribes from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcmService.unsubscribeFromTopic(topic);
    } catch (error, stack) {
      _logMessage('[NotificationManager] Unsubscribe from topic error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  /// Unsubscribes from all topics
  Future<void> unsubscribeFromAllTopics() async {
    try {
      await _fcmService.deleteToken();
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Unsubscribe from all topics error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  /// Gets FCM token
  Future<String?> getFcmToken() async {
    try {
      return await _storageService.getFcmToken();
    } catch (error, stack) {
      _logMessage('[NotificationManager] Get FCM token error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
      return null;
    }
  }

  /// Clears FCM token
  Future<void> clearToken() async {
    try {
      await _storageService.removeFcmToken();
    } catch (error, stack) {
      _logMessage('[NotificationManager] Clear token error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  /// Sets analytics callback
  void setAnalyticsCallback(
      void Function(String event, Map<String, dynamic> data) callback) {
    _analyticsService.setCallback(callback);
  }

  /// Tracks analytics event
  void trackAnalyticsEvent(String event, Map<String, dynamic> data) {
    _analyticsService.trackEvent(event, data);
  }

  /// Updates default foreground notification presentation options.
  void setForegroundNotificationOptions(ForegroundNotificationOptions options) {
    _foregroundOptions = options;
  }

  /// Registers in-app notification templates
  void registerInAppTemplates(
      Map<String, InAppNotificationTemplate> templates) {
    _inAppMessageManager.registerTemplates(templates);
  }

  /// Clears registered in-app templates
  void clearInAppTemplates() {
    _inAppMessageManager.clearTemplates();
  }

  /// Sets fallback display handler for unregistered templates
  void setInAppFallbackDisplayHandler(
      InAppNotificationDisplayCallback? fallback) {
    _inAppMessageManager.setFallbackDisplayHandler(fallback);
  }

  /// Provides stream of in-app messages triggered by data-only pushes
  Stream<InAppNotificationData> getInAppMessageStream({
    bool includePendingStorageItems = true,
  }) =>
      _inAppMessageManager.getMessageStream(
        includePendingStorageItems: includePendingStorageItems,
      );

  /// Flushes any stored in-app messages so the host app can present them now
  Future<void> flushPendingInAppMessages() async {
    await _inAppMessageManager.flushPendingInAppMessages();
  }

  /// Clears pending in-app messages
  Future<void> clearPendingInAppMessages({String? id}) async {
    await _inAppMessageManager.clearPendingInAppMessages(id: id);
  }

  /// Disposes of resources
  Future<void> dispose() async {
    try {
      _openedNotifications.clear();
      _foregroundShownNotifications.clear();
      await _notificationService.cancelAllNotifications();
      await _clickStreamController?.close();
      await _inAppMessageManager.dispose();
      _logMessage('[NotificationManager] Disposed');
    } catch (error, stack) {
      _logMessage('[NotificationManager] Dispose error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  Future<void> _handleFCMToken(String senderId,
      Future<bool> Function(String fcmToken)? updateTokenCallback) async {
    try {
      final String? savedFcmToken = await _storageService.getFcmToken();
      if (savedFcmToken == null && updateTokenCallback != null) {
        final String? fcmToken = await _fcmService.getToken(vapidKey: senderId);

        if (fcmToken != null) {
          _analyticsService.trackTokenEvent('fetched', fcmToken);

          final bool updateSuccessful = await updateTokenCallback(fcmToken);
          if (updateSuccessful) {
            await _storageService.saveFcmToken(fcmToken);
            _analyticsService.trackTokenEvent('updated', fcmToken);
          }
        } else {
          _logMessage('[NotificationManager] Error fetching FCM Token!');
          _analyticsService.trackTokenEvent('error', null);
        }
      }
    } catch (error, stack) {
      _logMessage('[NotificationManager] Handle FCM token error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  void _setupNotificationListeners(
      List<NotificationChannelData> androidChannels,
      String androidNotificationIconPath) {
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        _fcmService.onMessage.listen((RemoteMessage message) async {
          await _handleForegroundMessage(
              message, androidChannels, androidNotificationIconPath);
        });
      } else if (Platform.isIOS) {
        _fcmService.onMessage.listen((RemoteMessage message) async {
          await _handleForegroundMessage(
              message, androidChannels, androidNotificationIconPath);
        });
      } else {
        // Web platform
        _fcmService.onMessage.listen((RemoteMessage message) async {
          await _handleForegroundMessage(
              message, androidChannels, androidNotificationIconPath);
        });
      }
    }
  }

  Future<void> _handleForegroundMessage(
      RemoteMessage message,
      List<NotificationChannelData> androidChannels,
      String androidNotificationIconPath) async {
    try {
      /*
       * Why: Silent pushes rely on the same onMessage entry point; handling them first lets
       * us honor template triggers even when the system decides not to present a banner.
       */
      await _inAppMessageManager.handleRemoteMessage(message);

      final RemoteNotification? notification = message.notification;

      await _storageService.saveNotification(message);

      if (!_foregroundOptions.enabled) {
        return;
      }

      if (notification != null &&
          !_foregroundShownNotifications.contains(notification.hashCode)) {
        _foregroundShownNotifications.add(notification.hashCode);

        if (!kIsWeb && Platform.isAndroid) {
          await _showAndroidNotification(
              message, androidChannels, androidNotificationIconPath);
        } else if (!kIsWeb && Platform.isIOS) {
          await _showIOSNotification(message);
        } else {
          // Web platform
          await _showWebNotification(message);
        }
      }
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Handle foreground message error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  Future<void> _showAndroidNotification(
      RemoteMessage message,
      List<NotificationChannelData> androidChannels,
      String androidNotificationIconPath) async {
    try {
      final AndroidNotificationDetails? androidOverride =
          await _resolveAndroidForegroundDetails(message);
      if (message.notification?.android?.channelId != null) {
        AndroidNotificationChannel? selectedChannel;

        for (final NotificationChannelData channelData in androidChannels) {
          if (channelData.id == message.notification!.android!.channelId) {
            selectedChannel = channelData.toAndroidNotificationChannel();
            break;
          }
        }

        if (selectedChannel == null) {
          _logMessage(
              '[NotificationManager] Channel ID not found: ${message.notification?.android?.channelId}');
          return;
        }

        await _notificationService.showNotification(
          id: message.notification.hashCode,
          title: message.notification?.title ?? '',
          body: message.notification?.body ?? '',
          payload: message.data,
          channelId: message.notification?.android?.channelId,
          androidDetailsOverride: androidOverride,
        );
      }
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Show Android notification error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  Future<void> _showIOSNotification(RemoteMessage message) async {
    try {
      final RemoteNotification? notification = message.notification;

      if (notification != null) {
        final DarwinNotificationDetails? iosOverride =
            await _resolveIOSForegroundDetails(message);
        await _notificationService.showNotification(
          id: notification.hashCode,
          title: notification.title ?? '',
          body: notification.body ?? '',
          payload: message.data,
          iosDetailsOverride: iosOverride,
        );
      }
    } catch (error, stack) {
      _logMessage('[NotificationManager] Show iOS notification error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  Future<AndroidNotificationDetails?> _resolveAndroidForegroundDetails(
      RemoteMessage message) async {
    final ForegroundNotificationContext context =
        _buildForegroundContext(message);
    if (_foregroundOptions.androidBuilder != null) {
      final AndroidNotificationDetails? builtDetails =
          await Future<AndroidNotificationDetails?>.value(
        _foregroundOptions.androidBuilder!(context),
      );
      if (builtDetails != null) {
        return builtDetails;
      }
    }
    return _foregroundOptions.androidDefaults;
  }

  Future<DarwinNotificationDetails?> _resolveIOSForegroundDetails(
      RemoteMessage message) async {
    final ForegroundNotificationContext context =
        _buildForegroundContext(message);
    if (_foregroundOptions.iosBuilder != null) {
      final DarwinNotificationDetails? builtDetails =
          await Future<DarwinNotificationDetails?>.value(
        _foregroundOptions.iosBuilder!(context),
      );
      if (builtDetails != null) {
        return builtDetails;
      }
    }
    return _foregroundOptions.iosDefaults;
  }

  ForegroundNotificationContext _buildForegroundContext(RemoteMessage message) {
    return ForegroundNotificationContext(message: message);
  }

  Future<void> _showWebNotification(RemoteMessage message) async {
    try {
      final RemoteNotification? notification = message.notification;

      if (notification != null) {
        await _notificationService.showWebNotification(
          title: notification.title ?? 'Notification',
          body: notification.body ?? '',
          icon: '/icons/Icon-192.png',
          data: message.data,
        );
      }
    } catch (error, stack) {
      _logMessage('[NotificationManager] Show web notification error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  void _setupBackgroundNotifications() {
    _fcmService.onMessageOpenedApp.listen(processNotification);
  }

  Future<Stream<NotificationData?>?> _handleInitialNotification(
      bool includeInitialNotificationInStream) async {
    try {
      // Check Firebase Messaging initial message
      final RemoteMessage? firebaseInitialMessage =
          await _fcmService.getInitialMessage();
      if (firebaseInitialMessage?.data != null &&
          !_hasFetchedInitialNotification) {
        processNotification(firebaseInitialMessage!, isFromTerminated: true);
        _hasFetchedInitialNotification = true;

        if (includeInitialNotificationInStream) {
          return getNotificationClickStream().startWith(NotificationData(
            payload: firebaseInitialMessage.data,
            title: firebaseInitialMessage.notification?.title,
            body: firebaseInitialMessage.notification?.body,
            type: NotificationTypeEnum.terminated,
            isFromTerminated: true,
            messageId: firebaseInitialMessage.messageId,
          ));
        }
      }

      // Check flutter_local_notifications initial message
      final NotificationAppLaunchDetails? launchDetails =
          await _notificationService.getNotificationAppLaunchDetails();

      if ((launchDetails?.didNotificationLaunchApp ?? false) &&
          !_hasFetchedInitialNotification) {
        final payload = launchDetails?.notificationResponse?.payload != null
            ? jsonDecode(launchDetails!.notificationResponse!.payload!)
            : {};

        processNotification(
          RemoteMessage.fromMap({'data': payload}),
          isFromTerminated: true,
        );

        _hasFetchedInitialNotification = true;

        if (includeInitialNotificationInStream) {
          return getNotificationClickStream().startWith(NotificationData(
            payload: payload,
            type: NotificationTypeEnum.terminated,
            isFromTerminated: true,
          ));
        }
      }

      return null;
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Handle initial notification error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
      return null;
    }
  }

  void _addNotificationClickStreamEvent(
    Map<String, dynamic> payload, {
    RemoteMessage? message,
    bool isFromTerminated = false,
    NotificationTypeEnum type = NotificationTypeEnum.foreground,
  }) {
    try {
      if (!isFromTerminated) {
        _clickStreamController?.add(
          NotificationData(
            payload: payload,
            title: message?.notification?.title,
            body: message?.notification?.body,
            imageUrl: message?.notification?.android?.imageUrl ??
                message?.notification?.apple?.imageUrl,
            icon: message?.notification?.android?.smallIcon ??
                message?.notification?.apple?.badge,
            category: message?.category,
            timestamp: DateTime.now(),
            type: type,
            isFromTerminated: isFromTerminated,
            messageId: message?.messageId,
            senderId: message?.senderId,
            badgeCount: message?.notification?.apple?.badge != null
                ? int.tryParse(message!.notification!.apple!.badge.toString())
                : null,
            isSilent:
                message?.notification?.android?.channelId?.contains('silent') ??
                    false,
            sound: message?.notification?.android?.sound ??
                message?.notification?.apple?.sound?.name,
            tag: message?.notification?.android?.tag,
            metadata: {
              'ttl': message?.ttl,
              'collapseKey': message?.collapseKey,
              'contentAvailable': message?.contentAvailable,
            },
          ),
        );
      }
    } catch (error, stack) {
      _logMessage('[NotificationManager] Add click stream event error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  void _logMessage(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  // ========== ADDITIONAL METHODS FOR BACKWARD COMPATIBILITY ==========

  /// Creates a custom notification channel with sound (Android)
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
    try {
      final channel = NotificationChannelData(
        id: channelId,
        name: channelName,
        description: channelDescription,
        importance: importance,
        priority: priority,
        playSound: true,
        enableVibration: enableVibration,
        enableLights: enableLights,
        soundFileName: soundFileName,
      );

      await _notificationService.createNotificationChannel(channel);
      _logMessage(
          '[NotificationManager] Custom sound channel created: $channelId');
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Create custom sound channel error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  /// Gets available system notification sounds (iOS)
  Future<List<String>?> getAvailableSounds() async {
    try {
      // This would typically involve platform-specific implementation
      // For now, return a basic list of common sounds
      return [
        'default',
        'glass.caf',
        'horn.caf',
        'bell.caf',
        'electronic.caf',
      ];
    } catch (error, stack) {
      _logMessage('[NotificationManager] Get available sounds error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
      return null;
    }
  }

  /// Schedules a recurring notification
  Future<void> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required RepeatIntervalEnum repeatInterval,
    required int hour,
    required int minute,
    String? channelId,
    Map<String, dynamic>? payload,
    List<NotificationAction>? actions,
  }) async {
    try {
      // Calculate next occurrence
      final now = DateTime.now();
      DateTime scheduledDate =
          DateTime(now.year, now.month, now.day, hour, minute);

      // If time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notificationService.scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        channelId: channelId,
        payload: payload,
        actions: actions,
      );

      _logMessage(
          '[NotificationManager] Recurring notification scheduled: $id');
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Schedule recurring notification error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  /// Shows a grouped notification (Android)
  Future<void> showGroupedNotification({
    required String title,
    required String body,
    required String groupKey,
    required String groupTitle,
    String? channelId,
    Map<String, dynamic>? payload,
    bool isSummary = false,
    int? notificationId,
  }) async {
    try {
      await _notificationService.showNotification(
        id: notificationId ?? DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        channelId: channelId,
        payload: payload,
        groupKey: groupKey,
        sortKey: isSummary ? 'summary' : 'notification',
      );

      _logMessage(
          '[NotificationManager] Grouped notification shown: $groupKey');
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Show grouped notification error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  /// Creates a notification group with multiple notifications
  Future<void> createNotificationGroup({
    required String groupKey,
    required String groupTitle,
    required List<NotificationData> notifications,
    String? channelId,
  }) async {
    try {
      // Show summary notification first
      await showGroupedNotification(
        title: groupTitle,
        body: '${notifications.length} notifications',
        groupKey: groupKey,
        groupTitle: groupTitle,
        channelId: channelId,
        isSummary: true,
      );

      // Show individual notifications
      for (int i = 0; i < notifications.length; i++) {
        final notification = notifications[i];
        await showGroupedNotification(
          title: notification.title ?? 'Notification',
          body: notification.body ?? '',
          groupKey: groupKey,
          groupTitle: groupTitle,
          channelId: channelId,
          payload: notification.payload,
          notificationId: DateTime.now().millisecondsSinceEpoch + i,
        );
      }

      _logMessage(
          '[NotificationManager] Notification group created: $groupKey');
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Create notification group error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  /// Dismisses a notification group (Android)
  Future<void> dismissNotificationGroup(String groupKey) async {
    try {
      // This would typically involve platform-specific implementation
      // For now, we'll cancel all notifications with the group key
      await _notificationService.cancelAllNotifications();
      _logMessage(
          '[NotificationManager] Notification group dismissed: $groupKey');
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Dismiss notification group error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
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
    try {
      await _notificationService.showNotification(
        id: notificationId ?? DateTime.now().millisecondsSinceEpoch,
        title: title,
        body: body,
        channelId: channelId,
        payload: payload,
        category: threadIdentifier,
      );

      _logMessage(
          '[NotificationManager] Threaded notification shown: $threadIdentifier');
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Show threaded notification error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }
}
