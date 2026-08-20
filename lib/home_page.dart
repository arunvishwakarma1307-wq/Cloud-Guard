import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'login_page.dart';
import 'storage_page.dart';
import 'security_page.dart';
import 'upload_page.dart';

class CloudGuardHome extends StatelessWidget {
  const CloudGuardHome({super.key});

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> logout(BuildContext context) async {
    try {
      // Firebase se user ko sign out karo
      await FirebaseAuth.instance.signOut();

      if (!context.mounted) return;

      // Current Home Page ko remove karke
      // Login Page open karo
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Logout failed: $e",
          ),
        ),
      );
    }
  }

  // =====================================================
  // MESSAGE
  // =====================================================

  void showMessage(
    BuildContext context,
    String message,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  // =====================================================
  // HOME PAGE
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f8ff),

      // =================================================
      // APP BAR
      // =================================================

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

        title: const Text(
          "☁ Cloud Guard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),

        // =================================================
        // LOGOUT BUTTON
        // =================================================

        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.black,
            ),

            tooltip: "Logout",

            onPressed: () {
              logout(context);
            },
          ),

          const SizedBox(width: 10),
        ],
      ),

      // =================================================
      // BODY
      // =================================================

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // =================================================
            // WELCOME
            // =================================================

            const Text(
              "Welcome Back 👋",

              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Your cloud security dashboard",

              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 25),

            // =================================================
            // CLOUD STATUS
            // =================================================

            Card(
              elevation: 8,

              color: Colors.blue,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),

              child: const Padding(
                padding: EdgeInsets.all(25),

                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Text(
                            "Cloud Status",

                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),

                          SizedBox(height: 10),

                          Text(
                            "System Secure",

                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 5),

                          Text(
                            "All cloud services are running normally",

                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      Icons.check_circle,

                      color: Colors.white,

                      size: 35,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // =================================================
            // SECURITY SCORE
            // =================================================

            const Text(
              "Security Score",

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Card(
              elevation: 5,

              child: const ListTile(
                leading: Icon(
                  Icons.security,

                  color: Colors.green,

                  size: 35,
                ),

                title: Text(
                  "92%",

                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: Text(
                  "Security Health",
                ),
              ),
            ),

            const SizedBox(height: 25),

            // =================================================
            // QUICK ACTIONS
            // =================================================

            const Text(
              "Quick Actions",

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // =================================================
            // STORAGE + SECURITY
            // =================================================

            Row(
              children: [
                Expanded(
                  child: ActionCard(
                    icon: Icons.storage,

                    title: "Storage",

                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (context) =>
                              const StoragePage(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: ActionCard(
                    icon: Icons.security,

                    title: "Security",

                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (context) =>
                              const SecurityPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // =================================================
            // UPLOAD + SETTINGS
            // =================================================

            Row(
              children: [
                Expanded(
                  child: ActionCard(
                    icon: Icons.cloud_upload,

                    title: "Upload",

                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (context) =>
                              const UploadPage(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: ActionCard(
                    icon: Icons.settings,

                    title: "Settings",

                    onTap: () {
                      showMessage(
                        context,
                        "Settings opened",
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// ACTION CARD
// =====================================================

class ActionCard extends StatelessWidget {
  final IconData icon;

  final String title;

  final VoidCallback onTap;

  const ActionCard({
    super.key,

    required this.icon,

    required this.title,

    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),

      onTap: onTap,

      child: Card(
        elevation: 5,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),

        child: SizedBox(
          height: 120,

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              Icon(
                icon,

                size: 35,

                color: Colors.blue,
              ),

              const SizedBox(height: 12),

              Text(
                title,

                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}