import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';
import 'package:firebase_messaging_handler/src/core/utils/bridging_payload_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BridgingPayloadValidator', () {
    test('accepts minimal payload with title', () {
      bool failed = false;
      final ok = BridgingPayloadValidator.validate(
        <String, dynamic>{'title': 'Hello'},
        onError: (_) => failed = true,
      );

      expect(ok, isTrue);
      expect(failed, isFalse);
    });

    test('rejects missing title/body', () {
      String? error;
      final ok = BridgingPayloadValidator.validate(
        <String, dynamic>{'foo': 'bar'},
        onError: (String e) => error = e,
      );

      expect(ok, isFalse);
      expect(error?.toLowerCase().contains('title') ?? false, isTrue);
    });

    test('rejects non-string title/body and invalid actions', () {
      final errors = <String>[];
      final ok = BridgingPayloadValidator.validate(
        <String, dynamic>{
          'title': 123,
          'actions': <dynamic>[
            <String, dynamic>{'id': 'ok'}, // missing title
          ],
          'analytics': 'should-be-map',
        },
        onError: errors.add,
      );

      expect(ok, isFalse);
      expect(errors, isNotEmpty);
      expect(errors, isNotEmpty);
    });

    test('accepts valid actions and analytics map', () {
      bool failed = false;
      final ok = BridgingPayloadValidator.validate(
        <String, dynamic>{
          'title': 'Sale',
          'actions': <dynamic>[
            <String, dynamic>{'id': 'open', 'title': 'Open'},
          ],
          'analytics': <String, dynamic>{'campaign': 'promo'},
        },
        onError: (_) => failed = true,
      );

      expect(ok, isTrue);
      expect(failed, isFalse);
    });
  });
}

