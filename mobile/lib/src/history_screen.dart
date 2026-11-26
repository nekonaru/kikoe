// History screen: list of past transcriptions.
//
// Tap an entry to read it, copy it, export it or delete it. Entries live in
// the app documents directory (kikoe_history/); see history_store.dart.
library;

import 'l10n.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

import 'history_search.dart';
import 'history_store.dart';
import 'kikoe_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<HistoryEntry>> _future;
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() => _future = HistoryStore.instance.load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kSurface,
        title: Text(tr('Recent transcriptions')),
        actions: [
          IconButton(
            tooltip: 'Clear all',
            icon: const Icon(Icons.delete_sweep_outlined, color: kText),
            onPressed: () => _confirmClearAll(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(fontSize: 13, color: kText),
                decoration: InputDecoration(
                  hintText: tr('Search history'),
                  hintStyle: const TextStyle(fontSize: 12, color: kDim),
                  prefixIcon: const Icon(Icons.search, size: 18, color: kDim),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kSurface2),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<HistoryEntry>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return Center(child: CircularProgressIndicator(color: kBrand));
                  }
                  final entries = snapshot.data ?? const <HistoryEntry>[];
                  if (entries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history, size: 52, color: kDim),
                          SizedBox(height: 12),
                          Text(tr('Nothing yet'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
                          SizedBox(height: 4),
                          Text(tr('Your transcriptions will appear here.'), style: TextStyle(fontSize: 12, color: kDim)),
                        ],
                      ),
                    );
                  }
                  final visible = entries
                      .where((e) => historyMatches(e.fileName, e.txt(), _query))
                      .toList();
                  if (visible.isEmpty) {
                    return Center(child: Text(tr('No matches'), style: const TextStyle(color: kDim)));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => SizedBox(height: 10),
                    itemBuilder: (context, i) => _HistoryTile(entry: visible[i], onChanged: _reload),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('Clear history?')),
        content: Text(tr('All saved transcriptions will be deleted. Media files are untouched.')),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(tr('Cancel'))),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(tr('Delete all'))),
        ],
      ),
    );
    if (ok == true) {
      await HistoryStore.instance.clearAll();
      _reload();
    }
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry, required this.onChanged});

  final HistoryEntry entry;
  final VoidCallback onChanged;

  String _date(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => HistoryViewer(entry: entry)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.description_outlined, color: kBrand),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, color: kText)),
                    SizedBox(height: 2),
                    Text(tr('${_date(entry.createdAt)} · ${entry.wordCount} words'),
                        style: const TextStyle(fontSize: 11, color: kDim)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(Icons.close, color: kDim, size: 18),
                onPressed: () async {
                  await HistoryStore.instance.delete(entry.id);
                  onChanged();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryViewer extends StatefulWidget {
  const HistoryViewer({super.key, required this.entry});

  final HistoryEntry entry;

  @override
  State<HistoryViewer> createState() => _HistoryViewerState();
}

class _HistoryViewerState extends State<HistoryViewer> {
  String _format = 'srt';

  String get _content {
    switch (_format) {
      case 'srt':
        return widget.entry.srt();
      case 'vtt':
        return widget.entry.vtt();
      case 'json':
        return widget.entry.json();
      case 'md':
        return widget.entry.md();
      case 'csv':
        return widget.entry.csv();
      default:
        return widget.entry.txt();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kSurface,
        title: Text(entry.fileName, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.share, color: kText),
            onPressed: () async {
              final dir = await getTemporaryDirectory();
              final file = File(p.join(dir.path, '${p.basenameWithoutExtension(entry.fileName)}_kikoe.$_format'));
              await file.writeAsString(_content);
              await SharePlus.instance.share(
                ShareParams(files: [XFile(file.path)], text: 'Kikoe transcript'),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  for (final f in const ['srt', 'txt', 'vtt', 'json', 'md', 'csv'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f.toUpperCase()),
                        selected: _format == f,
                        onSelected: (_) => setState(() => _format = f),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: SelectableText(
                  _content,
                  style: const TextStyle(fontSize: 12.5, height: 1.5, color: kText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
