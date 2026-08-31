import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'security_activity_log.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool isResettingPassword = false;

  // Password visible hai ya hidden
  bool isPasswordVisible = false;

  // =====================================================
  // LOGIN
  // =====================================================

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage("Please enter email and password");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      securityActivityLog.record(
        title: 'Login successful',
        description: 'A Firebase Authentication login was completed.',
      );
    } on FirebaseAuthException catch (e) {
      String message = "Login failed";

      if (e.code == 'user-not-found') {
        message = "No account found with this email";
      } else if (e.code == 'wrong-password') {
        message = "Incorrect password";
      } else if (e.code == 'invalid-email') {
        message = "Please enter a valid email";
      } else if (e.code == 'invalid-credential') {
        message = "Email or password is incorrect";
      }

      showMessage(message);
    } catch (e) {
      showMessage("Something went wrong");
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  // =====================================================
  // FORGOT PASSWORD
  // =====================================================

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage("Please enter your email first");
      return;
    }

    setState(() {
      isResettingPassword = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      showMessage("Password reset email sent. Please check your inbox.");
    } on FirebaseAuthException catch (e) {
      String message = "Could not send reset email";

      if (e.code == 'invalid-email') {
        message = "Please enter a valid email";
      } else if (e.code == 'user-not-found') {
        message = "No account found with this email";
      }

      showMessage(message);
    } catch (e) {
      showMessage("Something went wrong");
    }

    if (mounted) {
      setState(() {
        isResettingPassword = false;
      });
    }
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // =====================================================
  // DISPOSE
  // =====================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f8ff),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              25,
              25,
              25,
              25 + MediaQuery.viewInsetsOf(context).bottom,
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                // =================================================
                // LOGO
                // =================================================
                const Icon(Icons.cloud, size: 80, color: Colors.blue),

                const SizedBox(height: 20),

                const Text(
                  "Cloud Guard",

                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                const Text(
                  "Secure your cloud world",

                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),

                const SizedBox(height: 40),

                // =================================================
                // EMAIL
                // =================================================
                TextField(
                  controller: emailController,

                  keyboardType: TextInputType.emailAddress,

                  decoration: InputDecoration(
                    labelText: "Email",

                    prefixIcon: const Icon(Icons.email),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // PASSWORD
                // =================================================
                TextField(
                  controller: passwordController,

                  // Eye button ke according
                  // password show/hide hoga
                  obscureText: !isPasswordVisible,

                  decoration: InputDecoration(
                    labelText: "Password",

                    prefixIcon: const Icon(Icons.lock),

                    // 👁️ EYE BUTTON
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),

                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                // =================================================
                // FORGOT PASSWORD
                // =================================================
                Align(
                  alignment: Alignment.centerRight,

                  child: TextButton(
                    onPressed: isResettingPassword ? null : resetPassword,

                    child: isResettingPassword
                        ? const SizedBox(
                            width: 18,
                            height: 18,

                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Forgot Password?"),
                  ),
                ),

                const SizedBox(height: 10),

                // =================================================
                // LOGIN BUTTON
                // =================================================
                SizedBox(
                  width: double.infinity,

                  height: 55,

                  child: ElevatedButton(
                    onPressed: isLoading ? null : loginUser,

                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            "Login",

                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // CREATE ACCOUNT
                // =================================================
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,

                  children: [
                    const Text("Don't have an account?"),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (context) => const SignupPage(),
                          ),
                        );
                      },

                      child: const Text("Create Account"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
