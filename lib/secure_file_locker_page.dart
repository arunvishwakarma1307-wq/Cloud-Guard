import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'secure_file_locker_storage.dart';

class SecureFileLockerPage extends StatefulWidget {
  const SecureFileLockerPage({super.key});

  @override
  State<SecureFileLockerPage> createState() =>
      _SecureFileLockerPageState();
}

class _SecureFileLockerPageState extends State<SecureFileLockerPage> {
  final List<_LockedFile> _lockedFiles = <_LockedFile>[];

  final SecureFileLockerStorage _storage =
      const SecureFileLockerStorage();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoredFiles();
  }

  Future<void> _loadStoredFiles() async {
    try {
      final storedFiles = await _storage.loadFiles();

      if (!mounted) return;

      setState(() {
        _lockedFiles
          ..clear()
          ..addAll(
            storedFiles.map(
              (file) => _LockedFile(
                name: file.name,
                size: _formatFileSize(file.bytes.length),
                bytes: file.bytes,
              ),
            ),
          );

        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load stored locker files.',
          ),
        ),
      );
    }
  }

  Future<void> _addFile() async {
    final files = await FilePicker.pickFiles();

    if (files.isEmpty) return;

    final pickedFile = files.first;
    final bytes = await pickedFile.readAsBytes();

    if (!mounted) return;

    if (bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The selected file is empty.'),
        ),
      );
      return;
    }

    final alreadyExists = _lockedFiles.any(
      (file) =>
          file.name.toLowerCase() == pickedFile.name.toLowerCase() &&
          file.bytes.length == bytes.length,
    );

    if (alreadyExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This file is already in the locker.'),
        ),
      );
      return;
    }

    final newFile = _LockedFile(
      name: pickedFile.name,
      size: _formatFileSize(bytes.length),
      bytes: bytes,
    );

    try {
      final updatedFiles = <_LockedFile>[
        ..._lockedFiles,
        newFile,
      ];

      await _saveLockedFiles(updatedFiles);

      if (!mounted) return;

      setState(() {
        _lockedFiles.add(newFile);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${pickedFile.name} added to Secure File Locker.',
          ),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save this file to the locker.',
          ),
        ),
      );
    }
  }

  Future<void> _saveLockedFiles(
    List<_LockedFile> files,
  ) async {
    final storedFiles = files
        .map(
          (file) => StoredSecureFile(
            name: file.name,
            bytes: file.bytes,
          ),
        )
        .toList();

    await _storage.saveFiles(storedFiles);
  }

  void _openFile(_LockedFile file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _SecureFilePreviewPage(
          file: file,
        ),
      ),
    );
  }

  Future<void> _removeFile(_LockedFile file) async {
    final updatedFiles = _lockedFiles
        .where((existingFile) => existingFile != file)
        .toList();

    try {
      await _saveLockedFiles(updatedFiles);

      if (!mounted) return;

      setState(() {
        _lockedFiles
          ..clear()
          ..addAll(updatedFiles);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${file.name} removed from locker.',
          ),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to remove this file.',
          ),
        ),
      );
    }
  }

  static String _formatFileSize(int bytes) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure File Locker'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 42,
                            color: Theme.of(context)
                                .colorScheme
                                .primary,
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Protected File Area',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Files added here are stored locally and restored when the app is reopened.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _addFile,
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'Add File',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Locked Files',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (_lockedFiles.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              Icon(
                                Icons.folder_off,
                                size: 50,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No files in the locker yet.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Use Add File to place a file in the locker.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount: _lockedFiles.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final file = _lockedFiles[index];

                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(
                                Icons.insert_drive_file,
                              ),
                            ),
                            title: Text(
                              file.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(file.size),
                            trailing:
                                PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'open') {
                                  _openFile(file);
                                }

                                if (value == 'remove') {
                                  _removeFile(file);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'open',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility),
                                      SizedBox(width: 10),
                                      Text('Open'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'remove',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
                                      ),
                                      SizedBox(width: 10),
                                      Text('Remove'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
    );
  }
}

class _SecureFilePreviewPage extends StatelessWidget {
  const _SecureFilePreviewPage({
    required this.file,
  });

  final _LockedFile file;

  String get _extension {
    final dotIndex = file.name.lastIndexOf('.');

    if (dotIndex == -1 ||
        dotIndex == file.name.length - 1) {
      return '';
    }

    return file.name
        .substring(dotIndex + 1)
        .toLowerCase();
  }

  bool get _isPdf => _extension == 'pdf';

  bool get _isImage =>
      _extension == 'png' ||
      _extension == 'jpg' ||
      _extension == 'jpeg' ||
      _extension == 'gif' ||
      _extension == 'webp';

  bool get _isText =>
      _extension == 'txt' ||
      _extension == 'csv';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          file.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _buildPreview(context),
    );
  }

  Widget _buildPreview(BuildContext context) {
    if (_isPdf) {
      return SfPdfViewer.memory(
        file.bytes,
      );
    }

    if (_isImage) {
      return _ImagePreview(
        file: file,
      );
    }

    if (_isText) {
      return _TextPreview(
        file: file,
      );
    }

    return _UnsupportedFilePreview(
      file: file,
      extension: _extension,
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.file,
  });

  final _LockedFile file;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5,
        child: Image.memory(
          file.bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Unable to preview this image.',
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TextPreview extends StatelessWidget {
  const _TextPreview({
    required this.file,
  });

  final _LockedFile file;

  @override
  Widget build(BuildContext context) {
    final text = utf8.decode(
      file.bytes,
      allowMalformed: true,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: SelectableText(
        text.isEmpty
            ? 'This text file is empty.'
            : text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }
}

class _UnsupportedFilePreview extends StatelessWidget {
  const _UnsupportedFilePreview({
    required this.file,
    required this.extension,
  });

  final _LockedFile file;
  final String extension;

  @override
  Widget build(BuildContext context) {
    final displayExtension =
        extension.isEmpty
            ? 'Unknown'
            : extension.toUpperCase();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.insert_drive_file,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  file.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'File type: $displayExtension',
                ),
                const SizedBox(height: 8),
                Text(
                  'Size: ${file.size}',
                ),
                const SizedBox(height: 20),
                const Text(
                  'Preview is not available for this file type yet.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedFile {
  const _LockedFile({
    required this.name,
    required this.size,
    required this.bytes,
  });

  final String name;
  final String size;
  final Uint8List bytes;
}