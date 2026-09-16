import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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

  final FileTypeDetector _fileTypeDetector = const FileTypeDetector();
  final FileSecurityScanner _securityScanner = const FileSecurityScanner();

  Future<void> pickFile() async {
    setState(() {
      isSelectingFile = true;
    });

    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );

      if (!mounted || file == null) return;

      final fileSize = await file.length();

      Uint8List? bytes;

      try {
        bytes = await file.readAsBytes();
      } catch (_) {
        // Keep the existing validation behavior when bytes are unavailable.
      }

      // ------------------------------------------------------------
      // 1. Detect actual file type from file content
      // ------------------------------------------------------------
      if (bytes != null) {
        final detectedType = _fileTypeDetector.detect(bytes);

        if (detectedType != null) {
          final currentExtension = _getExtension(file.name);

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
                  '${file.name} is named as $currentExtension but its actual content was detected as ${detectedType.name} (${detectedType.extension}).',
            );

            return;
          }

          // The extension matches the real detected type.
          // Cloud Guard currently accepts PDF files only.
          if (detectedType.extension != '.pdf') {
            showMessage(
              'Cloud Guard currently accepts PDF files only. '
              'Detected file type: ${detectedType.name}',
            );

            securityActivityLog.record(
              title: 'Non-PDF file blocked',
              description:
                  '${file.name} was detected as ${detectedType.name}, so it was not added to the PDF workspace.',
            );

            return;
          }
        }
      }

      // ------------------------------------------------------------
      // 2. Existing PDF validation
      // ------------------------------------------------------------
      final validationMessage = validatePdfFile(
        fileName: file.name,
        fileSize: fileSize,
        bytes: bytes,
      );

      if (validationMessage != null) {
        showMessage(validationMessage);

        securityActivityLog.record(
          title: 'PDF validation failed',
          description: '${file.name}: $validationMessage',
        );

        return;
      }

      // ------------------------------------------------------------
      // 3. Basic Security Scan
      // ------------------------------------------------------------
      final scanResult = _securityScanner.scan(
        fileName: file.name,
        fileSize: fileSize,
        bytes: bytes,
      );

      if (!scanResult.passed) {
        await _showSecurityScanFailedDialog(scanResult);

        securityActivityLog.record(
          title: 'Basic Security Scan failed',
          description:
              '${file.name} failed one or more basic security checks.',
        );

        return;
      }

      // ------------------------------------------------------------
      // 4. Add to local workspace
      // ------------------------------------------------------------
      final added = localFileWorkspace.add(
        LocalPdfEntry(
          name: file.name,
          sizeBytes: fileSize,
          bytes: bytes,
        ),
      );

      if (!added) {
        showMessage('This PDF is already in the local workspace.');

        securityActivityLog.record(
          title: 'Duplicate PDF blocked',
          description:
              '${file.name} was already present in the local workspace.',
        );

        return;
      }

      setState(() {
        selectedFile = file;
        selectedFileName = file.name;
        selectedFileSize = fileSize;
      });

      securityActivityLog.record(
        title: 'Basic Security Scan passed',
        description:
            '${file.name} passed the basic security checks and was added to the temporary local workspace.',
      );

      showMessage('PDF added to the local workspace.');
    } catch (_) {
      if (mounted) {
        showMessage('Unable to select a file. Please try again.');
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
    final dotIndex = fileName.lastIndexOf('.');

    if (dotIndex == -1 || dotIndex == fileName.length - 1) {
      return '';
    }

    return fileName.substring(dotIndex).toLowerCase();
  }

  bool _extensionMatches(
    String currentExtension,
    String detectedExtension,
  ) {
    if (detectedExtension == '.jpeg') {
      return currentExtension == '.jpeg' || currentExtension == '.jpg';
    }

    return currentExtension == detectedExtension;
  }

  Future<void> _showFileTypeMismatchDialog({
    required String fileName,
    required String currentExtension,
    required DetectedFileType detectedType,
  }) async {
    if (!mounted) return;

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
              SizedBox(width: 10),
              Expanded(
                child: Text('File Type Mismatch'),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'The file extension does not match the actual file content.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                _InfoRow(
                  label: 'File name',
                  value: fileName,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Current extension',
                  value: currentExtension.isEmpty
                      ? 'No extension'
                      : currentExtension,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  label: 'Detected file type',
                  value:
                      '${detectedType.name} (${detectedType.extension})',
                ),
                const SizedBox(height: 18),
                const Text(
                  'Why?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Cloud Guard checked the actual file signature '
                  'instead of trusting only the filename. '
                  'The file content matches ${detectedType.name}, '
                  'so the expected extension is ${detectedType.extension}.',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Cloud Guard cannot determine whether a person or another program changed the extension. '
                  'It can only detect that the current extension and actual file type do not match.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSecurityScanFailedDialog(
    FileSecurityScanResult result,
  ) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.security,
                color: Colors.orange,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('Basic Security Scan Failed'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ScanCheckRow(
                title: 'PDF extension',
                passed: result.extensionPassed,
              ),
              _ScanCheckRow(
                title: 'PDF signature',
                passed: result.signaturePassed,
              ),
              _ScanCheckRow(
                title: 'File size',
                passed: result.sizePassed,
              ),
              _ScanCheckRow(
                title: 'File name safety',
                passed: result.fileNamePassed,
              ),
              _ScanCheckRow(
                title: 'Duplicate check',
                passed: result.duplicatePassed,
              ),
              const SizedBox(height: 12),
              const Text(
                'This is a basic local security check. '
                'It is not an antivirus or malware detector.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
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
    final removed = localFileWorkspace.remove(entry);

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
      'Cloud upload is unavailable because Firebase Storage is not configured or enabled.',
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    mainAxisAlignment: MainAxisAlignment.center,
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
                            isSelectingFile ? null : pickFile,
                        icon: isSelectingFile
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload_file),
                        label: Text(
                          isSelectingFile
                              ? 'Scanning...'
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(getFileSize()),
                        const SizedBox(height: 4),
                        Text(
                          'Basic Security Scan passed',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      tooltip: 'Remove selected file',
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
                  padding: EdgeInsets.symmetric(horizontal: 4),
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
                    onPressed: showStorageUnavailable,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Upload to Cloud'),
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
                            leading: const Icon(
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
                            trailing: IconButton(
                              tooltip: 'Remove local file',
                              onPressed: () =>
                                  removeWorkspaceEntry(
                                entry,
                              ),
                              icon: const Icon(
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
    required this.title,
    required this.passed,
  });

  final String title;
  final bool passed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.cancel,
            color: passed ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title),
          ),
          Text(
            passed ? 'Passed' : 'Failed',
            style: TextStyle(
              color: passed ? Colors.green : Colors.red,
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 125,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}