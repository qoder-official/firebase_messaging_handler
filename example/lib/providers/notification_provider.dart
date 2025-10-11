import 'package:flutter/foundation.dart';
import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';

class NotificationProvider extends ChangeNotifier {
  final List<NotificationData> _notifications = [];
  NotificationData? _initialNotification;
  String? _fcmToken;
  bool _isInitialized = false;
  int _iosBadgeCount = 0;
  int _androidBadgeCount = 0;

  List<NotificationData> get notifications => _notifications;
  NotificationData? get initialNotification => _initialNotification;
  String? get fcmToken => _fcmToken;
  bool get isInitialized => _isInitialized;
  int get iosBadgeCount => _iosBadgeCount;
  int get androidBadgeCount => _androidBadgeCount;

  void addNotification(NotificationData notification) {
    _notifications.insert(0, notification); // Add to beginning for latest first
    notifyListeners();
  }

  void setInitialNotification(NotificationData? notification) {
    _initialNotification = notification;
    notifyListeners();
  }

  void setFcmToken(String? token) {
    _fcmToken = token;
    notifyListeners();
  }

  void setInitialized(bool initialized) {
    _isInitialized = initialized;
    notifyListeners();
  }

  void setIOSBadgeCount(int count) {
    _iosBadgeCount = count;
    notifyListeners();
  }

  void setAndroidBadgeCount(int count) {
    _androidBadgeCount = count;
    notifyListeners();
  }

  void clearNotifications() {
    _notifications.clear();
    notifyListeners();
  }

  void incrementIOSBadge() {
    _iosBadgeCount++;
    notifyListeners();
  }

  void incrementAndroidBadge() {
    _androidBadgeCount++;
    notifyListeners();
  }

  void clearBadges() {
    _iosBadgeCount = 0;
    _androidBadgeCount = 0;
    notifyListeners();
  }
}
