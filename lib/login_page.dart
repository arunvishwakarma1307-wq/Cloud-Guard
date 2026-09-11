import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  bool isGoogleLoading = false;
  bool isResettingPassword = false;
  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();

    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {
    if (kIsWeb) return;

    try {
      await GoogleSignIn.instance.initialize();
    } catch (e) {
      debugPrint('Google Sign-In initialization failed: $e');
    }
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showMessage('Please enter email and password');
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
      String message = 'Login failed';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email';
      } else if (e.code == 'invalid-credential') {
        message = 'Email or password is incorrect';
      }

      showMessage(message);
    } catch (e) {
      showMessage('Something went wrong');
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> signInWithGoogle() async {
    if (isGoogleLoading) return;

    setState(() {
      isGoogleLoading = true;
    });

    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();

        userCredential = await FirebaseAuth.instance.signInWithPopup(
          googleProvider,
        );
      } else {
        final googleUser = await GoogleSignIn.instance.authenticate();

        final googleAuth = googleUser.authentication;

        final idToken = googleAuth.idToken;

        if (idToken == null) {
          throw Exception('Google ID token was not returned.');
        }

        final credential = GoogleAuthProvider.credential(
          idToken: idToken,
        );

        userCredential = await FirebaseAuth.instance.signInWithCredential(
          credential,
        );
      }

      final user = userCredential.user;

      securityActivityLog.record(
        title: 'Google login successful',
        description: user?.email != null
            ? 'Signed in with Google as ${user!.email}.'
            : 'Signed in successfully with Google.',
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        showMessage('Google sign-in was cancelled');
      } else {
        debugPrint('Google Sign-In error: $e');
        showMessage('Google sign-in failed. Please try again.');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Google Sign-In error: ${e.code}');

      if (e.code == 'account-exists-with-different-credential') {
        showMessage(
          'An account already exists with this email using another sign-in method.',
        );
      } else if (e.code == 'popup-closed-by-user') {
        showMessage('Google sign-in was cancelled');
      } else if (e.code == 'popup-blocked') {
        showMessage(
          'Please allow pop-ups for Cloud Guard and try again.',
        );
      } else {
        showMessage('Google sign-in failed. Please try again.');
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      showMessage('Something went wrong during Google sign-in.');
    }

    if (mounted) {
      setState(() {
        isGoogleLoading = false;
      });
    }
  }

  Future<void> resetPassword() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      showMessage('Please enter your email first');
      return;
    }

    setState(() {
      isResettingPassword = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      showMessage(
        'Password reset email sent. Please check your inbox.',
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Could not send reset email';

      if (e.code == 'invalid-email') {
        message = 'Please enter a valid email';
      } else if (e.code == 'user-not-found') {
        message = 'No account found with this email';
      }

      showMessage(message);
    } catch (e) {
      showMessage('Something went wrong');
    }

    if (mounted) {
      setState(() {
        isResettingPassword = false;
      });
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration fieldDecoration({
    required BuildContext context,
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    final colors = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: colors.onSurfaceVariant,
      ),
      floatingLabelStyle: TextStyle(
        color: colors.primary,
      ),
      prefixIcon: Icon(
        icon,
        color: colors.primary,
      ),
      suffixIcon: suffixIcon,
      suffixIconColor: colors.onSurfaceVariant,
      filled: true,
      fillColor: colors.surface,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: colors.outline,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: colors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: colors.error,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: colors.error,
          width: 2,
        ),
      ),
    );
  }

  Widget googleLogo() {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
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
                Icon(
                  Icons.cloud,
                  size: 80,
                  color: colors.primary,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Cloud Guard',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Secure your cloud world',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: colors.onSurface,
                  ),
                  cursorColor: colors.primary,
                  decoration: fieldDecoration(
                    context: context,
                    label: 'Email',
                    icon: Icons.email,
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: passwordController,
                  obscureText: !isPasswordVisible,
                  style: TextStyle(
                    color: colors.onSurface,
                  ),
                  cursorColor: colors.primary,
                  decoration: fieldDecoration(
                    context: context,
                    label: 'Password',
                    icon: Icons.lock,
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
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: isResettingPassword
                        ? null
                        : resetPassword,
                    child: isResettingPassword
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Forgot Password?',
                          ),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading || isGoogleLoading
                        ? null
                        : loginUser,
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 18),

                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: colors.outline,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                      ),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: colors.outline,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    onPressed: isLoading || isGoogleLoading
                        ? null
                        : signInWithGoogle,
                    icon: isGoogleLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : googleLogo(),
                    label: Text(
                      isGoogleLoading
                          ? 'Signing in with Google...'
                          : 'Continue with Google',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SignupPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Create Account',
                      ),
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

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius = size.width * 0.43;

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;

    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;

    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;

    const startAngle = -0.78;
    const sweep = 1.58;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      startAngle,
      sweep,
      false,
      redPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      startAngle + sweep,
      1.05,
      false,
      yellowPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      startAngle + sweep + 1.05,
      1.15,
      false,
      greenPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      startAngle + sweep + 2.20,
      1.37,
      false,
      bluePaint,
    );

    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.22
      ..strokeCap = StrokeCap.butt;

    canvas.drawLine(
      Offset(
        center.dx,
        center.dy,
      ),
      Offset(
        size.width * 0.94,
        center.dy,
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant CustomPainter oldDelegate,
  ) {
    return false;
  }
}