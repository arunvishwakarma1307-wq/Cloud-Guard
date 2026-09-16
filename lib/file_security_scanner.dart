import 'dart:typed_data';

import 'local_file_workspace.dart';
import 'pdf_file_validation.dart';

class FileSecurityScanResult {
  const FileSecurityScanResult({
    required this.extensionPassed,
    required this.signaturePassed,
    required this.sizePassed,
    required this.fileNamePassed,
    required this.duplicatePassed,
  });

  final bool extensionPassed;
  final bool signaturePassed;
  final bool sizePassed;
  final bool fileNamePassed;
  final bool duplicatePassed;

  bool get passed =>
      extensionPassed &&
      signaturePassed &&
      sizePassed &&
      fileNamePassed &&
      duplicatePassed;

  String get resultText =>
      passed ? 'Basic Security Scan Passed' : 'Basic Security Scan Failed';
}

class FileSecurityScanner {
  const FileSecurityScanner();

  FileSecurityScanResult scan({
    required String fileName,
    required int fileSize,
    required Uint8List? bytes,
  }) {
    final extensionPassed = fileName.toLowerCase().endsWith('.pdf');

    final sizePassed = fileSize <= maxPdfFileSizeBytes;

    final signaturePassed =
        bytes != null && hasPdfSignature(bytes);

    final fileNamePassed = _isSafeFileName(fileName);

    final duplicatePassed = !_isDuplicate(
      fileName: fileName,
      fileSize: fileSize,
    );

    return FileSecurityScanResult(
      extensionPassed: extensionPassed,
      signaturePassed: signaturePassed,
      sizePassed: sizePassed,
      fileNamePassed: fileNamePassed,
      duplicatePassed: duplicatePassed,
    );
  }

  bool _isSafeFileName(String fileName) {
    final name = fileName.trim();

    if (name.isEmpty) return false;
    if (name == '.' || name == '..') return false;
    if (name.length > 255) return false;

    // Block control characters and path separators.
    for (final codeUnit in name.codeUnits) {
      if (codeUnit < 32) return false;
    }

    if (name.contains('/') || name.contains(r'\')) {
      return false;
    }

    return true;
  }

  bool _isDuplicate({
    required String fileName,
    required int fileSize,
  }) {
    return localFileWorkspace.entries.any(
      (entry) =>
          entry.name.toLowerCase() == fileName.toLowerCase() &&
          entry.sizeBytes == fileSize,
    );
  }
}