# ☁️ Cloud Guard

Cloud Guard is a Flutter-based cloud security dashboard and file-management MVP built with Dart and Firebase. It provides Firebase Authentication, account-security tools, responsive dashboard screens, and safe local PDF selection and validation.

## Project Status

Cloud Guard is currently in **MVP development**. Authentication, authentication-state routing, responsive layouts, local PDF selection and validation, the account-security presentation, and honest Storage/Recent Uploads empty states are working and tested.

> **Firebase Storage is not currently enabled or configured for live uploads.** The app does not upload files to the cloud, and it does not simulate upload progress or upload success.

## Completed Features

### Authentication and account security

- Email/password account registration and login.
- Authentication-state routing between the Login page and signed-in dashboard.
- Logout and session handling.
- Forgot-password and password-reset email flow through Firebase Authentication.
- Password visibility controls.
- Validation and clear authentication error messages.
- Logged-in email display and account-security settings.
- Password-reset request protection to prevent duplicate requests while one request is in progress.

### Responsive interface

- Scrollable content on constrained-height screens.
- Narrow-width fallback for dashboard Quick Actions.
- Keyboard-aware bottom spacing on Login and Signup forms.
- Long email addresses and selected filenames truncate safely.
- Existing card dimensions, colors, labels, and navigation preserved.

### Local PDF selection and validation

- Cross-platform file selection with `file_picker`.
- Case-insensitive `.pdf` extension validation.
- `%PDF-` signature validation when file bytes can be read.
- 10 MB maximum PDF file size.
- Safe picker-cancellation handling that preserves an existing selection.
- Selected filename and size display.
- Remove-selection action.
- Clear messaging when cloud uploads are unavailable.

### Honest Storage and Recent Uploads empty states

- Storage Overview and Recent Uploads no longer show fake quota values or placeholder cloud files.
- Both screens use unavailable/empty states that explain Firebase Storage is not enabled or configured.

### Truthful account-security summary

- Home Dashboard and Security Center use the same Firebase-derived account-setup summary.
- The summary checks signed-in account status, account email availability, password-provider linkage, and email verification status.
- The score is a transparent account-setup percentage, not a threat score, password-strength score, firewall status, encryption status, or overall security-risk assessment.
- Unsupported claims such as Firewall Active, AES-256 encryption enabled, No Threats Detected, cloud-health status, and fixed 92% security health have been removed.
- Security Center provides an action to manage account security.
- Password-reset wording describes the actual Firebase Authentication reset-email behavior.
- Pure unit tests cover no-user, unverified email/password, verified email/password, and non-password-provider cases.

## Current Screens

- Login
- Signup
- Home Dashboard
- Upload Files
- Storage
- Security
- Settings
- Security Settings

## Upload Behavior and Known Limitation

The Upload Files screen currently supports selecting and validating a PDF locally. After a valid file is selected, the interface clearly reports that cloud upload is unavailable because Firebase Storage is not configured or enabled.

No Firebase Storage request is made, and the app never reports a file as uploaded or displays simulated upload progress. Recent Uploads is an honest empty state: live cloud listings and cloud uploads are unavailable because Firebase Storage is not enabled or configured.

## Storage Behavior and Known Limitation

The Storage Overview screen does not show fabricated used/total space or placeholder files. It states that cloud storage and live cloud listings are unavailable because Firebase Storage is not enabled or configured. Cloud Guard does not invent stored files or used space.

## Security Behavior and Known Limitation

The Security Center displays Firebase Authentication account facts that the app can actually inspect. It does not monitor cloud infrastructure, threats, firewall status, encryption status, or other real-time security events.

The account-setup percentage is calculated from four checks: signed-in account, available email address, linked password sign-in, and verified email. It should not be interpreted as a complete security or risk score.

## Technology Stack

- Flutter
- Dart
- Firebase Core
- Firebase Authentication
- `file_picker`
- Firebase Storage dependency reserved for future integration; no live Storage upload is active
- Flutter Web and standard Flutter platform folders

## Prerequisites

- Flutter SDK compatible with the version specified in `pubspec.yaml`.
- A Firebase project configured for this application.
- Firebase Authentication enabled with the Email/Password provider.

Firebase Storage, a Storage bucket, billing setup, and Storage rules are not required for the current local PDF-selection and account-security-summary features.

## Setup and Run

Install dependencies:

~~~bash
flutter pub get
~~~

Run the application:

~~~bash
flutter run
~~~

Run the Web version in Chrome:

~~~bash
flutter run -d chrome
~~~

Run static analysis:

~~~bash
flutter analyze
~~~

Run the account-security unit tests:

~~~bash
flutter test test/security_status_test.dart
~~~

## Development Workflow

Before making changes, check the working tree:

~~~bash
git status
~~~

For a new feature, inspect the relevant files first, make a small scoped change, test the app, review the diff, and commit only the intended files. Do not push to the shared `main` branch until the change has been tested.

## Future Roadmap

1. Enable and configure Firebase Storage when project and billing requirements allow.
2. Add authenticated live uploads with real transfer progress and cancellation.
3. Define and deploy appropriate Firebase Storage security rules.
4. When Firebase Storage is enabled, replace the Storage and Recent Uploads empty states with per-user live cloud listings.
5. Add download, delete, rename, and search functionality.
6. Add broader automated tests for authentication, PDF validation, picker cancellation, responsive layouts, and account-security presentation.
7. Replace presentation-only security values with additional clearly defined, measurable checks when reliable data sources are available.
8. Improve app branding, privacy information, and release configuration.

## Project History

- **Task 1:** Added Firebase authentication-state startup and logout routing; removed duplicate dashboard code.
- **Task 2:** Added safe scrolling, narrow-width fallbacks, keyboard-aware spacing, and long-text handling.
- **Task 3:** Replaced the web-only PDF picker with cross-platform local selection and validation while keeping live cloud upload disabled until Firebase Storage is available.
- **Security task:** Replaced unsupported security claims with a truthful Firebase account-setup summary, added shared status logic, improved password-reset feedback, and added unit tests.
- **Storage honesty task:** Replaced fabricated storage quota and demo cloud-file/recent-upload entries with unavailable/empty states that explain Firebase Storage is not enabled or configured.

## Contributing

Cloud Guard is an MVP under active development. Keep changes focused, preserve existing authentication and UI behavior unless the task specifically requires otherwise, test changes locally, and document new functionality in this README.

## Development Notes

Cloud Guard has been developed with assistance from ChatGPT and OpenAI Codex for code analysis, authentication routing, responsive-layout improvements, PDF validation, security-status modeling, unit-test planning, and documentation. All generated changes were reviewed, tested, and committed by the project owner.
