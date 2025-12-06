import '../../models/notification_inbox_item.dart';

abstract class NotificationInboxStorageInterface {
  Future<List<NotificationInboxItem>> fetch({
    int page = 0,
    int pageSize = 20,
  });

  Future<void> upsert(NotificationInboxItem item);

  Future<void> upsertAll(List<NotificationInboxItem> items);

  Future<void> markRead(List<String> ids, {bool isRead = true});

  Future<void> delete(List<String> ids);

  Future<void> clear();

  Future<int> count({bool unreadOnly = false});
}

