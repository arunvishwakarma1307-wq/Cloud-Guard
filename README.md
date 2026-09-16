# ☁️ Cloud Guard

[![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com/)
[![Git](https://img.shields.io/badge/Git-F05032?logo=git&logoColor=white)](https://git-scm.com/)
[![GitHub](https://img.shields.io/badge/GitHub-181717?logo=git&logoColor=white)](https://github.com/)
[![Android](https://img.shields.io/badge/Android-3DDC84?logo=android&logoColor=white)](https://www.android.com/)
[![Web](https://img.shields.io/badge/Web-4285F4?logo=googlechrome&logoColor=white)](https://flutter.dev/multi-platform/web/)
[![Cursor](https://img.shields.io/badge/AI%20Assisted-Cursor-000000?logo=cursor&logoColor=white)](https://cursor.com/)
[![Codex](https://img.shields.io/badge/AI%20Assisted-Codex-412991?logo=openai&logoColor=white)](https://openai.com/codex/)

A Flutter-based cloud security and file-management MVP focused on honest account-security information, local PDF validation, a temporary local file workspace, App Lock PIN and biometric protection, auto-lock controls, theme settings, functional browser notifications, and a custom Android update notification system.

## 🔗 Try Cloud Guard

### 🌐 Web Demo

https://arunvishwakarma1307-wq.github.io/Cloud-Guard/

### **📱 Android APK**

https://github.com/arunvishwakarma1307-wq/Cloud-Guard/releases/download/v1.0.8/app-release.apk

[View Android Release v1.0.8](https://github.com/arunvishwakarma1307-wq/Cloud-Guard/releases/tag/v1.0.8)

> Android users: Download the APK, open it from the Downloads folder, allow installation from this source if Android asks for permission, install it, and then open Cloud Guard. Windows users should use the Web Demo because Windows cannot open Android APK files directly.

## 📌 Project Status

Cloud Guard is currently in **MVP development**.

| Area | Status |
|---|---|
| Firebase Authentication | Available and tested |
| Account-security summary | Available and tested |
| Local PDF selection and validation | Available and tested |
| Basic File Security Scanner | Available and tested |
| File Type Mismatch Detection | Available and tested |
| Local PDF workspace | Available and tested |
| App Lock PIN | Available and tested |
| Android biometric authentication | Implemented; Android device testing pending |
| Theme settings | Available and tested |
| Security Settings theme compatibility | Available and tested |
| Browser notifications | Available and tested |
| Flutter Web Demo | Deployed and verified through GitHub Pages |
| Android release APK | Built, installed, and tested on an Android device |
| Firebase Storage cloud uploads | Unavailable; Storage is not enabled or configured |
| Google Sign-In | Available and tested |
| App Lock Auto-Lock | Available with configurable lock duration |
| Android release APK | Built; latest release device testing pending |


> **Storage honesty:** Cloud Guard does not simulate cloud uploads, upload progress, cloud quota, stored cloud files, or successful cloud-upload messages. Firebase Storage is not currently enabled or configured for live uploads.

## ✨ What Cloud Guard Includes

| Icon | Feature | Description |
|---|---|---|
| 🔐 | Authentication | Email/password registration, login, logout, password reset, and session routing through Firebase Authentication. |
| 🔒 | App Lock PIN | PIN-based app lock protection to add an additional layer of security when accessing the application. |
| 👆 | Biometric App Lock | Android biometric authentication for unlocking the App Lock, with PIN fallback when biometric authentication is unavailable or not completed. |
| 🔔 | Notifications | Functional browser notifications with persistent enable/disable settings, browser notification permission handling, and a test notification feature. |
| ✅ | Account security | A transparent account-setup summary based only on Firebase account facts. It is not a risk or threat score. |
| 📄 | PDF validation | Case-insensitive `.pdf` validation, `%PDF-` signature checking, and a 10 MB size limit. |
| 🛡️ | Basic File Security Scanner | Performs basic local checks for file extension, file signature, file size, filename safety, and duplicate detection before a file is added to the local workspace. |
| 🔍 | File Type Mismatch Detection | Checks the actual file signature and detects when the file content does not match its current extension, including PDF, PNG, JPG, and JPEG detection. |
| 🗂️ | Local workspace | Add multiple validated PDFs to a temporary in-memory workspace without Firebase billing. |
| 🔎 | Search and sort | Search local filenames and sort by name or file size. |
| 🧹 | Safe cleanup | Remove individual entries or use confirmation-protected Clear All. |
| 📱 | Cross-platform UI | Responsive Flutter screens for Web and Android. |
| 📖 | PDF reader | Full-screen single-page PDF reader with readable default zoom, Zoom In, Zoom Out, Reset Zoom, page selection, text selection, and smooth vertical scrolling. |
| 🎨 | Theme settings | Persistent Light, Dark, and System theme options available from the Settings page. |
| 🔐 | Readable authentication forms | Theme-aware email, password, and confirm-password fields with clear text, icons, labels, backgrounds, and borders in Light, Dark, and System modes. |
| 🛡️ | Security Settings | Account-security controls with theme-aware headings and readable Light and Dark theme presentation. |
| 🔐 | Google Sign-In | Google account authentication through Firebase Authentication, available and tested on Android and Web. |
| ⏱️ | Auto-Lock | Automatically locks the application after a configurable period in the background, including Immediately, 1 minute, 5 minutes, 15 minutes, 30 minutes, or Never. |
| 🔄 | Update Checker | Android update checking through a trusted GitHub release manifest with version comparison and trusted release URL validation. |
| 🤖 | Update Popup | Custom Android update notification popup with Cloud Guard branding, robot artwork, version information, release notes, and an official GitHub download action. |

## 🖥️ Current Screens

| Screen | Purpose |
|---|---|
| 🔑 Login | Sign in with Firebase Authentication. |
| 📝 Signup | Create an email/password account. |
| 🏠 Home Dashboard | View account setup information and quick navigation actions. |
| ⬆️ Upload Files | Select, validate, and add PDFs to the local workspace. |
| ☁️ Storage | View local workspace entries and the honest cloud-unavailable state. |
| 🛡️ Security | Review Firebase-derived account-security checks. |
| 👤 Security Settings | Manage password-reset and email-verification actions. |
| 🔒 App Lock | Unlock the application using Android biometrics when available or the App Lock PIN. |
| ⚙️ | Settings | Access account, application, theme, App Lock, Auto-Lock, and notification settings. |

## 📄 PDF and Local Workspace Flow

```text
Choose PDF

    ↓

Detect actual file type from file signature

    ↓

Check extension and actual file type match

    ↓

Run Basic Security Scan

    ↓

Validate extension, size, and PDF signature

    ↓

Add valid PDF to the shared local workspace
```

### Local Workspace Features

* Multiple validated PDFs can be added.

* Duplicate entries with the same filename and file size are prevented.

* Upload Files and Storage use the same shared workspace.

* Each entry shows its filename and size.

* The workspace shows total file count and total size.

* Files can be searched by filename.

* Files can be sorted by name or size.

* Individual removal is available.

* Clear All requires confirmation before removing every local entry.

> The local workspace is temporary and in-memory. Entries are not uploaded to Firebase Storage and may disappear after the app is completely closed or restarted.

## ☁️ Firebase Storage Limitation

Firebase Authentication is active, but Firebase Storage cloud uploads are not enabled or configured for this MVP.

| Not available currently | What the app does instead |
|---|---|
| Cloud upload | Shows a clear unavailable message |
| Live cloud file listing | Shows an honest empty/unavailable state |
| Cloud quota and used space | Does not display fabricated values |
| Simulated upload progress | Does not show fake progress or success |
| Cloud file search/delete | Keeps search and removal limited to local entries |

Firebase Storage, a Storage bucket, billing setup, and Storage rules are not required for the current authentication, PDF-validation, local-workspace, account-security, browser-notification, and App Lock features.

## 🛡️ Account Security Summary

Cloud Guard displays only account facts that the app can actually inspect through Firebase Authentication.

| Check | Meaning |
|---|---|
| Signed-in account | An authenticated account is available. |
| Account email | The account has an available email address. |
| Password provider | Email/password sign-in is linked to the account. |
| Email verification | The account email is verified. |

> The account-setup percentage is not a threat score, password-strength score, firewall status, encryption status, cloud-health status, or overall security-risk assessment. Cloud Guard does not monitor cloud infrastructure or real-time threats.

## 🔒 App Lock and Biometric Authentication

Cloud Guard includes an additional local App Lock layer.

### App Lock Features

* Users can enable App Lock with a 4 to 6 digit PIN.

* The App Lock PIN is stored locally using persistent application preferences.

* The application can require the App Lock before accessing the main application.

* Android devices with an enrolled biometric can use biometric authentication to unlock the application.

* The biometric option uses the device's supported fingerprint or other enrolled biometric authentication.

* The App Lock PIN remains available as a fallback.

* Incorrect PIN attempts are limited.

* Five incorrect PIN attempts trigger a 10-minute local lockout.

* Biometric authentication is currently implemented for Android.

* The Web version does not display the biometric unlock option.

* Android biometric device testing will be completed when testing on the target Android device.

The biometric feature uses Flutter's `local_auth` package and Android biometric permissions. The Android application uses `FlutterFragmentActivity` to support the biometric authentication flow.

* Auto-Lock can automatically lock the application after it has been in the background for the selected duration.

* Available durations are Immediately, 1 minute, 5 minutes, 15 minutes, 30 minutes, and Never.

* The selected Auto-Lock duration is stored persistently.

* When the application returns from the background after the configured duration, the App Lock screen is shown again.

* Auto-Lock works together with the existing PIN and biometric unlock system.

## 🔔 Browser Notifications

Cloud Guard includes functional browser notification support.

### Notification Features

* Notifications can be enabled or disabled from Settings.

* The notification preference is stored persistently.

* Browser notification permission is requested when notifications are enabled.

* A **Test notification** option is available after notifications are enabled.

* The test notification confirms that browser notifications are working.

* Notification settings remain available after restarting the application.

The notification feature is currently implemented and tested on the Flutter Web version using browser notifications.

## 🎨 Theme Support

Cloud Guard supports persistent theme selection from the Settings page.

### Available Themes

* Light

* Dark

* System default

Theme settings are stored persistently and remain available after restarting the application.

Security Settings headings and page backgrounds are also theme-aware so that text remains readable in both Light and Dark modes.

## 🧰 Technology Stack

* Flutter and Dart

* Firebase Core

* Firebase Authentication

* Firebase Storage dependency reserved for future integration

* `file_picker`

* `flutter_local_notifications`

* `shared_preferences`

* `local_auth`

* `syncfusion_flutter_pdfviewer`

* `ChangeNotifier`-based local workspace

* Flutter Web and Android platform support

* Git and GitHub

* Cursor and OpenAI Codex for AI-assisted development

* `http`

* `package_info_plus`

* `url_launcher`

## 🚀 Platform Support

| Platform | How to use Cloud Guard |
|---|---|
| Desktop browser | Open the Web Demo URL. |
| Mobile browser | Open the Web Demo URL in a modern browser. |
| Android phone | Download and install the Android APK. |
| Android emulator | Install the APK inside an Android emulator. |
| Windows desktop | Use the Web Demo; Windows does not run Android APK files directly. |

> Android biometric App Lock is currently intended for Android devices. The Web version continues to use the App Lock PIN when App Lock is enabled.

## 📱 Android APK Installation

1. Download the APK on an Android phone.

2. Open `app-release.apk` from the Downloads folder.

3. If Android asks, allow installation from this source for the browser or file manager.

4. Install Cloud Guard.

5. Open the app and sign in or create an account.

6. If App Lock is enabled and the Android device has an enrolled biometric, biometric authentication can be used to unlock the application.

## 🛠️ Setup and Run

### Install dependencies

```bash
flutter pub get
```

### Run the application

```bash
flutter run
```

### Run the Web version in Chrome

```bash
flutter run -d chrome
```

### Check connected devices

```bash
flutter devices
```

### Run on a connected Android phone

Enable Developer Options and USB debugging on the phone, connect it with a data-capable USB cable, unlock the phone, select File Transfer if prompted, and allow the USB debugging permission. Then run:

```bash
flutter run -d DEVICE_ID
```

For example, for the tested phone device ID `6daa931e`:

```bash
flutter run -d 6daa931e
```

## 📦 Build Artifacts

### Build the Flutter Web release

```bash
flutter build web --release --base-href "/Cloud-Guard/"
```

### Build the Android release APK

```bash
flutter build apk --release
```

The generated APK is located at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## ✅ Testing and Quality Checks

| Check | Command |
|---|---|
| Run all tests | `flutter test` |
| Static analysis | `flutter analyze` |
| Diff whitespace check | `git diff --check` |
| Account-security tests | `flutter test test/security_status_test.dart` |
| PDF validation tests | `flutter test test/pdf_file_validation_test.dart` |
| File security scanner test | `flutter test test/file_security_scanner_test.dart` |
| Local workspace tests | `flutter test test/local_file_workspace_test.dart` |
| File type mismatch manual test | Rename a valid PDF copy to `.png`, `.jpg`, or `.jpeg`, select it, and verify that Cloud Guard detects the actual PDF file type and blocks the mismatched file |
| Browser notification manual test | Enable Notifications in Settings, allow browser permission, send a Test notification, disable/re-enable, and verify persistence |
| App Lock manual test | Enable App Lock, verify PIN unlock and lockout behavior, and test biometric unlock on a supported Android device |
| Auto-Lock manual test | Enable Auto-Lock, select a duration, background the application, return after the selected duration, and verify that App Lock is shown |
| Update popup manual test | Install an older Android release, publish a newer trusted release manifest, open the app, and verify the update popup and GitHub release action |

The current project test suite passes, and Flutter static analysis reports no issues.

## 🔁 Development Workflow

Before changing files:

```bash
git status
```

For each feature, inspect the relevant files first, make a small scoped change, run tests, review the diff, and commit only the intended files. Do not push to `main` until the change has been tested locally.

## 🗺️ Future Roadmap

| Priority | Planned work | Current state |
|-------:|---|---|
| 1 | Enable and configure Firebase Storage when project and billing requirements allow. | Not enabled |
| 2 | Add authenticated live uploads with real progress and cancellation. | Blocked by Storage availability |
| 3 | Define and deploy Firebase Storage security rules. | Future work |
| 4 | Replace cloud-unavailable states with per-user live listings. | Depends on Storage |
| 5 | Add download, delete, rename, and search for live cloud files. | Depends on Storage |
| 6 | Add broader authentication, picker, responsive-layout, and security-presentation tests. | Partially complete |
| 7 | Add more measurable security checks from reliable data sources. | Future work |
| 8 | Improve branding, privacy information, and release configuration. | Future work |
| 9 | Complete Android biometric device testing and refine biometric fallback behavior if needed. | Implemented; device testing pending |

## 🧾 Project History

* **Task 1:** Firebase authentication-state routing and logout routing.

* **Task 2:** Responsive layouts, safe scrolling, narrow-width fallbacks, keyboard-aware spacing, and long-text handling.

* **Task 3:** Cross-platform local PDF selection and validation with cloud upload kept unavailable.

* **Task 4:** Truthful Firebase account-security summary, replacing unsupported security claims and adding unit tests.

* **Storage honesty milestone:** Removed fabricated Storage quota/demo files and replaced them with honest unavailable/empty states.

* **Task 5:** Extracted PDF validation into a pure testable module and added focused unit tests.

* **Task 6:** Polished Home Dashboard branding, hierarchy, spacing, card consistency, and account-setup progress presentation.

* **Task 7:** Added Firebase Authentication email verification with duplicate-request protection and clear feedback.

* **Task 8:** Added local PDF validation-readiness status without changing cloud-upload behavior.

* **Task 9:** Added a shared in-memory local file workspace with multi-file support, duplicate prevention, search, total-size display, and removal actions.

* **Task 10:** Added local workspace sorting by filename and size, plus confirmation-protected Clear All.

* **Task 11:** Deployed the Flutter Web demo to GitHub Pages and published the verified Android release APK through GitHub Releases.

* **Task 12:** Added PDF Details with metadata and local visual PDF preview without Firebase Storage uploads.

* **Task 13:** Added a custom Android update checker using a trusted GitHub release manifest.

* **Task 14:** Added a Security Checklist Center showing Firebase account-setup facts and privacy notes.

* **Task 15:** Connected the Security Activity Center with supported local app events.

* **Task 16:** Added local activity records for login, signup, logout, password reset, email verification, update detection, and local PDF add/remove actions.

* **Task 17:** Added persistent local Security Activity History that remains available after app restarts.

* **Task 18:** Improved the PDF preview with a full-screen single-page viewer, readable page display, page navigation, zoom, and scrolling.

* **Task 19:** Improved the full-screen PDF reader with clearer default readability, higher zoom support, page selection, text selection, and smoother vertical scrolling.

* **Task 20:** Added persistent Light, Dark, and System theme settings and improved authentication form readability across all theme modes.

* **Task 21:** Added App Lock PIN protection to improve application security.

* **Task 22:** Added functional browser notifications with persistent enable/disable settings, browser notification permission handling, and a test notification feature.

* **Task 23:** Added Google Sign-In authentication with Firebase, including Android SHA-1 configuration and successful Android/Web Google account login testing.

* **Task 24:** Added Android biometric authentication for App Lock using `local_auth`, including Android biometric permission configuration, biometric unlock support, and PIN fallback.

* **Task 25:** Improved Settings and Security Settings theme compatibility, fixed the Settings page bottom overflow issue, and improved Security Settings heading/background readability in Dark Theme.

* **Task 26:** Added configurable App Lock Auto-Lock durations and automatic re-locking after the application remains in the background for the selected duration.

* **Task 27:** Improved the Android update notification popup with Cloud Guard branding, custom robot artwork, version and release-note presentation, trusted GitHub release download handling, and a polished update interface.

* **Task 28:** Added a Basic File Security Scanner with local checks for file extension, file signature, file size, filename safety, and duplicate detection before adding files to the local workspace.

* **Task 29:** Added File Type Mismatch Detection using actual file signatures to detect PDF, PNG, JPG, and JPEG content and identify when the current filename extension does not match the detected file type.

## 🤝 Contributing

Cloud Guard is an MVP under active development. Keep changes focused, preserve existing authentication and UI behavior unless a task specifically requires otherwise, test changes locally, and document new functionality in this README.

## 📝 Development Notes

Cloud Guard has been developed with assistance from ChatGPT, OpenAI Codex, and Cursor for code analysis, authentication routing, responsive-layout improvements, PDF validation, security-status modeling, local workspace development, unit-test planning, deployment configuration, notification functionality, biometric authentication, theme compatibility, and documentation.Basic File Security Scanner, File Type Mismatch Detection, and related testing. All generated changes were reviewed, tested, committed, and pushed by the project owner.update-system development, App Lock Auto-Lock functionality

## 📄 License

This project is currently an MVP and does not yet include a separate license file.