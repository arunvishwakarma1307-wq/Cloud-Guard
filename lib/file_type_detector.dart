import 'dart:typed_data';

class DetectedFileType {
  const DetectedFileType({
    required this.name,
    required this.extension,
    required this.extensionLabel,
  });

  final String name;

  /// Main/default extension.
  final String extension;

  /// User-friendly extension text.
  /// Example: ".jpg/.jpeg"
  final String extensionLabel;
}

class FileTypeDetector {
  const FileTypeDetector();

  DetectedFileType? detect(Uint8List bytes) {
    // PDF
    if (_isPdf(bytes)) {
      return const DetectedFileType(
        name: 'PDF',
        extension: '.pdf',
        extensionLabel: '.pdf',
      );
    }

    // PNG
    if (_isPng(bytes)) {
      return const DetectedFileType(
        name: 'PNG',
        extension: '.png',
        extensionLabel: '.png',
      );
    }

    // JPEG
    if (_isJpeg(bytes)) {
      return const DetectedFileType(
        name: 'JPEG',
        extension: '.jpg',
        extensionLabel: '.jpg/.jpeg',
      );
    }

    // GIF
    if (_isGif(bytes)) {
      return const DetectedFileType(
        name: 'GIF',
        extension: '.gif',
        extensionLabel: '.gif',
      );
    }

    // WebP
    if (_isWebP(bytes)) {
      return const DetectedFileType(
        name: 'WebP',
        extension: '.webp',
        extensionLabel: '.webp',
      );
    }

    // Modern Microsoft Office formats:
    // DOCX / XLSX / PPTX are ZIP-based files.
    if (_isZip(bytes)) {
      if (_containsAscii(bytes, 'word/')) {
        return const DetectedFileType(
          name: 'Word',
          extension: '.docx',
          extensionLabel: '.docx',
        );
      }

      if (_containsAscii(bytes, 'xl/')) {
        return const DetectedFileType(
          name: 'Excel',
          extension: '.xlsx',
          extensionLabel: '.xlsx',
        );
      }

      if (_containsAscii(bytes, 'ppt/')) {
        return const DetectedFileType(
          name: 'PowerPoint',
          extension: '.pptx',
          extensionLabel: '.pptx',
        );
      }

      // Generic ZIP file
      return const DetectedFileType(
        name: 'ZIP',
        extension: '.zip',
        extensionLabel: '.zip',
      );
    }

    // Legacy Microsoft Office formats:
    // DOC / XLS / PPT use the OLE Compound File format.
    if (_isOleCompoundFile(bytes)) {
      if (_containsUtf16Le(bytes, 'WordDocument')) {
        return const DetectedFileType(
          name: 'Word',
          extension: '.doc',
          extensionLabel: '.doc',
        );
      }

      if (_containsUtf16Le(bytes, 'Workbook') ||
          _containsUtf16Le(bytes, 'Book')) {
        return const DetectedFileType(
          name: 'Excel',
          extension: '.xls',
          extensionLabel: '.xls',
        );
      }

      if (_containsUtf16Le(bytes, 'PowerPoint Document')) {
        return const DetectedFileType(
          name: 'PowerPoint',
          extension: '.ppt',
          extensionLabel: '.ppt',
        );
      }
    }

    // Do not guess unknown file types.
    return null;
  }

  bool _isPdf(Uint8List bytes) {
    const signature = <int>[
      0x25,
      0x50,
      0x44,
      0x46,
      0x2D,
    ];

    return _startsWith(bytes, signature);
  }

  bool _isPng(Uint8List bytes) {
    const signature = <int>[
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ];

    return _startsWith(bytes, signature);
  }

  bool _isJpeg(Uint8List bytes) {
    const signature = <int>[
      0xFF,
      0xD8,
      0xFF,
    ];

    return _startsWith(bytes, signature);
  }

  bool _isGif(Uint8List bytes) {
    const signature = <int>[
      0x47,
      0x49,
      0x46,
      0x38,
    ];

    return _startsWith(bytes, signature);
  }

  bool _isWebP(Uint8List bytes) {
    const riffSignature = <int>[
      0x52,
      0x49,
      0x46,
      0x46,
    ];

    const webpSignature = <int>[
      0x57,
      0x45,
      0x42,
      0x50,
    ];

    // WebP files start with RIFF.
    if (!_startsWith(bytes, riffSignature)) {
      return false;
    }

    // Need at least:
    // 4 bytes RIFF
    // 4 bytes file size
    // 4 bytes WEBP
    if (bytes.length < 12) {
      return false;
    }

    // WEBP must be present at byte 8.
    for (var index = 0; index < webpSignature.length; index++) {
      if (bytes[8 + index] != webpSignature[index]) {
        return false;
      }
    }

    return true;
  }

  bool _isZip(Uint8List bytes) {
    const localFileHeader = <int>[
      0x50,
      0x4B,
      0x03,
      0x04,
    ];

    return _startsWith(bytes, localFileHeader);
  }

  bool _isOleCompoundFile(Uint8List bytes) {
    const signature = <int>[
      0xD0,
      0xCF,
      0x11,
      0xE0,
      0xA1,
      0xB1,
      0x1A,
      0xE1,
    ];

    return _startsWith(bytes, signature);
  }

  bool _containsAscii(
    Uint8List bytes,
    String text,
  ) {
    final pattern = text.codeUnits;

    return _containsBytes(
      bytes,
      pattern,
    );
  }

  bool _containsUtf16Le(
    Uint8List bytes,
    String text,
  ) {
    final pattern = <int>[];

    for (final codeUnit in text.codeUnits) {
      pattern.add(codeUnit & 0xFF);
      pattern.add((codeUnit >> 8) & 0xFF);
    }

    return _containsBytes(
      bytes,
      pattern,
    );
  }

  bool _containsBytes(
    Uint8List bytes,
    List<int> pattern,
  ) {
    if (pattern.isEmpty || bytes.length < pattern.length) {
      return false;
    }

    final lastStartIndex = bytes.length - pattern.length;

    for (var start = 0; start <= lastStartIndex; start++) {
      var matched = true;

      for (var offset = 0; offset < pattern.length; offset++) {
        if (bytes[start + offset] != pattern[offset]) {
          matched = false;
          break;
        }
      }

      if (matched) {
        return true;
      }
    }

    return false;
  }

  bool _startsWith(
    Uint8List bytes,
    List<int> signature,
  ) {
    if (bytes.length < signature.length) {
      return false;
    }

    for (var index = 0; index < signature.length; index++) {
      if (bytes[index] != signature[index]) {
        return false;
      }
    }

    return true;
  }
}