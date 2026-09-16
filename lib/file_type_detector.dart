import 'dart:typed_data';

class DetectedFileType {
  const DetectedFileType({
    required this.name,
    required this.extension,
  });

  final String name;
  final String extension;
}

class FileTypeDetector {
  const FileTypeDetector();

  DetectedFileType? detect(Uint8List bytes) {
    if (_isPdf(bytes)) {
      return const DetectedFileType(
        name: 'PDF',
        extension: '.pdf',
      );
    }

    if (_isPng(bytes)) {
      return const DetectedFileType(
        name: 'PNG',
        extension: '.png',
      );
    }

    if (_isJpeg(bytes)) {
      return const DetectedFileType(
        name: 'JPEG',
        extension: '.jpeg',
      );
    }

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

  bool _startsWith(Uint8List bytes, List<int> signature) {
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