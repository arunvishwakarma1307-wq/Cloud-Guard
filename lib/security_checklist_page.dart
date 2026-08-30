import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'security_status.dart';

class SecurityChecklistPage extends StatelessWidget {
  const SecurityChecklistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final summary = SecuritySetupSummary.fromAccount(
      isSignedIn: user != null,
      email: user?.email,
      providerIds:
          user?.providerData.map((provider) => provider.providerId).toList() ??
          const [],
      isEmailVerified: user?.emailVerified ?? false,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Security Checklist',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Security Checklist Center',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Review the account setup facts Cloud Guard can currently inspect.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.checklist, color: Colors.blue, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${summary.score}% complete',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(summary.label),
                            const SizedBox(height: 4),
                            const Text(
                              'Account setup progress — not a risk score',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Account checks',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...summary.checks.map(
                (check) => _ChecklistTile(
                  title: check.title,
                  description: check.description,
                  isComplete: check.isComplete,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Privacy and capability notes',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const _ChecklistTile(
                title: 'Cloud Storage status',
                description:
                    'Firebase Storage is currently unavailable or not configured. Cloud uploads are not claimed.',
                isComplete: true,
                icon: Icons.cloud_off,
              ),
              const _ChecklistTile(
                title: 'Local PDF privacy',
                description:
                    'PDF previews use temporary local memory. Files are not uploaded to Firebase Storage.',
                isComplete: true,
                icon: Icons.lock_outline,
              ),
              const _ChecklistTile(
                title: 'Monitoring scope',
                description:
                    'Cloud Guard does not currently monitor infrastructure, threats, firewalls, or encryption.',
                isComplete: true,
                icon: Icons.info_outline,
              ),
              const SizedBox(height: 20),
              const Text(
                'This center reports Firebase Authentication facts and documented app capabilities only. It is not a real-time security monitoring system.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  const _ChecklistTile({
    required this.title,
    required this.description,
    required this.isComplete,
    this.icon,
  });

  final String title;
  final String description;
  final bool isComplete;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tileIcon =
        icon ?? (isComplete ? Icons.check_circle : Icons.info_outline);
    final iconColor = isComplete ? Colors.green : Colors.orange;

    return Card(
      elevation: 3,
      child: ListTile(
        leading: Icon(tileIcon, color: iconColor, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }
}
