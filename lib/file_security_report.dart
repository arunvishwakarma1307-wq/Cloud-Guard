import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'file_integrity_service.dart';
import 'file_integrity_storage.dart';
import 'file_security_scanner.dart';

class FileSecurityReportPage extends StatefulWidget {
  const FileSecurityReportPage({
    super.key,
    required this.fileName,
    required this.fileSize,
    required this.bytes,
    required this.securityScan,
    required this.scannedAt,
  });

  final String fileName;
  final int fileSize;
  final Uint8List? bytes;
  final FileSecurityScanResult securityScan;
  final DateTime scannedAt;

  @override
  State<FileSecurityReportPage> createState() =>
      _FileSecurityReportPageState();
}

class _FileSecurityReportPageState
    extends State<FileSecurityReportPage> {
  final FileIntegrityService _integrityService =
      const FileIntegrityService();

  String? _currentHash;
  TrustedFileHash? _trustedHash;

  IntegrityStatus _integrityStatus =
      IntegrityStatus.cannotVerify;

  bool _isLoadingIntegrity = true;

  @override
  void initState() {
    super.initState();
    _loadIntegrityInformation();
  }

  Future<void> _loadIntegrityInformation() async {
    String? currentHash;

    if (widget.bytes != null &&
        widget.bytes!.isNotEmpty) {
      currentHash =
          _integrityService.calculateSha256(
        widget.bytes!,
      );
    }

    final trustedHash =
        await fileIntegrityStorage.getTrustedHash(
      widget.fileName,
    );

    final integrityStatus =
        widget.bytes == null ||
                widget.bytes!.isEmpty
            ? IntegrityStatus.cannotVerify
            : _integrityService.checkIntegrity(
                bytes: widget.bytes!,
                trustedHash: trustedHash?.hash,
              );

    if (!mounted) return;

    setState(() {
      _currentHash = currentHash;
      _trustedHash = trustedHash;
      _integrityStatus = integrityStatus;
      _isLoadingIntegrity = false;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes bytes';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();

    final month =
        local.month.toString().padLeft(2, '0');

    final day =
        local.day.toString().padLeft(2, '0');

    final hour =
        local.hour.toString().padLeft(2, '0');

    final minute =
        local.minute.toString().padLeft(2, '0');

    final second =
        local.second.toString().padLeft(2, '0');

    return '${local.year}-$month-$day '
        '$hour:$minute:$second';
  }

  String _integrityTitle() {
    switch (_integrityStatus) {
      case IntegrityStatus.originalBaselineMatched:
        return 'File Unchanged';

      case IntegrityStatus.modified:
        return 'File Changed';

      case IntegrityStatus.cannotVerify:
        return 'Cannot Verify';
    }
  }

  String _integrityDescription() {
    switch (_integrityStatus) {
      case IntegrityStatus.originalBaselineMatched:
        return 'The current selected bytes exactly match '
            'the saved trusted baseline.';

      case IntegrityStatus.modified:
        return 'The current selected bytes do not match '
            'the saved trusted baseline.';

      case IntegrityStatus.cannotVerify:
        return 'No trusted baseline is available, or the '
            'file bytes could not be read. Cloud Guard '
            'cannot verify integrity in this state.';
    }
  }

  Color _integrityColor(BuildContext context) {
    switch (_integrityStatus) {
      case IntegrityStatus.originalBaselineMatched:
        return Colors.green;

      case IntegrityStatus.modified:
        return Colors.orange;

      case IntegrityStatus.cannotVerify:
        return Theme.of(context)
            .colorScheme
            .outline;
    }
  }

  String _baselineText() {
    if (_trustedHash == null) {
      return 'No trusted baseline saved';
    }

    return 'Saved '
        '${_formatDateTime(_trustedHash!.savedAt)}';
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _checkRow({
    required String label,
    required bool passed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 5,
      ),
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
          const SizedBox(width: 10),
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

  Widget _infoRow({
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
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

  Widget _integrityCard() {
    final color =
        _integrityColor(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _sectionTitle(
              'File Integrity',
            ),
            if (_isLoadingIntegrity)
              const Center(
                child: Padding(
                  padding:
                      EdgeInsets.all(16),
                  child:
                      CircularProgressIndicator(),
                ),
              )
            else ...[
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    _integrityStatus ==
                            IntegrityStatus
                                .originalBaselineMatched
                        ? Icons.verified
                        : _integrityStatus ==
                                IntegrityStatus
                                    .modified
                            ? Icons.change_circle
                            : Icons.help_outline,
                    color: color,
                    size: 30,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _integrityTitle(),
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Text(
                          _integrityDescription(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _infoRow(
                label: 'Trusted baseline',
                value: _baselineText(),
              ),
              _infoRow(
                label: 'SHA-256',
                value: _currentHash ??
                    'Unavailable',
              ),
              if (_trustedHash != null)
                _infoRow(
                  label:
                      'Trusted SHA-256',
                  value:
                      _trustedHash!.hash,
                ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanPassed =
        widget.securityScan.passed;

    final resultColor =
        scanPassed
            ? Colors.green
            : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'File Security Report',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons
                            .description_outlined,
                        size: 42,
                        color: Colors.blue,
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              widget.fileName,
                              style:
                                  const TextStyle(
                                fontSize: 19,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                              maxLines: 3,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                            const SizedBox(
                              height: 6,
                            ),
                            Text(
                              _formatFileSize(
                                widget.fileSize,
                              ),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            Text(
                              'Scanned: '
                              '${_formatDateTime(
                                widget.scannedAt,
                              )}',
                              style:
                                  const TextStyle(
                                color:
                                    Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      _sectionTitle(
                        'Final Result',
                      ),
                      Row(
                        children: [
                          Icon(
                            scanPassed
                                ? Icons
                                    .check_circle
                                : Icons.cancel,
                            color:
                                resultColor,
                            size: 28,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              widget.securityScan
                                  .resultText,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color:
                                    resultColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      const Text(
                        'This is a basic local security '
                        'report. It is not an antivirus '
                        'or malware scan.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              _sectionTitle(
                'File Information',
              ),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _infoRow(
                        label: 'File name',
                        value:
                            widget.fileName,
                      ),
                      _infoRow(
                        label: 'File size',
                        value:
                            _formatFileSize(
                          widget.fileSize,
                        ),
                      ),
                      _infoRow(
                        label:
                            'Detected file type',
                        value:
                            widget.securityScan
                                .detectedFileType,
                      ),
                      _infoRow(
                        label:
                            'Original file type',
                        value:
                            widget.securityScan
                                .originalFileType,
                      ),
                      _infoRow(
                        label:
                            'Duplicate extension',
                        value:
                            widget.securityScan
                                .duplicateExtension,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              _sectionTitle(
                'Basic Security Checks',
              ),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _checkRow(
                        label:
                            'PDF extension check',
                        passed:
                            widget.securityScan
                                .extensionPassed,
                      ),
                      _checkRow(
                        label:
                            'PDF signature check',
                        passed:
                            widget.securityScan
                                .signaturePassed,
                      ),
                      _checkRow(
                        label:
                            'File size check',
                        passed:
                            widget.securityScan
                                .sizePassed,
                      ),
                      _checkRow(
                        label:
                            'Safe filename check',
                        passed:
                            widget.securityScan
                                .fileNamePassed,
                      ),
                      _checkRow(
                        label:
                            'Duplicate workspace check',
                        passed:
                            widget.securityScan
                                .duplicatePassed,
                      ),
                      _checkRow(
                        label:
                            'Double extension check',
                        passed:
                            widget.securityScan
                                .suspiciousNamePassed,
                      ),
                      _checkRow(
                        label:
                            'Dangerous extension check',
                        passed:
                            widget.securityScan
                                .dangerousExtensionPassed,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              _integrityCard(),

              const SizedBox(
                height: 20,
              ),

              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                  ),
                  title: const Text(
                    'Report Limitation',
                  ),
                  subtitle: const Text(
                    'The security scanner performs basic '
                    'local checks only. SHA-256 integrity '
                    'verification works by comparing the '
                    'current selected bytes with a trusted '
                    'baseline saved earlier. A hash alone '
                    'cannot prove that a file is inherently '
                    'original or free from malware.',
                  ),
                ),
              ),

              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}