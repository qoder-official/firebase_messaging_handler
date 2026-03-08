/// macOS platform registration stub for firebase_messaging_handler.
///
/// All FCM and local-notification functionality on macOS is handled by
/// the `firebase_messaging` and `flutter_local_notifications` packages.
/// This class exists solely to satisfy Flutter's `dartPluginClass`
/// registration requirement so macOS appears in the platform support matrix.
class FirebaseMessagingHandlerMacos {
  static void registerWith() {
    // No-op: all work is done by firebase_messaging and
    // flutter_local_notifications. The FMH singleton initialises lazily
    // when the host app calls FirebaseMessagingHandler.instance.init().
  }
}
