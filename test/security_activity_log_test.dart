import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_guard/security_activity_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('starts with no events when local storage is empty', () async {
    final log = SecurityActivityLog();

    await log.ready;

    expect(log.events, isEmpty);
  });

  test('loads events saved by an earlier activity-log instance', () async {
    final firstLog = SecurityActivityLog();
    await firstLog.ready;

    firstLog.record(
      title: 'Login successful',
      description: 'A Firebase Authentication login was completed.',
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final secondLog = SecurityActivityLog();
    await secondLog.ready;

    expect(secondLog.events, hasLength(1));
    expect(secondLog.events.first.title, 'Login successful');
  });

  test('clears events from local storage', () async {
    final log = SecurityActivityLog();
    await log.ready;

    log.record(
      title: 'Logout',
      description: 'The Firebase Authentication session was signed out.',
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    log.clear();
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final reloadedLog = SecurityActivityLog();
    await reloadedLog.ready;

    expect(reloadedLog.events, isEmpty);
  });
}
