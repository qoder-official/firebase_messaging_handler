/// Interface for storage service operations
abstract class StorageServiceInterface {
  /// Saves FCM token
  Future<void> saveFcmToken(String token);

  /// Gets FCM token
  Future<String?> getFcmToken();

  /// Removes FCM token
  Future<void> removeFcmToken();

  /// Saves notification data
  Future<void> saveNotification(dynamic message);

  /// Gets stored notifications
  Future<List<dynamic>> getStoredNotifications();

  /// Clears stored notifications
  Future<void> clearStoredNotifications();

  /// Saves configuration
  Future<void> saveConfiguration(String key, dynamic value);

  /// Gets configuration
  Future<dynamic> getConfiguration(String key);

  /// Removes configuration
  Future<void> removeConfiguration(String key);

  /// Saves pending in-app message payload
  Future<void> savePendingInAppMessage(Map<String, dynamic> message);

  /// Retrieves pending in-app message payloads
  Future<List<Map<String, dynamic>>> getPendingInAppMessages();

  /// Clears pending in-app messages, optionally by identifier
  Future<void> clearPendingInAppMessages({String? id});
}
