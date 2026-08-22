import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;

  // Password show/hide
  bool isPasswordVisible = false;

  // Confirm password show/hide
  bool isConfirmPasswordVisible = false;

  Future<void> createAccount() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword =
        confirmPasswordController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showMessage("Please fill all fields");
      return;
    }

    if (password != confirmPassword) {
      showMessage("Passwords do not match");
      return;
    }

    if (password.length < 6) {
      showMessage("Password must be at least 6 characters");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      showMessage("Account created successfully");
    } on FirebaseAuthException catch (e) {
      String message = "Account creation failed";

      if (e.code == 'email-already-in-use') {
        message =
            "An account already exists with this email";
      } else if (e.code == 'invalid-email') {
        message = "Please enter a valid email";
      } else if (e.code == 'weak-password') {
        message = "Password is too weak";
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

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f8ff),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        title: const Text(
          "Create Account",
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),

            child: Column(
              children: [
                // =================================================
                // ICON
                // =================================================

                const Icon(
                  Icons.person_add,
                  size: 75,
                  color: Colors.blue,
                ),

                const SizedBox(height: 20),

                // =================================================
                // TITLE
                // =================================================

                const Text(
                  "Create your Cloud Guard account",

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 35),

                // =================================================
                // EMAIL
                // =================================================

                TextField(
                  controller: emailController,

                  keyboardType:
                      TextInputType.emailAddress,

                  decoration: InputDecoration(
                    labelText: "Email",

                    prefixIcon:
                        const Icon(Icons.email),

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // PASSWORD
                // =================================================

                TextField(
                  controller: passwordController,

                  obscureText: !isPasswordVisible,

                  decoration: InputDecoration(
                    labelText: "Password",

                    prefixIcon:
                        const Icon(Icons.lock),

                    // 👁️ PASSWORD EYE BUTTON
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),

                      onPressed: () {
                        setState(() {
                          isPasswordVisible =
                              !isPasswordVisible;
                        });
                      },
                    ),

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // =================================================
                // CONFIRM PASSWORD
                // =================================================

                TextField(
                  controller:
                      confirmPasswordController,

                  obscureText:
                      !isConfirmPasswordVisible,

                  decoration: InputDecoration(
                    labelText: "Confirm Password",

                    prefixIcon:
                        const Icon(Icons.lock_outline),

                    // 👁️ CONFIRM PASSWORD EYE BUTTON
                    suffixIcon: IconButton(
                      icon: Icon(
                        isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),

                      onPressed: () {
                        setState(() {
                          isConfirmPasswordVisible =
                              !isConfirmPasswordVisible;
                        });
                      },
                    ),

                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // =================================================
                // CREATE ACCOUNT BUTTON
                // =================================================

                SizedBox(
                  width: double.infinity,

                  height: 55,

                  child: ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : createAccount,

                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            "Create Account",

                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                // =================================================
                // LOGIN
                // =================================================

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  child: const Text(
                    "Already have an account? Login",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
