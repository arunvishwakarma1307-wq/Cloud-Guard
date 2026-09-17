import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_guard/file_security_scanner.dart';

void main() {
  test('unsafe filename is rejected', () {
    const scanner = FileSecurityScanner();

    final result = scanner.scan(
      fileName: 'folder/unsafe.pdf',
      fileSize: 100,
      bytes: Uint8List.fromList([
        0x25,
        0x50,
        0x44,
        0x46,
        0x2D,
      ]),
    );

    expect(result.fileNamePassed, isFalse);
    expect(result.passed, isFalse);
  });

  test('double extension is detected', () {
    const scanner = FileSecurityScanner();

    final result = scanner.scan(
      fileName: 'invoice.pdf.exe',
      fileSize: 100,
      bytes: Uint8List.fromList([
        0x25,
        0x50,
        0x44,
        0x46,
        0x2D,
      ]),
    );

    expect(result.suspiciousNamePassed, isFalse);
    expect(result.dangerousExtensionPassed, isFalse);
    expect(result.passed, isFalse);
  });

  test('dangerous extension is detected', () {
    const scanner = FileSecurityScanner();

    final result = scanner.scan(
      fileName: 'script.bat',
      fileSize: 100,
      bytes: Uint8List.fromList([
        0x25,
        0x50,
        0x44,
        0x46,
        0x2D,
      ]),
    );

    expect(result.dangerousExtensionPassed, isFalse);
    expect(result.passed, isFalse);
  });

  test('normal PDF passes suspicious file checks', () {
    const scanner = FileSecurityScanner();

    final result = scanner.scan(
      fileName: 'invoice.pdf',
      fileSize: 100,
      bytes: Uint8List.fromList([
        0x25,
        0x50,
        0x44,
        0x46,
        0x2D,
      ]),
    );

    expect(result.suspiciousNamePassed, isTrue);
    expect(result.dangerousExtensionPassed, isTrue);
  });
}