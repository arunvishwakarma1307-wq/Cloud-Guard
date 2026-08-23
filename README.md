# ☁️ Cloud Guard

Cloud Guard is a Flutter-based cloud security dashboard and file-management MVP built with Dart and Firebase. It provides Firebase Authentication, account-security tools, responsive dashboard screens, and safe local PDF selection and validation.

## Project Status

Cloud Guard is currently in MVP development.

- Firebase Authentication and auth-state routing are working.
- The dashboard, security, storage, settings, and account-security screens are implemented.
- Responsive scrolling, narrow-width layout handling, keyboard-aware form spacing, and long-text handling are complete.
- Local PDF selection and validation are working.

> **Firebase Storage is not currently enabled or configured for live uploads.** The app does not upload files to the cloud, and it does not simulate upload progress or upload success.

## Completed Features

### Authentication and account security

- Email/password account registration and login
- Authentication-state routing between login and the signed-in dashboard
- Logout
- Forgot-password and password-reset email flow
- Password visibility controls
- Validation and clear authentication error messages
- Logged-in email display and account-security settings

### Responsive interface

- Scrollable content on constrained-height screens
- Narrow-width fallback for dashboard quick actions
- Keyboard-aware bottom spacing on login and signup forms
- Long email addresses and selected filenames truncate safely

### Local PDF selection and validation

- Cross-platform file selection with `file_picker`
- `.pdf` extension validation
- `%PDF-` signature validation when file bytes are available
- 10 MB maximum PDF file size
- Safe picker-cancellation handling that preserves an existing selection
- Selected filename and size display
- Remove-selection action
- Clear message explaining that cloud uploads are unavailable

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

No Firebase Storage request is made, and the app never reports a file as uploaded or displays simulated upload progress. The recent-upload item is a demo UI entry, not a live Storage listing.

## Technology Stack

- Flutter
- Dart
- Firebase Core
- Firebase Authentication
- `file_picker`
- Firebase Storage dependency for future integration only; no live Storage upload is active

## Prerequisites

- Flutter SDK compatible with the version specified in `pubspec.yaml`
- A Firebase project configured for this app
- Firebase Authentication enabled with the Email/Password provider

Firebase Storage, a Storage bucket, billing setup, and Storage rules are not required for the current local PDF-selection flow.

## Setup and Run

Install dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

Run the web version in Chrome:

```bash
flutter run -d chrome
```

Run static analysis:

```bash
flutter analyze
```

## Future Roadmap

- Enable and configure Firebase Storage when project and billing requirements allow
- Add authenticated live uploads, real transfer progress, and upload cancellation
- Define and deploy appropriate Firebase Storage security rules
- Replace the demo recent-upload item with per-user cloud file listings
- Add automated tests for authentication, PDF validation, picker cancellation, and responsive layouts
