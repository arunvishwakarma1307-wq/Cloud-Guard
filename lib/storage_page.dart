import 'package:flutter/material.dart';

import 'local_file_workspace.dart';

enum LocalFileSort { nameAscending, sizeAscending, sizeDescending }

class StoragePage extends StatefulWidget {
  const StoragePage({super.key});

  @override
  State<StoragePage> createState() => _StoragePageState();
}

class _StoragePageState extends State<StoragePage> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  LocalFileSort sortMode = LocalFileSort.nameAscending;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String formatFileSize(int size) {
    if (size < 1024) return '$size bytes';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String sortLabel(LocalFileSort mode) {
    switch (mode) {
      case LocalFileSort.nameAscending:
        return 'Name A-Z';
      case LocalFileSort.sizeAscending:
        return 'Size small-large';
      case LocalFileSort.sizeDescending:
        return 'Size large-small';
    }
  }

  List<LocalPdfEntry> sortedEntries(List<LocalPdfEntry> entries) {
    final result = List<LocalPdfEntry>.from(entries);

    switch (sortMode) {
      case LocalFileSort.nameAscending:
        result.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case LocalFileSort.sizeAscending:
        result.sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
      case LocalFileSort.sizeDescending:
        result.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    }

    return result;
  }

  void removeEntry(LocalPdfEntry entry) {
    localFileWorkspace.remove(entry);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${entry.name} removed from local workspace.')),
    );
  }

  Future<void> confirmClearAll() async {
    if (localFileWorkspace.entries.isEmpty) return;

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove all local files?'),
        content: const Text(
          'This removes only temporary local workspace entries. No cloud files are affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      localFileWorkspace.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All local workspace files removed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cloud Storage',
          style: TextStyle(fontWeight: FontWeight.bold),
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
                'Storage Overview',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Card(
                elevation: 5,
                child: ListTile(
                  leading: Icon(Icons.cloud, color: Colors.blue, size: 40),
                  title: Text(
                    'Cloud Space',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Cloud storage is unavailable because Firebase Storage is not enabled or configured.',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Local Workspace',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: localFileWorkspace,
                builder: (context, _) {
                  final allEntries = localFileWorkspace.entries;
                  final entries = sortedEntries(
                    localFileWorkspace.search(searchQuery),
                  );

                  if (allEntries.isEmpty) {
                    return const Card(
                      child: ListTile(
                        leading: Icon(Icons.folder_open, color: Colors.grey),
                        title: Text('No local files yet'),
                        subtitle: Text(
                          'Choose validated PDFs from the Upload page. Files stay in memory on this device and are not uploaded to Firebase Storage.',
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${allEntries.length} local file${allEntries.length == 1 ? '' : 's'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: confirmClearAll,
                                    icon: const Icon(Icons.delete_sweep),
                                    label: const Text('Clear All'),
                                  ),
                                ],
                              ),
                              Text(
                                'Total size: ${formatFileSize(localFileWorkspace.totalSizeBytes)}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: searchController,
                                onChanged: (value) {
                                  setState(() {
                                    searchQuery = value;
                                  });
                                },
                                decoration: InputDecoration(
                                  labelText: 'Search local files',
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: searchQuery.isEmpty
                                      ? null
                                      : IconButton(
                                          tooltip: 'Clear search',
                                          onPressed: () {
                                            searchController.clear();
                                            setState(() {
                                              searchQuery = '';
                                            });
                                          },
                                          icon: const Icon(Icons.clear),
                                        ),
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.sort, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Sort by:'),
                                  const SizedBox(width: 8),
                                  DropdownButton<LocalFileSort>(
                                    value: sortMode,
                                    isExpanded: false,
                                    items: LocalFileSort.values
                                        .map(
                                          (mode) => DropdownMenuItem(
                                            value: mode,
                                            child: Text(sortLabel(mode)),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        sortMode = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (entries.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.search_off),
                            title: Text('No matching local files'),
                            subtitle: Text(
                              'Try a different filename search.',
                            ),
                          ),
                        )
                      else
                        Card(
                          child: Column(
                            children: [
                              for (final entry in entries)
                                ListTile(
                                  leading: const Icon(
                                    Icons.picture_as_pdf,
                                    color: Colors.red,
                                  ),
                                  title: Text(
                                    entry.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${formatFileSize(entry.sizeBytes)} • Available locally only',
                                  ),
                                  trailing: IconButton(
                                    tooltip: 'Remove local file',
                                    onPressed: () => removeEntry(entry),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Cloud Files',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('No cloud files to show'),
                  subtitle: Text(
                    'Live cloud listings are unavailable because Firebase Storage is not enabled or configured. Cloud Guard does not invent stored files or used space.',
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
