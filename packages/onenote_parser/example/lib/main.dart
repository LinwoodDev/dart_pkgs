import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:onenote_parser/onenote_parser.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.pickFile});

  final Future<PickedOneNoteFile?> Function()? pickFile;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff7719aa)),
        useMaterial3: true,
      ),
      home: ParserPage(pickFile: pickFile ?? pickOneNoteFile),
    );
  }
}

class PickedOneNoteFile {
  const PickedOneNoteFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

Future<PickedOneNoteFile?> pickOneNoteFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['one', 'onepkg'],
    withData: true,
  );
  final file = result?.files.single;
  final bytes = file?.bytes;
  if (file == null || bytes == null) return null;
  return PickedOneNoteFile(name: file.name, bytes: bytes);
}

class ParserPage extends StatefulWidget {
  const ParserPage({required this.pickFile, super.key});

  final Future<PickedOneNoteFile?> Function() pickFile;

  @override
  State<ParserPage> createState() => _ParserPageState();
}

class _ParserPageState extends State<ParserPage> {
  ParsedDocument? _document;
  String? _error;
  bool _loading = false;

  Future<void> _openFile() async {
    final file = await widget.pickFile();
    if (file == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final extension = file.name.split('.').last.toLowerCase();
      final document = switch (extension) {
        'one' => await _readSection(file),
        'onepkg' => await _readNotebook(file),
        _ => throw UnsupportedError('Choose a .one or .onepkg file.'),
      };
      if (!mounted) return;
      setState(() => _document = document);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _document = null;
        _error = error.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<ParsedDocument> _readSection(PickedOneNoteFile file) async {
    final section = await parseSectionBytes(
      data: file.bytes,
      fileName: file.name,
    );
    return ParsedDocument(
      fileName: file.name,
      sections: [_readSectionSummary(section)],
    );
  }

  Future<ParsedDocument> _readNotebook(PickedOneNoteFile file) async {
    final notebook = await parsePackageBytes(data: file.bytes);
    return ParsedDocument(
      fileName: file.name,
      sections: _readEntries(notebook.entries),
      warnings: notebook.warnings.map((warning) => warning.message).toList(),
    );
  }

  List<SectionSummary> _readEntries(List<OneNoteSectionEntry> entries) =>
      entries
          .map(
            (entry) => entry.when(
              section: _readSectionSummary,
              sectionGroup: (group) => SectionSummary(
                name: group.displayName,
                children: _readEntries(group.entries),
              ),
            ),
          )
          .toList();

  SectionSummary _readSectionSummary(OneNoteSection section) {
    return SectionSummary(
      name: section.displayName,
      pages: [
        for (final series in section.pageSeries)
          for (final page in series.pages) _readPage(page),
      ],
      warnings: section.warnings.map((warning) => warning.message).toList(),
    );
  }

  PageSummary _readPage(OneNotePage page) {
    return PageSummary(
      title: page.title ?? 'Untitled page',
      author: page.author,
      createdAt: page.createdAt,
      updatedAt: page.updatedAt,
      recognizedText: page.recognizedText,
      blocks: [
        for (final content in page.contents) ..._readPageContent(content),
      ],
    );
  }

  List<ContentSummary> _readPageContent(OneNotePageContent value) => value.when(
    outline: _readOutline,
    image: (image) => [_readImage(image)],
    embeddedFile: (file) => [_readEmbeddedFile(file)],
    ink: (ink) => [_readInk(ink)],
    unknown: () => const [ContentSummary(label: 'Unknown content')],
  );

  List<ContentSummary> _readOutline(OneNoteOutline outline) => [
    for (final item in outline.items) ..._readOutlineItem(item),
  ];

  List<ContentSummary> _readOutlineItem(OneNoteOutlineItem item) => item.when(
    group: (group) => [
      for (final child in group.items) ..._readOutlineItem(child),
    ],
    element: (element) => [
      for (final content in element.contents) _readContent(content),
      for (final child in element.children) ..._readOutlineItem(child),
    ],
  );

  ContentSummary _readContent(OneNoteContent value) => value.when(
    richText: (text) =>
        ContentSummary(label: 'Text', text: text.text, icon: Icons.notes),
    table: (table) => ContentSummary(
      label: 'Table',
      text:
          '${table.rowCount} row${table.rowCount == 1 ? '' : 's'} × '
          '${table.columnCount} column${table.columnCount == 1 ? '' : 's'}',
      icon: Icons.table_chart_outlined,
    ),
    image: _readImage,
    embeddedFile: _readEmbeddedFile,
    ink: _readInk,
    unknown: () => const ContentSummary(label: 'Unknown content'),
  );

  ContentSummary _readImage(OneNoteImage image) {
    return ContentSummary(
      label: image.filename ?? 'Image',
      text: image.altText ?? image.ocrText,
      icon: Icons.image_outlined,
      bytes: image.data?.length,
    );
  }

  ContentSummary _readEmbeddedFile(OneNoteEmbeddedFile file) {
    return ContentSummary(
      label: file.filename,
      text: file.fileType,
      icon: Icons.attach_file,
      bytes: file.data.length,
    );
  }

  ContentSummary _readInk(OneNoteInk ink) {
    final strokes = _inkStrokeCount(ink);
    return ContentSummary(
      label: 'Ink drawing',
      text: '$strokes stroke${strokes == 1 ? '' : 's'}',
      icon: Icons.gesture,
    );
  }

  int _inkStrokeCount(OneNoteInk ink) =>
      ink.strokes.length +
      ink.childGroups.fold(0, (count, child) => count + _inkStrokeCount(child));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OneNote parser')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('open-file'),
        onPressed: _loading ? null : _openFile,
        icon: const Icon(Icons.file_open_outlined),
        label: const Text('Open file'),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _loading
            ? const Center(
                key: ValueKey('loading'),
                child: CircularProgressIndicator(),
              )
            : _error != null
            ? _ErrorView(error: _error!, onRetry: _openFile)
            : _document != null
            ? _DocumentView(document: _document!)
            : const _WelcomeView(),
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  const _WelcomeView();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('welcome'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book_outlined, size: 72),
              SizedBox(height: 20),
              Text(
                'Read a OneNote file',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text(
                'Open a .one section or a .onepkg notebook. Parsing happens locally on this device.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 56,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text('Could not parse the file'),
            const SizedBox(height: 8),
            SelectableText(error, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Choose another'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentView extends StatelessWidget {
  const _DocumentView({required this.document});

  final ParsedDocument document;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('document'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(document.fileName),
          subtitle: Text(
            '${document.sectionCount} section${document.sectionCount == 1 ? '' : 's'}, '
            '${document.pageCount} page${document.pageCount == 1 ? '' : 's'}',
          ),
        ),
        for (final warning in document.warnings)
          ListTile(
            leading: const Icon(Icons.warning_amber),
            title: Text(warning),
          ),
        const Divider(),
        for (final section in document.sections) _SectionTile(section: section),
      ],
    );
  }
}

class _SectionTile extends StatelessWidget {
  const _SectionTile({required this.section});

  final SectionSummary section;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: true,
      leading: Icon(
        section.children.isEmpty ? Icons.folder : Icons.folder_copy,
      ),
      title: Text(section.name),
      subtitle: Text(
        section.children.isEmpty
            ? '${section.pages.length} page${section.pages.length == 1 ? '' : 's'}'
            : '${section.children.length} item${section.children.length == 1 ? '' : 's'}',
      ),
      childrenPadding: const EdgeInsets.only(left: 16),
      children: [
        for (final warning in section.warnings)
          ListTile(
            leading: const Icon(Icons.warning_amber, size: 20),
            title: Text(warning),
          ),
        for (final child in section.children) _SectionTile(section: child),
        for (final page in section.pages) _PageTile(page: page),
      ],
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile({required this.page});

  final PageSummary page;

  @override
  Widget build(BuildContext context) {
    final metadata = [
      if (page.author != null) page.author!,
      page.updatedAt,
    ].join(' • ');
    return ExpansionTile(
      leading: const Icon(Icons.article_outlined),
      title: Text(page.title),
      subtitle: Text(metadata),
      childrenPadding: const EdgeInsets.only(left: 16, right: 8),
      children: [
        if (page.recognizedText case final text? when text.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.gesture),
            title: const Text('Recognized handwriting'),
            subtitle: Text(text),
          ),
        if (page.blocks.isEmpty)
          const ListTile(title: Text('This page has no supported content.')),
        for (final block in page.blocks)
          ListTile(
            leading: Icon(block.icon ?? Icons.help_outline),
            title: Text(block.label),
            subtitle: block.text == null || block.text!.trim().isEmpty
                ? null
                : Text(
                    block.text!,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
            trailing: block.bytes == null
                ? null
                : Text(_formatBytes(block.bytes!)),
          ),
      ],
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

class ParsedDocument {
  const ParsedDocument({
    required this.fileName,
    required this.sections,
    this.warnings = const [],
  });

  final String fileName;
  final List<SectionSummary> sections;
  final List<String> warnings;

  int get sectionCount =>
      sections.fold(0, (count, section) => count + section.sectionCount);

  int get pageCount =>
      sections.fold(0, (count, section) => count + section.pageCount);
}

class SectionSummary {
  const SectionSummary({
    required this.name,
    this.pages = const [],
    this.children = const [],
    this.warnings = const [],
  });

  final String name;
  final List<PageSummary> pages;
  final List<SectionSummary> children;
  final List<String> warnings;

  int get sectionCount => children.isEmpty
      ? 1
      : children.fold(0, (count, child) => count + child.sectionCount);

  int get pageCount =>
      pages.length +
      children.fold(0, (count, child) => count + child.pageCount);
}

class PageSummary {
  const PageSummary({
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.blocks,
    this.author,
    this.recognizedText,
  });

  final String title;
  final String? author;
  final String createdAt;
  final String updatedAt;
  final String? recognizedText;
  final List<ContentSummary> blocks;
}

class ContentSummary {
  const ContentSummary({required this.label, this.text, this.icon, this.bytes});

  final String label;
  final String? text;
  final IconData? icon;
  final int? bytes;
}
