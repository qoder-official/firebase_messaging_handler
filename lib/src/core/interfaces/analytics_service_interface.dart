/// Interface for analytics service operations
abstract class AnalyticsServiceInterface {
  /// Tracks an analytics event
  void trackEvent(String event, Map<String, dynamic> data);

  /// Sets the analytics callback
  void setCallback(
      void Function(String event, Map<String, dynamic> data) callback);

  /// Gets the current platform
  String getCurrentPlatform();

  /// Tracks notification received event
  void trackNotificationReceived(dynamic message);

  /// Tracks notification clicked event
  void trackNotificationClicked(dynamic notificationData);

  /// Tracks notification scheduled event
  void trackNotificationScheduled(String type, Map<String, dynamic> data);

  /// Tracks FCM token event
  void trackTokenEvent(String event, String? token);
}
