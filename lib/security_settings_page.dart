import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'security_status.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  bool isResettingPassword = false;

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> changePassword(BuildContext context) async {
    if (isResettingPassword) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user?.email == null) {
      showMessage(
        context,
        "No user found",
      );
      return;
    }

    setState(() {
      isResettingPassword = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: user!.email!,
      );

      if (!context.mounted) return;

      showMessage(
        context,
        "Password reset link sent to your email",
      );
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final securitySummary = SecuritySetupSummary.fromAccount(
      isSignedIn: user != null,
      email: user?.email,
      providerIds: user?.providerData
              .map((provider) => provider.providerId)
              .toList() ??
          const [],
      isEmailVerified: user?.emailVerified ?? false,
    );

    return Scaffold(
      backgroundColor: const Color(0xfff6f8ff),

      appBar: AppBar(
        title: const Text(
          "Security Settings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.password,
                  color: Colors.blue,
                ),

                title: const Text(
                  "Change Password",
                ),

                subtitle: const Text(
                  "Send password reset link",
                ),

                trailing: isResettingPassword
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_ios),

                onTap: isResettingPassword ? null : () => changePassword(context),
              ),
            ),

            const SizedBox(height: 15),

            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.email,
                  color: Colors.orange,
                ),

                title: const Text(
                  "Email Account",
                ),

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
                leading: const Icon(
                  Icons.shield,
                  color: Colors.green,
                ),

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
