import 'dart:async';
import 'package:flutter/foundation.dart';
import '../interfaces/badge_manager_interface.dart';
import '../services/storage_service.dart';
import '../services/firebase_messaging_handler_notification_service.dart';
import '../utils/platform_utils.dart';
import '../../constants/firebase_messaging_handler_constants.dart';

/// Manager class for handling app icon badges
class BadgeManager implements BadgeManagerInterface {
  static BadgeManager? _instance;

  final StorageService _storageService = StorageService.instance;
  final FirebaseMessagingHandlerNotificationService _notificationService =
      FirebaseMessagingHandlerNotificationService.instance;

  /// Singleton instance
  static BadgeManager get instance {
    _instance ??= BadgeManager._internal();
    return _instance!;
  }

  BadgeManager._internal();

  @override
  Future<bool> isSupported() async {
    // Web doesn't support app icon badges in the traditional sense
    if (isWeb) return false;

    // iOS is supported via flutter_local_notifications
    if (isIOS || isMacOS) return true;

    // Android support is fragmented and depends on the launcher.
    // We'll return true for now as we can at least track the count
    // and attempt to set it via notifications.
    if (isAndroid) return true;

    return false;
  }

  @override
  Future<void> setBadgeCount(int count) async {
    try {
      if (count < 0) {
        _logMessage(
            '[BadgeManager] Badge count cannot be negative. Setting to 0.');
        count = 0;
      }

      if (!await isSupported()) {
        _logMessage('[BadgeManager] Badges not supported on this platform.');
        return;
      }

      // 1. Persist the count locally
      await _persistBadgeCount(count);

      // 2. Update platform specific badge
      if (isIOS || isMacOS) {
        // iOS/macOS handling via flutter_local_notifications (or platform channel if we had one)
        // Currently delegating to the existing service which wraps flutter_local_notifications
        await _notificationService.setIOSBadgeCount(count);
      } else if (isAndroid) {
        // Android handling
        // For now, we update the service which might set it on the next notification
        // or if we implement a native bridge later.
        await _notificationService.setAndroidBadgeCount(count);
      }

      _logMessage('[BadgeManager] Badge count set to $count');
    } catch (e, stack) {
      _logMessage('[BadgeManager] Error setting badge count: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  @override
  Future<int> getBadgeCount() async {
    try {
      final dynamic stored = await _storageService.getConfiguration(
        FirebaseMessagingHandlerConstants.badgeCountPrefKey,
      );

      if (stored is int) return stored;
      if (stored is double) return stored.toInt();

      return 0;
    } catch (e) {
      _logMessage('[BadgeManager] Error getting badge count: $e');
      return 0;
    }
  }

  @override
  Future<void> removeBadge() async {
    await setBadgeCount(0);
  }

  @override
  Future<void> incrementBadgeCount({int amount = 1}) async {
    final int current = await getBadgeCount();
    await setBadgeCount(current + amount);
  }

  @override
  Future<void> decrementBadgeCount({int amount = 1}) async {
    final int current = await getBadgeCount();
    final int newCount = current - amount;
    await setBadgeCount(newCount < 0 ? 0 : newCount);
  }

  Future<void> _persistBadgeCount(int count) async {
    await _storageService.saveConfiguration(
      FirebaseMessagingHandlerConstants.badgeCountPrefKey,
      count,
    );
  }

  void _logMessage(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
}
