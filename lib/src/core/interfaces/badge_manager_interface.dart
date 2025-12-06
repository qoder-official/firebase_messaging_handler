abstract class BadgeManagerInterface {
  /// Sets the badge count on the app icon.
  Future<void> setBadgeCount(int count);

  /// Gets the current badge count.
  Future<int> getBadgeCount();

  /// Removes the badge from the app icon.
  Future<void> removeBadge();

  /// Checks if badges are supported on the current device/platform.
  Future<bool> isSupported();

  /// Increments the badge count by [amount].
  Future<void> incrementBadgeCount({int amount = 1});

  /// Decrements the badge count by [amount].
  Future<void> decrementBadgeCount({int amount = 1});
}
