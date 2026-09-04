import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'security_activity_log.dart';
import 'security_activity_page.dart';
import 'security_checklist_page.dart';
import 'security_page.dart';
import 'security_status.dart';
import 'settings_page.dart';
import 'storage_page.dart';
import 'upload_page.dart';

class CloudGuardHome extends StatelessWidget {
  const CloudGuardHome({super.key});

  Future<void> logout(BuildContext context) async {
    securityActivityLog.record(
      title: 'Logout',
      description: 'The Firebase Authentication session was signed out.',
    );
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.cloud, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Cloud Guard',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
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
                    'Welcome Back',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your cloud security dashboard',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 5,
                    color: colorScheme.primary,
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
                                Text(
                                  'Firebase Account',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  securitySummary.label,
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Account information from Firebase Authentication',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            securitySummary.score == 100
                                ? Icons.check_circle
                                : Icons.info_outline,
                            color: colorScheme.onPrimary,
                            size: 35,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Security Score',
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
                              '${securitySummary.score}%',
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: const Text(
                              'Firebase account setup — not a risk score',
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
                    'Quick Actions',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  useSingleColumnActions
                      ? Column(
                          children: [
                            _actionButton(
                              context,
                              icon: Icons.storage,
                              title: 'Storage',
                              page: const StoragePage(),
                            ),
                            const SizedBox(height: 16),
                            _actionButton(
                              context,
                              icon: Icons.security,
                              title: 'Security',
                              page: const SecurityPage(),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: ActionCard(
                                icon: Icons.storage,
                                title: 'Storage',
                                onTap: () =>
                                    _openPage(context, const StoragePage()),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ActionCard(
                                icon: Icons.security,
                                title: 'Security',
                                onTap: () =>
                                    _openPage(context, const SecurityPage()),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 16),
                  _actionButton(
                    context,
                    icon: Icons.history,
                    title: 'Security Activity',
                    page: const SecurityActivityPage(),
                  ),
                  const SizedBox(height: 16),
                  _actionButton(
                    context,
                    icon: Icons.checklist,
                    title: 'Security Checklist',
                    page: const SecurityChecklistPage(),
                  ),
                  const SizedBox(height: 16),
                  useSingleColumnActions
                      ? Column(
                          children: [
                            _actionButton(
                              context,
                              icon: Icons.cloud_upload,
                              title: 'Upload',
                              page: const UploadPage(),
                            ),
                            const SizedBox(height: 16),
                            _actionButton(
                              context,
                              icon: Icons.settings,
                              title: 'Settings',
                              page: const SettingsPage(),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: ActionCard(
                                icon: Icons.cloud_upload,
                                title: 'Upload',
                                onTap: () =>
                                    _openPage(context, const UploadPage()),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ActionCard(
                                icon: Icons.settings,
                                title: 'Settings',
                                onTap: () =>
                                    _openPage(context, const SettingsPage()),
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
                        'Logout',
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

  static void _openPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  static Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ActionCard(
        icon: icon,
        title: title,
        onTap: () => _openPage(context, page),
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
              Icon(
                icon,
                size: 35,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
