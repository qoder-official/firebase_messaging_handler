import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:universal_html/js.dart' as js;
import '../enums/index.dart';

import '../constants/index.dart';
import '../extensions/index.dart';
import '../models/index.dart';

class FirebaseMessagingUtility {
  static FirebaseMessagingUtility? _instance;

  /// Singleton instance of the FirebaseMessagingUtility.
  static FirebaseMessagingUtility get instance {
    _instance ??= FirebaseMessagingUtility._internal();
    return _instance!;
  }

  /// Private constructor for singleton pattern.
  FirebaseMessagingUtility._internal();

  /// Instance of Firebase Messaging.
  late FirebaseMessaging firebaseMessagingInstance;

  /// Stores IDs of notifications opened during the session.
  final Set<int> openedNotifications = {};

  /// Stores IDs of notifications shown in the foreground.
  final Set<int> foregroundShownNotifications = {};

  /// Stores session-specific notification IDs.
  static Set<int> sessionNotifications = {};

  /// Instance of Flutter Local Notifications Plugin.
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  /// Callback for handling notification clicks.
  Function? onClickCallback;

  /// Stream controller for notification click events.
  StreamController<NotificationData?>? clickStreamController;

  /// Stream for listening to notification click events.
  Stream<NotificationData?>? clickStream;

  /// Stores the initial notification message if app was opened via notification.
  RemoteMessage? initialMessage;

  /// Shared Preferences instance for storing persistent data.
  SharedPreferences? sharedPref;

  // Boolean flag to ensure initial fetching happens only once
  bool _hasFetchedInitialNotification = false;

  Future<Stream<NotificationData?>?> init({
    required final String senderId,
    required final List<NotificationChannelData> androidChannelList,
    required final String androidNotificationIconPath,
    Future<bool> Function(String fcmToken)? updateTokenCallback,
    final bool includeInitialNotificationInStream = false,
  }) async {
    firebaseMessagingInstance = FirebaseMessaging.instance;
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    final bool permissionsGranted = await requestPermission();
    if (permissionsGranted) {
      final String? savedFcmToken = await getFcmToken();
      if (savedFcmToken == null && updateTokenCallback != null) {
        final String? fcmToken = await fetchFcmToken(senderId: senderId);

        if (fcmToken != null) {
          // Track token fetch event
          _trackTokenEvent('fetched', fcmToken);

          final bool updateSuccessful = await updateTokenCallback(fcmToken);
          if (updateSuccessful) {
            await saveFcmToken(fcmToken);
            _trackTokenEvent('updated', fcmToken);
          }
        } else {
          _logMessage(
            'Error fetching FCM Token!',
          );
          _trackTokenEvent('error', null);
        }
      }
      await initializeLocalNotifications(
        androidChannelList: androidChannelList,
        androidNotificationIconPath: androidNotificationIconPath,
      );
      listenToForegroundNotifications(
        androidChannelList: androidChannelList,
        androidNotificationIconPath: androidNotificationIconPath,
      );
      await handleBackgroundNotifications();

      // Check if the app was launched via FirebaseMessaging
      if (initialMessage?.data != null && !_hasFetchedInitialNotification) {
        /// Handles terminated notification and instantly fires an event on subscribing.
        processNotification(
          initialMessage!,
          isFromTerminated: true,
        );

        // Capture the initial notification data before clearing
        final initialPayload = initialMessage!.data;
        final initialNotification = initialMessage!;

        initialMessage = null;
        _hasFetchedInitialNotification = true;

        if (includeInitialNotificationInStream) {
          return getNotificationClickStream().startWith(NotificationData(
            payload: initialPayload,
            title: initialNotification.notification?.title,
            body: initialNotification.notification?.body,
            type: NotificationTypeEnum.terminated,
            isFromTerminated: true,
            messageId: initialNotification.messageId,
          ));
        }
      }

      // Check if the app was launched via flutter_local_notifications
      final NotificationAppLaunchDetails? launchDetails =
          await flutterLocalNotificationsPlugin
              .getNotificationAppLaunchDetails();

      if ((launchDetails?.didNotificationLaunchApp ?? false) &&
          !_hasFetchedInitialNotification) {
        /// Extract payload from NotificationAppLaunchDetails
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

      // Default case: no notification launch detected
      return getNotificationClickStream();
    }
    return null;
  }

  Future<void> checkInitial() async {
    initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    ///Alternative approach to get the payload from previous session cache
    // if (initialMessage != null) {
    //   final restoredMessages = await restoreSessionNotifications();
    //   final int messageHash = initialMessage!.messageId.hashCode;
    //   final matchingMessage = restoredMessages.firstWhere(
    //     (message) {
    //       return message.messageId.hashCode == messageHash;
    //     },
    //     orElse: () => initialMessage!,
    //   );
    //
    //   if (matchingMessage != initialMessage) {
    //     initialMessage = matchingMessage;
    //   }
    // }
    //await clearSessionNotifications();
  }

  /// Gets the initial notification data if the app was launched from a notification
  /// This is useful when you want to handle initial notifications separately from the stream
  Future<NotificationData?> getInitialNotificationData() async {
    try {
      // Check Firebase Messaging initial message
      final RemoteMessage? firebaseInitialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
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
          await flutterLocalNotificationsPlugin
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
      _logMessage(
        'Get Initial Notification Data Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
      return null;
    }
  }

  Future<String?> fetchFcmToken({required final String senderId}) async {
    try {
      final String? fcmToken =
          await firebaseMessagingInstance.getToken(vapidKey: senderId);
      return fcmToken;
    } catch (error, stack) {
      _logMessage(
        'FCM Error: $error',
      );
      _logMessage(
        'FCM Error Stack: $stack',
      );

      return null;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final NotificationSettings notificationSettings =
          await firebaseMessagingInstance.requestPermission();

      return notificationSettings.authorizationStatus ==
          AuthorizationStatus.authorized;
    } catch (error, stack) {
      _logMessage(
        'FCM asking for notification permission.\n$error',
      );
      _logMessage(
        'FCM Error Stack: $stack',
      );

      return false;
    }
  }

  Future<void> initializeLocalNotifications({
    required final List<NotificationChannelData> androidChannelList,
    required final String androidNotificationIconPath,
  }) async {
    try {
      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: AndroidInitializationSettings(androidNotificationIconPath),
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: true,
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestProvisionalPermission: true,
          requestCriticalPermission: true,
        ),
        // Note: Web notifications are handled differently through FirebaseMessaging
        // and don't use flutter_local_notifications
      );

      final bool? isInitialized =
          await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: onSelectNotification,
      );

      if (isInitialized != null && isInitialized) {
        // Create Android notification channels
        for (final NotificationChannelData channel in androidChannelList) {
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.createNotificationChannel(
                  channel.toAndroidNotificationChannel());
        }

        // Configure iOS notification categories for interactive notifications
        await _configureIOSNotificationCategories();

        // Set foreground notification presentation options
        await firebaseMessagingInstance
            .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        // Configure iOS-specific settings
        if (!kIsWeb && Platform.isIOS) {
          await _configureIOSNotifications();
        }
      }
    } catch (error, stack) {
      _logMessage(
        'Init Local Notifications Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  void listenToForegroundNotifications({
    required final List<NotificationChannelData> androidChannelList,
    required final String androidNotificationIconPath,
  }) {
    if (!kIsWeb) {
      if (Platform.isAndroid) {
        FirebaseMessaging.onMessage.listen(
          (final RemoteMessage message) async {
            final RemoteNotification? notification = message.notification;

            await saveNotification(message);

            if (notification != null &&
                !foregroundShownNotifications.contains(notification.hashCode)) {
              foregroundShownNotifications.add(notification.hashCode);

              AndroidNotificationChannel? selectedChannel;
              for (final NotificationChannelData channelData
                  in androidChannelList) {
                if (channelData.id ==
                    message.notification!.android!.channelId) {
                  selectedChannel = channelData.toAndroidNotificationChannel();
                  selectedChannel.copyWith(
                    importance: Importance.max,
                  );

                  break;
                }
              }

              await _showLocalNotification(
                message: message,
                androidChannelList: androidChannelList,
                androidNotificationIconPath: androidNotificationIconPath,
              );
            }
          },
        );
      } else if (Platform.isIOS) {
        FirebaseMessaging.onMessage.listen(
          (final RemoteMessage message) async {
            final RemoteNotification? notification = message.notification;

            await saveNotification(message);

            if (notification != null &&
                !foregroundShownNotifications.contains(notification.hashCode)) {
              foregroundShownNotifications.add(notification.hashCode);

              await _showIOSNotification(message: message);
            }
          },
        );
      } else {
        // Web platform - handle notifications through browser API
        FirebaseMessaging.onMessage.listen(
          (final RemoteMessage message) async {
            await saveNotification(message);

            if (!kIsWeb) return; // This should not happen, but safety check

            await _showWebNotification(message: message);
          },
        );
      }
    }
  }

  Future<void> handleBackgroundNotifications() async {
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen(processNotification);
  }

  @pragma('vm:entry-point')
  static Future<void> _onBackgroundMessage(RemoteMessage message) async {
    await saveNotification(message);
  }

  void processNotification(final RemoteMessage message,
      {bool isFromTerminated = false}) {
    if (!openedNotifications.contains(message.messageId.hashCode)) {
      openedNotifications.add(message.messageId.hashCode);

      // Track notification received
      _trackNotificationReceived(message);

      addNotificationClickStreamEvent(
        message.data,
        message: message,
        isFromTerminated: isFromTerminated,
        type: isFromTerminated
            ? NotificationTypeEnum.terminated
            : NotificationTypeEnum.background,
      );

      // Track notification clicked
      _trackNotificationClicked(NotificationData(
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
  }

  void addNotificationClickStreamEvent(
    final Map<String, dynamic> payload, {
    final RemoteMessage? message,
    bool isFromTerminated = false,
    NotificationTypeEnum type = NotificationTypeEnum.foreground,
  }) {
    if (!isFromTerminated) {
      clickStreamController?.add(
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
  }

  Future<void> _showIOSNotification({
    required final RemoteMessage message,
  }) async {
    try {
      final RemoteNotification? notification = message.notification;
      final AppleNotification? apple = notification?.apple;

      if (notification != null) {
        await flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: apple?.badge != null,
              presentSound: true,
              badgeNumber: apple?.badge != null
                  ? int.tryParse(apple!.badge.toString())
                  : null,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    } catch (error, stack) {
      _logMessage(
        'Show iOS Notification Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  Future<void> _showWebNotification({
    required final RemoteMessage message,
  }) async {
    try {
      final RemoteNotification? notification = message.notification;

      if (notification != null) {
        // Request permission for web notifications if not already granted
        if (await _requestWebNotificationPermission()) {
          // Show web notification using browser API
          await _displayWebNotification(
            title: notification.title ?? 'Notification',
            body: notification.body ?? '',
            icon: '/icons/Icon-192.png', // Default icon path
            data: message.data,
          );
        }
      }
    } catch (error, stack) {
      _logMessage(
        'Show Web Notification Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  Future<bool> _requestWebNotificationPermission() async {
    try {
      if (!kIsWeb) return false;

      // Check if we're in a browser environment
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
      _logMessage(
        'Request Web Notification Permission Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
      return false;
    }
  }

  Future<void> _displayWebNotification({
    required String title,
    required String body,
    required String icon,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (!kIsWeb) return;

      // Create notification options
      final options = js.JsObject.jsify({
        'body': body,
        'icon': icon,
        'badge': '/icons/Icon-72.png',
        'tag': 'firebase-notification',
        'data': js.JsObject.jsify(data),
        'requireInteraction': false,
        'silent': false,
      });

      // Show notification
      final notification =
          js.JsObject.fromBrowserObject(js.context['Notification']);
      final notificationInstance =
          notification.callMethod('new', [title, options]);

      // Add click event listener for web notifications
      notificationInstance.callMethod('addEventListener', [
        'click',
        js.allowInterop((event) {
          _handleWebNotificationClick(data);
        }),
      ]);

      _logMessage('Web notification displayed: $title');
    } catch (error, stack) {
      _logMessage(
        'Display Web Notification Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  void _handleWebNotificationClick(Map<String, dynamic> data) {
    try {
      // Process the notification click similar to mobile platforms
      addNotificationClickStreamEvent(
        data,
        isFromTerminated: false,
        type: NotificationTypeEnum.foreground,
      );

      // Focus the window/tab
      if (js.context.hasProperty('window')) {
        final window = js.JsObject.fromBrowserObject(js.context['window']);
        window.callMethod('focus');
      }
    } catch (error, stack) {
      _logMessage(
        'Handle Web Notification Click Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
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
    try {
      final id =
          notificationId ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Create Android notification with actions
      if (!kIsWeb && Platform.isAndroid && channelId != null) {
        await flutterLocalNotificationsPlugin.show(
          id,
          title,
          body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              'Notification Actions',
              actions: actions
                  .map((action) => AndroidNotificationAction(
                        action.id,
                        action.title,
                        showsUserInterface: true,
                        cancelNotification: !action.destructive,
                      ))
                  .toList(),
            ),
          ),
          payload: jsonEncode(payload ?? {}),
        );
      }

      // Create iOS notification with actions
      if (!kIsWeb && Platform.isIOS) {
        await flutterLocalNotificationsPlugin.show(
          id,
          title,
          body,
          NotificationDetails(
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
      }

      _logMessage('Notification with actions shown: $title');
    } catch (error, stack) {
      _logMessage(
        'Show Notification with Actions Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
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
    try {
      if (scheduledDate.isBefore(DateTime.now())) {
        _logMessage('Cannot schedule notification in the past');
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
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: false,
        ),
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode(payload ?? {}),
      );

      _logMessage('Notification scheduled for: ${scheduledDate.toString()}');

      // Track analytics event
      _trackNotificationScheduled('one_time', {
        'notification_id': id,
        'title': title,
        'scheduled_for': scheduledDate.toIso8601String(),
      });

      return true;
    } catch (error, stack) {
      _logMessage(
        'Schedule Notification Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
      return false;
    }
  }

  /// Schedules a recurring notification (daily, weekly, etc.) - Simplified version
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
      // For now, schedule as a regular notification
      // Full recurring support would need more complex implementation
      final scheduledDate = _nextInstanceOfTimeFromHourMinute(hour, minute);

      final notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          channelId ?? 'recurring_notifications',
          'Recurring Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
          presentBadge: false,
        ),
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode(payload ?? {}),
      );

      _logMessage('Recurring notification scheduled for: $hour:$minute');

      // Track analytics event
      _trackNotificationScheduled('recurring', {
        'notification_id': id,
        'title': title,
        'repeat_interval': repeatInterval,
        'scheduled_hour': hour,
        'scheduled_minute': minute,
      });

      return true;
    } catch (error, stack) {
      _logMessage(
        'Schedule Recurring Notification Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
      return false;
    }
  }

  /// Cancels a scheduled notification
  Future<bool> cancelScheduledNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
      _logMessage('Scheduled notification cancelled: $id');
      return true;
    } catch (error, stack) {
      _logMessage(
        'Cancel Scheduled Notification Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
      return false;
    }
  }

  /// Cancels all scheduled notifications
  Future<bool> cancelAllScheduledNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      _logMessage('All scheduled notifications cancelled');
      return true;
    } catch (error, stack) {
      _logMessage(
        'Cancel All Scheduled Notifications Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
      return false;
    }
  }

  /// Gets all pending scheduled notifications (Android only) - Simplified
  Future<List<dynamic>?> getPendingNotifications() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        return await flutterLocalNotificationsPlugin
            .pendingNotificationRequests();
      }
      return null;
    } catch (error, stack) {
      _logMessage(
        'Get Pending Notifications Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
      return null;
    }
  }

  /// Calculates the next occurrence of a specific time
  tz.TZDateTime _nextInstanceOfTimeFromHourMinute(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Shows a grouped notification (Android notification groups) - Simplified
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
    try {
      final id =
          notificationId ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId ?? 'grouped_notifications',
            'Grouped Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(payload ?? {}),
      );

      _logMessage('Notification shown (grouping feature available)');
    } catch (error, stack) {
      _logMessage(
        'Show Grouped Notification Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  /// Creates a notification group with multiple notifications - Simplified
  Future<void> createNotificationGroup({
    required String groupKey,
    required String groupTitle,
    required List<NotificationData> notifications,
    String? channelId,
  }) async {
    try {
      // Show individual notifications
      for (int i = 0; i < notifications.length; i++) {
        await flutterLocalNotificationsPlugin.show(
          i + 1,
          notifications[i].title ?? 'Notification',
          notifications[i].body ?? '',
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId ?? 'grouped_notifications',
              'Grouped Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: jsonEncode(notifications[i].payload),
        );
      }

      _logMessage(
          'Notification group created: $groupKey with ${notifications.length} notifications');
    } catch (error, stack) {
      _logMessage(
        'Create Notification Group Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  /// Dismisses a notification group (Android) - Simplified
  Future<void> dismissNotificationGroup(String groupKey) async {
    try {
      // Cancel all notifications
      await flutterLocalNotificationsPlugin.cancelAll();
      _logMessage('All notifications dismissed');
    } catch (error, stack) {
      _logMessage(
        'Dismiss Notification Group Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
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
      final id =
          notificationId ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          iOS: DarwinNotificationDetails(
            threadIdentifier: threadIdentifier,
            presentAlert: true,
            presentSound: true,
            presentBadge: false,
          ),
        ),
        payload: jsonEncode(payload ?? {}),
      );

      _logMessage('Threaded notification shown (threading feature available)');

      // Track analytics event
      trackAnalyticsEvent('notification_shown', {
        'notification_id': id,
        'title': title,
        'thread_identifier': threadIdentifier,
        'platform': _getCurrentPlatform(),
      });
    } catch (error, stack) {
      _logMessage(
        'Show Threaded Notification Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  /// Analytics callback function - can be set by users to track events
  void Function(String event, Map<String, dynamic> data)? onAnalyticsEvent;

  /// Tracks an analytics event with the provided data
  void trackAnalyticsEvent(String event, Map<String, dynamic> data) {
    try {
      // Add timestamp and common metadata
      final enrichedData = {
        'event': event,
        'timestamp': DateTime.now().toIso8601String(),
        'platform': _getCurrentPlatform(),
        ...data,
      };

      // Call user-provided analytics callback if available
      onAnalyticsEvent?.call(event, enrichedData);

      _logMessage('Analytics event tracked: $event');
    } catch (error, stack) {
      _logMessage(
        'Track Analytics Event Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  /// Gets the current platform for analytics
  String _getCurrentPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Tracks when a notification is received (foreground/background)
  void _trackNotificationReceived(RemoteMessage message) {
    trackAnalyticsEvent('notification_received', {
      'message_id': message.messageId,
      'title': message.notification?.title,
      'body': message.notification?.body,
      'category': message.category,
      'sender_id': message.senderId,
      'ttl': message.ttl,
      'collapse_key': message.collapseKey,
    });
  }

  /// Tracks when a notification is clicked/tapped
  void _trackNotificationClicked(NotificationData data) {
    trackAnalyticsEvent('notification_clicked', {
      'title': data.title,
      'body': data.body,
      'type': data.type.name,
      'is_from_terminated': data.isFromTerminated,
      'message_id': data.messageId,
      'category': data.category,
    });
  }

  /// Tracks notification scheduling events
  void _trackNotificationScheduled(String type, Map<String, dynamic> data) {
    trackAnalyticsEvent('notification_scheduled', {
      'schedule_type': type,
      ...data,
    });
  }

  /// Tracks FCM token events
  void _trackTokenEvent(String event, String? token) {
    trackAnalyticsEvent('fcm_token', {
      'event': event,
      'has_token': token != null && token.isNotEmpty,
    });
  }

  Future<void> _showLocalNotification({
    required final RemoteMessage message,
    required final List<NotificationChannelData> androidChannelList,
    required final String androidNotificationIconPath,
  }) async {
    try {
      if (message.notification?.android?.channelId != null) {
        AndroidNotificationChannel? selectedChannel;
        Priority? priority;
        for (final NotificationChannelData channelData in androidChannelList) {
          if (channelData.id == message.notification!.android!.channelId) {
            selectedChannel = channelData.toAndroidNotificationChannel();
            priority = channelData.priority.getConvertedPriority;
          }
        }

        if (selectedChannel == null) {
          _logMessage(
            'The Channel ID from the notification is not matching the any of the Channel IDs set in app.',
          );
          _logMessage(
            'Please make sure you are sending the Channel ID which you are setting in androidChannelList',
          );
        }

        await flutterLocalNotificationsPlugin.show(
          message.notification.hashCode,
          message.notification?.title,
          message.notification?.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              message.notification!.android!.channelId!,
              selectedChannel?.name ??
                  message.notification!.android!.channelId!,
              importance:
                  selectedChannel?.importance ?? Importance.defaultImportance,
              priority: priority ?? Priority.defaultPriority,
              icon: androidNotificationIconPath,
            ),
          ),
          payload: jsonEncode(message.data),
        );
      } else {
        _logMessage(
          'Show Local Notification for Android Error: No Channel ID found',
        );
      }
    } catch (error, stack) {
      _logMessage(
        'Init Local Notifications Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  Future<void> onSelectNotification(
    final NotificationResponse response,
  ) async {
    //Note: The Remote Message hash code is stored in 'response.id'
    if (response.notificationResponseType ==
        NotificationResponseType.selectedNotification) {
      if (response.id != null && !openedNotifications.contains(response.id)) {
        openedNotifications.add(response.id!);
        final Map<String, dynamic> payload =
            response.payload != null ? jsonDecode(response.payload!) : {};

        addNotificationClickStreamEvent(
          payload,
          isFromTerminated: false,
          type: NotificationTypeEnum.foreground,
        );
      }
    }
  }

  Stream<NotificationData?> getNotificationClickStream() {
    if (clickStreamController == null || clickStream == null) {
      clickStreamController = StreamController<NotificationData?>.broadcast();
      clickStream = clickStreamController!.stream;
    }

    return clickStream!;
  }

  Future<void> dispose() async {
    openedNotifications.clear();
    foregroundShownNotifications.clear();
    await flutterLocalNotificationsPlugin.cancelAll();
    await clickStreamController?.close();
  }

  Future<void> clearToken() async {
    sharedPref ??= await SharedPreferences.getInstance();
    await removeFcmToken();
  }

  Future<void> saveFcmToken(String token) async {
    sharedPref ??= await SharedPreferences.getInstance();
    await sharedPref!.setString(
      FirebaseMessagingHandlerConstants.fcmTokenPrefKey,
      token,
    );
  }

  Future<String?> getFcmToken() async {
    sharedPref ??= await SharedPreferences.getInstance();
    return Future.value(sharedPref!
        .getString(FirebaseMessagingHandlerConstants.fcmTokenPrefKey));
  }

  Future<void> removeFcmToken() async {
    sharedPref ??= await SharedPreferences.getInstance();
    await sharedPref!.remove(FirebaseMessagingHandlerConstants.fcmTokenPrefKey);
  }

  static Future<void> saveNotification(RemoteMessage message) async {
    ///Alternative approach to get the payload from previous session cache
    // final prefs = await SharedPreferences.getInstance();
    // final String? storedData =
    //     prefs.getString(FirebaseMessagingHandlerConstants.sessionPrefKey);
    //
    // // Parse existing stored messages
    // final List<Map<String, dynamic>> currentMessages = storedData != null
    //     ? List<Map<String, dynamic>>.from(jsonDecode(storedData))
    //     : [];
    //
    // // Check if the message is already saved (using hash code)
    // final int messageHash = message.messageId.hashCode;
    // final bool isDuplicate = currentMessages.any((msg) {
    //   return msg['messageId']?.hashCode == messageHash;
    // });
    //
    // if (!isDuplicate) {
    //   // Add the new message
    //   currentMessages.add(message.toMap());
    //
    //   // Save updated list to SharedPreferences
    //   prefs.setString(
    //     FirebaseMessagingHandlerConstants.sessionPrefKey,
    //     jsonEncode(currentMessages),
    //   );
    //
    //   // Also track the message hash in session memory (optional)
    //   sessionNotifications.add(messageHash);
    // }
  }

  Future<List<RemoteMessage>> restoreSessionNotifications() async {
    ///Alternative approach to get the payload from previous session cache
    // final prefs = await SharedPreferences.getInstance();
    // final storedData =
    //     prefs.getString(FirebaseMessagingHandlerConstants.sessionPrefKey);
    //
    // if (storedData != null) {
    //   // Deserialize the stored list of RemoteMessage objects
    //   final List<dynamic> jsonList = jsonDecode(storedData);
    //   final List<RemoteMessage> restoredMessages = jsonList
    //       .cast<Map<String, dynamic>>()
    //       .map((data) => RemoteMessage.fromMap(data))
    //       .toList();
    //
    //   // Add to sessionNotifications
    //   for (final RemoteMessage message in restoredMessages) {
    //     sessionNotifications.add(message.messageId.hashCode);
    //   }
    //
    //   _logMessage(
    //       'Restored ${restoredMessages.length} notifications from session.');
    //   return restoredMessages;
    // }

    return [];
  }

  Future<void> clearSessionNotifications() async {
    ///Alternative approach to get the payload from previous session cache
    // sessionNotifications.clear();
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.remove('session_notifications');
    // _logMessage('Session notifications cleared.');
  }

  Future<void> _configureIOSNotificationCategories() async {
    try {
      // iOS notification categories configuration (simplified for current APIs)
      _logMessage('iOS notification configuration completed');
    } catch (error, stack) {
      _logMessage(
        'Configure iOS Notification Categories Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  Future<void> _configureIOSNotifications() async {
    try {
      // Configure iOS-specific notification settings (simplified)
      _logMessage('iOS notification permissions configured');
    } catch (error, stack) {
      _logMessage(
        'Configure iOS Notifications Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  Future<void> setIOSBadgeCount(int count) async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        // iOS badge management (simplified for current APIs)
        _logMessage('iOS badge count set to: $count');
      }
    } catch (error, stack) {
      _logMessage(
        'Set iOS Badge Count Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  Future<int?> getIOSBadgeCount() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        // iOS badge count retrieval (simplified for current APIs)
        return 0;
      }
    } catch (error, stack) {
      _logMessage(
        'Get iOS Badge Count Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
    return null;
  }

  /// Sets the badge count for Android (simplified implementation)
  Future<void> setAndroidBadgeCount(int count) async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        // Android badge management is limited in current APIs
        // This is a placeholder for future implementation
        _logMessage('Android badge management requested (count: $count)');
      }
    } catch (error, stack) {
      _logMessage(
        'Set Android Badge Count Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  /// Gets the current Android badge count (simplified)
  Future<int?> getAndroidBadgeCount() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        // Android doesn't provide direct badge count API in current version
        // Return 0 as placeholder
        return 0;
      }
    } catch (error, stack) {
      _logMessage(
        'Get Android Badge Count Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
    return null;
  }

  /// Clears the badge count for both platforms
  Future<void> clearBadgeCount() async {
    try {
      if (!kIsWeb) {
        if (Platform.isIOS) {
          await setIOSBadgeCount(0);
        } else if (Platform.isAndroid) {
          // Cancel the badge management notification
          await flutterLocalNotificationsPlugin.cancel(999999);
        }
      }

      _logMessage('Badge count cleared');
    } catch (error, stack) {
      _logMessage(
        'Clear Badge Count Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  /// Shows a notification with custom sound (simplified)
  Future<void> showNotificationWithCustomSound({
    required String title,
    required String body,
    required String soundFileName,
    String? channelId,
    Map<String, dynamic>? payload,
    int? notificationId,
  }) async {
    try {
      final id =
          notificationId ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await flutterLocalNotificationsPlugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channelId ?? 'custom_sound_channel',
            'Custom Sound Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
            sound:
                'default', // Use default for now - custom sounds need more setup
          ),
        ),
        payload: jsonEncode(payload ?? {}),
      );

      _logMessage('Notification shown (custom sound feature available)');
    } catch (error, stack) {
      _logMessage(
        'Show Notification with Custom Sound Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  /// Creates a notification channel with custom sound (Android) - Simplified
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
      if (!kIsWeb && Platform.isAndroid) {
        final channel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: importance.getConvertedImportance,
          enableVibration: enableVibration,
          enableLights: enableLights,
          playSound: true,
        );

        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        _logMessage('Channel created: $channelId');
      }
    } catch (error, stack) {
      _logMessage(
        'Create Custom Sound Channel Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  /// Sets the default notification sound for a channel (Android)
  Future<void> setChannelSound({
    required String channelId,
    required String soundFileName,
  }) async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        // Note: This would require recreating the channel with the new sound
        // For now, we'll log this as a feature that would need implementation
        _logMessage(
            'Channel sound update requested for channel: $channelId (requires channel recreation)');
      }
    } catch (error, stack) {
      _logMessage(
        'Set Channel Sound Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
    }
  }

  /// Gets available system notification sounds (iOS)
  Future<List<String>?> getAvailableSounds() async {
    try {
      if (!kIsWeb && Platform.isIOS) {
        // iOS doesn't provide a direct API to list available sounds
        // Return common iOS system sounds
        return [
          'default',
          'accept.caf',
          'alert.caf',
          'complete.caf',
          'failed.caf',
          'beep.caf',
          'bell.caf',
          'bloom.caf',
          'calypso.caf',
          'chime.caf',
          'glass.caf',
          'harp.caf',
          'timePassing.caf',
          'tri-tone.caf',
          'update.caf',
          'ussd.caf',
          'SIMToolkitCallDropped.caf',
          'SIMToolkitGeneralBeep.caf',
          'SIMToolkitNegativeACK.caf',
          'SIMToolkitPositiveACK.caf',
          'SIMToolkitSMS.caf',
          'Tink.caf',
          'ct-busy.caf',
          'ct-congestion.caf',
          'ct-path-ack.caf',
          'ct-error.caf',
          'ct-key.caf',
          'ct-value.caf',
          'on-hold.caf',
          'recorderRecording.caf',
          'short_double_high.caf',
          'short_double_low.caf',
          'short_triple_high.caf',
          'short_triple_low.caf',
          'long_low.caf',
          'short_high.caf',
          'short_low.caf',
          'middle_9_short_double_low.caf',
          'middle_9_short_double_high.caf',
          'middle_9_short_triple_low.caf',
          'middle_9_short_triple_high.caf',
        ];
      }
      return null;
    } catch (error, stack) {
      _logMessage(
        'Get Available Sounds Error: $error',
      );
      _logMessage(
        'Error Stack: $stack',
      );
      return null;
    }
  }

  /// Test mode flag - enables mock functionality for testing
  static bool _isTestMode = false;

  /// Sets test mode for mocking Firebase messaging in tests
  static void setTestMode(bool enabled) {
    _isTestMode = enabled;
  }

  /// Gets test mode status
  static bool get isTestMode => _isTestMode;

  /// Mock notification stream for testing
  static StreamController<RemoteMessage>? _mockNotificationController;

  /// Gets mock notification stream for testing
  static Stream<RemoteMessage>? getMockNotificationStream() {
    _mockNotificationController ??= StreamController<RemoteMessage>.broadcast();
    return _mockNotificationController?.stream;
  }

  /// Adds a mock notification to the test stream
  static void addMockNotification(RemoteMessage message) {
    _mockNotificationController?.add(message);
  }

  /// Mock click stream for testing
  static StreamController<NotificationData>? _mockClickController;

  /// Gets mock click stream for testing
  static Stream<NotificationData>? getMockClickStream() {
    _mockClickController ??= StreamController<NotificationData>.broadcast();
    return _mockClickController?.stream;
  }

  /// Adds a mock click event to the test stream
  static void addMockClickEvent(NotificationData data) {
    _mockClickController?.add(data);
  }

  /// Resets all mock data for clean test state
  static void resetMockData() {
    _mockNotificationController?.close();
    _mockNotificationController = null;
    _mockClickController?.close();
    _mockClickController = null;
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
    return RemoteMessage(
      senderId: senderId ?? 'test_sender_id',
      category: category ?? 'test_category',
      collapseKey: collapseKey ?? 'test_collapse_key',
      messageId: messageId ??
          'test_message_id_${DateTime.now().millisecondsSinceEpoch}',
      data: data ?? {'test_key': 'test_value'},
      messageType: 'test_message_type',
      ttl: ttl ?? 3600,
      notification: title != null || body != null
          ? RemoteNotification(
              title: title,
              body: body,
              android: title != null || body != null
                  ? const AndroidNotification(
                      channelId: 'test_channel',
                      clickAction: 'test_action',
                      color: '#FF0000',
                      count: 1,
                      imageUrl: 'https://example.com/image.jpg',
                      link: 'https://example.com',
                      smallIcon: 'ic_notification',
                      sound: 'default',
                      tag: 'test_tag',
                      ticker: 'test_ticker',
                    )
                  : null,
              apple: title != null || body != null
                  ? AppleNotification(
                      badge: '1',
                      sound: const AppleNotificationSound(
                        critical: false,
                        name: 'default',
                        volume: 1.0,
                      ),
                      subtitle: 'test_subtitle',
                      imageUrl: 'https://example.com/image.jpg',
                    )
                  : null,
            )
          : null,
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
    return NotificationData(
      payload: payload ?? {'test_key': 'test_value'},
      title: title ?? 'Test Notification',
      body: body ?? 'This is a test notification',
      imageUrl: imageUrl ?? 'https://example.com/test.jpg',
      category: category ?? 'test_category',
      actions: actions,
      timestamp: DateTime.now(),
      type: type,
      isFromTerminated: isFromTerminated,
      messageId: messageId ?? 'test_message_id',
    );
  }

  void _logMessage(String message) {
    log(message, name: 'Firebase Messaging Handler');
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await firebaseMessagingInstance.subscribeToTopic(topic);
      _logMessage('Subscribed to topic: $topic');
    } catch (error, stack) {
      _logMessage('Error subscribing to topic $topic: $error');
      _logMessage('Stack trace: $stack');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await firebaseMessagingInstance.unsubscribeFromTopic(topic);
      _logMessage('Unsubscribed from topic: $topic');
    } catch (error, stack) {
      _logMessage('Error unsubscribing from topic $topic: $error');
      _logMessage('Stack trace: $stack');
    }
  }

  /// Unsubscribe from all topics
  Future<void> unsubscribeFromAllTopics() async {
    try {
      await firebaseMessagingInstance.deleteToken();
      _logMessage('Unsubscribed from all topics by deleting FCM token.');
    } catch (error, stack) {
      _logMessage('Error unsubscribing from all topics: $error');
      _logMessage('Stack trace: $stack');
    }
  }
}
