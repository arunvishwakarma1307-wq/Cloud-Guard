import 'package:flutter/material.dart';

import 'app_update_checker.dart';
import 'security_activity_log.dart';

class UpdatePrompt extends StatefulWidget {
  const UpdatePrompt({
    super.key,
    required this.child,
  });

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

    securityActivityLog.record(
      title: 'Update detected',
      description:
          'A newer Cloud Guard release ${update.version} is available.',
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
              maxHeight: 700,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF111116),
                borderRadius: BorderRadius.circular(28),

                // Clearly visible outer border
                border: Border.all(
                  color: const Color(0xFF9B5CFF).withValues(alpha: 0.75),
                  width: 1.5,
                ),

                // Purple + blue outer glow
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9B5CFF).withValues(alpha: 0.22),
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: const Color(0xFF4F8CFF).withValues(alpha: 0.16),
                    blurRadius: 36,
                    spreadRadius: 2,
                  ),

                  // Original black shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 30,
                    spreadRadius: 2,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  24,
                  20,
                  24,
                  24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/images/update_robot.png',
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'New Update Available!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Cloud Guard ${update.version}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFE56BFF),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 22),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFF4FA3),
                                  Color(0xFF9B5CFF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),

                          const SizedBox(width: 10),

                          const Text(
                            "What's New",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.045),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Text(
                        update.releaseNotes,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF4FA3),
                              Color(0xFF9B5CFF),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFFF4FA3,
                              ).withValues(alpha: 0.22),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            final opened =
                                await _checker.openDownloadUrl(
                              update.downloadUrl,
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.of(dialogContext).pop();

                            if (!opened && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Unable to open the official update link.',
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            'Update App Now',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(
                        'Later',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'Download updates only from the official Cloud Guard release.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _checker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}