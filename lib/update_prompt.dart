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

    final availableUpdate = update;

    securityActivityLog.record(
      title: 'Update detected',
      description:
          'A newer Cloud Guard release ${availableUpdate.version} is available.',
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.84),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.sizeOf(context).width;
              final screenHeight = MediaQuery.sizeOf(context).height;

              // Keep the popup width controlled on both Web and Android.
              final popupWidth = screenWidth >= 700
                  ? 430.0
                  : screenWidth * 0.88;

              // Keep the robot proportional instead of allowing it
              // to make the Android popup unnecessarily tall.
              final robotHeight = screenWidth >= 700
                  ? 205.0
                  : (screenWidth * 0.34).clamp(150.0, 190.0);

              final horizontalPadding = screenWidth >= 700 ? 22.0 : 20.0;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: 0,
                    maxWidth: popupWidth,
                    maxHeight: screenHeight - 48,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF07080D),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFF9B5CFF).withValues(
                          alpha: 0.82,
                        ),
                        width: 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9B5CFF).withValues(
                            alpha: 0.30,
                          ),
                          blurRadius: 28,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: const Color(0xFF4F8CFF).withValues(
                            alpha: 0.22,
                          ),
                          blurRadius: 42,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.60,
                          ),
                          blurRadius: 34,
                          spreadRadius: 4,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        20,
                        horizontalPadding,
                        22,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ------------------------------------------------
                          // ROBOT
                          // ------------------------------------------------
                          SizedBox(
                            height: robotHeight,
                            width: double.infinity,
                            child: Image.asset(
                              'assets/images/update_robot.png',
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // ------------------------------------------------
                          // MAIN TITLE
                          // ------------------------------------------------
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'New Update Available!',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ------------------------------------------------
                          // VERSION
                          // ------------------------------------------------
                          ShaderMask(
                            shaderCallback: (bounds) {
                              return const LinearGradient(
                                colors: [
                                  Color(0xFFFF4FA3),
                                  Color(0xFFB95CFF),
                                  Color(0xFF4F8CFF),
                                ],
                              ).createShader(bounds);
                            },
                            child: Text(
                              'Cloud Guard ${availableUpdate.version}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // ------------------------------------------------
                          // WHAT'S NEW
                          // ------------------------------------------------
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                Container(
                                  width: 5,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFFFF4FA3),
                                        Color(0xFF9B5CFF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFF4FA3,
                                        ).withValues(alpha: 0.35),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "What's New",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 13),

                          // ------------------------------------------------
                          // RELEASE NOTES CARD
                          // ------------------------------------------------
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(
                              18,
                              17,
                              18,
                              17,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF11131B),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(
                                  0xFF7180B0,
                                ).withValues(alpha: 0.30),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              availableUpdate.releaseNotes,
                              style: const TextStyle(
                                color: Color(0xFFD6D9EA),
                                fontSize: 16,
                                height: 1.55,
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          // ------------------------------------------------
                          // UPDATE BUTTON
                          // ------------------------------------------------
                          SizedBox(
                            width: double.infinity,
                            height: 62,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color(0xFFFF3FA4),
                                    Color(0xFFB84CFF),
                                    Color(0xFF496CFF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(19),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF3FA4,
                                    ).withValues(alpha: 0.28),
                                    blurRadius: 22,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: const Color(
                                      0xFF496CFF,
                                    ).withValues(alpha: 0.20),
                                    blurRadius: 25,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(19),
                                  ),
                                ),
                                onPressed: () async {
                                  final opened =
                                      await _checker.openDownloadUrl(
                                    availableUpdate.downloadUrl,
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
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ------------------------------------------------
                          // LATER
                          // ------------------------------------------------
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            child: Text(
                              'Later',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.68),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const SizedBox(height: 3),

                          // ------------------------------------------------
                          // SECURITY MESSAGE
                          // ------------------------------------------------
                          Text(
                            'Download updates only from the official Cloud Guard release.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.40),
                              fontSize: 12,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
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