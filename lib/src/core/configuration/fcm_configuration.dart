import '../../models/export.dart';
import '../../enums/export.dart';

/// Immutable configuration object describing how the handler should initialize
/// Firebase Messaging, local notifications, analytics, and storage behavior.
class FCMConfiguration {
  /// Sender ID for FCM
  final String senderId;

  /// Android notification channels
  final List<NotificationChannelData> androidChannels;

  /// Android notification icon path
  final String androidNotificationIconPath;

  /// Callback for updating FCM token
  final Future<bool> Function(String fcmToken)? updateTokenCallback;

  /// Whether to include initial notification in stream
  final bool includeInitialNotificationInStream;

  /// Analytics callback
  final void Function(String event, Map<String, dynamic> data)?
      analyticsCallback;

  /// Whether to enable debug logging
  final bool enableDebugLogging;

  /// Whether to save notifications to storage
  final bool saveNotificationsToStorage;

  /// Maximum number of notifications to store
  final int maxStoredNotifications;

  /// Whether to enable background message handling
  final bool enableBackgroundMessageHandling;

  /// Whether to enable foreground message handling
  final bool enableForegroundMessageHandling;

  /// Whether to enable notification scheduling
  final bool enableNotificationScheduling;

  /// Whether to enable badge management
  final bool enableBadgeManagement;

  /// Whether to enable topic subscriptions
  final bool enableTopicSubscriptions;

  /// Default notification channel ID
  final String? defaultChannelId;

  /// Default notification importance
  final NotificationImportanceEnum defaultImportance;

  /// Default notification priority
  final NotificationPriorityEnum defaultPriority;

  /// Whether to enable sound by default
  final bool enableSoundByDefault;

  /// Whether to enable vibration by default
  final bool enableVibrationByDefault;

  /// Whether to enable lights by default
  final bool enableLightsByDefault;

  /// Whether to show badge by default
  final bool showBadgeByDefault;

  /// Creates a configuration for initializing the handler.
  const FCMConfiguration({
    required this.senderId,
    required this.androidChannels,
    required this.androidNotificationIconPath,
    this.updateTokenCallback,
    this.includeInitialNotificationInStream = false,
    this.analyticsCallback,
    this.enableDebugLogging = true,
    this.saveNotificationsToStorage = true,
    this.maxStoredNotifications = 100,
    this.enableBackgroundMessageHandling = true,
    this.enableForegroundMessageHandling = true,
    this.enableNotificationScheduling = true,
    this.enableBadgeManagement = true,
    this.enableTopicSubscriptions = true,
    this.defaultChannelId,
    this.defaultImportance = NotificationImportanceEnum.high,
    this.defaultPriority = NotificationPriorityEnum.high,
    this.enableSoundByDefault = true,
    this.enableVibrationByDefault = true,
    this.enableLightsByDefault = false,
    this.showBadgeByDefault = true,
  });

  /// Creates a copy of this configuration with selected fields replaced.
  FCMConfiguration copyWith({
    String? senderId,
    List<NotificationChannelData>? androidChannels,
    String? androidNotificationIconPath,
    Future<bool> Function(String fcmToken)? updateTokenCallback,
    bool? includeInitialNotificationInStream,
    void Function(String event, Map<String, dynamic> data)? analyticsCallback,
    bool? enableDebugLogging,
    bool? saveNotificationsToStorage,
    int? maxStoredNotifications,
    bool? enableBackgroundMessageHandling,
    bool? enableForegroundMessageHandling,
    bool? enableNotificationScheduling,
    bool? enableBadgeManagement,
    bool? enableTopicSubscriptions,
    String? defaultChannelId,
    NotificationImportanceEnum? defaultImportance,
    NotificationPriorityEnum? defaultPriority,
    bool? enableSoundByDefault,
    bool? enableVibrationByDefault,
    bool? enableLightsByDefault,
    bool? showBadgeByDefault,
  }) {
    return FCMConfiguration(
      senderId: senderId ?? this.senderId,
      androidChannels: androidChannels ?? this.androidChannels,
      androidNotificationIconPath:
          androidNotificationIconPath ?? this.androidNotificationIconPath,
      updateTokenCallback: updateTokenCallback ?? this.updateTokenCallback,
      includeInitialNotificationInStream: includeInitialNotificationInStream ??
          this.includeInitialNotificationInStream,
      analyticsCallback: analyticsCallback ?? this.analyticsCallback,
      enableDebugLogging: enableDebugLogging ?? this.enableDebugLogging,
      saveNotificationsToStorage:
          saveNotificationsToStorage ?? this.saveNotificationsToStorage,
      maxStoredNotifications:
          maxStoredNotifications ?? this.maxStoredNotifications,
      enableBackgroundMessageHandling: enableBackgroundMessageHandling ??
          this.enableBackgroundMessageHandling,
      enableForegroundMessageHandling: enableForegroundMessageHandling ??
          this.enableForegroundMessageHandling,
      enableNotificationScheduling:
          enableNotificationScheduling ?? this.enableNotificationScheduling,
      enableBadgeManagement:
          enableBadgeManagement ?? this.enableBadgeManagement,
      enableTopicSubscriptions:
          enableTopicSubscriptions ?? this.enableTopicSubscriptions,
      defaultChannelId: defaultChannelId ?? this.defaultChannelId,
      defaultImportance: defaultImportance ?? this.defaultImportance,
      defaultPriority: defaultPriority ?? this.defaultPriority,
      enableSoundByDefault: enableSoundByDefault ?? this.enableSoundByDefault,
      enableVibrationByDefault:
          enableVibrationByDefault ?? this.enableVibrationByDefault,
      enableLightsByDefault:
          enableLightsByDefault ?? this.enableLightsByDefault,
      showBadgeByDefault: showBadgeByDefault ?? this.showBadgeByDefault,
    );
  }

  /// Recreates a configuration from a serialized map.
  factory FCMConfiguration.fromMap(Map<String, dynamic> map) {
    return FCMConfiguration(
      senderId: map['senderId'] ?? '',
      androidChannels: map['androidChannels'] != null
          ? (map['androidChannels'] as List<dynamic>)
              .map((channel) => NotificationChannelData(
                    id: channel['id'] ?? '',
                    name: channel['name'] ?? '',
                    description: channel['description'],
                    groupId: channel['groupId'],
                    importance: NotificationImportanceEnum.values.firstWhere(
                      (importance) => importance.name == channel['importance'],
                      orElse: () => NotificationImportanceEnum.high,
                    ),
                    playSound: channel['playSound'] ?? true,
                    soundPath: channel['soundPath'],
                    enableVibration: channel['enableVibration'] ?? true,
                    enableLights: channel['enableLights'] ?? false,
                    vibrationPattern: channel['vibrationPattern'],
                    ledColor: channel['ledColor'],
                    showBadge: channel['showBadge'] ?? true,
                    priority: NotificationPriorityEnum.values.firstWhere(
                      (priority) => priority.name == channel['priority'],
                      orElse: () => NotificationPriorityEnum.high,
                    ),
                    actions: channel['actions'],
                  ))
              .toList()
          : [],
      androidNotificationIconPath: map['androidNotificationIconPath'] ?? '',
      includeInitialNotificationInStream:
          map['includeInitialNotificationInStream'] ?? false,
      enableDebugLogging: map['enableDebugLogging'] ?? true,
      saveNotificationsToStorage: map['saveNotificationsToStorage'] ?? true,
      maxStoredNotifications: map['maxStoredNotifications'] ?? 100,
      enableBackgroundMessageHandling:
          map['enableBackgroundMessageHandling'] ?? true,
      enableForegroundMessageHandling:
          map['enableForegroundMessageHandling'] ?? true,
      enableNotificationScheduling: map['enableNotificationScheduling'] ?? true,
      enableBadgeManagement: map['enableBadgeManagement'] ?? true,
      enableTopicSubscriptions: map['enableTopicSubscriptions'] ?? true,
      defaultChannelId: map['defaultChannelId'],
      defaultImportance: NotificationImportanceEnum.values.firstWhere(
        (importance) => importance.name == map['defaultImportance'],
        orElse: () => NotificationImportanceEnum.high,
      ),
      defaultPriority: NotificationPriorityEnum.values.firstWhere(
        (priority) => priority.name == map['defaultPriority'],
        orElse: () => NotificationPriorityEnum.high,
      ),
      enableSoundByDefault: map['enableSoundByDefault'] ?? true,
      enableVibrationByDefault: map['enableVibrationByDefault'] ?? true,
      enableLightsByDefault: map['enableLightsByDefault'] ?? false,
      showBadgeByDefault: map['showBadgeByDefault'] ?? true,
    );
  }

  /// Converts the configuration to a serializable map.
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'androidChannels': androidChannels
          .map((channel) => {
                'id': channel.id,
                'name': channel.name,
                'description': channel.description,
                'groupId': channel.groupId,
                'importance': channel.importance.name,
                'playSound': channel.playSound,
                'soundPath': channel.soundPath,
                'enableVibration': channel.enableVibration,
                'enableLights': channel.enableLights,
                'vibrationPattern': channel.vibrationPattern,
                'ledColor': channel.ledColor,
                'showBadge': channel.showBadge,
                'priority': channel.priority.name,
                'actions': channel.actions,
              })
          .toList(),
      'androidNotificationIconPath': androidNotificationIconPath,
      'includeInitialNotificationInStream': includeInitialNotificationInStream,
      'enableDebugLogging': enableDebugLogging,
      'saveNotificationsToStorage': saveNotificationsToStorage,
      'maxStoredNotifications': maxStoredNotifications,
      'enableBackgroundMessageHandling': enableBackgroundMessageHandling,
      'enableForegroundMessageHandling': enableForegroundMessageHandling,
      'enableNotificationScheduling': enableNotificationScheduling,
      'enableBadgeManagement': enableBadgeManagement,
      'enableTopicSubscriptions': enableTopicSubscriptions,
      'defaultChannelId': defaultChannelId,
      'defaultImportance': defaultImportance.name,
      'defaultPriority': defaultPriority.name,
      'enableSoundByDefault': enableSoundByDefault,
      'enableVibrationByDefault': enableVibrationByDefault,
      'enableLightsByDefault': enableLightsByDefault,
      'showBadgeByDefault': showBadgeByDefault,
    };
  }

  /// Returns true when the minimum required initialization fields are present.
  bool get isValid {
    return senderId.isNotEmpty &&
        androidChannels.isNotEmpty &&
        androidNotificationIconPath.isNotEmpty;
  }

  /// Returns a list of validation errors for missing required fields.
  List<String> get validationErrors {
    final List<String> errors = [];

    if (senderId.isEmpty) {
      errors.add('Sender ID is required');
    }

    if (androidChannels.isEmpty) {
      errors.add('At least one Android channel is required');
    }

    if (androidNotificationIconPath.isEmpty) {
      errors.add('Android notification icon path is required');
    }

    if (maxStoredNotifications <= 0) {
      errors.add('Maximum stored notifications must be greater than 0');
    }

    return errors;
  }
}
