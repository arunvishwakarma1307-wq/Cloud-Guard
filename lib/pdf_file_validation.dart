import 'dart:typed_data';

const int maxPdfFileSizeBytes = 10 * 1024 * 1024;

/// Validates a local PDF selection using filename, size, and optional bytes.
///
/// Returns an error message, or `null` when the selection is accepted.
/// When [bytes] is `null`, the `%PDF-` signature check is skipped because some
/// platforms do not expose file bytes until a later operation.
String? validatePdfFile({
  required String fileName,
  required int fileSize,
  Uint8List? bytes,
}) {
  if (!fileName.toLowerCase().endsWith('.pdf')) {
    return "Please choose a PDF file";
  }

  if (fileSize > maxPdfFileSizeBytes) {
    return "PDF files must be 10 MB or smaller";
  }

  if (bytes != null && !hasPdfSignature(bytes)) {
    return "The selected file is not a valid PDF";
  }

  return null;
}

bool hasPdfSignature(Uint8List bytes) {
  const pdfSignature = [0x25, 0x50, 0x44, 0x46, 0x2D];

  if (bytes.length < pdfSignature.length) {
    return false;
  }

  for (var index = 0; index < pdfSignature.length; index++) {
    if (bytes[index] != pdfSignature[index]) {
      return false;
    }
  }

  return true;
}
