import 'dart:typed_data';

import 'file_type_detector.dart';
import 'local_file_workspace.dart';
import 'pdf_file_validation.dart';

class FileSecurityScanResult {
  const FileSecurityScanResult({
    required this.extensionPassed,
    required this.signaturePassed,
    required this.sizePassed,
    required this.fileNamePassed,
    required this.duplicatePassed,
    required this.suspiciousNamePassed,
    required this.dangerousExtensionPassed,
    required this.originalFileType,
    required this.duplicateExtension,
    required this.detectedFileType,
  });

  final bool extensionPassed;
  final bool signaturePassed;
  final bool sizePassed;
  final bool fileNamePassed;
  final bool duplicatePassed;
  final bool suspiciousNamePassed;
  final bool dangerousExtensionPassed;

  /// Example:
  /// PDF (.pdf)
  /// Word (.docx)
  /// Not detected
  final String originalFileType;

  /// Final dangerous extension when a double extension exists.
  /// Example:
  /// invoice.pdf.exe -> .exe
  final String duplicateExtension;

  /// Example:
  /// PDF
  /// Word
  /// Unknown
  final String detectedFileType;

  bool get passed =>
      extensionPassed &&
      signaturePassed &&
      sizePassed &&
      fileNamePassed &&
      duplicatePassed &&
      suspiciousNamePassed &&
      dangerousExtensionPassed;

  String get resultText =>
      passed ? 'Basic Security Scan Passed' : 'Basic Security Scan Failed';
}

class FileSecurityScanner {
  const FileSecurityScanner();

  static const Set<String> _dangerousExtensions = {
    '.exe',
    '.bat',
    '.cmd',
    '.ps1',
    '.scr',
    '.com',
  };

  FileSecurityScanResult scan({
    required String fileName,
    required int fileSize,
    required Uint8List? bytes,
  }) {
    // Existing PDF workspace rule.
    final extensionPassed =
        fileName.toLowerCase().endsWith('.pdf');

    final sizePassed =
        fileSize <= maxPdfFileSizeBytes;

    final signaturePassed =
        bytes != null && hasPdfSignature(bytes);

    final fileNamePassed =
        _isSafeFileName(fileName);

    final duplicatePassed = !_isDuplicate(
      fileName: fileName,
      fileSize: fileSize,
    );

    final suspiciousNamePassed =
        !_hasSuspiciousDoubleExtension(fileName);

    final dangerousExtensionPassed =
        !_hasDangerousExtension(fileName);

    final detected =
        _detectFileType(bytes);

    final originalFileType =
        _buildOriginalFileType(detected);

    final duplicateExtension =
        _getDuplicateExtension(fileName);

    final detectedFileType =
        detected?.name ?? 'Unknown';

    return FileSecurityScanResult(
      extensionPassed: extensionPassed,
      signaturePassed: signaturePassed,
      sizePassed: sizePassed,
      fileNamePassed: fileNamePassed,
      duplicatePassed: duplicatePassed,
      suspiciousNamePassed: suspiciousNamePassed,
      dangerousExtensionPassed: dangerousExtensionPassed,
      originalFileType: originalFileType,
      duplicateExtension: duplicateExtension,
      detectedFileType: detectedFileType,
    );
  }

  DetectedFileType? _detectFileType(
    Uint8List? bytes,
  ) {
    if (bytes == null) {
      return null;
    }

    const detector = FileTypeDetector();

    return detector.detect(bytes);
  }

  String _buildOriginalFileType(
    DetectedFileType? detected,
  ) {
    if (detected == null) {
      return 'Not detected';
    }

    return '${detected.name} (${detected.extensionLabel})';
  }

  String _getDuplicateExtension(
    String fileName,
  ) {
    if (!_hasSuspiciousDoubleExtension(fileName)) {
      return 'None';
    }

    final name = fileName.trim();

    final lastDotIndex = name.lastIndexOf('.');

    if (lastDotIndex <= 0 ||
        lastDotIndex == name.length - 1) {
      return 'None';
    }

    return name
        .substring(lastDotIndex)
        .toLowerCase();
  }

  bool _isSafeFileName(
    String fileName,
  ) {
    final name = fileName.trim();

    if (name.isEmpty) return false;

    if (name == '.' || name == '..') {
      return false;
    }

    if (name.length > 255) {
      return false;
    }

    // Block control characters.
    for (final codeUnit in name.codeUnits) {
      if (codeUnit < 32) {
        return false;
      }
    }

    // Block path separators.
    if (name.contains('/') ||
        name.contains(r'\')) {
      return false;
    }

    return true;
  }

  bool _hasSuspiciousDoubleExtension(
    String fileName,
  ) {
    final name =
        fileName.trim().toLowerCase();

    final hasDangerousFinalExtension =
        _dangerousExtensions.any(
      (extension) =>
          name.endsWith(extension),
    );

    if (!hasDangerousFinalExtension) {
      return false;
    }

    final lastDotIndex =
        name.lastIndexOf('.');

    if (lastDotIndex <= 0) {
      return false;
    }

    final beforeFinalExtension =
        name.substring(
      0,
      lastDotIndex,
    );

    // Example:
    // invoice.pdf.exe
    //
    // beforeFinalExtension = invoice.pdf
    // Therefore another extension exists.
    return beforeFinalExtension.contains('.');
  }

  bool _hasDangerousExtension(
    String fileName,
  ) {
    final name =
        fileName.trim().toLowerCase();

    return _dangerousExtensions.any(
      (extension) =>
          name.endsWith(extension),
    );
  }

  bool _isDuplicate({
    required String fileName,
    required int fileSize,
  }) {
    return localFileWorkspace.entries.any(
      (entry) =>
          entry.name.toLowerCase() ==
              fileName.toLowerCase() &&
          entry.sizeBytes == fileSize,
    );
  }
}