/// Base class for FCM-related errors
abstract class FCMError implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  FCMError({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'FCMError: $message${code != null ? ' (Code: $code)' : ''}';
  }

  /// Converts the error to a map for serialization
  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'code': code,
      'originalError': originalError?.toString(),
      'stackTrace': stackTrace?.toString(),
      'timestamp': timestamp.toIso8601String(),
      'type': runtimeType.toString(),
    };
  }
}

/// Error thrown when FCM initialization fails
class FCMInitializationError extends FCMError {
  FCMInitializationError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    super.timestamp,
  });
}

/// Error thrown when FCM token operations fail
class FCMTokenError extends FCMError {
  FCMTokenError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    super.timestamp,
  });
}

/// Error thrown when notification operations fail
class NotificationError extends FCMError {
  NotificationError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    super.timestamp,
  });
}

/// Error thrown when permission operations fail
class PermissionError extends FCMError {
  PermissionError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    super.timestamp,
  });
}

/// Error thrown when storage operations fail
class StorageError extends FCMError {
  StorageError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    super.timestamp,
  });
}

/// Error thrown when configuration is invalid
class ConfigurationError extends FCMError {
  ConfigurationError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    super.timestamp,
  });
}

/// Error thrown when analytics operations fail
class AnalyticsError extends FCMError {
  AnalyticsError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
    super.timestamp,
  });
}
