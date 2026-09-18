import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cloud_guard/file_integrity_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns empty list when no trusted hashes exist', () async {
    final storage = FileIntegrityStorage();

    final hashes = await storage.getTrustedHashes();

    expect(hashes, isEmpty);
  });

  test('saves and retrieves a trusted hash', () async {
    final storage = FileIntegrityStorage();

    await storage.saveTrustedHash(
      fileName: 'photo.jpg',
      hash: 'abc123',
    );

    final saved = await storage.getTrustedHash('photo.jpg');

    expect(saved, isNotNull);
    expect(saved!.fileName, 'photo.jpg');
    expect(saved.hash, 'abc123');
  });

  test('file name lookup is case insensitive', () async {
    final storage = FileIntegrityStorage();

    await storage.saveTrustedHash(
      fileName: 'Photo.JPG',
      hash: 'abc123',
    );

    final saved = await storage.getTrustedHash('photo.jpg');

    expect(saved, isNotNull);
    expect(saved!.hash, 'abc123');
  });

  test('saving the same file replaces its previous hash', () async {
    final storage = FileIntegrityStorage();

    await storage.saveTrustedHash(
      fileName: 'document.pdf',
      hash: 'old-hash',
    );

    await storage.saveTrustedHash(
      fileName: 'document.pdf',
      hash: 'new-hash',
    );

    final hashes = await storage.getTrustedHashes();

    expect(hashes.length, 1);
    expect(hashes.first.hash, 'new-hash');
  });

  test('deletes a trusted hash', () async {
    final storage = FileIntegrityStorage();

    await storage.saveTrustedHash(
      fileName: 'document.pdf',
      hash: 'abc123',
    );

    await storage.deleteTrustedHash('document.pdf');

    final saved = await storage.getTrustedHash('document.pdf');

    expect(saved, isNull);
  });

  test('can store multiple trusted files', () async {
    final storage = FileIntegrityStorage();

    await storage.saveTrustedHash(
      fileName: 'photo.jpg',
      hash: 'hash-photo',
    );

    await storage.saveTrustedHash(
      fileName: 'document.pdf',
      hash: 'hash-pdf',
    );

    final hashes = await storage.getTrustedHashes();

    expect(hashes.length, 2);
  });
}