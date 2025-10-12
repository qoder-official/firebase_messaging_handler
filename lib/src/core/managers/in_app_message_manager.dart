import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../services/export.dart';
import '../../enums/export.dart';
import '../../models/export.dart';

class InAppMessageManager {
  static InAppMessageManager? _instance;

  static InAppMessageManager get instance {
    _instance ??= InAppMessageManager._internal();
    return _instance!;
  }

  InAppMessageManager._internal();

  final StorageService _storageService = StorageService.instance;
  final AnalyticsService _analyticsService = AnalyticsService.instance;

  final Map<String, InAppNotificationTemplate> _templates =
      <String, InAppNotificationTemplate>{};
  final Set<String> _processedMessageIds = <String>{};
  final List<InAppNotificationData> _pendingMemoryQueue =
      <InAppNotificationData>[];
  StreamController<InAppNotificationData>? _streamController;
  bool _hasHydratedStorage = false;
  InAppNotificationDisplayCallback? _fallbackDisplay;

  Stream<InAppNotificationData> getMessageStream({
    bool includePendingStorageItems = true,
  }) {
    _streamController ??=
        StreamController<InAppNotificationData>.broadcast(onListen: () {
      if (includePendingStorageItems) {
        unawaited(_deliverPendingFromStorage());
      }
    });

    if (includePendingStorageItems && !_hasHydratedStorage) {
      unawaited(_deliverPendingFromStorage());
    }

    if (_pendingMemoryQueue.isNotEmpty) {
      for (final InAppNotificationData queued in _pendingMemoryQueue) {
        _streamController?.add(queued);
      }
      _pendingMemoryQueue.clear();
    }

    return _streamController!.stream;
  }

  void registerTemplates(Map<String, InAppNotificationTemplate> templates) {
    _templates.addAll(templates);
    _logMessage(
        '[InAppMessageManager] Registered templates: ${templates.keys.join(', ')}');
  }

  void clearTemplates() {
    _templates.clear();
    _logMessage('[InAppMessageManager] Templates cleared');
  }

  void setFallbackDisplayHandler(
      InAppNotificationDisplayCallback? fallbackDisplay) {
    _fallbackDisplay = fallbackDisplay;
  }

  Future<void> handleRemoteMessage(RemoteMessage message) async {
    final Map<String, dynamic>? rawPayload = _extractInAppPayload(message.data);
    if (rawPayload == null) {
      return;
    }

    final String candidateId =
        rawPayload['id'] as String? ?? message.messageId ?? _generateTempId();
    if (_processedMessageIds.contains(candidateId)) {
      return;
    }

    final InAppNotificationData data = _buildNotificationData(
      candidateId,
      rawPayload,
      message,
    );

    _processedMessageIds.add(candidateId);
    _analyticsService.trackEvent('in_app_received', <String, dynamic>{
      'template_id': data.templateId,
      'trigger_type': data.triggerType.name,
      'message_id': data.id,
    });

    switch (data.triggerType) {
      case InAppTriggerTypeEnum.immediate:
        _dispatch(data);
        break;
      case InAppTriggerTypeEnum.nextForeground:
      case InAppTriggerTypeEnum.appLaunch:
        await _enqueuePending(data);
        break;
      case InAppTriggerTypeEnum.custom:
        /*
         * Why: Custom triggers are user-defined; we surface them immediately so the host
         * app can decide when and how to render based on its own heuristics.
         */
        _dispatch(data);
        break;
    }
  }

  Future<void> flushPendingInAppMessages() async {
    await _deliverPendingFromStorage();
  }

  Future<void> clearPendingInAppMessages({String? id}) async {
    await _storageService.clearPendingInAppMessages(id: id);
  }

  Future<void> dispose() async {
    await _streamController?.close();
    _streamController = null;
    _processedMessageIds.clear();
    _pendingMemoryQueue.clear();
    _hasHydratedStorage = false;
  }

  Future<void> _enqueuePending(InAppNotificationData data) async {
    _pendingMemoryQueue.add(data);
    await _storageService.savePendingInAppMessage(data.toMap());
    _logMessage(
        '[InAppMessageManager] Pending in-app message queued: ${data.id}');
  }

  Future<void> _deliverPendingFromStorage() async {
    if (_hasHydratedStorage) {
      return;
    }
    _hasHydratedStorage = true;

    final List<Map<String, dynamic>> stored =
        await _storageService.getPendingInAppMessages();
    if (stored.isEmpty) {
      return;
    }

    for (final Map<String, dynamic> item in stored) {
      try {
        final InAppNotificationData data = InAppNotificationData.fromMap(item);
        _dispatch(data);
        await _storageService.clearPendingInAppMessages(id: data.id);
      } catch (error, stack) {
        _logMessage(
            '[InAppMessageManager] Pending message hydration error: $error');
        _logMessage('[InAppMessageManager] Stack trace: $stack');
      }
    }
  }

  void _dispatch(InAppNotificationData data) {
    if (_streamController == null || !_streamController!.hasListener) {
      _pendingMemoryQueue.add(data);
    } else {
      _streamController?.add(data);
    }

    final InAppNotificationTemplate? template = _templates[data.templateId];
    if (template != null) {
      try {
        template.onDisplay(data);
      } catch (error, stack) {
        _logMessage('[InAppMessageManager] Template display error: $error');
        _logMessage('[InAppMessageManager] Stack trace: $stack');
      }
      return;
    }

    if (_fallbackDisplay != null) {
      try {
        _fallbackDisplay!.call(data);
      } catch (error, stack) {
        _logMessage('[InAppMessageManager] Fallback display error: $error');
        _logMessage('[InAppMessageManager] Stack trace: $stack');
      }
    }
  }

  Map<String, dynamic>? _extractInAppPayload(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return null;
    }

    final dynamic payloadCandidate =
        data['fcmh_inapp'] ?? data['in_app_payload'];
    if (payloadCandidate == null) {
      return null;
    }

    if (payloadCandidate is Map<String, dynamic>) {
      return Map<String, dynamic>.from(payloadCandidate);
    }

    if (payloadCandidate is String) {
      try {
        final dynamic decoded = jsonDecode(payloadCandidate);
        if (decoded is Map<String, dynamic>) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (error, stack) {
        _logMessage(
            '[InAppMessageManager] Payload decode error: $error for data: $payloadCandidate');
        _logMessage('[InAppMessageManager] Stack trace: $stack');
      }
    }

    return null;
  }

  InAppNotificationData _buildNotificationData(
    String id,
    Map<String, dynamic> payload,
    RemoteMessage message,
  ) {
    final String templateId = payload['templateId'] as String? ??
        payload['template_id'] as String? ??
        'default';
    final InAppTriggerTypeEnum trigger =
        InAppTriggerTypeEnum.fromString(payload['trigger'] as String?);

    final Map<String, dynamic> analyticsPayload = Map<String, dynamic>.from(
        payload['analytics'] as Map? ?? <String, dynamic>{})
      ..putIfAbsent('campaign_id', () => payload['campaignId'])
      ..putIfAbsent('variant_id', () => payload['variant']);

    final Map<String, dynamic> reservedKeys = <String, dynamic>{
      'templateId': templateId,
      'template_id': templateId,
      'trigger': trigger.name,
      'analytics': analyticsPayload,
      'campaignId': payload['campaignId'],
      'variant': payload['variant'],
      'id': id,
      'autoDismissMs': payload['autoDismissMs'],
    };

    final Map<String, dynamic> content = <String, dynamic>{};
    if (payload['content'] is Map<String, dynamic>) {
      content.addAll(payload['content'] as Map<String, dynamic>);
    }

    if (content.isEmpty) {
      payload.forEach((String key, dynamic value) {
        if (!reservedKeys.containsKey(key)) {
          content[key] = value;
        }
      });
    }

    if (payload['autoDismissMs'] != null) {
      content['autoDismissMs'] = payload['autoDismissMs'];
    }

    return InAppNotificationData(
      id: id,
      templateId: templateId,
      triggerType: trigger,
      content: content,
      analytics: analyticsPayload,
      rawPayload: payload,
      receivedAt: message.sentTime ?? DateTime.now(),
    );
  }

  String _generateTempId() =>
      'inapp_${DateTime.now().microsecondsSinceEpoch}_${_processedMessageIds.length}';

  void _logMessage(String message) {
    if (kDebugMode) {
      print(message);
    }
  }
}
