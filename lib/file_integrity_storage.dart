import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TrustedFileHash {
  const TrustedFileHash({
    required this.fileName,
    required this.hash,
    required this.savedAt,
  });

  final String fileName;
  final String hash;
  final DateTime savedAt;

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'hash': hash,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory TrustedFileHash.fromJson(Map<String, dynamic> json) {
    return TrustedFileHash(
      fileName: json['fileName'] as String,
      hash: json['hash'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }
}

class FileIntegrityStorage {
  static const String _storageKey =
      'cloud_guard_trusted_file_hashes';

  Future<List<TrustedFileHash>> getTrustedHashes() async {
    final preferences = await SharedPreferences.getInstance();

    final storedValue = preferences.getString(_storageKey);

    if (storedValue == null || storedValue.isEmpty) {
      return <TrustedFileHash>[];
    }

    final decoded = jsonDecode(storedValue);

    if (decoded is! List) {
      return <TrustedFileHash>[];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(TrustedFileHash.fromJson)
        .toList(growable: false);
  }

  Future<void> saveTrustedHash({
    required String fileName,
    required String hash,
  }) async {
    final existingHashes = await getTrustedHashes();

    final updatedHashes = existingHashes
        .where(
          (item) => item.fileName.toLowerCase() != fileName.toLowerCase(),
        )
        .toList();

    updatedHashes.add(
      TrustedFileHash(
        fileName: fileName,
        hash: hash,
        savedAt: DateTime.now(),
      ),
    );

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _storageKey,
      jsonEncode(
        updatedHashes.map((item) => item.toJson()).toList(),
      ),
    );
  }

  Future<TrustedFileHash?> getTrustedHash(String fileName) async {
    final hashes = await getTrustedHashes();

    for (final item in hashes) {
      if (item.fileName.toLowerCase() == fileName.toLowerCase()) {
        return item;
      }
    }

    return null;
  }

  Future<void> deleteTrustedHash(String fileName) async {
    final hashes = await getTrustedHashes();

    final updatedHashes = hashes
        .where(
          (item) => item.fileName.toLowerCase() != fileName.toLowerCase(),
        )
        .toList();

    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(
      _storageKey,
      jsonEncode(
        updatedHashes.map((item) => item.toJson()).toList(),
      ),
    );
  }
}

final fileIntegrityStorage = FileIntegrityStorage();