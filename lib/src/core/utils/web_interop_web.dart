/// WASM-compatible web interop using dart:js_interop.
/// This file is only compiled on web targets.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('Notification')
external JSObject? get _notificationCtor;

@JS('navigator')
external JSObject get _navigator;

@JS('isSecureContext')
external bool get _isSecureContext;

@JS('location')
external JSObject get _location;

String getWebNotificationPermission() {
  try {
    final ctor = _notificationCtor;
    if (ctor == null) return 'unavailable';
    final perm = ctor.getProperty<JSString?>('permission'.toJS);
    return perm?.toDart ?? 'unknown';
  } catch (_) {
    return 'error';
  }
}

Future<bool> requestWebNotificationPermission() async {
  try {
    final ctor = _notificationCtor;
    if (ctor == null) return false;
    final perm =
        ctor.getProperty<JSString?>('permission'.toJS)?.toDart;
    if (perm == 'granted') return true;
    if (perm == 'default') {
      final result = await ctor
          .callMethod<JSPromise<JSString>>('requestPermission'.toJS)
          .toDart;
      return result.toDart == 'granted';
    }
    return false;
  } catch (_) {
    return false;
  }
}

Map<String, dynamic> getWebRuntimeDiagnostics() {
  try {
    final notifAvailable = _notificationCtor != null;
    final nav = _navigator;
    final sw = nav.getProperty<JSObject?>('serviceWorker'.toJS);
    final swController = sw?.getProperty<JSObject?>('controller'.toJS);
    final ua = nav.getProperty<JSString?>('userAgent'.toJS)?.toDart;
    final proto =
        _location.getProperty<JSString?>('protocol'.toJS)?.toDart;
    final host = _location.getProperty<JSString?>('host'.toJS)?.toDart;
    return {
      'supported': notifAvailable,
      'notificationApiAvailable': notifAvailable,
      'serviceWorkerApiAvailable': sw != null,
      'serviceWorkerControllerPresent': swController != null,
      'pushManagerLikelyAvailable':
          sw?.getProperty<JSAny?>('ready'.toJS) != null,
      'isSecureContext': _isSecureContext,
      'locationProtocol': proto,
      'locationHost': host,
      'userAgent': ua,
    };
  } catch (e) {
    return {'supported': false, 'error': e.toString()};
  }
}

Future<void> showWebNotification({
  required String title,
  required String body,
  required String icon,
  required Map<String, dynamic> data,
}) async {
  try {
    final granted = await requestWebNotificationPermission();
    if (!granted) return;
    final ctor = _notificationCtor;
    if (ctor == null) return;
    final opts = {
      'body': body,
      'icon': icon,
      'badge': '/icons/Icon-72.png',
      'tag': 'firebase-notification',
      'requireInteraction': false,
      'silent': false,
    }.jsify();
    ctor.callMethod<JSObject>('new'.toJS, title.toJS, opts!);
  } catch (_) {}
}
