import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'security_checklist_page.dart';
import 'security_activity_page.dart';

import 'storage_page.dart';
import 'security_page.dart';
import 'security_status.dart';
import 'upload_page.dart';
import 'settings_page.dart';

class CloudGuardHome extends StatelessWidget {
  const CloudGuardHome({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.cloud, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                "Cloud Guard",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useSingleColumnActions = constraints.maxWidth < 360;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text(
                    "Welcome Back 👋",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Your cloud security dashboard",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),

                  const SizedBox(height: 20),

                  Card(
                    elevation: 5,
                    color: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: Padding(
                      padding: const EdgeInsets.all(20),

                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                const Text(
                                  "Firebase Account",
                                  style: TextStyle(color: Colors.white70),
                                ),

                                SizedBox(height: 10),

                                Text(
                                  securitySummary.label,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 5),

                                const Text(
                                  "Account information from Firebase Authentication",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),

                          Icon(
                            securitySummary.score == 100
                                ? Icons.check_circle
                                : Icons.info_outline,
                            color: Colors.white,
                            size: 35,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Security Score",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.security,
                              color: Colors.green,
                            ),

                            title: Text(
                              "${securitySummary.score}%",
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            subtitle: const Text(
                              "Firebase account setup — not a risk score",
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                            child: LinearProgressIndicator(
                              value: securitySummary.score / 100,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(8),
                              semanticsLabel:
                                  'Firebase account setup ${securitySummary.score} percent, not a risk score',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Quick Actions",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 16),

                  useSingleColumnActions
                      ? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ActionCard(
                                icon: Icons.storage,
                                title: "Storage",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const StoragePage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
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
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: ActionCard(
                                icon: Icons.storage,
                                title: "Storage",

                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const StoragePage(),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(width: 16),

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

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ActionCard(
                      icon: Icons.history,
                      title: "Security Activity",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SecurityActivityPage(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ActionCard(
                      icon: Icons.checklist,
                      title: "Security Checklist",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SecurityChecklistPage(),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  useSingleColumnActions
                      ? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ActionCard(
                                icon: Icons.cloud_upload,
                                title: "Upload",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const UploadPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ActionCard(
                                icon: Icons.settings,
                                title: "Settings",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SettingsPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: ActionCard(
                                icon: Icons.cloud_upload,
                                title: "Upload",

                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const UploadPage(),
                                    ),
                                  );
                                },
                              ),
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: ActionCard(
                                icon: Icons.settings,
                                title: "Settings",

                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SettingsPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,

                    child: ElevatedButton.icon(
                      onPressed: () => logout(context),

                      icon: const Icon(Icons.logout),

                      label: const Text(
                        "Logout",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

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

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),

        child: SizedBox(
          height: 120,

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Icon(icon, size: 35, color: Colors.blue),

              const SizedBox(height: 12),

              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
