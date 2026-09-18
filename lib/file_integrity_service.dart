import 'dart:typed_data';

import 'package:crypto/crypto.dart';

enum IntegrityStatus {
  originalBaselineMatched,
  modified,
  cannotVerify,
}

class FileIntegrityService {
  const FileIntegrityService();

  /// Calculates the real SHA-256 hash
  /// from the supplied file bytes.
  String calculateSha256(Uint8List bytes) {
    return sha256.convert(bytes).toString();
  }

  /// Performs the real integrity check.
  ///
  /// No trusted baseline:
  /// Cannot verify.
  ///
  /// Same SHA-256:
  /// File Unchanged.
  ///
  /// Different SHA-256:
  /// File Changed.
  IntegrityStatus checkIntegrity({
    required Uint8List bytes,
    required String? trustedHash,
  }) {
    if (trustedHash == null || trustedHash.trim().isEmpty) {
      return IntegrityStatus.cannotVerify;
    }

    final currentHash = calculateSha256(bytes);

    final hashesMatch =
        currentHash.toLowerCase().trim() ==
        trustedHash.toLowerCase().trim();

    if (hashesMatch) {
      return IntegrityStatus.originalBaselineMatched;
    }

    return IntegrityStatus.modified;
  }

  /// Returns true only when the real SHA-256
  /// matches the trusted SHA-256.
  bool matchesTrustedHash({
    required Uint8List bytes,
    required String trustedHash,
  }) {
    return checkIntegrity(
          bytes: bytes,
          trustedHash: trustedHash,
        ) ==
        IntegrityStatus.originalBaselineMatched;
  }
}