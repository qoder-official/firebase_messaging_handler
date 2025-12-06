import 'dart:async';
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/export.dart';
import 'in_app_message_manager.dart';
import '../../models/export.dart';
import '../../models/normalized_message.dart';
import '../../enums/export.dart';
import '../../enums/notification_lifecycle_enum.dart';
import '../utils/platform_utils.dart';
import 'badge_manager.dart';
import '../utils/bridging_payload_validator.dart';
import '../interfaces/notification_inbox_storage_interface.dart';

typedef BackgroundMessageCallback = Future<bool> Function(
    RemoteMessage message);
typedef DataOnlyMessageBridge = Future<void> Function(RemoteMessage message);
typedef UnifiedMessageHandler = Future<bool> Function(
    NormalizedMessage message, NotificationLifecycle lifecycle);

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
  final FirebaseMessagingHandlerNotificationService _notificationService =
      FirebaseMessagingHandlerNotificationService.instance;
  final FmhAnalyticsService _analyticsService = FmhAnalyticsService.instance;
  final StorageService _storageService = StorageService.instance;
  final NotificationInboxStorageInterface _inboxStorage =
      InboxStorageService();

  final InAppMessageManager _inAppMessageManager = InAppMessageManager.instance;
  final BadgeManager _badgeManager = BadgeManager.instance;
  ForegroundNotificationOptions _foregroundOptions =
      ForegroundNotificationOptions.defaults;
  UnifiedMessageHandler? _unifiedMessageHandler;
  int _invalidPayloadCount = 0;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _backgroundHandlerRegistered = false;
  BackgroundMessageCallback? _backgroundMessageCallback;
  DataOnlyMessageBridge? _dataOnlyMessageBridge;
  bool _isReplayingBackgroundQueue = false;

  // Stream controllers
  StreamController<NotificationData?>? _clickStreamController;
  Stream<NotificationData?>? _clickStream;
  final List<NotificationData?> _pendingClickEvents = <NotificationData?>[];

  // State management
  final Set<int> _openedNotifications = {};
  final Set<int> _foregroundShownNotifications = {};
  final Set<String> _persistedInboxIds = <String>{};
  bool _hasFetchedInitialNotification = false;

  /// Initializes the notification manager
  Future<Stream<NotificationData?>?> initialize({
    required String senderId,
    required List<NotificationChannelData> androidChannels,
    required String androidNotificationIconPath,
    Future<bool> Function(String fcmToken)? updateTokenCallback,
    bool includeInitialNotificationInStream = true,
  }) async {
    try {
      // Initialize services
      await _fcmService.initialize();

      // [Smart Default Channel]
      // Ensure at least one high-importance channel exists to prevent "silent" notification issues on Android.
      final List<NotificationChannelData> effectiveChannels =
          List.from(androidChannels);
      final bool hasHighImportanceChannel = effectiveChannels.any((channel) =>
          channel.importance == NotificationImportanceEnum.high ||
          channel.importance == NotificationImportanceEnum.max);

      if (!hasHighImportanceChannel) {
        _logMessage(
            '[NotificationManager] 💡 No High-Importance channel found. Auto-creating "default_channel" to ensure heads-up notifications work.');
        effectiveChannels.add(NotificationChannelData(
          id: 'default_channel',
          name: 'Default Notifications',
          description: 'Standard high-importance notifications',
          importance: NotificationImportanceEnum.high,
          priority: NotificationPriorityEnum.high,
          playSound: true,
          enableVibration: true,
        ));
      }

      await _notificationService.initialize(
        androidChannels: effectiveChannels,
        androidIconPath: androidNotificationIconPath,
      );

      // Request permissions
      final bool permissionsGranted = await _fcmService.requestPermissions();
      if (!permissionsGranted) {
        _logMessage('[NotificationManager] Permissions not granted');
        return null;
      }

      // Configure iOS foreground notification presentation options
      // Enable automatic notifications for iOS since flutter_local_notifications
      // doesn't show notifications when app is in foreground on iOS
      await _fcmService.setForegroundNotificationPresentationOptions(
        alert: true, // Enable automatic alerts (iOS only)
        badge: true, // Keep badge updates
        sound: true, // Enable automatic sounds
      );

      // Handle FCM token
      await _handleFCMToken(senderId, updateTokenCallback);

      if (updateTokenCallback != null) {
        _listenForTokenRefresh(updateTokenCallback);
      } else {
        await _tokenRefreshSubscription?.cancel();
        _tokenRefreshSubscription = null;
      }

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
      _clickStreamController = StreamController<NotificationData?>.broadcast(
        onListen: () {
          if (_pendingClickEvents.isEmpty) {
            return;
          }
          for (final NotificationData? event in List<NotificationData?>.from(
              _pendingClickEvents)) {
            _clickStreamController?.add(event);
          }
          _pendingClickEvents.clear();
        },
      );
      _clickStream = _clickStreamController!.stream;
    }
    return _clickStream!;
  }

  /// Exposes a way for tests to emit synthetic click events.
  void emitTestClick(NotificationData data) {
    getNotificationClickStream();
    _emitOrQueueClick(data);
  }

  /// Gets the initial notification data (instance wrapper)
  Future<NotificationData?> getInitialNotificationData() async {
    return await NotificationManager.getInitialNotificationDataStatic();
  }

  /// Gets the initial notification data (static, safe to call early)
  static Future<NotificationData?> getInitialNotificationDataStatic() async {
    try {
      // Check Firebase Messaging initial message
      final RemoteMessage? firebaseInitialMessage =
          await FCMService.instance.getInitialMessage();

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
          await FirebaseMessagingHandlerNotificationService.instance
              .getNotificationAppLaunchDetails();

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
      NotificationManager.instance._logMessage(
          '[NotificationManager] Get initial notification error: $error');
      NotificationManager.instance
          ._logMessage('[NotificationManager] Stack trace: $stack');
      return null;
    }
  }

  /// Processes a notification
  Future<void> processNotification(RemoteMessage message,
      {bool isFromTerminated = false,
      bool emitToClickStream = true}) async {
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

        final NotificationLifecycle lifecycle = isFromTerminated
            ? NotificationLifecycle.terminated
            : NotificationLifecycle.resume;

        unawaited(_persistInboxEntry(message, lifecycle));

        // Unified handler (resume/terminated)
        unawaited(_invokeUnifiedHandler(message, lifecycle));

        // Add to click stream
        if (emitToClickStream) {
          _addNotificationClickStreamEvent(
            message.data,
            message: message,
            isFromTerminated: isFromTerminated,
            type: isFromTerminated
                ? NotificationTypeEnum.terminated
                : NotificationTypeEnum.background,
          );
        }

        // Track notification clicked
        _analyticsService.trackNotificationClicked(message);
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
        _analyticsService.trackEvent('notification_scheduled_one_time', {
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
    await _badgeManager.setBadgeCount(count);
  }

  /// Gets iOS badge count
  Future<int?> getIOSBadgeCount() async {
    return await _badgeManager.getBadgeCount();
  }

  /// Sets badge count for Android
  Future<void> setAndroidBadgeCount(int count) async {
    await _badgeManager.setBadgeCount(count);
  }

  /// Gets Android badge count
  Future<int?> getAndroidBadgeCount() async {
    return await _badgeManager.getBadgeCount();
  }

  /// Clears badge count
  Future<void> clearBadgeCount() async {
    await _badgeManager.removeBadge();
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

  /// Sets the navigator key used for in-app template presentation.
  void setInAppNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _inAppMessageManager.setNavigatorKey(navigatorKey);
  }

  Future<void> setInAppDeliveryPolicy(InAppDeliveryPolicy policy) async {
    await _inAppMessageManager.setDeliveryPolicy(policy);
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

  Future<void> setBackgroundProcessingCallback(
      BackgroundMessageCallback? callback) async {
    _backgroundMessageCallback = callback;
    if (callback != null) {
      await _replayQueuedBackgroundMessages();
    }
  }

  void setDataOnlyMessageBridge(DataOnlyMessageBridge? bridge) {
    _dataOnlyMessageBridge = bridge;
  }

  Future<void> setUnifiedMessageHandler(
      UnifiedMessageHandler? handler) async {
    _unifiedMessageHandler = handler;
    if (handler != null) {
      await _replayQueuedBackgroundMessages();
    }
  }

  void enableDefaultDataOnlyBridge({
    String? channelId,
    String titleKey = 'title',
    String bodyKey = 'body',
  }) {
    _dataOnlyMessageBridge = (RemoteMessage message) async {
      final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
      final String? title =
          data[titleKey] as String? ?? message.notification?.title;
      final String? body =
          data[bodyKey] as String? ?? message.notification?.body;

      if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
        return;
      }

      await _notificationService.showNotification(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title ?? '',
        body: body ?? '',
        payload: data,
        channelId: channelId ?? message.notification?.android?.channelId,
      );
    };
  }

  /// Registers a background message handler. The handler must be a top-level or
  /// static function as required by Firebase Messaging.
  Future<void> setBackgroundMessageHandler(
      Future<void> Function(RemoteMessage message) handler) async {
    try {
      // Wrap the user handler so the plugin pipeline always hydrates first.
      await _fcmService.setBackgroundMessageHandler((RemoteMessage message) async {
        await handleBackgroundMessage(message);
        await handler(message);
      });
      _backgroundHandlerRegistered = true;
      _logMessage('[NotificationManager] Background handler registered');
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Register background handler error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  /// Internal handler to leverage plugin services during background delivery.
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      await _storageService.saveNotification(message);
      await _persistInboxEntry(message, NotificationLifecycle.background);
      await _inAppMessageManager.handleRemoteMessage(message);
      _analyticsService.trackNotificationReceived(message);
      await _maybeBridgeDataOnlyMessage(message);

      bool handled =
          await _invokeUnifiedHandler(message, NotificationLifecycle.background);

      if (_backgroundMessageCallback != null) {
        try {
          final bool callbackHandled = await _backgroundMessageCallback!(message);
          handled = handled && callbackHandled;
        } catch (error, stack) {
          _logMessage(
              '[NotificationManager] Background callback error: $error');
          _logMessage('[NotificationManager] Stack trace: $stack');
          handled = false;
        }
      }

      if (!handled) {
        await _queueBackgroundMessage(message);
      } else {
        await _storageService.clearQueuedBackgroundMessages(
            messageId: message.messageId);
      }
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Handle background message error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  /// Runs a best-effort diagnostics sweep and returns actionable hints.
  Future<NotificationDiagnosticsResult> runDiagnostics() async {
    try {
      final NotificationSettings settings =
          await _fcmService.getNotificationSettings();
      final bool permissionsGranted =
          _isAuthorized(settings.authorizationStatus);

      final String? storedToken = await _storageService.getFcmToken();
      final bool tokenAvailable = storedToken != null && storedToken.isNotEmpty;

      final bool badgeSupported = await _notificationService.isBadgeSupported();
      final List<dynamic> pendingNotifications =
          await _notificationService.getPendingNotifications();

      final String webPermission =
          await _notificationService.getWebNotificationPermissionStatus();
      final bool webAllowed = webPermission == 'granted';

      final Map<String, dynamic> deliveryDiagnostics =
          _inAppMessageManager.getDeliveryDiagnostics(DateTime.now());
      final int queuedBackgroundMessages =
          (await _storageService.getQueuedBackgroundMessages()).length;

      final List<String> recommendations = <String>[];

      if (!permissionsGranted) {
        recommendations.add(
            'Prompt the user for notification permissions; current status: '
            '${settings.authorizationStatus.name}.');
      }

      if (!tokenAvailable) {
        recommendations.add(
            'No stored FCM token found. Ensure init() completed and updateTokenCallback saved the token.');
      }

      if (!badgeSupported) {
        recommendations.add(
            'App icon badges are not supported on $currentPlatformName or the current launcher.');
      }

      if (isWeb && !webAllowed) {
        recommendations.add(
            'Browser notifications are currently "$webPermission". Trigger a permission prompt or guide the user to allow notifications.');
      }

      if (pendingNotifications.length > 16) {
        recommendations.add(
            'There are ${pendingNotifications.length} pending notifications queued locally. Consider pruning scheduled notifications.');
      }

      return NotificationDiagnosticsResult(
        success: true,
        permissionsGranted: permissionsGranted,
        authorizationStatus: settings.authorizationStatus.name,
        fcmTokenAvailable: tokenAvailable,
        badgeSupported: badgeSupported,
        webNotificationsAllowed: webAllowed,
        pendingNotificationCount: pendingNotifications.length,
        platform: currentPlatformName,
        recommendations: recommendations,
        metadata: {
          'alertSetting': settings.alert.name,
          'badgeSetting': settings.badge.name,
          'soundSetting': settings.sound.name,
          'showPreviews': settings.showPreviews.name,
          'providesAppNotificationSettings':
              settings.providesAppNotificationSettings.name,
          'webPermission': webPermission,
          'storedTokenPresent': tokenAvailable,
          'deliveryPolicy': deliveryDiagnostics,
          'queuedBackgroundMessages': queuedBackgroundMessages,
          'dataBridgeEnabled': _dataOnlyMessageBridge != null,
          'backgroundHandlerRegistered': _backgroundHandlerRegistered,
          'invalidPayloadCount': _invalidPayloadCount,
        },
      );
    } catch (error, stack) {
      _logMessage('[NotificationManager] Diagnostics error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
      return NotificationDiagnosticsResult.failure(
        platform: currentPlatformName,
        error: error.toString(),
      );
    }
  }

  bool _isAuthorized(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  Future<void> _maybeBridgeDataOnlyMessage(RemoteMessage message) async {
    if (_dataOnlyMessageBridge == null) {
      return;
    }
    if (message.notification != null) {
      return;
    }
    try {
      final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
      if (!_validateBridgingPayload(data)) {
        return;
      }
      await _dataOnlyMessageBridge!(message);
    } catch (error, stack) {
      _logMessage('[NotificationManager] Data-only bridge error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  bool _validateBridgingPayload(Map<String, dynamic> data) {
    return BridgingPayloadValidator.validate(
      data,
      onError: (String reason) {
        _invalidPayloadCount++;
        _logMessage('[UnifiedHandler] invalid payload: $reason');
      },
    );
  }

  Future<void> _queueBackgroundMessage(RemoteMessage message) async {
    try {
      await _storageService.saveQueuedBackgroundMessage(
        _serializeRemoteMessage(message),
      );
    } catch (error, stack) {
      _logMessage('[NotificationManager] Queue background error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  Future<void> _replayQueuedBackgroundMessages() async {
    if (_backgroundMessageCallback == null || _isReplayingBackgroundQueue) {
      return;
    }
    _isReplayingBackgroundQueue = true;
    try {
      final List<Map<String, dynamic>> queued =
          await _storageService.getQueuedBackgroundMessages();
      if (queued.isEmpty) {
        return;
      }

      for (final Map<String, dynamic> item in queued) {
        try {
          final RemoteMessage message = RemoteMessage.fromMap(item);
          final bool handled = await _backgroundMessageCallback!(message);
          if (handled) {
            await _storageService.clearQueuedBackgroundMessages(
                messageId: message.messageId);
          }
        } catch (error, stack) {
          _logMessage('[NotificationManager] Replay background error: $error');
          _logMessage('[NotificationManager] Stack trace: $stack');
        }
      }
    } finally {
      _isReplayingBackgroundQueue = false;
    }
  }

  Map<String, dynamic> _serializeRemoteMessage(RemoteMessage message) {
    final Map<String, dynamic> map = <String, dynamic>{
      'messageId': message.messageId ??
          'queued_${DateTime.now().millisecondsSinceEpoch}',
      'data': message.data,
      'sentTime': message.sentTime?.millisecondsSinceEpoch,
      'category': message.category,
      'collapseKey': message.collapseKey,
      'senderId': message.senderId,
      'ttl': message.ttl,
      'notification': message.notification == null
          ? null
          : {
              'title': message.notification?.title,
              'body': message.notification?.body,
            },
    };

    map.removeWhere((String key, dynamic value) => value == null);
    return map;
  }

  /// Disposes of resources
  Future<void> dispose() async {
    try {
      _openedNotifications.clear();
      _foregroundShownNotifications.clear();
      await _notificationService.cancelAllNotifications();
      await _clickStreamController?.close();
      await _inAppMessageManager.dispose();
      await _tokenRefreshSubscription?.cancel();
      _backgroundHandlerRegistered = false;
      _backgroundMessageCallback = null;
      _dataOnlyMessageBridge = null;
      _logMessage('[NotificationManager] Disposed');
    } catch (error, stack) {
      _logMessage('[NotificationManager] Dispose error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  Future<void> _handleFCMToken(String senderId,
      Future<bool> Function(String fcmToken)? updateTokenCallback) async {
    try {
      final String? currentToken =
          await _fcmService.getToken(vapidKey: senderId);

      if (currentToken == null) {
        _logMessage('[NotificationManager] Error fetching FCM Token!');
        _analyticsService.trackTokenEvent('error', null);
        return;
      }

      final String? storedToken = await _storageService.getFcmToken();
      if (storedToken == currentToken) {
        _logMessage('[NotificationManager] FCM token unchanged');
        return;
      }

      _analyticsService.trackTokenEvent(
        storedToken == null ? 'fetched' : 'refreshed',
        currentToken,
      );

      if (updateTokenCallback != null) {
        final bool updateSuccessful = await updateTokenCallback(currentToken);
        if (!updateSuccessful) {
          _logMessage(
              '[NotificationManager] updateTokenCallback returned false; token not persisted');
          return;
        }
      }

      await _storageService.saveFcmToken(currentToken);
      _analyticsService.trackTokenEvent('updated', currentToken);
    } catch (error, stack) {
      _logMessage('[NotificationManager] Handle FCM token error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  void _listenForTokenRefresh(
      Future<bool> Function(String fcmToken) updateTokenCallback) {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _fcmService.onTokenRefresh.listen(
      (String refreshedToken) async {
        try {
          _analyticsService.trackTokenEvent('refreshed', refreshedToken);
          final bool updateSuccessful =
              await updateTokenCallback(refreshedToken);
          if (updateSuccessful) {
            await _storageService.saveFcmToken(refreshedToken);
            _analyticsService.trackTokenEvent('updated', refreshedToken);
          } else {
            _logMessage(
                '[NotificationManager] Token refresh callback returned false; pending retry next refresh');
          }
        } catch (error, stack) {
          _logMessage(
              '[NotificationManager] Token refresh handling error: $error');
          _logMessage('[NotificationManager] Stack trace: $stack');
        }
      },
      onError: (Object error, StackTrace stack) {
        _logMessage('[NotificationManager] Token refresh stream error: $error');
        _logMessage('[NotificationManager] Stack trace: $stack');
      },
    );
  }

  void _setupNotificationListeners(
      List<NotificationChannelData> androidChannels,
      String androidNotificationIconPath) {
    _fcmService.onMessage.listen((RemoteMessage message) async {
      await _handleForegroundMessage(
          message, androidChannels, androidNotificationIconPath);
    });
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
      await _persistInboxEntry(message, NotificationLifecycle.foreground);
      if (notification == null) {
        await _maybeBridgeDataOnlyMessage(message);
      }

      await _invokeUnifiedHandler(
          message, NotificationLifecycle.foreground);

      if (!_foregroundOptions.enabled) {
        return;
      }

      if (notification != null &&
          !_foregroundShownNotifications.contains(notification.hashCode)) {
        _foregroundShownNotifications.add(notification.hashCode);

        if (isAndroid) {
          await _showAndroidNotification(
              message, androidChannels, androidNotificationIconPath);
        } else if (isIOS) {
          // iOS handles foreground notifications automatically via setForegroundNotificationPresentationOptions
          // No need to manually show notifications to avoid duplicates
          _logMessage(
              '[NotificationManager] iOS foreground notification handled by system');
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

      // Determine channel ID - use provided one or fall back to first available channel
      String? channelId = message.notification?.android?.channelId;
      AndroidNotificationChannel? selectedChannel;

      if (channelId != null) {
        // Look for the specified channel
        for (final NotificationChannelData channelData in androidChannels) {
          if (channelData.id == channelId) {
            selectedChannel = channelData.toAndroidNotificationChannel();
            break;
          }
        }

        if (selectedChannel == null) {
          _logMessage(
              '[NotificationManager] Channel ID not found: $channelId, falling back to default');
          channelId = null; // Will fall back to default
        }
      }

      // Fall back to first available channel if no channel specified or found
      if (channelId == null && androidChannels.isNotEmpty) {
        channelId = androidChannels.first.id;
        selectedChannel = androidChannels.first.toAndroidNotificationChannel();
        _logMessage('[NotificationManager] Using default channel: $channelId');
      }

      // Show notification if we have a valid channel
      if (channelId != null) {
        await _notificationService.showNotification(
          id: message.notification.hashCode,
          title: message.notification?.title ?? '',
          body: message.notification?.body ?? '',
          payload: message.data,
          channelId: channelId,
          androidDetailsOverride: androidOverride,
        );
      } else {
        _logMessage(
            '[NotificationManager] No Android channels available for notification');
      }
    } catch (error, stack) {
      _logMessage(
          '[NotificationManager] Show Android notification error: $error');
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

    // Apply default sound if configured
    AndroidNotificationDetails? defaults = _foregroundOptions.androidDefaults;
    if (_foregroundOptions.androidSoundFileName != null && defaults != null) {
      return AndroidNotificationDetails(
        defaults.channelId,
        defaults.channelName,
        channelDescription: defaults.channelDescription,
        importance: defaults.importance,
        priority: defaults.priority,
        showWhen: defaults.showWhen,
        enableVibration: defaults.enableVibration,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(
            _foregroundOptions.androidSoundFileName!),
      );
    }

    return defaults;
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
    _fcmService.onMessageOpenedApp
        .listen((message) => unawaited(processNotification(message)));
  }

  Future<Stream<NotificationData?>?> _handleInitialNotification(
      bool includeInitialNotificationInStream) async {
    try {
      // Check Firebase Messaging initial message
      final RemoteMessage? firebaseInitialMessage =
          await _fcmService.getInitialMessage();
      if (firebaseInitialMessage?.data != null &&
          !_hasFetchedInitialNotification) {
        await processNotification(
          firebaseInitialMessage!,
          isFromTerminated: true,
          emitToClickStream: includeInitialNotificationInStream,
        );
        _hasFetchedInitialNotification = true;

        if (includeInitialNotificationInStream) {
          return getNotificationClickStream();
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

        await processNotification(
          RemoteMessage.fromMap({'data': payload}),
          isFromTerminated: true,
          emitToClickStream: includeInitialNotificationInStream,
        );

        _hasFetchedInitialNotification = true;

        if (includeInitialNotificationInStream) {
          return getNotificationClickStream();
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
      final NotificationData event = NotificationData(
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
      );
      _emitOrQueueClick(event);
    } catch (error, stack) {
      _logMessage('[NotificationManager] Add click stream event error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  void _emitOrQueueClick(NotificationData? event) {
    if (event == null) {
      return;
    }
    if (_clickStreamController != null &&
        _clickStreamController!.hasListener) {
      _clickStreamController!.add(event);
    } else {
      _pendingClickEvents.add(event);
    }
  }

  NormalizedMessage _normalizeMessage(
    RemoteMessage message,
    NotificationLifecycle lifecycle,
  ) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
    Map<String, dynamic>? analytics;
    final dynamic analyticsRaw = data['analytics'];
    if (analyticsRaw is Map<String, dynamic>) {
      analytics = Map<String, dynamic>.from(analyticsRaw);
    } else if (analyticsRaw is String) {
      try {
        final decoded = jsonDecode(analyticsRaw);
        if (decoded is Map<String, dynamic>) {
          analytics = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // ignore parsing errors; fallback to null
      }
    }

    final String? imageUrl = message.notification?.android?.imageUrl ??
        message.notification?.apple?.imageUrl ??
        data['image'] as String?;

    return NormalizedMessage(
      id: message.messageId ??
          data['messageId']?.toString() ??
          '${DateTime.now().millisecondsSinceEpoch}',
      title: message.notification?.title ?? data['title'] as String?,
      body: message.notification?.body ?? data['body'] as String?,
      imageUrl: imageUrl,
      data: data,
      actions: null,
      receivedAt: DateTime.now(),
      origin: 'remote',
      channelId: message.notification?.android?.channelId,
      analytics: analytics,
      rawMessage: message,
      lifecycle: lifecycle,
    );
  }

  Future<bool> _invokeUnifiedHandler(
      RemoteMessage message, NotificationLifecycle lifecycle) async {
    if (_unifiedMessageHandler == null) {
      return true;
    }
    try {
      final normalized = _normalizeMessage(message, lifecycle);
      return await _unifiedMessageHandler!(normalized, lifecycle);
    } catch (error, stack) {
      _logMessage('[NotificationManager] Unified handler error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
      return false;
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
      final DateTime now = DateTime.now();
      DateTime initial = DateTime(now.year, now.month, now.day, hour, minute);

      if (initial.isBefore(now)) {
        initial = initial.add(const Duration(days: 1));
      }

      final bool scheduled =
          await _notificationService.scheduleRecurringNotification(
        id: id,
        title: title,
        body: body,
        repeatInterval: repeatInterval,
        initialScheduleDate: initial,
        channelId: channelId,
        payload: payload,
        actions: actions,
      );

      if (scheduled) {
        _analyticsService.trackEvent('notification_scheduled_recurring', {
          'notification_id': id,
          'title': title,
          'repeat_interval': repeatInterval.name,
          'scheduled_start': initial.toIso8601String(),
        });
        _logMessage(
            '[NotificationManager] Recurring notification scheduled: $id (${repeatInterval.name})');
      }
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

  Future<void> _persistInboxEntry(
    RemoteMessage message,
    NotificationLifecycle lifecycle,
  ) async {
    try {
      final Map<String, dynamic> data = Map<String, dynamic>.from(message.data);
      final String id = message.messageId ??
          data['id']?.toString() ??
          '${DateTime.now().millisecondsSinceEpoch}';

      if (_persistedInboxIds.contains(id)) {
        return;
      }

      final String? title =
          message.notification?.title ?? data['title'] as String?;
      final String? body = message.notification?.body ?? data['body'] as String?;

      if ((title == null || title.isEmpty) &&
          (body == null || body.isEmpty)) {
        return;
      }

      final NotificationInboxItem item = NotificationInboxItem(
        id: id,
        title: title ?? '',
        body: body ?? '',
        subtitle: data['subtitle'] as String?,
        timestamp: DateTime.now(),
        isRead: false,
        imageUrl: message.notification?.android?.imageUrl ??
            message.notification?.apple?.imageUrl ??
            data['image'] as String?,
        actions: _parseActions(data['actions']),
        category: data['category'] as String?,
        data: data,
      );

      _persistedInboxIds.add(id);
      await _inboxStorage.upsert(item);

      _analyticsService.trackEvent('inbox_item_persisted', <String, dynamic>{
        'id': id,
        'lifecycle': lifecycle.name,
        'has_actions': item.actions.isNotEmpty,
      });
    } catch (error, stack) {
      _logMessage('[NotificationManager] Inbox persist error: $error');
      _logMessage('[NotificationManager] Stack trace: $stack');
    }
  }

  List<NotificationAction> _parseActions(dynamic rawActions) {
    if (rawActions is! List) {
      return const <NotificationAction>[];
    }

    return rawActions
        .map((dynamic action) {
          if (action is! Map) {
            return null;
          }
          final Map<String, dynamic> parsed =
              Map<String, dynamic>.from(action);
          final String? id = parsed['id']?.toString();
          final String? title = parsed['title']?.toString();
          if (id == null || title == null) {
            return null;
          }
          return NotificationAction(
            id: id,
            title: title,
            destructive: parsed['destructive'] == true,
            payload: parsed['payload'] is Map
                ? Map<String, dynamic>.from(parsed['payload'] as Map)
                : null,
          );
        })
        .whereType<NotificationAction>()
        .toList();
  }
}
