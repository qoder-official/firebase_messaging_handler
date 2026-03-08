import Flutter
import UIKit

public class FirebaseMessagingHandlerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    // No native method channels needed — all FCM work is handled by
    // the firebase_messaging package. This stub satisfies the Flutter
    // plugin registry requirement.
  }
}
