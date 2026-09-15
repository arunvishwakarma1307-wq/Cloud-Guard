import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app_lock_controller.dart';
import 'notification_controller.dart';
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

  Future<String?> _showPinDialog(
    BuildContext context, {
    required String title,
    required String confirmLabel,
  }) async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorMessage;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'New PIN',
                      prefixIcon: Icon(Icons.password),
                    ),
                  ),
                  TextField(
                    controller: confirmController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Confirm PIN',
                      prefixIcon: Icon(Icons.check_circle_outline),
                    ),
                  ),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final pin = pinController.text.trim();
                    final confirmation =
                        confirmController.text.trim();

                    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
                      setDialogState(() {
                        errorMessage =
                            'PIN must contain 4 to 6 digits.';
                      });
                      return;
                    }

                    if (pin != confirmation) {
                      setDialogState(() {
                        errorMessage = 'PINs do not match.';
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(pin);
                  },
                  child: Text(confirmLabel),
                ),
              ],
            );
          },
        );
      },
    );

    pinController.dispose();
    confirmController.dispose();

    return result;
  }

  Future<void> _setUpAppLock(BuildContext context) async {
    final pin = await _showPinDialog(
      context,
      title: 'Set App Lock PIN',
      confirmLabel: 'Enable',
    );

    if (pin == null) return;

    await appLockController.enableWithPin(pin);
  }

  Future<void> _changeAppLockPin(BuildContext context) async {
    final pin = await _showPinDialog(
      context,
      title: 'Change App Lock PIN',
      confirmLabel: 'Save',
    );

    if (pin == null) return;

    await appLockController.changePin(pin);
  }

  Future<void> _disableAppLock(BuildContext context) async {
    final shouldDisable = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Disable App Lock?'),
        content: const Text(
          'The app will open without requesting the App Lock PIN.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(true),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (shouldDisable == true) {
      await appLockController.disable();
    }
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

  Future<void> _showAutoLockPicker(BuildContext context) async {
    final selectedDuration =
        await showDialog<AutoLockDuration>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Auto Lock'),
          content: AnimatedBuilder(
            animation: appLockController,
            builder: (context, _) {
              return RadioGroup<AutoLockDuration>(
                groupValue: appLockController.autoLockDuration,
                onChanged: (value) {
                  if (value != null) {
                    Navigator.of(dialogContext).pop(value);
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: AutoLockDuration.values
                      .map((duration) {
                        return RadioListTile<AutoLockDuration>(
                          value: duration,
                          title: Text(duration.label),
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

    if (selectedDuration != null) {
      await appLockController.setAutoLockDuration(
        selectedDuration,
      );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
                  leading: const Icon(
                    Icons.person,
                    color: Colors.blue,
                  ),
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
                    builder: (context, _) {
                      return Text(
                        _themeLabel(themeController.themeMode),
                      );
                    },
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),
                  onTap: () => _showThemePicker(context),
                ),
              ),

              const SizedBox(height: 15),

              AnimatedBuilder(
                animation: appLockController,
                builder: (context, _) {
                  final isEnabled = appLockController.enabled;

                  return Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: Icon(
                            isEnabled
                                ? Icons.lock
                                : Icons.lock_open,
                            color: isEnabled
                                ? Colors.green
                                : Colors.grey,
                          ),
                          title: const Text('App Lock'),
                          subtitle: Text(
                            isEnabled
                                ? 'PIN protection is enabled'
                                : 'Optional PIN protection for this app',
                          ),
                          value: isEnabled,
                          onChanged: (value) {
                            if (value) {
                              _setUpAppLock(context);
                            } else {
                              _disableAppLock(context);
                            }
                          },
                        ),

                        if (isEnabled)
                          ListTile(
                            leading: const Icon(Icons.password),
                            title: const Text(
                              'Change App Lock PIN',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                            ),
                            onTap: () =>
                                _changeAppLockPin(context),
                          ),

                        if (isEnabled)
                          ListTile(
                            leading: const Icon(
                              Icons.timer_outlined,
                            ),
                            title: const Text('Auto Lock'),
                            subtitle: AnimatedBuilder(
                              animation: appLockController,
                              builder: (context, _) {
                                return Text(
                                  appLockController
                                      .autoLockDuration.label,
                                );
                              },
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                            ),
                            onTap: () =>
                                _showAutoLockPicker(context),
                          ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),

              AnimatedBuilder(
                animation: notificationController,
                builder: (context, _) {
                  final isEnabled =
                      notificationController.enabled;

                  return Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: Icon(
                            isEnabled
                                ? Icons.notifications_active
                                : Icons.notifications_off,
                            color: isEnabled
                                ? Colors.orange
                                : Colors.grey,
                          ),
                          title: const Text('Notifications'),
                          subtitle: Text(
                            isEnabled
                                ? 'Notifications are enabled'
                                : 'Notifications are disabled',
                          ),
                          value: isEnabled,
                          onChanged: (value) async {
                            final success =
                                await notificationController
                                    .setEnabled(value);

                            if (!context.mounted) return;

                            if (!success && value) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Notification permission was not granted.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),

                        if (isEnabled)
                          ListTile(
                            leading: const Icon(
                              Icons.notifications_active,
                            ),
                            title: const Text(
                              'Test notification',
                            ),
                            subtitle: const Text(
                              'Send a test notification to verify that it works',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 18,
                            ),
                            onTap: () async {
                              await notificationController
                                  .showTestNotification();
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 15),

              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.security,
                    color: Colors.green,
                  ),
                  title: const Text('Security Settings'),
                  subtitle: const Text(
                    'Manage account security',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                  ),
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

              const SizedBox(height: 30),

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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}