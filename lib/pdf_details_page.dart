import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'local_file_workspace.dart';

class PdfDetailsPage extends StatelessWidget {
  const PdfDetailsPage({super.key, required this.entry});

  final LocalPdfEntry entry;

  String formatFileSize(int size) {
    if (size < 1024) return '$size bytes';
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(2)} KB';
    }
    return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Future<void> confirmRemove(BuildContext context) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove local PDF?'),
        content: Text(
          'Remove “${entry.name}” from the temporary local workspace? No cloud file will be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (shouldRemove == true && context.mounted) {
      localFileWorkspace.remove(entry);
      Navigator.of(context).pop();
    }
  }

  void openFullScreenPreview(BuildContext context) {
    final bytes = entry.bytes;
    if (bytes == null || bytes.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PdfReaderPage(fileName: entry.name, bytes: bytes),
      ),
    );
  }

  Widget buildPreview(BuildContext context) {
    final bytes = entry.bytes;

    if (bytes == null || bytes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.preview_outlined, size: 42, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                'Preview is unavailable for this entry.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(
                'The file metadata is available, but the PDF bytes were not retained by the local picker.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
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
            const Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
            const SizedBox(height: 10),
            const Text(
              'Open the complete PDF in full-screen preview.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => openFullScreenPreview(context),
                icon: const Icon(Icons.open_in_full),
                label: const Text('Open Full-Screen Preview'),
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
        title: const Text('PDF Details'),
        actions: [
          IconButton(
            tooltip: 'Remove local PDF',
            onPressed: () => confirmRemove(context),
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.picture_as_pdf, color: Colors.red, size: 42),
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
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailRow(label: 'File name', value: entry.name),
                      _DetailRow(
                        label: 'File size',
                        value: formatFileSize(entry.sizeBytes),
                      ),
                      const _DetailRow(
                        label: 'Validation',
                        value: 'PDF validated locally',
                        valueColor: Colors.green,
                      ),
                      const _DetailRow(
                        label: 'Storage status',
                        value: 'Temporary local workspace only',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.lock_outline, color: Colors.blue),
                  title: Text('Storage Honesty'),
                  subtitle: Text(
                    'This preview uses PDF bytes kept in this device memory. Nothing is uploaded to Firebase Storage, which is currently disabled or not configured.',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Preview',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
  const PdfReaderPage({super.key, required this.fileName, required this.bytes});

  final String fileName;
  final Uint8List bytes;

  @override
  State<PdfReaderPage> createState() => _PdfReaderPageState();
}

class _PdfReaderPageState extends State<PdfReaderPage> {
  final PdfViewerController _controller = PdfViewerController();
  int _pageCount = 0;
  int _currentPage = 0;

  void _jumpToPage(int? page) {
    if (page == null || page < 1 || page > _pageCount) return;
    _controller.jumpToPage(page);
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
          if (_pageCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: DropdownButton<int>(
                  value: _currentPage == 0 ? 1 : _currentPage,
                  underline: const SizedBox.shrink(),
                  dropdownColor: Theme.of(context).colorScheme.surface,
                  onChanged: _jumpToPage,
                  items: List<DropdownMenuItem<int>>.generate(
                    _pageCount,
                    (index) => DropdownMenuItem<int>(
                      value: index + 1,
                      child: Text('Page ${index + 1}'),
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
        pageLayoutMode: PdfPageLayoutMode.single,
        scrollDirection: PdfScrollDirection.vertical,
        enableDoubleTapZooming: true,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onDocumentLoaded: (details) {
          if (!mounted) return;
          setState(() {
            _pageCount = details.document.pages.count;
            _currentPage = 1;
          });
        },
        onPageChanged: (details) {
          if (!mounted) return;
          setState(() {
            _currentPage = details.newPageNumber;
          });
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w600, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
