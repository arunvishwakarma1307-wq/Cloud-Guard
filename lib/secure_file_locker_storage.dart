import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecureFileLockerStorage {
  static const String _storageKey = 'cloud_guard_secure_file_locker';
  static const String _pinStorageKey = 'cloud_guard_secure_file_locker_pin';

  const SecureFileLockerStorage();

  // =========================
  // FILE STORAGE
  // =========================

  Future<List<StoredSecureFile>> loadFiles() async {
    final preferences = await SharedPreferences.getInstance();

    final storedFiles = preferences.getStringList(_storageKey);

    if (storedFiles == null || storedFiles.isEmpty) {
      return const <StoredSecureFile>[];
    }

    final files = <StoredSecureFile>[];

    for (final item in storedFiles) {
      try {
        final decoded = jsonDecode(item);

        if (decoded is! Map<String, dynamic>) {
          continue;
        }

        final name = decoded['name'];
        final bytesBase64 = decoded['bytes'];
        final isLockedValue = decoded['isLocked'];

        if (name is! String || bytesBase64 is! String) {
          continue;
        }

        final bytes = base64Decode(bytesBase64);

        files.add(
          StoredSecureFile(
            name: name,
            bytes: Uint8List.fromList(bytes),
            isLocked: isLockedValue == true,
          ),
        );
      } catch (_) {
        // Ignore corrupted individual entries.
      }
    }

    return files;
  }

  Future<void> saveFiles(List<StoredSecureFile> files) async {
    final preferences = await SharedPreferences.getInstance();

    final encodedFiles = files.map((file) {
      return jsonEncode({
        'name': file.name,
        'bytes': base64Encode(file.bytes),
        'isLocked': file.isLocked,
      });
    }).toList();

    await preferences.setStringList(
      _storageKey,
      encodedFiles,
    );
  }

  Future<void> clearFiles() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_storageKey);
  }

  // =========================
  // COMMON LOCKER PIN
  // =========================

  Future<bool> hasLockerPin() async {
    final preferences = await SharedPreferences.getInstance();

    final storedPinHash = preferences.getString(_pinStorageKey);

    return storedPinHash != null && storedPinHash.isNotEmpty;
  }

  Future<void> setLockerPin(String pin) async {
    final preferences = await SharedPreferences.getInstance();

    final pinHash = _hashPin(pin);

    await preferences.setString(
      _pinStorageKey,
      pinHash,
    );
  }

  Future<bool> verifyLockerPin(String pin) async {
    final preferences = await SharedPreferences.getInstance();

    final storedPinHash = preferences.getString(_pinStorageKey);

    if (storedPinHash == null || storedPinHash.isEmpty) {
      return false;
    }

    return storedPinHash == _hashPin(pin);
  }

  Future<void> changeLockerPin(String newPin) async {
    await setLockerPin(newPin);
  }

  Future<void> removeLockerPin() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_pinStorageKey);
  }

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }
}

class StoredSecureFile {
  const StoredSecureFile({
    required this.name,
    required this.bytes,
    this.isLocked = false,
  });

  final String name;
  final Uint8List bytes;
  final bool isLocked;
}