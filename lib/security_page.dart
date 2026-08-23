import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'security_settings_page.dart';
import 'security_status.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

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

      appBar: AppBar(
        title: const Text(
          "Security Center",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
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
              "Security Overview",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),


            const SizedBox(height: 20),


            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.security,
                      color: Colors.blue,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${securitySummary.score}%',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            securitySummary.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Firebase account setup — not a risk score',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            ...securitySummary.checks.map(
              (check) => Card(
                elevation: 5,
                child: ListTile(
                  leading: Icon(
                    check.isComplete ? Icons.check_circle : Icons.info_outline,
                    color: check.isComplete ? Colors.green : Colors.orange,
                    size: 36,
                  ),
                  title: Text(
                    check.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(check.description),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Cloud Guard shows Firebase Authentication account information only. '
              'It does not monitor cloud infrastructure, threats, firewall status, '
              'or encryption status.',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SecuritySettingsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.manage_accounts),
                label: const Text('Manage Account Security'),
              ),
            ),


          ],
          ),
        ),
      ),
    );
  }
}
