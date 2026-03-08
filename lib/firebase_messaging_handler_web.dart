import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'firebase_messaging_handler.dart';

/// Registers the web implementation so the plugin can participate in the
/// generated plugin registrant without additional setup.
class FirebaseMessagingHandlerWeb {
  static void registerWith(Registrar registrar) {
    // Touch the singleton to ensure any required lazy initialization runs.
    FirebaseMessagingHandler.instance;
    // Required to keep the registrar alive for method channel plugins.
    registrar.registerMessageHandler();
  }
}
