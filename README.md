# ☁️ Cloud Guard

Cloud Guard is a Flutter-based cloud security dashboard and file-management MVP built with Dart and Firebase. It provides Firebase Authentication, account-security tools, responsive dashboard screens, and safe local PDF selection, validation, and workspace management.

## Project Status

Cloud Guard is currently in **MVP development**. Authentication, authentication-state routing, responsive layouts, local PDF selection and validation, the local file workspace, the account-security presentation, and honest Storage/Recent Uploads empty states are working and tested.

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
- Email verification action for unverified accounts through Firebase Authentication.

### Responsive interface

- Scrollable content on constrained-height screens.
- Narrow-width fallback for dashboard Quick Actions.
- Keyboard-aware bottom spacing on Login and Signup forms.
- Long email addresses and selected filenames truncate safely.
- Existing card dimensions, colors, labels, and navigation preserved.

### Home Dashboard visual polish

- Home Dashboard branding, spacing, typography, and card consistency were tightened without changing navigation, logout, or account-setup wording.
- A decorative account-setup progress bar was added; it is not a risk, threat, or security-health score.

### Local PDF selection and validation

- Cross-platform file selection with `file_picker`.
- Case-insensitive `.pdf` extension validation.
- `%PDF-` signature validation when file bytes can be read.
- 10 MB maximum PDF file size.
- Safe picker-cancellation handling that preserves an existing selection.
- Selected filename and size display.
- Remove-selection action.
- Clear messaging when cloud uploads are unavailable.
- Filename, size, and `%PDF-` checks live in a pure testable module.
- A selected valid PDF shows a clear local-validation status; this does not indicate cloud upload.

### Honest Storage and Recent Uploads empty states

- Storage Overview and Recent Uploads no longer show fake quota values or placeholder cloud files.
- Both screens use unavailable/empty states that explain Firebase Storage is not enabled or configured.

### Local File Workspace

- Multiple validated PDFs can be added to a temporary in-memory local workspace without Firebase Storage or billing.
- Duplicate entries with the same filename and file size are prevented.
- Upload Files and Storage screens use the same shared local workspace.
- Local files show their filename, individual size, total file count, and total size.
- Local workspace files can be searched and removed.
- Local workspace unit tests cover adding, duplicate prevention, searching, removing, clearing, and total-size calculation.

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

The Upload Files screen currently supports selecting and validating PDF files locally. After a valid file is selected, it is added to the shared in-memory local workspace, and the interface clearly reports that cloud upload is unavailable because Firebase Storage is not configured or enabled.

No Firebase Storage request is made, and the app never reports a file as uploaded or displays simulated upload progress. Recent Uploads is an honest empty state: live cloud listings and cloud uploads are unavailable because Firebase Storage is not enabled or configured.

## Storage Behavior and Known Limitation

The Storage Overview screen does not show fabricated used/total space or placeholder files. It states that cloud storage and live cloud listings are unavailable because Firebase Storage is not enabled or configured. Cloud Guard does not invent stored files or used space.

The screen also displays the temporary local workspace with search, total size, and remove actions. These local workspace entries are not cloud files and are not persisted after the app is completely closed or restarted.

## Security Behavior and Known Limitation

The Security Center displays Firebase Authentication account facts that the app can actually inspect. It does not monitor cloud infrastructure, threats, firewall status, encryption status, or other real-time security events.

The account-setup percentage is calculated from four checks: signed-in account, available email address, linked password sign-in, and verified email. It should not be interpreted as a complete security or risk score.

## Technology Stack

- Flutter
- Dart
- Firebase Core
- Firebase Authentication
- `file_picker`
- `ChangeNotifier`-based in-memory local file workspace
- Firebase Storage dependency reserved for future integration; no live Storage upload is active
- Flutter Web and standard Flutter platform folders

## Prerequisites

- Flutter SDK compatible with the version specified in `pubspec.yaml`.
- A Firebase project configured for this application.
- Firebase Authentication enabled with the Email/Password provider.
- For Android phone testing: a data-capable USB cable and USB debugging enabled on the phone.

Firebase Storage, a Storage bucket, billing setup, and Storage rules are not required for the current local PDF-selection, local-workspace, and account-security-summary features.

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

Check connected devices:

~~~bash
flutter devices
~~~

Run on a connected Android phone:

Enable Developer Options and USB debugging on the phone, connect it with a data-capable USB cable, unlock the phone, select File Transfer if prompted, and allow the USB debugging permission. Then run:

~~~bash
flutter run -d DEVICE_ID
~~~

For example, for the connected phone device ID `6daa931e`:

~~~bash
flutter run -d 6daa931e
~~~

Run static analysis:

~~~bash
flutter analyze
~~~

Run all tests:

~~~bash
flutter test
~~~

Run the account-security unit tests:

~~~bash
flutter test test/security_status_test.dart
~~~

Run the PDF validation unit tests:

~~~bash
flutter test test/pdf_file_validation_test.dart
~~~

Run the local workspace unit tests:

~~~bash
flutter test test/local_file_workspace_test.dart
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
5. Add download, delete, rename, and search functionality for live cloud files.
6. Add broader automated tests for authentication, picker cancellation, responsive layouts, and account-security presentation. PDF validation and local workspace unit tests are in place.
7. Replace presentation-only security values with additional clearly defined, measurable checks when reliable data sources are available.
8. Improve app branding, privacy information, and release configuration.

## Project History

- **Task 1:** Firebase authentication-state routing and logout routing.
- **Task 2:** Responsive layouts, safe scrolling, narrow-width fallbacks, keyboard-aware spacing, and long-text handling.
- **Task 3:** Cross-platform local PDF selection and validation with cloud upload kept unavailable.
- **Task 4:** Truthful Firebase account-security summary, replacing unsupported security claims and adding unit tests.
- **Storage honesty milestone:** Removed fabricated Storage quota/demo files and replaced them with honest unavailable/empty states because Firebase Storage is not enabled or configured.
- **Task 5:** Extracted PDF validation into a pure testable module and added focused unit tests.
- **Task 6:** Focused Home Dashboard UI/UX polish for branding, hierarchy, spacing, card consistency, and a decorative account-setup progress indicator.
- **Task 7:** Added a Firebase Authentication email-verification action with verified/unverified account states, duplicate-request protection, and clear success/error feedback.
- **Task 8:** Added a clear local PDF validation-readiness status and local-only explanation without enabling Firebase Storage or changing cloud-upload behavior.
- **Task 9:** Added a shared in-memory local file workspace with multi-file support, duplicate prevention, local search, total-size display, and removal actions on Upload Files and Storage screens. Added focused workspace unit tests.

## Contributing

Cloud Guard is an MVP under active development. Keep changes focused, preserve existing authentication and UI behavior unless the task specifically requires otherwise, test changes locally, and document new functionality in this README.

## Development Notes

Cloud Guard has been developed with assistance from ChatGPT, OpenAI Codex, and Cursor for code analysis, authentication routing, responsive-layout improvements, PDF validation, security-status modeling, local workspace development, unit-test planning, and documentation. All generated changes were reviewed, tested, committed, and pushed by the project owner.
