import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'security_settings_page.dart';
import 'theme_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  String _themeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System default',
    };
  }

  Future<void> _showThemePicker(BuildContext context) async {
    final selectedMode = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Choose app theme'),
          content: AnimatedBuilder(
            animation: themeController,
            builder: (context, _) {
              return RadioGroup<ThemeMode>(
                groupValue: themeController.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.of(dialogContext).pop(value);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: ThemeMode.values
                      .map((mode) {
                        return RadioListTile<ThemeMode>(
                          value: mode,
                          title: Text(_themeLabel(mode)),
                        );
                      })
                      .toList(growable: false),
                ),
              );
            },
          ),
        );
      },
    );

    if (selectedMode != null) {
      await themeController.setThemeMode(selectedMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 40,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.blue),
                        title: const Text('Logged in user'),
                        subtitle: Text(
                          user?.email ?? 'No email',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Text(
                      'Preferences',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Card(
                      child: ListTile(
                        leading: Icon(
                          themeController.themeMode == ThemeMode.dark
                              ? Icons.dark_mode
                              : Icons.palette_outlined,
                          color: Colors.indigo,
                        ),
                        title: const Text('App theme'),
                        subtitle: AnimatedBuilder(
                          animation: themeController,
                          builder: (context, _) =>
                              Text(_themeLabel(themeController.themeMode)),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () => _showThemePicker(context),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Card(
                      child: SwitchListTile(
                        secondary: const Icon(
                          Icons.notifications,
                          color: Colors.orange,
                        ),
                        title: const Text('Notifications'),
                        subtitle: const Text('Enable or disable notifications'),
                        value: true,
                        onChanged: (value) {},
                      ),
                    ),
                    const SizedBox(height: 15),
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.security,
                          color: Colors.green,
                        ),
                        title: const Text('Security Settings'),
                        subtitle: const Text('Manage account security'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const SecuritySettingsPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () => logout(context),
                        icon: const Icon(Icons.logout),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
