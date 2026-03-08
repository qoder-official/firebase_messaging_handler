import 'platform_utils_web.dart' if (dart.library.io) 'platform_utils_io.dart';

/// Provides platform-specific flags in a web-safe way.
bool get isWeb => platformIsWeb;

bool get isAndroid => platformIsAndroid;

bool get isIOS => platformIsIOS;

bool get isMacOS => platformIsMacOS;

bool get isWindows => platformIsWindows;

bool get isLinux => platformIsLinux;

bool get isFuchsia => platformIsFuchsia;

bool get isMobile => platformIsAndroid || platformIsIOS;

String get currentPlatformName => platformDisplayName;
