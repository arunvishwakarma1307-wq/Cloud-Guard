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
    required this.detectedExtension,
    required this.fileTypeSupported,
  });

  final bool extensionPassed;
  final bool signaturePassed;
  final bool sizePassed;
  final bool fileNamePassed;
  final bool duplicatePassed;
  final bool suspiciousNamePassed;
  final bool dangerousExtensionPassed;

  final String originalFileType;
  final String duplicateExtension;
  final String detectedFileType;
  final String detectedExtension;

  /// True when Cloud Guard knows how to identify the file
  /// from its content/signature.
  final bool fileTypeSupported;

  bool get passed =>
      extensionPassed &&
      signaturePassed &&
      sizePassed &&
      fileNamePassed &&
      duplicatePassed &&
      suspiciousNamePassed &&
      dangerousExtensionPassed;

  String get resultText {
    return passed
        ? 'Basic Security Scan Passed'
        : 'Basic Security Scan Failed';
  }
}

class FileSecurityScanner {
  const FileSecurityScanner();

  static const Set<String> dangerousExtensions = {
    '.exe',
    '.bat',
    '.cmd',
    '.ps1',
    '.scr',
    '.com',
  };

  static const Set<String> supportedExtensions = {
    '.pdf',
    '.png',
    '.jpg',
    '.jpeg',
    '.gif',
    '.webp',
    '.zip',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
    '.txt',
    '.csv',
  };

  FileSecurityScanResult scan({
    required String fileName,
    required int fileSize,
    Uint8List? bytes,
  }) {
    final currentExtension = _getExtension(fileName);

    final dangerousExtension =
        _hasDangerousExtension(currentExtension);

    final suspiciousDoubleExtension =
        _hasSuspiciousDoubleExtension(fileName);

    final safeFileName = _isSafeFileName(fileName);

    final duplicate = _isDuplicate(
      fileName: fileName,
      fileSize: fileSize,
    );

    final detectedType =
        bytes == null ? null : const FileTypeDetector().detect(bytes);

    final detectedExtension =
        detectedType?.extension ?? '';

    final detectedTypeName =
        detectedType?.name ?? 'Not detected';

    final supported =
        detectedType != null ||
        supportedExtensions.contains(currentExtension);

    final extensionPassed =
        !dangerousExtension &&
        supportedExtensions.contains(currentExtension);

    final signaturePassed = _signatureCheck(
      fileName: fileName,
      bytes: bytes,
      detectedType: detectedType,
    );

    final sizePassed = _sizeCheck(
      fileName: fileName,
      fileSize: fileSize,
    );

    final originalFileType =
        detectedType?.name ?? 'Not detected';

    return FileSecurityScanResult(
      extensionPassed: extensionPassed,
      signaturePassed: signaturePassed,
      sizePassed: sizePassed,
      fileNamePassed: safeFileName,
      duplicatePassed: !duplicate,
      suspiciousNamePassed: !suspiciousDoubleExtension,
      dangerousExtensionPassed: !dangerousExtension,
      originalFileType: originalFileType,
      duplicateExtension:
          _getSuspiciousExtension(fileName),
      detectedFileType: detectedTypeName,
      detectedExtension: detectedExtension,
      fileTypeSupported: supported,
    );
  }

  String _getExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');

    if (lastDot == -1 ||
        lastDot == fileName.length - 1) {
      return '';
    }

    return fileName
        .substring(lastDot)
        .toLowerCase();
  }

  bool _hasDangerousExtension(String extension) {
    return dangerousExtensions.contains(extension);
  }

  bool _hasSuspiciousDoubleExtension(String fileName) {
    final lowerName = fileName.toLowerCase();

    for (final dangerousExtension
        in dangerousExtensions) {
      if (!lowerName.endsWith(dangerousExtension)) {
        continue;
      }

      final nameWithoutDangerousExtension =
          lowerName.substring(
        0,
        lowerName.length -
            dangerousExtension.length,
      );

      if (nameWithoutDangerousExtension.contains('.')) {
        return true;
      }
    }

    return false;
  }

  String _getSuspiciousExtension(String fileName) {
    final extension = _getExtension(fileName);

    if (_hasDangerousExtension(extension)) {
      return extension;
    }

    if (_hasSuspiciousDoubleExtension(fileName)) {
      return extension;
    }

    return 'None';
  }

  bool _isSafeFileName(String fileName) {
  final trimmedName = fileName.trim();

  if (trimmedName.isEmpty) {
    return false;
  }

  if (trimmedName == '.' ||
      trimmedName == '..') {
    return false;
  }

  // Reject path separators and null characters.
  if (trimmedName.contains('/') ||
      trimmedName.contains('\\') ||
      trimmedName.contains('\u0000')) {
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
          entry.name.toLowerCase() ==
              fileName.toLowerCase() &&
          entry.sizeBytes == fileSize,
    );
  }

  bool _signatureCheck({
    required String fileName,
    required Uint8List? bytes,
    required DetectedFileType? detectedType,
  }) {
    final extension = _getExtension(fileName);

    // Existing PDF validation remains exactly
    // signature-based when bytes are available.
    if (extension == '.pdf') {
      if (bytes == null) {
        return false;
      }

      return hasPdfSignature(bytes);
    }

    // For other supported formats, the actual
    // content must be detectable when bytes exist.
    if (bytes == null) {
      return false;
    }

    return detectedType != null;
  }

  bool _sizeCheck({
    required String fileName,
    required int fileSize,
  }) {
    final extension = _getExtension(fileName);

    // Preserve the existing 10 MB PDF rule.
    if (extension == '.pdf') {
      return fileSize <= maxPdfFileSizeBytes;
    }

    // Other file types currently do not inherit
    // the PDF 10 MB restriction.
    return fileSize >= 0;
  }
}