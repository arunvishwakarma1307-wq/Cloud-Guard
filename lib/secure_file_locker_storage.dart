import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class SecureFileLockerStorage {
  static const String _storageKey = 'cloud_guard_secure_file_locker';

  const SecureFileLockerStorage();

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

        if (name is! String || bytesBase64 is! String) {
          continue;
        }

        final bytes = base64Decode(bytesBase64);

        files.add(
          StoredSecureFile(
            name: name,
            bytes: Uint8List.fromList(bytes),
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
}

class StoredSecureFile {
  const StoredSecureFile({
    required this.name,
    required this.bytes,
  });

  final String name;
  final Uint8List bytes;
}