import 'package:cloud_guard/security_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecuritySetupSummary', () {
    test('reports no completed checks when no account is signed in', () {
      final summary = SecuritySetupSummary.fromAccount(
        isSignedIn: false,
        email: null,
        providerIds: const [],
        isEmailVerified: false,
      );

      expect(summary.score, 0);
      expect(summary.checks.where((check) => check.isComplete), isEmpty);
    });

    test('reports an unverified email and password account accurately', () {
      final summary = SecuritySetupSummary.fromAccount(
        isSignedIn: true,
        email: 'user@example.com',
        providerIds: const ['password'],
        isEmailVerified: false,
      );

      expect(summary.score, 75);
      expect(summary.checks.last.isComplete, isFalse);
      expect(summary.label, 'Account setup needs attention');
    });

    test('reports a verified email and password account as complete', () {
      final summary = SecuritySetupSummary.fromAccount(
        isSignedIn: true,
        email: 'user@example.com',
        providerIds: const ['password'],
        isEmailVerified: true,
      );

      expect(summary.score, 100);
      expect(summary.checks.every((check) => check.isComplete), isTrue);
      expect(summary.label, 'Account setup complete');
    });

    test('does not credit password sign-in when another provider is linked', () {
      final summary = SecuritySetupSummary.fromAccount(
        isSignedIn: true,
        email: 'user@example.com',
        providerIds: const ['google.com'],
        isEmailVerified: true,
      );

      expect(summary.score, 75);
      expect(summary.checks[2].isComplete, isFalse);
    });
  });
}
