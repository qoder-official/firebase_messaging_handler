import 'package:flutter/material.dart';

import '../../models/export.dart';
import '../overlay/in_app_overlay_controller.dart';

typedef InAppTemplateActionCallback = void Function(
  String actionId,
  InAppNotificationData data,
);

class VersionPromptTemplateConfig {
  const VersionPromptTemplateConfig({
    this.defaultTitle = 'Update available',
    this.defaultMessage =
        'A newer version of the app is ready. Update now to enjoy the latest features.',
    this.primaryActionId = 'primary',
    this.secondaryActionId = 'secondary',
    this.dismissActionId = 'dismiss',
  });

  final String defaultTitle;
  final String defaultMessage;
  final String primaryActionId;
  final String secondaryActionId;
  final String dismissActionId;
}

class BuiltInInAppTemplates {
  const BuiltInInAppTemplates._();

  static InAppNotificationTemplate versionPrompt({
    required InAppOverlayController controller,
    VersionPromptTemplateConfig config = const VersionPromptTemplateConfig(),
    InAppTemplateActionCallback? onAction,
  }) {
    return InAppNotificationTemplate(
      id: 'builtin_version_prompt',
      description: 'Full-screen dialog encouraging users to update the app',
      autoDismissDuration: null,
      onDisplay: (data) {
        controller.show(
          builder: (context) => _VersionPromptView(
            data: data,
            controller: controller,
            config: config,
            onAction: onAction,
          ),
          dismissible: _resolveDismissible(data, config),
        );
      },
    );
  }

  static InAppNotificationTemplate generic({
    InAppTemplateActionCallback? onAction,
  }) {
    return InAppNotificationTemplate(
      id: 'builtin_generic',
      description:
          'Generic template for various layouts (dialog, banner, bottom sheet, tooltip, carousel)',
      autoDismissDuration: null,
      onDisplay: (data) {
        // For now, we'll use a simple dialog as the default
        // In a full implementation, this would parse the layout type
        // and show the appropriate UI component
        final content = data.content;
        final layout = content['layout'] as String? ?? 'dialog';

        // This is a placeholder - the actual implementation would need
        // access to the overlay controller and context
        // For now, we'll just log that the template was triggered
        debugPrint(
            '[BuiltInInAppTemplates] Generic template triggered with layout: $layout');
        debugPrint('[BuiltInInAppTemplates] Content: $content');

        // Call the action callback if provided
        onAction?.call('generic_triggered', data);
      },
    );
  }

  static bool _resolveDismissible(
    InAppNotificationData data,
    VersionPromptTemplateConfig config,
  ) {
    final dismissible = data.content['dismissible'];
    if (dismissible is bool) {
      return dismissible;
    }
    return true;
  }
}

class _VersionPromptView extends StatelessWidget {
  const _VersionPromptView({
    required this.data,
    required this.controller,
    required this.config,
    this.onAction,
  });

  final InAppNotificationData data;
  final InAppOverlayController controller;
  final VersionPromptTemplateConfig config;
  final InAppTemplateActionCallback? onAction;

  Map<String, dynamic> get _content => data.content;

  @override
  Widget build(BuildContext context) {
    final title = _stringValue('title', fallback: config.defaultTitle);
    final message =
        _stringValue('message', fallback: config.defaultMessage) ?? '';
    final primaryLabel =
        _stringValue('primaryLabel', fallback: 'Update now') ?? 'Update now';
    final secondaryLabel = _stringValue('secondaryLabel', fallback: 'Later');
    final imageUrl = _stringValue('imageUrl');

    return Material(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            alignment: Alignment.center,
                            child: const Icon(Icons.system_update),
                          ),
                        ),
                      ),
                    ),
                  if (imageUrl != null) const SizedBox(height: 18),
                  Text(
                    title ?? config.defaultTitle,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (secondaryLabel != null)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleAction(
                              config.secondaryActionId,
                            ),
                            child: Text(secondaryLabel),
                          ),
                        ),
                      if (secondaryLabel != null) const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () =>
                              _handleAction(config.primaryActionId),
                          child: Text(primaryLabel),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () => _handleAction(config.dismissActionId,
                          dismissOnly: true),
                      child: Text(
                        _stringValue('dismissLabel', fallback: 'Maybe later') ??
                            'Maybe later',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _stringValue(String key, {String? fallback}) {
    final normalizedKey = key;
    final altKey = _snakeToCamel(key);
    if (_content[normalizedKey] is String) {
      return _content[normalizedKey] as String;
    }
    if (_content[altKey] is String) {
      return _content[altKey] as String;
    }
    return fallback;
  }

  String _snakeToCamel(String input) {
    final buffer = StringBuffer();
    var upperNext = false;
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      if (char == '_') {
        upperNext = true;
        continue;
      }
      if (upperNext) {
        buffer.write(char.toUpperCase());
        upperNext = false;
      } else {
        buffer.write(char);
      }
    }
    return buffer.toString();
  }

  Future<void> _handleAction(String actionId,
      {bool dismissOnly = false}) async {
    await controller.dismiss();
    if (!dismissOnly) {
      onAction?.call(actionId, data);
    }
  }
}
