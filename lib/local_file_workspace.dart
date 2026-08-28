

import 'package:flutter/foundation.dart';

class LocalPdfEntry {
  const LocalPdfEntry({
    required this.name,
    required this.sizeBytes,
    this.bytes,
  });

  final String name;
  final int sizeBytes;
  final Uint8List? bytes;
}

class LocalFileWorkspace extends ChangeNotifier {
  final List<LocalPdfEntry> _entries = <LocalPdfEntry>[];

  List<LocalPdfEntry> get entries => List.unmodifiable(_entries);

  int get totalSizeBytes => _entries.fold<int>(
        0,
        (total, entry) => total + entry.sizeBytes,
      );

  bool add(LocalPdfEntry entry) {
    final alreadyExists = _entries.any(
      (existing) =>
          existing.name.toLowerCase() == entry.name.toLowerCase() &&
          existing.sizeBytes == entry.sizeBytes,
    );

    if (alreadyExists) return false;

    _entries.add(entry);
    notifyListeners();
    return true;
  }

  bool remove(LocalPdfEntry entry) {
    final index = _entries.indexWhere(
      (existing) =>
          existing.name.toLowerCase() == entry.name.toLowerCase() &&
          existing.sizeBytes == entry.sizeBytes,
    );

    if (index == -1) return false;

    _entries.removeAt(index);
    notifyListeners();
    return true;
  }

  void clear() {
    if (_entries.isEmpty) return;
    _entries.clear();
    notifyListeners();
  }

  List<LocalPdfEntry> search(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return entries;

    return _entries
        .where((entry) => entry.name.toLowerCase().contains(normalizedQuery))
        .toList(growable: false);
  }
}

final localFileWorkspace = LocalFileWorkspace();
