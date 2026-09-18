import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_guard/file_integrity_service.dart';

void main() {
  const service = FileIntegrityService();

  test('calculates a SHA-256 hash', () {
    final bytes = Uint8List.fromList(
      utf8.encode('Cloud Guard'),
    );

    final hash = service.calculateSha256(bytes);

    expect(hash.length, 64);
    expect(
      RegExp(r'^[0-9a-f]{64}$').hasMatch(hash),
      isTrue,
    );
  });

  test('same file matches the trusted hash', () {
    final bytes = Uint8List.fromList(
      utf8.encode('Cloud Guard'),
    );

    final trustedHash = service.calculateSha256(bytes);

    expect(
      service.matchesTrustedHash(
        bytes: bytes,
        trustedHash: trustedHash,
      ),
      isTrue,
    );
  });

  test('changed file does not match the trusted hash', () {
    final originalBytes = Uint8List.fromList(
      utf8.encode('Cloud Guard'),
    );

    final changedBytes = Uint8List.fromList(
      utf8.encode('Cloud Guard Changed'),
    );

    final trustedHash = service.calculateSha256(
      originalBytes,
    );

    expect(
      service.matchesTrustedHash(
        bytes: changedBytes,
        trustedHash: trustedHash,
      ),
      isFalse,
    );
  });

  test('hash comparison ignores uppercase and surrounding spaces', () {
    final bytes = Uint8List.fromList(
      utf8.encode('Cloud Guard'),
    );

    final trustedHash = service.calculateSha256(bytes);

    expect(
      service.matchesTrustedHash(
        bytes: bytes,
        trustedHash: '  ${trustedHash.toUpperCase()}  ',
      ),
      isTrue,
    );
  });
}