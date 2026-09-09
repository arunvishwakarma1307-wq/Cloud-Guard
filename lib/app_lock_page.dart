import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_lock_controller.dart';

class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> {
  bool _isUnlocked = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appLockController,
      builder: (context, _) {
        if (!appLockController.enabled || _isUnlocked) {
          return widget.child;
        }

        return AppLockPage(
          onUnlocked: () {
            if (!mounted) return;
            setState(() {
              _isUnlocked = true;
            });
          },
        );
      },
    );
  }
}

class AppLockPage extends StatefulWidget {
  const AppLockPage({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<AppLockPage> createState() => _AppLockPageState();
}

class _AppLockPageState extends State<AppLockPage> {
  final TextEditingController _pinController = TextEditingController();
  Timer? _lockoutTimer;
  static const String _recoveryEmailKey = 'cloud_guard_app_lock_recovery_email';

  String? _errorMessage;
  Duration _remainingLockout = Duration.zero;

  @override
  void initState() {
    super.initState();
    _refreshLockout();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  void _refreshLockout() {
    _lockoutTimer?.cancel();
    if (!appLockController.isLockedOut) {
      setState(() {
        _remainingLockout = Duration.zero;
      });
      return;
    }

    _updateRemainingLockout();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingLockout();
    });
  }

  void _updateRemainingLockout() {
    if (!mounted) return;
    final remaining = appLockController.remainingLockout;
    setState(() {
      _remainingLockout = remaining;
    });
    if (remaining == Duration.zero) {
      _lockoutTimer?.cancel();
    }
  }

  Future<void> _unlock() async {
    if (_remainingLockout > Duration.zero) return;

    await appLockController.reload();
    if (!mounted || _remainingLockout > Duration.zero) return;

    final result = appLockController.verifyPin(_pinController.text);
    _pinController.clear();

    if (result.isValid) {
      widget.onUnlocked();
      return;
    }

    if (!mounted) return;
    setState(() {
      if (result.isLockedOut) {
        _errorMessage = 'Too many incorrect attempts. Try again in 10 minutes.';
      } else {
        final remainingAttempts =
            appLockController.maximumFailedAttempts -
            appLockController.failedAttempts;
        _errorMessage =
            'Incorrect PIN. $remainingAttempts attempt(s) remaining.';
      }
    });
    _refreshLockout();
  }

  String _formatRemaining(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _sendRecoveryLink() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) {
      setState(() {
        _errorMessage = 'No Firebase account email is available.';
      });
      return;
    }

    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(_recoveryEmailKey, email);

      final recoveryUrl = kIsWeb
          ? Uri.base
                .replace(
                  queryParameters: const <String, String>{},
                  fragment: '',
                )
                .toString()
          : 'https://arunvishwakarma1307-wq.github.io/Cloud-Guard/';
      final actionCodeSettings = ActionCodeSettings(
        url: recoveryUrl,
        handleCodeInApp: true,
      );
      await FirebaseAuth.instance.sendSignInLinkToEmail(
        email: email,
        actionCodeSettings: actionCodeSettings,
      );

      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Recovery link sent'),
          content: Text(
            'A secure Firebase sign-in link was sent to $email. Open it in this same browser, then set a new App Lock PIN.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage =
            'Could not send recovery link: ${error.message ?? error.code}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not send recovery link. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLockedOut = _remainingLockout > Duration.zero;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, size: 64, color: colors.primary),
                      const SizedBox(height: 16),
                      const Text(
                        'Cloud Guard is locked',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Enter your App Lock PIN to continue.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _pinController,
                        enabled: !isLockedOut,
                        autofocus: true,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.onSurface,
                          letterSpacing: 8,
                          fontSize: 22,
                        ),
                        decoration: InputDecoration(
                          labelText: 'App Lock PIN',
                          counterText: '',
                          prefixIcon: const Icon(Icons.password),
                          filled: true,
                          fillColor: colors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onSubmitted: (_) => _unlock(),
                      ),
                      const SizedBox(height: 16),
                      if (isLockedOut)
                        Text(
                          'Try again in ${_formatRemaining(_remainingLockout)}',
                          style: TextStyle(color: colors.error),
                          textAlign: TextAlign.center,
                        )
                      else if (_errorMessage != null)
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: colors.error),
                          textAlign: TextAlign.center,
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: isLockedOut ? null : _unlock,
                          icon: const Icon(Icons.lock_open),
                          label: const Text('Unlock'),
                        ),
                      ),
                      TextButton(
                        onPressed: _sendRecoveryLink,
                        child: const Text('Forgot PIN?'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
