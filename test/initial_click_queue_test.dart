import 'package:firebase_messaging_handler/firebase_messaging_handler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('click events are queued when no listeners are attached', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final NotificationManager manager = NotificationManager.instance;

    final NotificationData event = NotificationData(
      payload: const <String, dynamic>{'hello': 'world'},
      title: 'Hello',
      timestamp: DateTime.now(),
    );

    // Emit before any listeners subscribe.
    manager.emitTestClick(event);

    final List<NotificationData?> received = <NotificationData?>[];
    final stream = manager.getNotificationClickStream().listen(received.add);

    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(received.length, 1);
    expect(received.first?.title, 'Hello');

    await stream.cancel();
  });
}
