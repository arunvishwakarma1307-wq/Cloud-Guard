import 'package:cloud_guard/local_file_workspace.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late LocalFileWorkspace workspace;

  setUp(() {
    workspace = LocalFileWorkspace();
  });

  test('adds entries and calculates count and total size', () {
    workspace.add(const LocalPdfEntry(name: 'one.pdf', sizeBytes: 100));
    workspace.add(const LocalPdfEntry(name: 'two.pdf', sizeBytes: 250));

    expect(workspace.entries.length, 2);
    expect(workspace.totalSizeBytes, 350);
  });

  test('rejects the same filename and size as a duplicate', () {
    const entry = LocalPdfEntry(name: 'report.pdf', sizeBytes: 100);

    expect(workspace.add(entry), isTrue);
    expect(workspace.add(entry), isFalse);
    expect(workspace.entries.length, 1);
  });

  test('searches by filename case-insensitively', () {
    workspace.add(const LocalPdfEntry(name: 'Annual_Report.pdf', sizeBytes: 100));
    workspace.add(const LocalPdfEntry(name: 'notes.pdf', sizeBytes: 200));

    final results = workspace.search('annual');

    expect(results.map((entry) => entry.name), contains('Annual_Report.pdf'));
    expect(results.length, 1);
  });

  test('removes an entry and updates total size', () {
    const entry = LocalPdfEntry(name: 'remove.pdf', sizeBytes: 500);
    workspace.add(entry);

    expect(workspace.remove(entry), isTrue);
    expect(workspace.entries, isEmpty);
    expect(workspace.totalSizeBytes, 0);
  });

  test('clear removes all entries', () {
    workspace.add(const LocalPdfEntry(name: 'one.pdf', sizeBytes: 100));
    workspace.add(const LocalPdfEntry(name: 'two.pdf', sizeBytes: 200));

    workspace.clear();

    expect(workspace.entries, isEmpty);
    expect(workspace.totalSizeBytes, 0);
  });
}
