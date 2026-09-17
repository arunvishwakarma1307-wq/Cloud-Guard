import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'file_security_scanner.dart';
import 'file_type_detector.dart';
import 'local_file_workspace.dart';
import 'pdf_file_validation.dart';
import 'security_activity_log.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String? selectedFileName;
  int? selectedFileSize;
  PlatformFile? selectedFile;
  bool isSelectingFile = false;

  final FileTypeDetector _fileTypeDetector =
      const FileTypeDetector();

  final FileSecurityScanner _securityScanner =
      const FileSecurityScanner();

  Future<void> pickFile() async {
    setState(() {
      isSelectingFile = true;
    });

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'png',
          'jpg',
          'jpeg',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'exe',
          'bat',
          'cmd',
          'ps1',
          'scr',
          'com',
        ],
      );

      if (!mounted || file == null) return;

      final fileSize = await file.length();

      Uint8List? bytes;

      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        // Keep the existing validation behavior when bytes
        // are unavailable.
      }

      // ---------------------------------------------------------
      // CASE 2: Suspicious / Dangerous File Detection
      // This runs before Case 1 and PDF validation.
      // ---------------------------------------------------------
      final securityScan = _securityScanner.scan(
        fileName: file.name,
        fileSize: fileSize,
        bytes: bytes,
      );

      final suspiciousFile =
          !securityScan.suspiciousNamePassed ||
          !securityScan.dangerousExtensionPassed;

      if (suspiciousFile) {
        await _showSecurityScanFailedDialog(
          fileName: file.name,
          result: securityScan,
        );

        securityActivityLog.record(
          title: 'Suspicious file detected',
          description:
              '${file.name} was blocked because its filename or extension was suspicious.',
        );

        return;
      }

      // ---------------------------------------------------------
      // CASE 1: File Type Mismatch Detection
      // Existing behavior kept.
      // ---------------------------------------------------------
      if (bytes != null) {
        final detectedType = _fileTypeDetector.detect(bytes);

        if (detectedType != null) {
          final currentExtension =
              _getExtension(file.name);

          final extensionMatches = _extensionMatches(
            currentExtension,
            detectedType.extension,
          );

          if (!extensionMatches) {
            await _showFileTypeMismatchDialog(
              fileName: file.name,
              currentExtension: currentExtension,
              detectedType: detectedType,
            );

            securityActivityLog.record(
              title: 'File type mismatch detected',
              description:
                  '${file.name} has extension $currentExtension but the actual file type was detected as ${detectedType.name}.',
            );

            return;
          }

          if (detectedType.extension != '.pdf') {
            showMessage(
              'Cloud Guard currently accepts PDF files only. '
              'Detected file type: ${detectedType.name}',
            );

            securityActivityLog.record(
              title: 'Non-PDF file blocked',
              description:
                  '${file.name} was detected as ${detectedType.name} '
                  'and was not added because Cloud Guard currently '
                  'accepts PDF files only.',
            );

            return;
          }
        }
      }

      // ---------------------------------------------------------
      // CASE 3: Existing PDF Validation
      // Existing behavior kept.
      // ---------------------------------------------------------
      final validationMessage = validatePdfFile(
        fileName: file.name,
        fileSize: fileSize,
        bytes: bytes,
      );

      if (validationMessage != null) {
        showMessage(validationMessage);
        return;
      }

      // Remaining basic security checks.
      if (!securityScan.passed) {
        await _showSecurityScanFailedDialog(
          fileName: file.name,
          result: securityScan,
        );

        securityActivityLog.record(
          title: 'Basic Security Scan failed',
          description:
              '${file.name} was blocked because one or more local security checks failed.',
        );

        return;
      }

      final added = localFileWorkspace.add(
        LocalPdfEntry(
          name: file.name,
          sizeBytes: fileSize,
          bytes: bytes,
        ),
      );

      if (!added) {
        showMessage(
          'This PDF is already in the local workspace.',
        );
        return;
      }

      setState(() {
        selectedFile = file;
        selectedFileName = file.name;
        selectedFileSize = fileSize;
      });

      securityActivityLog.record(
        title: 'Local PDF added',
        description:
            '${file.name} was added to the temporary local workspace.',
      );

      showMessage(
        'PDF added to the local workspace.',
      );
    } catch (_) {
      if (mounted) {
        showMessage(
          'Unable to select a file. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSelectingFile = false;
        });
      }
    }
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

  bool _extensionMatches(
    String currentExtension,
    String detectedExtension,
  ) {
    if (detectedExtension == '.jpeg') {
      return currentExtension == '.jpeg' ||
          currentExtension == '.jpg';
    }

    return currentExtension == detectedExtension;
  }

  // -------------------------------------------------------------
  // CASE 1 DIALOG
  // -------------------------------------------------------------
  Future<void> _showFileTypeMismatchDialog({
    required String fileName,
    required String currentExtension,
    required DetectedFileType detectedType,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'File Type Mismatch Detected',
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cloud Guard detected that the file content does not match its filename extension.',
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  label: 'File name',
                  value: fileName,
                ),
                _InfoRow(
                  label: 'Current extension',
                  value: currentExtension.isEmpty
                      ? 'No extension'
                      : currentExtension,
                ),
                _InfoRow(
                  label: 'Detected file type',
                  value:
                      '${detectedType.name} (${detectedType.extensionLabel})',
                ),
                const SizedBox(height: 14),
                const Text(
                  'Why was it blocked?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'The file signature indicates a different file type than the current filename extension. The file was not added to the local workspace.',
                ),
                const SizedBox(height: 14),
                const Text(
                  'Note: This is a basic local file-type check. It is not an antivirus or malware scanner.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // CASE 2 DIALOG
  // -------------------------------------------------------------
  Future<void> _showSecurityScanFailedDialog({
    required String fileName,
    required FileSecurityScanResult result,
  }) async {
    final isDoubleExtension =
        !result.suspiciousNamePassed;

    final dangerousExtension =
        !result.dangerousExtensionPassed;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Suspicious File Detected',
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Cloud Guard detected a suspicious filename or dangerous file extension.',
                ),

                const SizedBox(height: 18),

                const Text(
                  'File Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 10),

                _InfoRow(
                  label: 'Filename',
                  value: fileName,
                ),

                _InfoRow(
                  label: 'Original file type',
                  value: result.originalFileType,
                ),

                _InfoRow(
                  label: 'Duplicate extension',
                  value: result.duplicateExtension,
                ),

                _InfoRow(
                  label: 'Detected file type',
                  value: result.detectedFileType,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Security Warning',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 10),

                if (isDoubleExtension) ...[
                  const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Duplicate extension detected',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  if (result.originalFileType !=
                      'Not detected')
                    Text(
                      'The file was originally detected as '
                      '${result.originalFileType}, but an additional '
                      '${result.duplicateExtension} extension was added.',
                    )
                  else
                    const Text(
                      'No known original file type was detected from the file content.',
                    ),
                ],

                if (dangerousExtension) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Dangerous extension detected: '
                    '${result.duplicateExtension == 'None' ? 'Yes' : result.duplicateExtension}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                if (!isDoubleExtension &&
                    !dangerousExtension) ...[
                  const Text(
                    'One or more basic local security checks failed.',
                  ),
                ],

                const SizedBox(height: 20),

                const Text(
                  'Security Checks',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 10),

                _ScanCheckRow(
                  label: 'PDF extension check',
                  passed: result.extensionPassed,
                ),

                _ScanCheckRow(
                  label: 'PDF signature check',
                  passed: result.signaturePassed,
                ),

                _ScanCheckRow(
                  label: 'File size check',
                  passed: result.sizePassed,
                ),

                _ScanCheckRow(
                  label: 'Safe filename check',
                  passed: result.fileNamePassed,
                ),

                _ScanCheckRow(
                  label: 'Duplicate workspace check',
                  passed: result.duplicatePassed,
                ),

                _ScanCheckRow(
                  label: 'Double extension check',
                  passed:
                      result.suspiciousNamePassed,
                ),

                _ScanCheckRow(
                  label: 'Dangerous extension check',
                  passed:
                      result.dangerousExtensionPassed,
                ),

                if (isDoubleExtension) ...[
                  const SizedBox(height: 18),

                  const Text(
                    'Examples of suspicious files:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    '• invoice.pdf.exe\n'
                    '• photo.jpg.exe\n'
                    '• document.pdf.bat',
                  ),
                ],

                const SizedBox(height: 18),

                const Text(
                  'Cloud Guard performs a basic local security check. '
                  'It does not scan files for viruses or malware.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void removeSelection() {
    final name = selectedFileName;
    final size = selectedFileSize;

    if (name != null && size != null) {
      localFileWorkspace.remove(
        LocalPdfEntry(
          name: name,
          sizeBytes: size,
        ),
      );

      securityActivityLog.record(
        title: 'Local PDF removed',
        description:
            '$name was removed from the temporary local workspace.',
      );
    }

    setState(() {
      selectedFile = null;
      selectedFileName = null;
      selectedFileSize = null;
    });
  }

  void removeWorkspaceEntry(LocalPdfEntry entry) {
    final removed =
        localFileWorkspace.remove(entry);

    if (removed) {
      securityActivityLog.record(
        title: 'Local PDF removed',
        description:
            '${entry.name} was removed from the temporary local workspace.',
      );
    }

    if (selectedFileName == entry.name &&
        selectedFileSize == entry.sizeBytes) {
      setState(() {
        selectedFile = null;
        selectedFileName = null;
        selectedFileSize = null;
      });
    }
  }

  void showStorageUnavailable() {
    showMessage(
      'Cloud upload is unavailable because Firebase Storage '
      'is not configured or enabled.',
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String formatFileSize(int size) {
    if (size < 1024) return '$size bytes';

    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    }

    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String getFileSize() {
    if (selectedFileSize == null) return '';

    return formatFileSize(selectedFileSize!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cloud Upload',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Files',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Select PDF files to keep in your local Cloud Guard workspace',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 30),

              Card(
                elevation: 5,
                child: SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.cloud_upload,
                        size: 55,
                        color: Colors.blue,
                      ),

                      const SizedBox(height: 15),

                      const Text(
                        'Select a PDF to add locally',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      ElevatedButton.icon(
                        onPressed:
                            isSelectingFile
                                ? null
                                : pickFile,
                        icon: isSelectingFile
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.upload_file,
                              ),
                        label: Text(
                          isSelectingFile
                              ? 'Selecting...'
                              : 'Choose PDF',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              if (selectedFileName != null)
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.picture_as_pdf,
                      color: Colors.red,
                      size: 35,
                    ),
                    title: Text(
                      selectedFileName!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(getFileSize()),
                        const SizedBox(height: 4),
                        Text(
                          'PDF validated locally',
                          style: TextStyle(
                            color:
                                Colors.green.shade700,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      tooltip:
                          'Remove selected file',
                      onPressed: removeSelection,
                      icon: const Icon(
                        Icons.close,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),

              if (selectedFileName != null) ...[
                const SizedBox(height: 8),
                const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    horizontal: 4,
                  ),
                  child: Text(
                    'This file is available locally; cloud upload is unavailable until Firebase Storage is enabled.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              if (selectedFile != null)
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed:
                        showStorageUnavailable,
                    icon: const Icon(
                      Icons.cloud_upload,
                    ),
                    label: const Text(
                      'Upload to Cloud',
                    ),
                  ),
                ),

              if (selectedFile != null) ...[
                const SizedBox(height: 15),
                const Text(
                  'Cloud upload is unavailable because Firebase Storage is not configured or enabled.',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],

              const SizedBox(height: 25),

              const Text(
                'Local Workspace',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              AnimatedBuilder(
                animation: localFileWorkspace,
                builder: (context, _) {
                  final entries =
                      localFileWorkspace.entries;

                  if (entries.isEmpty) {
                    return const Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.folder_open,
                          color: Colors.grey,
                        ),
                        title: Text(
                          'No local files yet',
                        ),
                        subtitle: Text(
                          'Validated PDFs added here stay in memory on this device. They are not uploaded to Firebase Storage.',
                        ),
                      ),
                    );
                  }

                  return Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.folder,
                            color: Colors.blue,
                          ),
                          title: Text(
                            '${entries.length} local file${entries.length == 1 ? '' : 's'}',
                          ),
                          subtitle: Text(
                            'Total: ${formatFileSize(localFileWorkspace.totalSizeBytes)}',
                          ),
                        ),

                        ...entries.map(
                          (entry) => ListTile(
                            dense: true,
                            leading:
                                const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.red,
                            ),
                            title: Text(
                              entry.name,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              formatFileSize(
                                entry.sizeBytes,
                              ),
                            ),
                            trailing:
                                IconButton(
                              tooltip:
                                  'Remove local file',
                              onPressed: () =>
                                  removeWorkspaceEntry(
                                entry,
                              ),
                              icon:
                                  const Icon(
                                Icons.delete_outline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 25),

              const Text(
                'Recent Uploads',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Card(
                child: ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: Colors.grey,
                  ),
                  title: Text(
                    'No recent cloud uploads',
                  ),
                  subtitle: Text(
                    'Live cloud listings and cloud uploads are unavailable because Firebase Storage is not enabled or configured.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanCheckRow extends StatelessWidget {
  const _ScanCheckRow({
    required this.label,
    required this.passed,
  });

  final String label;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            passed
                ? Icons.check_circle
                : Icons.cancel,
            color:
                passed ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label),
          ),
          Text(
            passed ? 'Passed' : 'Failed',
            style: TextStyle(
              color:
                  passed ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PdfDetailsPage extends StatelessWidget {
  const PdfDetailsPage({
    super.key,
    required this.entry,
  });

  final LocalPdfEntry entry;

  String formatFileSize(int size) {
    if (size < 1024) return '$size bytes';

    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    }

    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> confirmRemove(
    BuildContext context,
  ) async {
    final shouldRemove =
        await showDialog<bool>(
      context: context,
      builder: (context) =>
          AlertDialog(
        title: const Text(
          'Remove local PDF?',
        ),
        content: Text(
          'Remove “${entry.name}” from the temporary local workspace? No cloud file will be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context)
                    .pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context)
                    .pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldRemove == true &&
        context.mounted) {
      localFileWorkspace.remove(entry);
      Navigator.of(context).pop();
    }
  }

  void openFullScreenPreview(
    BuildContext context,
  ) {
    final bytes = entry.bytes;

    if (bytes == null || bytes.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfReaderPage(
          fileName: entry.name,
          bytes: bytes,
        ),
      ),
    );
  }

  Widget buildPreview(
    BuildContext context,
  ) {
    final bytes = entry.bytes;

    if (bytes == null || bytes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.preview_outlined,
                size: 42,
                color: Colors.grey,
              ),
              SizedBox(height: 10),
              Text(
                'Preview is unavailable for this entry.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'The file metadata is available, but the PDF bytes were not retained by the local picker.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.picture_as_pdf,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 10),
            const Text(
              'Open the complete PDF in full-screen preview.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    openFullScreenPreview(
                  context,
                ),
                icon: const Icon(
                  Icons.open_in_full,
                ),
                label: const Text(
                  'Open Full-Screen Preview',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PDF Details',
        ),
        actions: [
          IconButton(
            tooltip: 'Remove local PDF',
            onPressed: () =>
                confirmRemove(context),
            icon: const Icon(
              Icons.delete_outline,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.red,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'File name',
                        value: entry.name,
                      ),
                      _DetailRow(
                        label: 'File size',
                        value: formatFileSize(
                          entry.sizeBytes,
                        ),
                      ),
                      const _DetailRow(
                        label: 'Validation',
                        value:
                            'PDF validated locally',
                        valueColor:
                            Colors.green,
                      ),
                      const _DetailRow(
                        label: 'Storage status',
                        value:
                            'Temporary local workspace only',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              const Card(
                child: ListTile(
                  leading: Icon(
                    Icons.lock_outline,
                    color: Colors.blue,
                  ),
                  title: Text(
                    'Storage Honesty',
                  ),
                  subtitle: Text(
                    'This preview uses PDF bytes kept in this device memory. Nothing is uploaded to Firebase Storage, which is currently disabled or not configured.',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Preview',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              buildPreview(context),
            ],
          ),
        ),
      ),
    );
  }
}

class PdfReaderPage extends StatefulWidget {
  const PdfReaderPage({
    super.key,
    required this.fileName,
    required this.bytes,
  });

  final String fileName;
  final Uint8List bytes;

  @override
  State<PdfReaderPage> createState() =>
      _PdfReaderPageState();
}

class _PdfReaderPageState
    extends State<PdfReaderPage> {
  static const double _minimumZoom = 0.75;
  static const double _maximumZoom = 4.0;
  static const double _zoomStep = 0.25;
  static const double _defaultZoom = 2.0;

  final PdfViewerController _controller =
      PdfViewerController();

  int _pageCount = 0;
  int _currentPage = 0;
  double _zoomLevel = _defaultZoom;

  void _jumpToPage(int? page) {
    if (page == null ||
        page < 1 ||
        page > _pageCount) {
      return;
    }

    _controller.jumpToPage(page);
  }

  void _changeZoom(double amount) {
    final nextZoom =
        (_zoomLevel + amount)
            .clamp(
              _minimumZoom,
              _maximumZoom,
            )
            .toDouble();

    _controller.zoomLevel = nextZoom;

    setState(() {
      _zoomLevel = nextZoom;
    });
  }

  void _resetZoom() {
    _controller.zoomLevel = _defaultZoom;

    setState(() {
      _zoomLevel = _defaultZoom;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Zoom out',
            onPressed:
                _zoomLevel > _minimumZoom
                    ? () => _changeZoom(
                          -_zoomStep,
                        )
                    : null,
            icon: const Icon(
              Icons.zoom_out,
            ),
          ),

          IconButton(
            tooltip: 'Reset zoom',
            onPressed:
                _zoomLevel == _defaultZoom
                    ? null
                    : _resetZoom,
            icon: const Icon(
              Icons.fit_screen,
            ),
          ),

          IconButton(
            tooltip: 'Zoom in',
            onPressed:
                _zoomLevel < _maximumZoom
                    ? () => _changeZoom(
                          _zoomStep,
                        )
                    : null,
            icon: const Icon(
              Icons.zoom_in,
            ),
          ),

          if (_pageCount > 0)
            Padding(
              padding:
                  const EdgeInsets.only(
                right: 12,
              ),
              child: Center(
                child: DropdownButton<int>(
                  value:
                      _currentPage == 0
                          ? 1
                          : _currentPage,
                  underline:
                      const SizedBox.shrink(),
                  dropdownColor:
                      Theme.of(context)
                          .colorScheme
                          .surface,
                  onChanged:
                      _jumpToPage,
                  items:
                      List<
                          DropdownMenuItem<int>
                      >.generate(
                    _pageCount,
                    (index) =>
                        DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text(
                        'Page ${index + 1}',
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SfPdfViewer.memory(
        widget.bytes,
        controller: _controller,
        pageLayoutMode:
            PdfPageLayoutMode.single,
        scrollDirection:
            PdfScrollDirection.vertical,
        pageSpacing: 8,
        maxZoomLevel: _maximumZoom,
        enableDoubleTapZooming: true,
        enableTextSelection: true,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onDocumentLoaded: (details) {
          if (!mounted) return;

          setState(() {
            _pageCount =
                details.document.pages.count;
            _currentPage = 1;
            _controller.zoomLevel =
                _defaultZoom;
            _zoomLevel = _defaultZoom;
          });
        },
        onPageChanged: (details) {
          if (!mounted) return;

          setState(() {
            _currentPage =
                details.newPageNumber;
          });
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 8,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}