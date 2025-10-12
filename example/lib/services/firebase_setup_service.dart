import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../firebase_options.dart';

enum FirebaseErrorType {
  general,
  iosApns,
  packageName,
  configurationFile,
  unknown,
}

class FirebaseSetupService {
  static bool _isInitialized = false;
  static bool _isConfigured = false;
  static String? _errorMessage;
  static FirebaseErrorType _errorType = FirebaseErrorType.unknown;

  static bool get isInitialized => _isInitialized;
  static bool get isConfigured => _isConfigured;
  static String? get errorMessage => _errorMessage;
  static FirebaseErrorType get errorType => _errorType;
  static bool get isIOSApnsError => _errorType == FirebaseErrorType.iosApns;
  static bool get requiresRecompile =>
      _errorType == FirebaseErrorType.packageName ||
      _errorType == FirebaseErrorType.configurationFile;

  /// Initialize Firebase and check if it's properly configured
  static Future<bool> initializeAndCheck() async {
    try {
      debugPrint('[FirebaseSetupService] Starting Firebase initialization...');

      // Initialize Firebase Core
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
      debugPrint(
        '[FirebaseSetupService] Firebase Core initialized successfully',
      );

      // Check if Firebase Messaging is available
      final messaging = FirebaseMessaging.instance;

      // Try to get the default FCM token to verify configuration
      try {
        final token = await messaging.getToken();
        if (token != null && token.isNotEmpty) {
          _isConfigured = true;
          debugPrint(
            '[FirebaseSetupService] Firebase Messaging configured successfully',
          );
          debugPrint(
            '[FirebaseSetupService] FCM Token: ${token.substring(0, 20)}...',
          );
          return true;
        } else {
          _errorMessage =
              'FCM token is null or empty. Check Firebase configuration.';
          debugPrint('[FirebaseSetupService] Error: $_errorMessage');
          return false;
        }
      } catch (e) {
        final errorString = e.toString().toLowerCase();

        // Categorize the error type
        if (errorString.contains('apns') ||
            errorString.contains('apple push notification') ||
            errorString.contains('apns token')) {
          _errorType = FirebaseErrorType.iosApns;
          _errorMessage =
              'iOS APNs not configured in Firebase Console. This is required for iOS notifications.';
        } else if (errorString.contains('messaging sender id') ||
            errorString.contains('sender id') ||
            errorString.contains('bundle id') ||
            errorString.contains('package name')) {
          _errorType = FirebaseErrorType.packageName;
          _errorMessage =
              'Package name or bundle ID mismatch. Check Firebase Console configuration and app settings.';
        } else if (errorString.contains('google-services') ||
            errorString.contains('googleservice-info') ||
            errorString.contains('configuration') ||
            errorString.contains('file not found')) {
          _errorType = FirebaseErrorType.configurationFile;
          _errorMessage =
              'Firebase configuration files missing or incorrect. Check google-services.json and GoogleService-Info.plist.';
        } else {
          _errorType = FirebaseErrorType.general;
          _errorMessage = 'Firebase configuration error: $e';
        }

        debugPrint('[FirebaseSetupService] Error Type: $_errorType');
        debugPrint('[FirebaseSetupService] Error Message: $_errorMessage');
        debugPrint('[FirebaseSetupService] Full error: $e');
        return false;
      }
    } catch (e) {
      _isInitialized = false;
      _errorMessage = 'Firebase initialization failed: $e';
      debugPrint('[FirebaseSetupService] Error: $_errorMessage');
      return false;
    }
  }

  /// Check if Firebase configuration files exist
  static Future<bool> checkConfigurationFiles() async {
    try {
      // This is a basic check - in a real app, you'd check for actual file existence
      // For now, we'll rely on the FCM token test
      return true;
    } catch (e) {
      debugPrint('[FirebaseSetupService] Configuration file check failed: $e');
      return false;
    }
  }

  /// Get setup instructions based on the error
  static String getSetupInstructions() {
    if (!_isInitialized) {
      return 'Firebase Core failed to initialize. Check your firebase_options.dart file and ensure Firebase is properly configured.';
    }

    if (!_isConfigured) {
      return 'Firebase Messaging is not configured. Please:\n\n'
          '1. Add your app to Firebase Console\n'
          '2. Download google-services.json (Android) and GoogleService-Info.plist (iOS)\n'
          '3. Place them in the correct directories\n'
          '4. For iOS: Upload APNS key to Firebase Console\n'
          '5. Restart the app';
    }

    return 'Firebase is properly configured!';
  }

  /// Reset the service state (useful for retrying)
  static void reset() {
    _isInitialized = false;
    _isConfigured = false;
    _errorMessage = null;
    _errorType = FirebaseErrorType.unknown;
  }
}
