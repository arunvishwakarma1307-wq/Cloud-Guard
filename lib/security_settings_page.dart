import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  Future<void> changePassword(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user?.email == null) {
      showMessage(
        context,
        "No user found",
      );
      return;
    }

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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

      body: Padding(
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

                trailing: const Icon(
                  Icons.arrow_forward_ios,
                ),

                onTap: () {
                  changePassword(context);
                },
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

                title: const Text(
                  "Account Protection",
                ),

                subtitle: const Text(
                  "Firebase authentication enabled",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}