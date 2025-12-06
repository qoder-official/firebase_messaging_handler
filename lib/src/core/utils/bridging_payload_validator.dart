import 'dart:convert';

/// Validates data-only / bridging payloads before promotion or unified handling.
class BridgingPayloadValidator {
  /// Returns true when the payload is valid. Calls [onError] with a human-friendly
  /// reason when invalid.
  static bool validate(
    Map<String, dynamic> data, {
    void Function(String reason)? onError,
  }) {
    String? _asString(dynamic value) =>
        value == null ? null : value.toString().trim();

    bool fail(String reason) {
      onError?.call(reason);
      return false;
    }

    final String? title = _asString(data['title']);
    final String? body = _asString(data['body']);

    if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
      return fail('missing "title" or "body" for data-only bridge');
    }

    // Analytics: allow map or JSON string representing a map.
    final dynamic analytics = data['analytics'];
    if (analytics != null) {
      if (analytics is Map<String, dynamic>) {
        // ok
      } else if (analytics is String) {
        try {
          final decoded = jsonDecode(analytics);
          if (decoded is Map<String, dynamic>) {
            data['analytics'] = decoded;
          } else {
            return fail('"analytics" JSON must decode to a map');
          }
        } catch (_) {
          return fail('"analytics" must be a map or valid JSON string');
        }
      } else {
        return fail('"analytics" must be a map or JSON string');
      }
    }

    // Actions: must be a list of maps with id/title strings.
    if (data['actions'] != null) {
      final dynamic actions = data['actions'];
      if (actions is! List) {
        return fail('"actions" must be an array of action objects');
      }
      for (final dynamic item in actions) {
        if (item is! Map) {
          return fail('each action must be an object with "id" and "title"');
        }
        final String? actionId = _asString(item['id']);
        final String? actionTitle = _asString(item['title']);
        if (actionId == null || actionId.isEmpty || actionTitle == null) {
          return fail('action is missing "id" or "title"');
        }
      }
    }

    // Optional keys type checks.
    final List<String> stringFields = <String>[
      'channelId',
      'image',
      'deeplink',
      'templateId',
      'priority',
      'category',
    ];
    for (final String field in stringFields) {
      if (data[field] != null && data[field] is! String) {
        return fail('"$field" must be a string when provided');
      }
    }

    return true;
  }
}

