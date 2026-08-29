import 'package:flutter/material.dart';

import 'app_update_checker.dart';

class UpdatePrompt extends StatefulWidget {
  const UpdatePrompt({super.key, required this.child});

  final Widget child;

  @override
  State<UpdatePrompt> createState() => _UpdatePromptState();
}

class _UpdatePromptState extends State<UpdatePrompt> {
  final AppUpdateChecker _checker = AppUpdateChecker();
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdate();
    });
  }

  Future<void> _checkForUpdate() async {
    if (_hasChecked) return;
    _hasChecked = true;

    final update = await _checker.checkForAndroidUpdate();
    if (!mounted || update == null) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('Cloud Guard ${update.version} available'),
        content: SingleChildScrollView(
          child: Text(
            'A new update is available.\n\n${update.releaseNotes}\n\nDownload it only from the official Cloud Guard GitHub Release.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Later'),
          ),
          FilledButton(
            onPressed: () async {
              final opened = await _checker.openDownloadUrl(update.downloadUrl);
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
              if (!opened && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Unable to open the official update link.'),
                  ),
                );
              }
            },
            child: const Text('Open Download'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _checker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
