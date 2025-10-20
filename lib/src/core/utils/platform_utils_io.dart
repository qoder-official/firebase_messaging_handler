import 'dart:io' show Platform;

bool get platformIsWeb => false;
bool get platformIsAndroid => Platform.isAndroid;
bool get platformIsIOS => Platform.isIOS;
bool get platformIsMacOS => Platform.isMacOS;
bool get platformIsWindows => Platform.isWindows;
bool get platformIsLinux => Platform.isLinux;
bool get platformIsFuchsia => Platform.isFuchsia;
String get platformDisplayName => Platform.operatingSystem;
