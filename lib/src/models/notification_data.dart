import '../enums/index.dart';

class NotificationAction {
  final String id;
  final String title;
  final bool destructive;
  final Map<String, dynamic>? payload;

  const NotificationAction({
    required this.id,
    required this.title,
    this.destructive = false,
    this.payload,
  });
}

class NotificationData {
  final Map<String, dynamic> payload;
  final String? title;
  final String? body;
  final String? imageUrl;
  final String? icon;
  final String? category;
  final List<NotificationAction>? actions;
  final DateTime? timestamp;
  final NotificationTypeEnum type;
  final bool isFromTerminated;
  final String? messageId;
  final String? senderId;
  final int? badgeCount;
  final bool? isSilent;
  final String? sound;
  final String? tag;
  final String? groupKey;
  final Map<String, dynamic>? metadata;

  NotificationData({
    required this.payload,
    this.title,
    this.body,
    this.imageUrl,
    this.icon,
    this.category,
    this.actions,
    this.timestamp,
    this.type = NotificationTypeEnum.foreground,
    this.isFromTerminated = false,
    this.messageId,
    this.senderId,
    this.badgeCount,
    this.isSilent,
    this.sound,
    this.tag,
    this.groupKey,
    this.metadata,
  });

  /// Creates a copy of this NotificationData with the given fields replaced
  NotificationData copyWith({
    Map<String, dynamic>? payload,
    String? title,
    String? body,
    String? imageUrl,
    String? icon,
    String? category,
    List<NotificationAction>? actions,
    DateTime? timestamp,
    NotificationTypeEnum? type,
    bool? isFromTerminated,
    String? messageId,
    String? senderId,
    int? badgeCount,
    bool? isSilent,
    String? sound,
    String? tag,
    String? groupKey,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationData(
      payload: payload ?? this.payload,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      actions: actions ?? this.actions,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isFromTerminated: isFromTerminated ?? this.isFromTerminated,
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      badgeCount: badgeCount ?? this.badgeCount,
      isSilent: isSilent ?? this.isSilent,
      sound: sound ?? this.sound,
      tag: tag ?? this.tag,
      groupKey: groupKey ?? this.groupKey,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Converts the notification data to a map for serialization
  Map<String, dynamic> toMap() {
    return {
      'payload': payload,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'icon': icon,
      'category': category,
      'actions': actions
          ?.map((action) => {
                'id': action.id,
                'title': action.title,
                'destructive': action.destructive,
                'payload': action.payload,
              })
          .toList(),
      'timestamp': timestamp?.toIso8601String(),
      'type': type.name,
      'isFromTerminated': isFromTerminated,
      'messageId': messageId,
      'senderId': senderId,
      'badgeCount': badgeCount,
      'isSilent': isSilent,
      'sound': sound,
      'tag': tag,
      'groupKey': groupKey,
      'metadata': metadata,
    };
  }

  /// Creates a NotificationData from a map
  factory NotificationData.fromMap(Map<String, dynamic> map) {
    return NotificationData(
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      title: map['title'],
      body: map['body'],
      imageUrl: map['imageUrl'],
      icon: map['icon'],
      category: map['category'],
      actions: map['actions'] != null
          ? (map['actions'] as List<dynamic>)
              .map((action) => NotificationAction(
                    id: action['id'],
                    title: action['title'],
                    destructive: action['destructive'] ?? false,
                    payload: action['payload'] != null
                        ? Map<String, dynamic>.from(action['payload'])
                        : null,
                  ))
              .toList()
          : null,
      timestamp:
          map['timestamp'] != null ? DateTime.parse(map['timestamp']) : null,
      type: NotificationTypeEnum.values.firstWhere(
        (type) => type.name == map['type'],
        orElse: () => NotificationTypeEnum.foreground,
      ),
      isFromTerminated: map['isFromTerminated'] ?? false,
      messageId: map['messageId'],
      senderId: map['senderId'],
      badgeCount: map['badgeCount'],
      isSilent: map['isSilent'],
      sound: map['sound'],
      tag: map['tag'],
      groupKey: map['groupKey'],
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }
}
