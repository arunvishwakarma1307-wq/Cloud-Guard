import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'secure_file_locker_storage.dart';

class SecureFileLockerPage extends StatefulWidget {
  const SecureFileLockerPage({super.key});

  @override
  State<SecureFileLockerPage> createState() =>
      _SecureFileLockerPageState();
}

class _SecureFileLockerPageState
    extends State<SecureFileLockerPage> {
  final List<_LockedFile> _lockedFiles =
      <_LockedFile>[];

  final SecureFileLockerStorage _storage =
      const SecureFileLockerStorage();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoredFiles();
  }

  Future<void> _loadStoredFiles() async {
    try {
      final storedFiles =
          await _storage.loadFiles();

      if (!mounted) return;

      setState(() {
        _lockedFiles
          ..clear()
          ..addAll(
            storedFiles.map(
              (file) => _LockedFile(
                name: file.name,
                size: _formatFileSize(
                  file.bytes.length,
                ),
                bytes: file.bytes,
                isLocked: file.isLocked,
              ),
            ),
          );

        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load stored locker files.',
          ),
        ),
      );
    }
  }

  // =========================================================
  // ADD FILE
  // =========================================================

  Future<void> _addFile() async {
    final files =
        await FilePicker.pickFiles();

    if (files.isEmpty) return;

    final pickedFile = files.first;
    final bytes =
        await pickedFile.readAsBytes();

    if (!mounted) return;

    if (bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The selected file is empty.',
          ),
        ),
      );
      return;
    }

    final alreadyExists = _lockedFiles.any(
      (file) =>
          file.name.toLowerCase() ==
              pickedFile.name.toLowerCase() &&
          file.bytes.length == bytes.length,
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This file is already in the locker.',
          ),
        ),
      );
      return;
    }

    final newFile = _LockedFile(
      name: pickedFile.name,
      size: _formatFileSize(bytes.length),
      bytes: bytes,
      isLocked: false,
    );

    try {
      final updatedFiles = <_LockedFile>[
        ..._lockedFiles,
        newFile,
      ];

      await _saveLockedFiles(
        updatedFiles,
      );

      if (!mounted) return;

      setState(() {
        _lockedFiles.add(newFile);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${pickedFile.name} added to Secure File Locker.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save this file to the locker.',
          ),
        ),
      );
    }
  }

  // =========================================================
  // SAVE FILES
  // =========================================================

  Future<void> _saveLockedFiles(
    List<_LockedFile> files,
  ) async {
    final storedFiles = files
        .map(
          (file) => StoredSecureFile(
            name: file.name,
            bytes: file.bytes,
            isLocked: file.isLocked,
          ),
        )
        .toList();

    await _storage.saveFiles(
      storedFiles,
    );
  }

  // =========================================================
  // LOCK FILE
  // =========================================================

  Future<void> _lockFile(
    _LockedFile file,
  ) async {
    final hasPin =
        await _storage.hasLockerPin();

    if (!mounted) return;

    if (!hasPin) {
      final pin =
          await _showSetLockerPinDialog();

      if (pin == null) return;

      await _setFileLocked(
        file: file,
        pin: pin,
      );

      return;
    }

    await _setFileLocked(
      file: file,
    );
  }

  Future<void> _setFileLocked({
    required _LockedFile file,
    String? pin,
  }) async {
    try {
      if (pin != null) {
        await _storage.setLockerPin(
          pin,
        );
      }

      final index =
          _lockedFiles.indexOf(file);

      if (index == -1) return;

      final updatedFile =
          file.copyWith(
        isLocked: true,
      );

      final updatedFiles =
          <_LockedFile>[
        ..._lockedFiles,
      ];

      updatedFiles[index] =
          updatedFile;

      await _saveLockedFiles(
        updatedFiles,
      );

      if (!mounted) return;

      setState(() {
        _lockedFiles
          ..clear()
          ..addAll(updatedFiles);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${file.name} is now locked.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to lock this file.',
          ),
        ),
      );
    }
  }

  // =========================================================
  // SET COMMON LOCKER PIN
  // =========================================================

  Future<String?>
      _showSetLockerPinDialog() async {
    final pinController =
        TextEditingController();

    final confirmPinController =
        TextEditingController();

    String? errorMessage;

    final result =
        await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Set Locker PIN',
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Text(
                      'This PIN will be used for all locked files in Secure File Locker.',
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextField(
                      controller:
                          pinController,
                      keyboardType:
                          TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Locker PIN',
                        hintText:
                            '4 to 6 digits',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller:
                          confirmPinController,
                      keyboardType:
                          TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Confirm PIN',
                        hintText:
                            'Enter PIN again',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                    if (errorMessage !=
                        null) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        errorMessage!,
                        style:
                            const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child:
                      const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final pin =
                        pinController.text
                            .trim();

                    final confirmPin =
                        confirmPinController
                            .text
                            .trim();

                    if (!RegExp(
                      r'^\d{4,6}$',
                    ).hasMatch(pin)) {
                      setDialogState(() {
                        errorMessage =
                            'PIN must contain 4 to 6 digits.';
                      });
                      return;
                    }

                    if (pin !=
                        confirmPin) {
                      setDialogState(() {
                        errorMessage =
                            'PIN and Confirm PIN do not match.';
                      });
                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop(pin);
                  },
                  child: const Text(
                    'Set PIN & Lock',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    pinController.dispose();
    confirmPinController.dispose();

    return result;
  }

  // =========================================================
  // UNLOCK FILE
  // =========================================================

  Future<void> _unlockFile(
    _LockedFile file,
  ) async {
    final pin =
        await _showUnlockPinDialog();

    if (pin == null) return;

    // User selected Forgot PIN?
    if (pin == '__FORGOT_PIN__') {
      await _forgotLockerPin();

      if (!mounted) return;

      // After the new PIN is created,
      // immediately ask for the new PIN.
      final newPin =
          await _showUnlockPinDialog();

      if (newPin == null ||
          newPin == '__FORGOT_PIN__') {
        return;
      }

      final validNewPin =
          await _storage.verifyLockerPin(
        newPin,
      );

      if (!mounted) return;

      if (!validNewPin) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Incorrect Locker PIN.',
            ),
          ),
        );
        return;
      }

      _openFile(file);
      return;
    }

    final valid =
        await _storage.verifyLockerPin(
      pin,
    );

    if (!mounted) return;

    if (!valid) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Incorrect Locker PIN.',
          ),
        ),
      );
      return;
    }

    _openFile(file);
  }

  Future<String?>
      _showUnlockPinDialog() async {
    final pinController =
        TextEditingController();

    final result =
        await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Unlock File',
          ),
          content: TextField(
            controller: pinController,
            keyboardType:
                TextInputType.number,
            obscureText: true,
            maxLength: 6,
            autofocus: true,
            decoration:
                const InputDecoration(
              labelText:
                  'Locker PIN',
              hintText:
                  'Enter your Locker PIN',
              border:
                  OutlineInputBorder(),
            ),
            onSubmitted: (_) {
              Navigator.of(
                dialogContext,
              ).pop(
                pinController.text
                    .trim(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child:
                  const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  '__FORGOT_PIN__',
                );
              },
              child:
                  const Text('Forgot PIN?'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(
                  pinController.text
                      .trim(),
                );
              },
              child:
                  const Text('Unlock File'),
            ),
          ],
        );
      },
    );

    pinController.dispose();

    if (result == null ||
        result.isEmpty) {
      return null;
    }

    return result;
  }

  // =========================================================
  // OPEN FILE
  // =========================================================

  void _openFile(
    _LockedFile file,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            _SecureFilePreviewPage(
          file: file,
        ),
      ),
    );
  }

  // =========================================================
  // REMOVE FILE
  // =========================================================

  Future<void> _removeFile(
    _LockedFile file,
  ) async {
    final updatedFiles =
        _lockedFiles
            .where(
              (existingFile) =>
                  existingFile != file,
            )
            .toList();

    try {
      await _saveLockedFiles(
        updatedFiles,
      );

      if (!mounted) return;

      setState(() {
        _lockedFiles
          ..clear()
          ..addAll(updatedFiles);
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${file.name} removed from locker.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to remove this file.',
          ),
        ),
      );
    }
  }

  // =========================================================
  // FORGOT PIN
  // =========================================================

  Future<void> _forgotLockerPin() async {
    final verified =
        await _verifyFirebaseAccount();

    if (!verified || !mounted) {
      return;
    }

    final newPin =
        await _showSetNewLockerPinDialog();

    if (newPin == null) return;

    try {
      // New PIN becomes active immediately
      // for every locked file.
      await _storage.changeLockerPin(
        newPin,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Locker PIN changed successfully. The new PIN is active now.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to change Locker PIN.',
          ),
        ),
      );
    }
  }

  Future<String?>
      _showSetNewLockerPinDialog() async {
    final pinController =
        TextEditingController();

    final confirmPinController =
        TextEditingController();

    String? errorMessage;

    final result =
        await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Set New Locker PIN',
              ),
              content:
                  SingleChildScrollView(
                child: Column(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    const Text(
                      'Your new PIN will immediately become active for all locked files.',
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    TextField(
                      controller:
                          pinController,
                      keyboardType:
                          TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'New Locker PIN',
                        hintText:
                            '4 to 6 digits',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller:
                          confirmPinController,
                      keyboardType:
                          TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Confirm New PIN',
                        border:
                            OutlineInputBorder(),
                      ),
                    ),
                    if (errorMessage !=
                        null) ...[
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        errorMessage!,
                        style:
                            const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child:
                      const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final pin =
                        pinController.text
                            .trim();

                    final confirmPin =
                        confirmPinController
                            .text
                            .trim();

                    if (!RegExp(
                      r'^\d{4,6}$',
                    ).hasMatch(pin)) {
                      setDialogState(() {
                        errorMessage =
                            'PIN must contain 4 to 6 digits.';
                      });
                      return;
                    }

                    if (pin !=
                        confirmPin) {
                      setDialogState(() {
                        errorMessage =
                            'PIN and Confirm PIN do not match.';
                      });
                      return;
                    }

                    Navigator.of(
                      dialogContext,
                    ).pop(pin);
                  },
                  child:
                      const Text('Set New PIN'),
                ),
              ],
            );
          },
        );
      },
    );

    pinController.dispose();
    confirmPinController.dispose();

    return result;
  }

  // =========================================================
  // FIREBASE ACCOUNT VERIFICATION
  // =========================================================

  Future<bool>
      _verifyFirebaseAccount() async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'No Firebase account is currently signed in.',
          ),
        ),
      );

      return false;
    }

    final providerIds =
        user.providerData
            .map(
              (provider) =>
                  provider.providerId,
            )
            .toSet();

    if (providerIds.contains(
      'password',
    )) {
      return _reauthenticateWithPassword(
        user,
      );
    }

    if (providerIds.contains(
      'google.com',
    )) {
      return _reauthenticateWithGoogle(
        user,
      );
    }

    if (!mounted) return false;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'This account provider is not supported for Locker PIN recovery yet.',
        ),
      ),
    );

    return false;
  }

  // =========================================================
  // FIREBASE PASSWORD VERIFICATION
  // =========================================================

  Future<bool>
      _reauthenticateWithPassword(
    User user,
  ) async {
    final passwordController =
        TextEditingController();

    bool obscurePassword = true;

    final password =
        await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder:
              (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Verify Firebase Account',
              ),
              content: TextField(
                controller:
                    passwordController,
                obscureText:
                    obscurePassword,
                autofocus: true,
                decoration:
                    InputDecoration(
                  labelText:
                      'Firebase account password',
                  border:
                      const OutlineInputBorder(),
                  helperText:
                      user.email,
                  suffixIcon:
                      IconButton(
                    tooltip:
                        obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                    icon: Icon(
                      obscurePassword
                          ? Icons
                              .visibility_off
                          : Icons
                              .visibility,
                    ),
                    onPressed: () {
                      setDialogState(() {
                        obscurePassword =
                            !obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop();
                  },
                  child:
                      const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(
                      passwordController
                          .text,
                    );
                  },
                  child:
                      const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();

    if (password == null ||
        password.isEmpty) {
      return false;
    }

    try {
      final email = user.email;

      if (email == null ||
          email.isEmpty) {
        return false;
      }

      final credential =
          EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await user
          .reauthenticateWithCredential(
        credential,
      );

      return true;
    } on FirebaseAuthException catch (
        e) {
      if (!mounted) return false;

      String message =
          'Firebase account verification failed.';

      if (e.code ==
              'wrong-password' ||
          e.code ==
              'invalid-credential') {
        message =
            'Incorrect Firebase account password.';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );

      return false;
    } catch (_) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Firebase account verification failed.',
          ),
        ),
      );

      return false;
    }
  }

  // =========================================================
  // GOOGLE VERIFICATION
  // =========================================================

  Future<bool>
      _reauthenticateWithGoogle(
    User user,
  ) async {
    try {
      final provider =
          GoogleAuthProvider();

      if (kIsWeb) {
        await user
            .reauthenticateWithPopup(
          provider,
        );

        return true;
      }

      final googleUser =
          await GoogleSignIn.instance
              .authenticate();

      final googleAuth =
          googleUser.authentication;

      final idToken =
          googleAuth.idToken;

      if (idToken == null) {
        throw Exception(
          'Google ID token was not returned.',
        );
      }

      final credential =
          GoogleAuthProvider.credential(
        idToken: idToken,
      );

      await user
          .reauthenticateWithCredential(
        credential,
      );

      return true;
    } on FirebaseAuthException catch (
        e) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                'Google account verification failed.',
          ),
        ),
      );

      return false;
    } catch (_) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Google account verification failed.',
          ),
        ),
      );

      return false;
    }
  }

  // =========================================================
  // SIZE
  // =========================================================

  static String _formatFileSize(
    int bytes,
  ) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes <
        1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }

    if (bytes <
        1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Secure File Locker',
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value ==
                  'forgot_pin') {
                _forgotLockerPin();
              }
            },
            itemBuilder:
                (context) => const [
              PopupMenuItem(
                value: 'forgot_pin',
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_reset,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Forgot Locker PIN?',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding:
                  const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Padding(
                      padding:
                          const EdgeInsets.all(
                        20,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 42,
                            color: Theme.of(
                              context,
                            )
                                .colorScheme
                                .primary,
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  'Protected File Area',
                                  style:
                                      TextStyle(
                                    fontSize: 20,
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),
                                SizedBox(
                                  height: 6,
                                ),
                                Text(
                                  'Files are stored locally. Lock individual files with one common Locker PIN.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child:
                        ElevatedButton.icon(
                      onPressed: _addFile,
                      icon: const Icon(
                        Icons.add,
                      ),
                      label: const Text(
                        'Add File',
                        style:
                            TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 28,
                  ),
                  const Text(
                    'Locker Files',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  if (_lockedFiles.isEmpty)
                    Card(
                      child: Padding(
                        padding:
                            const EdgeInsets
                                .all(24),
                        child: SizedBox(
                          width:
                              double.infinity,
                          child: Column(
                            children: [
                              Icon(
                                Icons
                                    .folder_off,
                                size: 50,
                                color: Colors
                                    .grey
                                    .shade500,
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              const Text(
                                'No files in the locker yet.',
                                textAlign:
                                    TextAlign
                                        .center,
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              const Text(
                                'Use Add File to place a file in the locker.',
                                textAlign:
                                    TextAlign
                                        .center,
                                style:
                                    TextStyle(
                                  color: Colors
                                      .grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount:
                          _lockedFiles.length,
                      separatorBuilder:
                          (context, index) =>
                              const SizedBox(
                        height: 10,
                      ),
                      itemBuilder:
                          (context, index) {
                        final file =
                            _lockedFiles[
                                index];

                        return Card(
                          child: ListTile(
                            leading:
                                CircleAvatar(
                              child: Icon(
                                file.isLocked
                                    ? Icons.lock
                                    : Icons
                                        .lock_open,
                              ),
                            ),
                            title: Text(
                              file.name,
                              maxLines: 2,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                            subtitle: Text(
                              file.isLocked
                                  ? '${file.size} • Locked'
                                  : '${file.size} • Unlocked',
                            ),
                            trailing:
                                PopupMenuButton<
                                    String>(
                              onSelected:
                                  (value) {
                                if (value ==
                                    'open') {
                                  if (file
                                      .isLocked) {
                                    _unlockFile(
                                      file,
                                    );
                                  } else {
                                    _openFile(
                                      file,
                                    );
                                  }
                                }

                                if (value ==
                                    'lock') {
                                  _lockFile(
                                    file,
                                  );
                                }

                                if (value ==
                                    'remove') {
                                  _removeFile(
                                    file,
                                  );
                                }
                              },
                              itemBuilder:
                                  (context) {
                                return [
                                  PopupMenuItem(
                                    value:
                                        'open',
                                    child: Row(
                                      children: [
                                        Icon(
                                          file.isLocked
                                              ? Icons
                                                  .lock_open
                                              : Icons
                                                  .visibility,
                                        ),
                                        const SizedBox(
                                          width:
                                              10,
                                        ),
                                        Text(
                                          file.isLocked
                                              ? 'Unlock File'
                                              : 'Open',
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (!file
                                      .isLocked)
                                    const PopupMenuItem(
                                      value:
                                          'lock',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons
                                                .lock,
                                          ),
                                          SizedBox(
                                            width:
                                                10,
                                          ),
                                          Text(
                                            'Lock File',
                                          ),
                                        ],
                                      ),
                                    ),
                                  const PopupMenuItem(
                                    value:
                                        'remove',
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons
                                              .delete_outline,
                                        ),
                                        SizedBox(
                                          width:
                                              10,
                                        ),
                                        Text(
                                          'Remove',
                                        ),
                                      ],
                                    ),
                                  ),
                                ];
                              },
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

// =========================================================
// FILE PREVIEW
// =========================================================

class _SecureFilePreviewPage
    extends StatelessWidget {
  const _SecureFilePreviewPage({
    required this.file,
  });

  final _LockedFile file;

  String get _extension {
    final dotIndex =
        file.name.lastIndexOf('.');

    if (dotIndex == -1 ||
        dotIndex ==
            file.name.length - 1) {
      return '';
    }

    return file.name
        .substring(dotIndex + 1)
        .toLowerCase();
  }

  bool get _isPdf =>
      _extension == 'pdf';

  bool get _isImage =>
      _extension == 'png' ||
      _extension == 'jpg' ||
      _extension == 'jpeg' ||
      _extension == 'gif' ||
      _extension == 'webp';

  bool get _isText =>
      _extension == 'txt' ||
      _extension == 'csv';

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          file.name,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
        ),
      ),
      body:
          _buildPreview(context),
    );
  }

  Widget _buildPreview(
    BuildContext context,
  ) {
    if (_isPdf) {
      return SfPdfViewer.memory(
        file.bytes,
      );
    }

    if (_isImage) {
      return _ImagePreview(
        file: file,
      );
    }

    if (_isText) {
      return _TextPreview(
        file: file,
      );
    }

    return _UnsupportedFilePreview(
      file: file,
      extension: _extension,
    );
  }
}

// =========================================================
// IMAGE PREVIEW
// =========================================================

class _ImagePreview
    extends StatelessWidget {
  const _ImagePreview({
    required this.file,
  });

  final _LockedFile file;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5,
        child: Image.memory(
          file.bytes,
          fit: BoxFit.contain,
          errorBuilder:
              (context, error, stackTrace) {
            return const Padding(
              padding:
                  EdgeInsets.all(24),
              child: Text(
                'Unable to preview this image.',
                textAlign:
                    TextAlign.center,
              ),
            );
          },
        ),
      ),
    );
  }
}

// =========================================================
// TEXT PREVIEW
// =========================================================

class _TextPreview
    extends StatelessWidget {
  const _TextPreview({
    required this.file,
  });

  final _LockedFile file;

  @override
  Widget build(
    BuildContext context,
  ) {
    final text = utf8.decode(
      file.bytes,
      allowMalformed: true,
    );

    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(20),
      child: SelectableText(
        text.isEmpty
            ? 'This text file is empty.'
            : text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }
}

// =========================================================
// UNSUPPORTED FILE PREVIEW
// =========================================================

class _UnsupportedFilePreview
    extends StatelessWidget {
  const _UnsupportedFilePreview({
    required this.file,
    required this.extension,
  });

  final _LockedFile file;
  final String extension;

  @override
  Widget build(
    BuildContext context,
  ) {
    final displayExtension =
        extension.isEmpty
            ? 'Unknown'
            : extension.toUpperCase();

    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Icon(
                  Icons.insert_drive_file,
                  size: 64,
                ),
                const SizedBox(
                  height: 16,
                ),
                Text(
                  file.name,
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'File type: $displayExtension',
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  'Size: ${file.size}',
                ),
                const SizedBox(
                  height: 20,
                ),
                const Text(
                  'Preview is not available for this file type yet.',
                  textAlign:
                      TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================
// FILE MODEL
// =========================================================

class _LockedFile {
  const _LockedFile({
    required this.name,
    required this.size,
    required this.bytes,
    required this.isLocked,
  });

  final String name;
  final String size;
  final Uint8List bytes;
  final bool isLocked;

  _LockedFile copyWith({
    bool? isLocked,
  }) {
    return _LockedFile(
      name: name,
      size: size,
      bytes: bytes,
      isLocked:
          isLocked ?? this.isLocked,
    );
  }
}