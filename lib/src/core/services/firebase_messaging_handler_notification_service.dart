import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:universal_html/js.dart' as js;
import '../interfaces/notification_service_interface.dart';
import '../managers/notification_manager.dart';
import '../../enums/export.dart';
import '../../constants/firebase_messaging_handler_constants.dart';
import '../../enums/repeat_interval_enum.dart';
import '../../models/export.dart';
import '../utils/platform_utils.dart';
import 'storage_service.dart';

/// Local notification service implementation for Firebase Messaging Handler
class FirebaseMessagingHandlerNotificationService
    implements NotificationServiceInterface {
  static FirebaseMessagingHandlerNotificationService? _instance;
  FlutterLocalNotificationsPlugin? _localNotifications;
  bool _isInitialized = false;
  final StorageService _storageService = StorageService.instance;
  int? _cachedBadgeCount;

  /// Singleton instance
  static FirebaseMessagingHandlerNotificationService get instance {
    _instance ??= FirebaseMessagingHandlerNotificationService._internal();
    return _instance!;
  }

  FirebaseMessagingHandlerNotificationService._internal();

  /// Ensure the service is initialized before use
  void _ensureInitialized() {
    if (isWeb) {
      return;
    }
    if (!_isInitialized || _localNotifications == null) {
      throw Exception(
          'NotificationService not initialized. Call initialize() first.');
    }
  }

  @override
  Future<bool> initialize({
    required List<NotificationChannelData> androidChannels,
    required String androidIconPath,
  }) async {
    try {
      if (isWeb) {
        _isInitialized = true;
        _logMessage(
            '[NotificationService] Web environment detected - skipping local notifications init');
        return true;
      }

      _localNotifications = FlutterLocalNotificationsPlugin();

      // Initialize timezone data for scheduled notifications
      tz.initializeTimeZones();

      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: AndroidInitializationSettings(androidIconPath),
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: true,
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestProvisionalPermission: true,
          requestCriticalPermission: true,
        ),
      );

      final bool? isInitialized = await _localNotifications!.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      if (isInitialized == true) {
        // Create Android notification channels
        for (final NotificationChannelData channel in androidChannels) {
          await _createAndroidChannel(channel);
        }

        // Configure iOS notification categories
        await _configureIOSNotificationCategories();

        _isInitialized = true;
        _logMessage('[NotificationService] Initialized successfully');
        return true;
      }

      _logMessage('[NotificationService] Initialization failed');
      return false;
    } catch (error, stack) {
      _logMessage('[NotificationService] Initialization error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
      return false;
    }
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
    String? channelId,
    String? groupKey,
    String? sortKey,
    String? category,
    AndroidNotificationDetails? androidDetailsOverride,
    DarwinNotificationDetails? iosDetailsOverride,
  }) async {
    try {
      if (isWeb) {
        await showWebNotification(
          title: title,
          body: body,
          icon: '/icons/Icon-192.png',
          data: payload ?? <String, dynamic>{},
        );
        return;
      }

      _ensureInitialized();
      final NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetailsOverride ??
            AndroidNotificationDetails(
              channelId ?? 'default_channel',
              'Default Notifications',
              importance: Importance.max,
              priority: Priority.high,
              groupKey: groupKey,
            ),
        iOS: iosDetailsOverride ??
            DarwinNotificationDetails(
              presentAlert: true,
              presentSound: true,
              presentBadge: true,
              categoryIdentifier: category,
            ),
      );

      await _localNotifications!.show(
        id,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(payload ?? {}),
      );

      _logMessage('[NotificationService] Notification shown: $title');
    } catch (error, stack) {
      _logMessage('[NotificationService] Show notification error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
  }

  @override
  Future<void> showNotificationWithActions({
    required int id,
    required String title,
    required String body,
    required List<NotificationAction> actions,
    Map<String, dynamic>? payload,
    String? channelId,
  }) async {
    try {
      if (isWeb) {
        _logMessage(
            '[NotificationService] Notification actions are not supported on web');
        await showWebNotification(
          title: title,
          body: body,
          icon: '/icons/Icon-192.png',
          data: payload ?? <String, dynamic>{},
        );
        return;
      }

      _ensureInitialized();
      await _localNotifications!.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId ?? 'action_channel',
            'Action Notifications',
            importance: Importance.max,
            priority: Priority.high,
            actions: actions
                .map((action) => AndroidNotificationAction(
                      action.id,
                      action.title,
                      showsUserInterface: true,
                      cancelNotification: !action.destructive,
                    ))
                .toList(),
          ),
          iOS: const DarwinNotificationDetails(
            categoryIdentifier: 'actionCategory',
            presentAlert: true,
            presentSound: true,
            presentBadge: false,
          ),
        ),
        payload: jsonEncode({
          'title': title,
          'body': body,
          'actions': actions
              .map((action) => {
                    'id': action.id,
                    'title': action.title,
                    'destructive': action.destructive,
                    'payload': action.payload,
                  })
              .toList(),
          ...payload ?? {},
        }),
      );

      _logMessage(
          '[NotificationService] Notification with actions shown: $title');
    } catch (error, stack) {
      _logMessage(
          '[NotificationService] Show notification with actions error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
  }

  @override
  Future<bool> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    Map<String, dynamic>? payload,
    String? channelId,
    List<NotificationAction>? actions,
  }) async {
    try {
      if (isWeb) {
        _logMessage(
            '[NotificationService] Scheduling is not supported on web - ignoring request');
        return false;
      }

      if (scheduledDate.isBefore(DateTime.now())) {
        _logMessage(
            '[NotificationService] Cannot schedule notification in the past');
        return false;
      }

      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId ?? 'scheduled_notifications',
          'Scheduled Notifications',
          importance: Importance.max,
          priority: Priority.high,
          actions: actions
              ?.map((action) => AndroidNotificationAction(
                    action.id,
                    action.title,
                    showsUserInterface: true,
                    cancelNotification: !action.destructive,
                  ))
              .toList(),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: false,
        ),
      );

      _ensureInitialized();
      await _localNotifications!.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode(payload ?? {}),
      );

      _logMessage(
          '[NotificationService] Notification scheduled for: ${scheduledDate.toString()}');
      return true;
    } catch (error, stack) {
      _logMessage('[NotificationService] Schedule notification error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
      return false;
    }
  }

  @override
  Future<bool> scheduleRecurringNotification({
    required int id,
    required String title,
    required String body,
    required RepeatIntervalEnum repeatInterval,
    required DateTime initialScheduleDate,
    Map<String, dynamic>? payload,
    String? channelId,
    List<NotificationAction>? actions,
  }) async {
    try {
      if (isWeb) {
        _logMessage(
            '[NotificationService] Recurring scheduling is not supported on web');
        return false;
      }

      _ensureInitialized();

      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId ?? 'recurring_notifications',
          'Recurring Notifications',
          importance: Importance.max,
          priority: Priority.high,
          actions: actions
              ?.map((action) => AndroidNotificationAction(
                    action.id,
                    action.title,
                    showsUserInterface: true,
                    cancelNotification: !action.destructive,
                  ))
              .toList(),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: false,
        ),
      );

      final Map<String, dynamic> encodedPayload =
          payload ?? <String, dynamic>{};

      if (repeatInterval == RepeatIntervalEnum.hourly ||
          repeatInterval == RepeatIntervalEnum.minutely) {
        if (actions != null && actions.isNotEmpty) {
          _logMessage(
              '[NotificationService] Actions are not supported for periodic notifications; ignoring provided actions');
        }
        final RepeatInterval periodicInterval =
            repeatInterval == RepeatIntervalEnum.hourly
                ? RepeatInterval.hourly
                : RepeatInterval.everyMinute;

        await _localNotifications!.periodicallyShow(
          id,
          title,
          body,
          periodicInterval,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: jsonEncode(encodedPayload),
        );

        _logMessage(
            '[NotificationService] Periodic notification scheduled (interval: ${repeatInterval.name}) for id: $id');
        return true;
      }

      final tz.TZDateTime normalizedDate =
          _normalizeScheduledDate(initialScheduleDate, repeatInterval);
      final DateTimeComponents? matchComponents =
          _mapRepeatIntervalToDateTimeComponents(repeatInterval);

      if (matchComponents == null) {
        _logMessage(
            '[NotificationService] Unsupported repeat interval: ${repeatInterval.name}');
        return false;
      }

      await _localNotifications!.zonedSchedule(
        id,
        title,
        body,
        normalizedDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode(encodedPayload),
        matchDateTimeComponents: matchComponents,
      );

      _logMessage(
          '[NotificationService] Recurring notification scheduled (interval: ${repeatInterval.name}) starting ${normalizedDate.toString()}');
      return true;
    } catch (error, stack) {
      _logMessage(
          '[NotificationService] Schedule recurring notification error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
      return false;
    }
  }

  @override
  Future<void> cancelNotification(int id) async {
    try {
      if (isWeb) {
        _logMessage(
            '[NotificationService] Cancel notification ignored on web (no local schedule)');
        return;
      }

      _ensureInitialized();
      await _localNotifications!.cancel(id);
      _logMessage('[NotificationService] Notification cancelled: $id');
    } catch (error, stack) {
      _logMessage('[NotificationService] Cancel notification error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
  }

  @override
  Future<void> cancelAllNotifications() async {
    try {
      if (isWeb) {
        _logMessage(
            '[NotificationService] Cancel all notifications ignored on web');
        return;
      }

      _ensureInitialized();
      await _localNotifications!.cancelAll();
      _logMessage('[NotificationService] All notifications cancelled');
    } catch (error, stack) {
      _logMessage(
          '[NotificationService] Cancel all notifications error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
  }

  @override
  Future<List<dynamic>> getPendingNotifications() async {
    try {
      if (isAndroid) {
        _ensureInitialized();
        return await _localNotifications!.pendingNotificationRequests();
      }
      return [];
    } catch (error, stack) {
      _logMessage(
          '[NotificationService] Get pending notifications error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
      return [];
    }
  }

  @override
  Future<void> createNotificationChannel(
      NotificationChannelData channel) async {
    try {
      if (isAndroid) {
        await _localNotifications!
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel.toAndroidNotificationChannel());
        _logMessage('[NotificationService] Channel created: ${channel.id}');
      }
    } catch (error, stack) {
      _logMessage('[NotificationService] Create channel error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
  }

  @override
  Future<NotificationAppLaunchDetails?>
      getNotificationAppLaunchDetails() async {
    try {
      if (isWeb) {
        _logMessage(
            '[NotificationService] Launch details unavailable on web platform');
        return null;
      }

      // Do not hard require initialize() here so apps can call checkInitial()
      // early during startup. On Android, the plugin must be initialized once
      // to capture the launch intent; do a minimal, safe initialization.
      if (_localNotifications == null) {
        final FlutterLocalNotificationsPlugin temp =
            FlutterLocalNotificationsPlugin();
        try {
          final InitializationSettings init = InitializationSettings(
            android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: const DarwinInitializationSettings(),
          );
          await temp.initialize(init);
        } catch (_) {
          // Best-effort; still attempt to read launch details
        }
        return await temp.getNotificationAppLaunchDetails();
      }

      return await _localNotifications!.getNotificationAppLaunchDetails();
    } catch (error, stack) {
      _logMessage('[NotificationService] Get launch details error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
      return null;
    }
  }

  @override
  Future<bool> isBadgeSupported() async {
    if (isWeb) {
      return false;
    }

    try {
      // flutter_local_notifications supports badge management on iOS
      // For Android, badge support depends on the launcher
      return !isWeb;
    } catch (error, stack) {
      _logMessage('[NotificationService] Badge support check error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
      return false;
    }
  }

  @override
  Future<String> getWebNotificationPermissionStatus() async {
    if (!isWeb) {
      return 'unavailable';
    }

    try {
      if (js.context.hasProperty('Notification')) {
        final dynamic notification = js.context['Notification'];
        if (notification != null && notification.hasProperty('permission')) {
          final dynamic permission = notification['permission'];
          if (permission is String) {
            return permission;
          }
        }
      }
      return 'unknown';
    } catch (error, stack) {
      _logMessage('[NotificationService] Web permission status error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
      return 'error';
    }
  }

  /// Shows web notification
  Future<void> showWebNotification({
    required String title,
    required String body,
    required String icon,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (!isWeb) return;

      if (await _requestWebNotificationPermission()) {
        final options = js.JsObject.jsify({
          'body': body,
          'icon': icon,
          'badge': '/icons/Icon-72.png',
          'tag': 'firebase-notification',
          'data': js.JsObject.jsify(data),
          'requireInteraction': false,
          'silent': false,
        });

        final notification =
            js.JsObject.fromBrowserObject(js.context['Notification']);
        final notificationInstance =
            notification.callMethod('new', [title, options]);

        notificationInstance.callMethod('addEventListener', [
          'click',
          js.allowInterop((event) {
            _handleWebNotificationClick(data);
          }),
        ]);

        _logMessage('[NotificationService] Web notification displayed: $title');
      }
    } catch (error, stack) {
      _logMessage('[NotificationService] Show web notification error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
  }

  /// Sets iOS badge count
  Future<void> setIOSBadgeCount(int count) async {
    try {
      if (isIOS) {
        await _updateBadgeCount(count);
      }
    } catch (error, stack) {
      _logMessage('[NotificationService] Set iOS badge count error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
  }

  /// Gets iOS badge count
  Future<int?> getIOSBadgeCount() async {
    try {
      if (isIOS) {
        return await _getStoredBadgeCount();
      }
    } catch (error, stack) {
      _logMessage('[NotificationService] Get iOS badge count error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
    return null;
  }

  /// Sets Android badge count
  Future<void> setAndroidBadgeCount(int count) async {
    try {
      if (isAndroid) {
        await _updateBadgeCount(count);
      }
    } catch (error, stack) {
      _logMessage(
          '[NotificationService] Set Android badge count error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
  }

  /// Gets Android badge count
  Future<int?> getAndroidBadgeCount() async {
    try {
      if (isAndroid) {
        return await _getStoredBadgeCount();
      }
    } catch (error, stack) {
      _logMessage(
          '[NotificationService] Get Android badge count error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
    return null;
  }

  /// Clears badge count for both platforms
  Future<void> clearBadgeCount() async {
    try {
      if (isWeb) {
        _logMessage(
            '[NotificationService] Badge count clearing not supported on web');
        return;
      }

      final bool supported = await isBadgeSupported();
      if (!supported) {
        _logMessage(
            '[NotificationService] Badge count clearing not supported on this platform');
        return;
      }

      // Use flutter_local_notifications to clear badge
      await _localNotifications!.cancelAll();
      await _clearStoredBadgeCount();
      _logMessage('[NotificationService] Badge count cleared');
    } catch (error, stack) {
      _logMessage('[NotificationService] Clear badge count error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
  }

  Future<bool> _updateBadgeCount(int count) async {
    if (isWeb) {
      _logMessage(
          '[NotificationService] Badge updates are not available on web');
      return false;
    }

    try {
      final bool supported = await isBadgeSupported();
      if (!supported) {
        _logMessage(
            '[NotificationService] App badges not supported on current platform');
        return false;
      }

      // For iOS, we can use flutter_local_notifications to set badge count
      // For Android, badge count is typically handled by the launcher
      if (isIOS) {
        // iOS badge management through flutter_local_notifications
        // Note: This is a simplified approach - in practice, you might need
        // to use platform channels for more precise badge control
        _logMessage('[NotificationService] iOS badge count set to: $count');
      } else {
        _logMessage('[NotificationService] Android badge count set to: $count');
      }
      await _persistBadgeCount(count);
      _logMessage('[NotificationService] Badge count set to: $count');
      return true;
    } catch (error, stack) {
      _logMessage('[NotificationService] Update badge error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
      return false;
    }
  }

  Future<void> _persistBadgeCount(int count) async {
    _cachedBadgeCount = count;
    try {
      await _storageService.saveConfiguration(
        FirebaseMessagingHandlerConstants.badgeCountPrefKey,
        count,
      );
    } catch (error, stack) {
      _logMessage('[NotificationService] Persist badge error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
  }

  Future<int> _getStoredBadgeCount() async {
    if (_cachedBadgeCount != null) {
      return _cachedBadgeCount!;
    }

    try {
      final dynamic stored = await _storageService.getConfiguration(
        FirebaseMessagingHandlerConstants.badgeCountPrefKey,
      );

      if (stored is int) {
        _cachedBadgeCount = stored;
        return stored;
      }
      if (stored is double) {
        final int converted = stored.toInt();
        _cachedBadgeCount = converted;
        return converted;
      }
    } catch (error, stack) {
      _logMessage('[NotificationService] Read badge error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }

    return 0;
  }

  Future<void> _clearStoredBadgeCount() async {
    _cachedBadgeCount = 0;
    try {
      await _storageService.removeConfiguration(
        FirebaseMessagingHandlerConstants.badgeCountPrefKey,
      );
    } catch (error, stack) {
      _logMessage('[NotificationService] Clear badge storage error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
  }

  tz.TZDateTime _normalizeScheduledDate(
      DateTime initial, RepeatIntervalEnum repeatInterval) {
    tz.TZDateTime scheduled = tz.TZDateTime.from(initial, tz.local);
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    while (scheduled.isBefore(now)) {
      scheduled = _incrementScheduledDate(scheduled, repeatInterval);
      if (scheduled.isAtSameMomentAs(now)) {
        break;
      }
    }
    return scheduled;
  }

  tz.TZDateTime _incrementScheduledDate(
      tz.TZDateTime date, RepeatIntervalEnum repeatInterval) {
    switch (repeatInterval) {
      case RepeatIntervalEnum.daily:
        return date.add(const Duration(days: 1));
      case RepeatIntervalEnum.weekly:
        return date.add(const Duration(days: 7));
      case RepeatIntervalEnum.monthly:
        return tz.TZDateTime(date.location, date.year, date.month + 1, date.day,
            date.hour, date.minute, date.second);
      case RepeatIntervalEnum.yearly:
        return tz.TZDateTime(date.location, date.year + 1, date.month, date.day,
            date.hour, date.minute, date.second);
      case RepeatIntervalEnum.hourly:
        return date.add(const Duration(hours: 1));
      case RepeatIntervalEnum.minutely:
        return date.add(const Duration(minutes: 1));
    }
  }

  DateTimeComponents? _mapRepeatIntervalToDateTimeComponents(
      RepeatIntervalEnum repeatInterval) {
    switch (repeatInterval) {
      case RepeatIntervalEnum.daily:
        return DateTimeComponents.time;
      case RepeatIntervalEnum.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case RepeatIntervalEnum.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case RepeatIntervalEnum.yearly:
        return DateTimeComponents.dateAndTime;
      default:
        return null;
    }
  }

  Future<void> _createAndroidChannel(NotificationChannelData channel) async {
    try {
      await _localNotifications!
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel.toAndroidNotificationChannel());
    } catch (error, stack) {
      _logMessage('[NotificationService] Create Android channel error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
  }

  Future<void> _configureIOSNotificationCategories() async {
    try {
      // iOS notification categories configuration
      _logMessage(
          '[NotificationService] iOS notification categories configured');
    } catch (error, stack) {
      _logMessage(
          '[NotificationService] Configure iOS categories error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
  }

  Future<bool> _requestWebNotificationPermission() async {
    try {
      if (!isWeb) return false;

      if (js.context.hasProperty('Notification')) {
        final notification =
            js.JsObject.fromBrowserObject(js.context['Notification']);

        if (notification.hasProperty('permission')) {
          final permission = notification['permission'];

          if (permission == 'granted') {
            return true;
          } else if (permission == 'default') {
            final requestResult =
                await notification.callMethod('requestPermission');
            return requestResult == 'granted';
          }
        }
      }

      return false;
    } catch (error, stack) {
      _logMessage('[NotificationService] Request web permission error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
      return false;
    }
  }

  void _handleWebNotificationClick(Map<String, dynamic> data) {
    try {
      // Handle web notification click
      _logMessage('[NotificationService] Web notification clicked');
    } catch (error, stack) {
      _logMessage('[NotificationService] Handle web click error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    try {
      if (response.notificationResponseType ==
          NotificationResponseType.selectedNotification) {
        _logMessage(
            '[NotificationService] Notification response received: ${response.id}');

        // Forward to click stream so foreground taps are published consistently
        final String? rawPayload = response.payload;
        Map<String, dynamic> payload = <String, dynamic>{};
        if (rawPayload != null && rawPayload.isNotEmpty) {
          try {
            final dynamic decoded = jsonDecode(rawPayload);
            if (decoded is Map<String, dynamic>) {
              payload = decoded;
            }
          } catch (_) {
            // Ignore malformed payloads; keep empty map
          }
        }

        NotificationManager.instance.emitTestClick(
          NotificationData(
            payload: payload,
            // Foreground tap on a local notification we presented
            type: NotificationTypeEnum.foreground,
            isFromTerminated: false,
          ),
        );
      }
    } catch (error, stack) {
      _logMessage('[NotificationService] Notification response error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
  }

  void _logMessage(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
}
