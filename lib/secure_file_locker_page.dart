import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class SecureFileLockerPage extends StatefulWidget {
  const SecureFileLockerPage({super.key});

  @override
  State<SecureFileLockerPage> createState() => _SecureFileLockerPageState();
}

class _SecureFileLockerPageState extends State<SecureFileLockerPage> {
  final List<_LockedFile> _lockedFiles = <_LockedFile>[];

  Future<void> _addFile() async {
    try {
      final files = await FilePicker.pickFiles();

      if (files.isEmpty) {
        return;
      }

      final pickedFile = files.first;
      final bytes = await pickedFile.readAsBytes();

      if (bytes.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to read the selected file.'),
          ),
        );
        return;
      }

      final newFile = _LockedFile(
        name: pickedFile.name,
        size: _formatFileSize(bytes.length),
        bytes: bytes,
      );

      final alreadyExists = _lockedFiles.any(
        (file) =>
            file.name.toLowerCase() == newFile.name.toLowerCase() &&
            file.bytes.length == newFile.bytes.length,
      );

      if (alreadyExists) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This file is already in the locker.'),
          ),
        );
        return;
      }

      setState(() {
        _lockedFiles.add(newFile);
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pickedFile.name} added to the locker.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to select the file: $error'),
        ),
      );
    }
  }

  void _openFile(_LockedFile file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _SecureFileDetailsPage(
          file: file,
        ),
      ),
    );
  }

  void _removeFile(_LockedFile file) {
    setState(() {
      _lockedFiles.remove(file);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${file.name} removed from the locker.'),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }

    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }

    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure File Locker'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.lock,
                          color: Theme.of(context).colorScheme.primary,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your Secure Files',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Files stored here will be protected by Cloud Guard.',
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
                child: FilledButton.icon(
                  onPressed: _addFile,
                  icon: const Icon(Icons.add),
                  label: const Text('Add File to Locker'),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Locked Files',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: _lockedFiles.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: _lockedFiles.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final file = _lockedFiles[index];

                          return Card(
                            child: ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.lock),
                              ),
                              title: Text(
                                file.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(file.size),
                              onTap: () => _openFile(file),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'open') {
                                    _openFile(file);
                                  } else if (value == 'remove') {
                                    _removeFile(file);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(
                                    value: 'open',
                                    child: Text('Open'),
                                  ),
                                  PopupMenuItem(
                                    value: 'remove',
                                    child: Text('Remove'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 70,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          const Text(
            'No files in the locker',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add a file to keep it in your secure locker.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _addFile,
            icon: const Icon(Icons.add),
            label: const Text('Add Your First File'),
          ),
        ],
      ),
    );
  }
}

class _SecureFileDetailsPage extends StatelessWidget {
  const _SecureFileDetailsPage({
    required this.file,
  });

  final _LockedFile file;

  String _getExtension(String name) {
    final lastDot = name.lastIndexOf('.');

    if (lastDot == -1 || lastDot == name.length - 1) {
      return 'Unknown';
    }

    return name.substring(lastDot + 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final extension = _getExtension(file.name);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure File'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.lock,
                  size: 50,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                file.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              Card(
                child: Column(
                  children: [
                    _infoTile(
                      icon: Icons.insert_drive_file,
                      title: 'File Type',
                      value: extension,
                    ),
                    const Divider(height: 1),
                    _infoTile(
                      icon: Icons.storage,
                      title: 'File Size',
                      value: file.size,
                    ),
                    const Divider(height: 1),
                    _infoTile(
                      icon: Icons.lock,
                      title: 'Locker Status',
                      value: 'Stored in current session',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Actual file opening will be connected next.',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open File'),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'The file is currently kept in memory. '
                'Permanent encrypted storage will be added next.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value),
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
  final List<int> bytes;
}