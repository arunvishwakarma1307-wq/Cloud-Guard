import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'file_integrity_service.dart';
import 'file_integrity_storage.dart';

class FileIntegrityPage extends StatefulWidget {
  const FileIntegrityPage({super.key});

  @override
  State<FileIntegrityPage> createState() => _FileIntegrityPageState();
}

class _FileIntegrityPageState extends State<FileIntegrityPage> {
  final FileIntegrityService _integrityService =
      const FileIntegrityService();

  String? _fileName;
  int? _fileSize;
  Uint8List? _fileBytes;
  String? _currentHash;
  TrustedFileHash? _trustedHash;

  bool _isLoading = false;

  IntegrityStatus get _integrityStatus {
    if (_fileBytes == null) {
      return IntegrityStatus.cannotVerify;
    }

    return _integrityService.checkIntegrity(
      bytes: _fileBytes!,
      trustedHash: _trustedHash?.hash,
    );
  }

  Future<void> _pickFile() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final selectedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'png',
          'jpg',
          'jpeg',
          'gif',
          'webp',
          'bmp',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'ppt',
          'pptx',
          'txt',
          'zip',
        ],
      );

      if (selectedFile == null) {
        return;
      }

      /*
       * IMPORTANT:
       * SHA-256 must be calculated from the actual current
       * file bytes.
       *
       * file_picker 12 uses PlatformFile.readAsBytes().
       */
      final bytes = await selectedFile.readAsBytes();

      if (bytes.isEmpty && await selectedFile.length() > 0) {
        throw Exception(
          'The selected file could not be read correctly.',
        );
      }

      // Use the actual bytes that are going to be hashed.
      final fileSize = bytes.length;

      // Calculate SHA-256 from the current file bytes.
      final hash = _integrityService.calculateSha256(bytes);

      /*
       * Get the previously saved trusted baseline for this
       * filename.
       */
      final trusted = await fileIntegrityStorage.getTrustedHash(
        selectedFile.name,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _fileName = selectedFile.name;
        _fileSize = fileSize;
        _fileBytes = bytes;
        _currentHash = hash;
        _trustedHash = trusted;
      });
    } catch (error) {
      if (mounted) {
        _showMessage(
          'Could not read the selected file.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveAsOriginalBaseline() async {
    if (_fileName == null || _currentHash == null) {
      return;
    }

    await fileIntegrityStorage.saveTrustedHash(
      fileName: _fileName!,
      hash: _currentHash!,
    );

    final trusted = await fileIntegrityStorage.getTrustedHash(
      _fileName!,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _trustedHash = trusted;
    });

    _showMessage(
      'Original baseline saved successfully.',
    );
  }

  Future<void> _deleteTrustedHash() async {
    if (_fileName == null) {
      return;
    }

    await fileIntegrityStorage.deleteTrustedHash(
      _fileName!,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _trustedHash = null;
    });

    _showMessage(
      'Original baseline deleted.',
    );
  }

  void _copyHash() {
    if (_currentHash == null) {
      return;
    }

    Clipboard.setData(
      ClipboardData(text: _currentHash!),
    );

    _showMessage(
      'SHA-256 hash copied.',
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _statusTitle() {
    switch (_integrityStatus) {
      case IntegrityStatus.originalBaselineMatched:
        return 'File Unchanged';

      case IntegrityStatus.modified:
        return 'File Changed';

      case IntegrityStatus.cannotVerify:
        return 'Cannot Verify';
    }
  }

  String _statusDescription() {
    switch (_integrityStatus) {
      case IntegrityStatus.originalBaselineMatched:
        return 'The current file exactly matches the saved '
            'original baseline. No byte-level changes were detected.';

      case IntegrityStatus.modified:
        return 'The current file does not match the saved '
            'original baseline. File changes were detected.';

      case IntegrityStatus.cannotVerify:
        return 'No trusted original baseline is saved for this '
            'file, so Cloud Guard cannot verify whether it has changed.';
    }
  }

  IconData _statusIcon() {
    switch (_integrityStatus) {
      case IntegrityStatus.originalBaselineMatched:
        return Icons.verified;

      case IntegrityStatus.modified:
        return Icons.warning_amber_rounded;

      case IntegrityStatus.cannotVerify:
        return Icons.help_outline;
    }
  }

  Color _statusColor(ColorScheme colorScheme) {
    switch (_integrityStatus) {
      case IntegrityStatus.originalBaselineMatched:
        return Colors.green;

      case IntegrityStatus.modified:
        return Colors.orange;

      case IntegrityStatus.cannotVerify:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('File Integrity Checker'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 700,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'File & Image Integrity',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Check whether a file or image has changed '
                    'since its trusted original version was saved.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _pickFile,
                      icon: const Icon(Icons.folder_open),
                      label: Text(
                        _isLoading
                            ? 'Reading File...'
                            : 'Select File or Image',
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_fileName != null) ...[
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Selected File',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 16),

                            _infoRow(
                              icon: Icons.insert_drive_file,
                              title: 'File Name',
                              value: _fileName!,
                            ),

                            const SizedBox(height: 12),

                            _infoRow(
                              icon: Icons.data_usage,
                              title: 'File Size',
                              value: _formatFileSize(
                                _fileSize ?? 0,
                              ),
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              'Current SHA-256 Hash',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme
                                    .surfaceContainerHighest,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: SelectableText(
                                _currentHash ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _copyHash,
                                icon: const Icon(Icons.copy),
                                label: const Text(
                                  'Copy SHA-256 Hash',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_trustedHash == null)
                      Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.orange,
                                  ),

                                  SizedBox(width: 10),

                                  Expanded(
                                    child: Text(
                                      'No Original Baseline Saved',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              const Text(
                                'If this file is a verified original '
                                'version, save its current SHA-256 hash '
                                'as the trusted baseline. Future checks '
                                'will compare the actual file bytes '
                                'against this baseline.',
                              ),

                              const SizedBox(height: 16),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      _saveAsOriginalBaseline,
                                  icon: const Icon(
                                    Icons.verified,
                                  ),
                                  label: const Text(
                                    'Save as Original Baseline',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Card(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _statusIcon(),
                                    color: _statusColor(
                                      colorScheme,
                                    ),
                                    size: 32,
                                  ),

                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Text(
                                      _statusTitle(),
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: _statusColor(
                                          colorScheme,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              Text(
                                _statusDescription(),
                                style: const TextStyle(
                                  fontSize: 15,
                                ),
                              ),

                              const SizedBox(height: 20),

                              const Text(
                                'Trusted Original SHA-256',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 8),

                              SelectableText(
                                _trustedHash!.hash,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),

                              const SizedBox(height: 16),

                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _deleteTrustedHash,
                                  icon: const Icon(
                                    Icons.delete_outline,
                                  ),
                                  label: const Text(
                                    'Delete Original Baseline',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Text(
                                'Privacy: The file is processed '
                                'locally. Cloud Guard saves only '
                                'the trusted SHA-256 hash locally. '
                                'The integrity result is based on '
                                'an actual SHA-256 comparison between '
                                'the current file and the saved '
                                'trusted baseline.',
                                style: TextStyle(
                                  color: colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 3),

              Text(value),
            ],
          ),
        ),
      ],
    );
  }
}