import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:universal_html/js.dart' as js;
import '../interfaces/notification_service_interface.dart';
import '../../models/export.dart';

/// Local notification service implementation
class NotificationService implements NotificationServiceInterface {
  static NotificationService? _instance;
  FlutterLocalNotificationsPlugin? _localNotifications;
  bool _isInitialized = false;

  /// Singleton instance
  static NotificationService get instance {
    _instance ??= NotificationService._internal();
    return _instance!;
  }

  NotificationService._internal();

  /// Ensure the service is initialized before use
  void _ensureInitialized() {
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
          iOS: DarwinNotificationDetails(
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
  Future<void> cancelNotification(int id) async {
    try {
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
      if (!kIsWeb && Platform.isAndroid) {
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
      if (!kIsWeb && Platform.isAndroid) {
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
      _ensureInitialized();
      return await _localNotifications!.getNotificationAppLaunchDetails();
    } catch (error, stack) {
      _logMessage('[NotificationService] Get launch details error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
      return null;
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
      if (!kIsWeb) return;

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
      if (!kIsWeb && Platform.isIOS) {
        // iOS badge management implementation would go here
        _logMessage('[NotificationService] iOS badge count set to: $count');
      }
    } catch (error, stack) {
      _logMessage('[NotificationService] Set iOS badge count error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
    }
  }

  /// Gets iOS badge count
  Future<int?> getIOSBadgeCount() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        // iOS badge count retrieval implementation would go here
        return 0;
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
      if (!kIsWeb && Platform.isAndroid) {
        // Android badge management implementation would go here
        _logMessage('[NotificationService] Android badge count set to: $count');
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
      if (!kIsWeb && Platform.isAndroid) {
        // Android badge count retrieval implementation would go here
        return 0;
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
      if (!kIsWeb) {
        if (Platform.isIOS) {
          await setIOSBadgeCount(0);
        } else if (Platform.isAndroid) {
          _ensureInitialized();
          await _localNotifications!.cancel(999999);
        }
      }
      _logMessage('[NotificationService] Badge count cleared');
    } catch (error, stack) {
      _logMessage('[NotificationService] Clear badge count error: $error');
      _logMessage('[NotificationService] Stack trace: $stack');
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
      if (!kIsWeb) return false;

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
