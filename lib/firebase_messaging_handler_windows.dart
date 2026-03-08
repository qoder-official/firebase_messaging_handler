/// Windows platform registration stub for firebase_messaging_handler.
///
/// Firebase Cloud Messaging is not available on Windows, but the package
/// supports local features (scheduling, inbox, in-app templates, quiet hours)
/// via `flutter_local_notifications` and pure-Dart implementations.
class FirebaseMessagingHandlerWindows {
  static void registerWith() {
    // No-op: FCM is not available on Windows. Local-notification features
    // are available and initialize lazily via FirebaseMessagingHandler.instance.
  }
}
