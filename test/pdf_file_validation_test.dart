import 'dart:typed_data';

import 'package:cloud_guard/pdf_file_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validatePdfFile', () {
    test('rejects a file that does not use a .pdf extension', () {
      final message = validatePdfFile(
        fileName: 'notes.txt',
        fileSize: 100,
        bytes: null,
      );

      expect(message, "Please choose a PDF file");
    });

    test('accepts an uppercase .PDF extension', () {
      final message = validatePdfFile(
        fileName: 'Report.PDF',
        fileSize: 100,
        bytes: null,
      );

      expect(message, isNull);
    });

    test('rejects a PDF larger than 10 MB', () {
      final message = validatePdfFile(
        fileName: 'large.pdf',
        fileSize: maxPdfFileSizeBytes + 1,
        bytes: null,
      );

      expect(message, "PDF files must be 10 MB or smaller");
    });

    test('accepts a PDF that is exactly 10 MB', () {
      final message = validatePdfFile(
        fileName: 'exact.pdf',
        fileSize: maxPdfFileSizeBytes,
        bytes: null,
      );

      expect(message, isNull);
    });

    test('accepts bytes that start with the %PDF- signature', () {
      final message = validatePdfFile(
        fileName: 'valid.pdf',
        fileSize: 8,
        bytes: Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x37]),
      );

      expect(message, isNull);
    });

    test('rejects bytes that do not start with the %PDF- signature', () {
      final message = validatePdfFile(
        fileName: 'fake.pdf',
        fileSize: 5,
        bytes: Uint8List.fromList([0x00, 0x50, 0x44, 0x46, 0x2D]),
      );

      expect(message, "The selected file is not a valid PDF");
    });

    test('rejects bytes that are shorter than the %PDF- signature', () {
      final message = validatePdfFile(
        fileName: 'short.pdf',
        fileSize: 3,
        bytes: Uint8List.fromList([0x25, 0x50, 0x44]),
      );

      expect(message, "The selected file is not a valid PDF");
    });

    test('skips the signature check when bytes are not available', () {
      final message = validatePdfFile(
        fileName: 'unread.pdf',
        fileSize: 2048,
        bytes: null,
      );

      expect(message, isNull);
    });
  });
}
