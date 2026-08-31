import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'security_activity_log.dart';
import 'security_status.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  bool isResettingPassword = false;
  bool isSendingVerification = false;

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> changePassword(BuildContext context) async {
    if (isResettingPassword) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user?.email == null) {
      showMessage(context, "No user found");
      return;
    }

    setState(() {
      isResettingPassword = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);

      securityActivityLog.record(
        title: 'Password reset requested',
        description: 'A password reset email was requested for the account.',
      );

      if (!context.mounted) return;

      showMessage(context, "Password reset link sent to your email");
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      showMessage(
        context,
        "Password reset failed: ${e.message ?? "Unknown error"}",
      );
    } finally {
      if (context.mounted) {
        setState(() {
          isResettingPassword = false;
        });
      }
    }
  }

  Future<void> sendEmailVerification(BuildContext context) async {
    if (isSendingVerification) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user?.email == null) {
      showMessage(context, "No email address is available for this account");
      return;
    }

    if (user!.emailVerified) {
      showMessage(context, "This email address is already verified");
      return;
    }

    setState(() {
      isSendingVerification = true;
    });

    try {
      await user.sendEmailVerification();

      securityActivityLog.record(
        title: 'Email verification requested',
        description:
            'An email verification link was requested for the account.',
      );

      if (!context.mounted) return;

      showMessage(context, "Email verification link sent to your email");
    } on FirebaseAuthException catch (e) {
      if (!context.mounted) return;

      showMessage(
        context,
        "Email verification failed: ${e.message ?? "Unknown error"}",
      );
    } finally {
      if (context.mounted) {
        setState(() {
          isSendingVerification = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final securitySummary = SecuritySetupSummary.fromAccount(
      isSignedIn: user != null,
      email: user?.email,
      providerIds:
          user?.providerData.map((provider) => provider.providerId).toList() ??
          const [],
      isEmailVerified: user?.emailVerified ?? false,
    );

    return Scaffold(
      backgroundColor: const Color(0xfff6f8ff),
      appBar: AppBar(
        title: const Text(
          "Security Settings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Account Security",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.password, color: Colors.blue),
                  title: const Text("Change Password"),
                  subtitle: const Text("Send password reset link"),
                  trailing: isResettingPassword
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_ios),
                  onTap: isResettingPassword
                      ? null
                      : () => changePassword(context),
                ),
              ),
              const SizedBox(height: 15),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.email, color: Colors.orange),
                  title: const Text("Email Account"),
                  subtitle: Text(
                    user?.email ?? "No email",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Card(
                child: ListTile(
                  leading: Icon(
                    user?.emailVerified == true
                        ? Icons.verified
                        : Icons.mark_email_unread,
                    color: user?.emailVerified == true
                        ? Colors.green
                        : Colors.orange,
                  ),
                  title: Text(
                    user?.emailVerified == true
                        ? "Email verified"
                        : "Send verification email",
                  ),
                  subtitle: Text(
                    user?.emailVerified == true
                        ? "Firebase Authentication reports this email as verified"
                        : "Send a verification link to the account email",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: user?.emailVerified == true
                      ? null
                      : isSendingVerification
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_ios),
                  onTap: user?.emailVerified == true || isSendingVerification
                      ? null
                      : () => sendEmailVerification(context),
                ),
              ),
              const SizedBox(height: 15),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.shield, color: Colors.green),
                  title: const Text("Account setup"),
                  subtitle: Text(
                    '${securitySummary.score}% complete — Firebase account setup, not a risk score',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
