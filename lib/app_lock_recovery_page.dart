import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_lock_controller.dart';

class AppLockRecoveryPage extends StatefulWidget {
  const AppLockRecoveryPage({
    super.key,
    required this.emailLink,
    required this.onCompleted,
  });

  final String emailLink;
  final VoidCallback onCompleted;

  @override
  State<AppLockRecoveryPage> createState() => _AppLockRecoveryPageState();
}

class _AppLockRecoveryPageState extends State<AppLockRecoveryPage> {
  static const String _recoveryEmailKey = 'cloud_guard_app_lock_recovery_email';

  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  String? _errorMessage;
  bool _isLoading = true;
  bool _isVerified = false;
  bool _isSaving = false;
  bool _isRecoveryComplete = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _startRecovery();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _startRecovery() async {
    if (_started) return;
    _started = true;

    try {
      final preferences = await SharedPreferences.getInstance();
      final email = preferences.getString(_recoveryEmailKey);
      if (email == null || email.isEmpty) {
        throw const FormatException(
          'Recovery email was not found on this browser. Request a new link.',
        );
      }

      await FirebaseAuth.instance.signInWithEmailLink(
        email: email,
        emailLink: widget.emailLink,
      );
      await preferences.remove(_recoveryEmailKey);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isVerified = true;
      });
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _friendlyFirebaseError(error);
      });
    } on FormatException catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Email recovery failed. The link may be expired or already used.';
      });
    }
  }

  String _friendlyFirebaseError(FirebaseAuthException error) {
    final code = error.code.toLowerCase();
    if (code == 'invalid-action-code' ||
        code == 'expired-action-code' ||
        code == 'invalid-credential') {
      return 'This recovery link has expired or was already used. Request a new link.';
    }
    if (code == 'quota-exceeded') {
      return 'Email recovery limit reached. Please try again later.';
    }
    return 'Email recovery failed. Please request a new link.';
  }

  Future<void> _saveNewPin() async {
    if (_isSaving || !_isVerified || _isRecoveryComplete) return;

    final pin = _pinController.text.trim();
    final confirmation = _confirmController.text.trim();

    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      setState(() {
        _errorMessage = 'PIN must contain 4 to 6 digits.';
      });
      return;
    }
    if (pin != confirmation) {
      setState(() {
        _errorMessage = 'PINs do not match.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await appLockController.changePin(pin);
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isRecoveryComplete = true;
        _pinController.clear();
        _confirmController.clear();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage =
            'Unable to save the new App Lock PIN. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
                      Icon(
                        Icons.mark_email_read,
                        size: 64,
                        color: colors.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'App Lock recovery',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Verifying your secure Firebase email link.'),
                          ],
                        )
                      else if (_isRecoveryComplete)
                        _SuccessContent(onContinue: widget.onCompleted)
                      else if (_isVerified)
                        _PinForm(
                          pinController: _pinController,
                          confirmController: _confirmController,
                          isSaving: _isSaving,
                          errorMessage: _errorMessage,
                          onSave: _saveNewPin,
                        )
                      else
                        Text(
                          _errorMessage ??
                              'Recovery could not be completed. Request a new link.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.error),
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

class _PinForm extends StatelessWidget {
  const _PinForm({
    required this.pinController,
    required this.confirmController,
    required this.isSaving,
    required this.errorMessage,
    required this.onSave,
  });

  final TextEditingController pinController;
  final TextEditingController confirmController;
  final bool isSaving;
  final String? errorMessage;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        const Text(
          'Email verified. Set a new 4–6 digit App Lock PIN.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: pinController,
          enabled: !isSaving,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'New PIN'),
        ),
        TextField(
          controller: confirmController,
          enabled: !isSaving,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'Confirm new PIN'),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.error),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isSaving ? null : onSave,
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save new PIN'),
          ),
        ),
      ],
    );
  }
}

class _SuccessContent extends StatelessWidget {
  const _SuccessContent({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 56),
        const SizedBox(height: 12),
        const Text(
          'Your App Lock PIN was changed successfully.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onContinue,
            child: const Text('Continue to Cloud Guard'),
          ),
        ),
      ],
    );
  }
}
