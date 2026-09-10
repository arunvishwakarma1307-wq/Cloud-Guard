import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app_lock_controller.dart';
import 'app_lock_page.dart';
import 'app_lock_recovery_page.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'notification_controller.dart';
import 'theme_controller.dart';
import 'update_prompt.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await themeController.ready;
  await appLockController.ready;
  await notificationController.readyFuture;

  runApp(
    CloudGuardApp(
      emailRecoveryLink: _emailRecoveryLink(),
    ),
  );
}

String? _emailRecoveryLink() {
  if (!kIsWeb) return null;

  final link = Uri.base.toString();

  if (!FirebaseAuth.instance.isSignInWithEmailLink(link)) {
    return null;
  }

  return link;
}

class CloudGuardApp extends StatelessWidget {
  const CloudGuardApp({
    super.key,
    this.emailRecoveryLink,
  });

  final String? emailRecoveryLink;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Cloud Guard',
          themeMode: themeController.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
            ),
            scaffoldBackgroundColor: const Color(0xfff6f8ff),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: AuthGate(
            emailRecoveryLink: emailRecoveryLink,
          ),
        );
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({
    super.key,
    this.emailRecoveryLink,
  });

  final String? emailRecoveryLink;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late bool _isRecovering;

  @override
  void initState() {
    super.initState();

    _isRecovering = widget.emailRecoveryLink != null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isRecovering) {
      return AppLockRecoveryPage(
        emailLink: widget.emailRecoveryLink!,
        onCompleted: () {
          if (!mounted) return;

          setState(() {
            _isRecovering = false;
          });
        },
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return const UpdatePrompt(
            child: AppLockGate(
              child: CloudGuardHome(),
            ),
          );
        }

        return const LoginPage();
      },
    );
  }
}