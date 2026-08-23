/// A transparent summary of the Firebase Authentication account information
/// that Cloud Guard can currently inspect.
///
/// This is an account-setup checklist, not a security-risk assessment and not
/// a source of real-time monitoring data.
class SecuritySetupSummary {
  const SecuritySetupSummary._({
    required this.score,
    required this.checks,
  });

  final int score;
  final List<SecuritySetupCheck> checks;

  /// Creates a summary from Firebase Authentication account facts.
  factory SecuritySetupSummary.fromAccount({
    required bool isSignedIn,
    required String? email,
    required Iterable<String> providerIds,
    required bool isEmailVerified,
  }) {
    final hasEmail = email != null && email.trim().isNotEmpty;
    final hasPasswordProvider = providerIds.contains('password');

    final checks = [
      SecuritySetupCheck(
        title: 'Signed-in account',
        description: isSignedIn
            ? 'A Firebase Authentication session is active.'
            : 'No Firebase Authentication session is active.',
        isComplete: isSignedIn,
      ),
      SecuritySetupCheck(
        title: 'Account email',
        description: hasEmail
            ? 'An email address is available for this account.'
            : 'No account email is available.',
        isComplete: hasEmail,
      ),
      SecuritySetupCheck(
        title: 'Password sign-in',
        description: hasPasswordProvider
            ? 'Email and password sign-in is linked to this account.'
            : 'Email and password sign-in is not linked to this account.',
        isComplete: hasPasswordProvider,
      ),
      SecuritySetupCheck(
        title: 'Email verification',
        description: isEmailVerified
            ? 'Firebase reports this account email as verified.'
            : 'Firebase does not report this account email as verified.',
        isComplete: isEmailVerified,
      ),
    ];

    final completedChecks = checks.where((check) => check.isComplete).length;
    return SecuritySetupSummary._(
      score: completedChecks * 25,
      checks: List.unmodifiable(checks),
    );
  }

  String get label {
    if (score == 100) {
      return 'Account setup complete';
    }
    if (score >= 75) {
      return 'Account setup needs attention';
    }
    return 'Account setup in progress';
  }
}

class SecuritySetupCheck {
  const SecuritySetupCheck({
    required this.title,
    required this.description,
    required this.isComplete,
  });

  final String title;
  final String description;
  final bool isComplete;
}
