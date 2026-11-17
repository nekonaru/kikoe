/// History of past transcriptions. One JSON file per entry in the
/// kikoe_history directory; newest kept at 50.
library;

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'transcript.dart';

class HistoryEntry {
  HistoryEntry({
    required this.id,
    required this.fileName,
    required this.createdAt,
    required this.segments,
  });

  final String id;
  final String fileName;
  final int createdAt;
  final List<RenderSegment> segments;

  int get wordCount {
    var n = 0;
    for (final s in segments) {
      final t = s.text.trim();
      if (t.isNotEmpty) n += t.split(RegExp(r'\s+')).length;
    }
    return n;
  }

  Duration get duration => segments.isEmpty
      ? Duration.zero
      : Duration(milliseconds: segments.last.endMs);

  String txt() => renderTxt(segments);
  String srt() => renderSrt(segments);
  String vtt() => renderVtt(segments);
  String json() => renderJson(segments);
}

class HistoryStore {
  HistoryStore._();

  static final instance = HistoryStore._();

  static const maxEntries = 50;

  Future<Directory> _dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final base = p.join(docs.path, 'kikoe_history');
    return Directory(base).create(recursive: true);
  }

  Future<List<HistoryEntry>> load() async {
    final dir = await _dir();
    final entries = <HistoryEntry>[];
    await for (final file in dir.list(followLinks: false)) {
      if (file is! File || !file.path.endsWith('.json')) continue;
      try {
        final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final segments = (map['segments'] as List<dynamic>)
            .map((s) => RenderSegment(
                  (s as Map<String, dynamic>)['start_ms'] as int,
                  s['end_ms'] as int,
                  s['text'] as String,
                ))
            .toList();
        entries.add(HistoryEntry(
          id: map['id'] as String,
          fileName: map['file'] as String? ?? 'unknown',
          createdAt: map['created_at'] as int? ?? 0,
          segments: segments,
        ));
      } catch (_) {
        // Corrupt entry: skip it rather than failing the whole list.
      }
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<HistoryEntry?> add({required String fileName, required List<RenderSegment> segments}) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
      var id = '';
      for (var i = 0; i < 10; i++) {
        // Cheap unique id, no uuid dependency needed.
        id += chars[(now + i * 2654435761) % chars.length];
      }
      final dir = await _dir();
      final entry = HistoryEntry(id: id, fileName: fileName, createdAt: now, segments: segments);
      final map = {
        'id': entry.id,
        'file': entry.fileName,
        'created_at': entry.createdAt,
        'segments': segments
            .map((s) => {'start_ms': s.startMs, 'end_ms': s.endMs, 'text': s.text})
            .toList(),
      };
      await File(p.join(dir.path, '$id.json')).writeAsString(jsonEncode(map));
      await _prune(dir);
      return entry;
    } catch (_) {
      return null;
    }
  }

  Future<void> _prune(Directory dir) async {
    final files = (await dir.list().toList()).where((e) => e is File && e.path.endsWith('.json')).cast<File>().toList();
    if (files.length <= maxEntries) return;
    final stats = await Future.wait(files.map((f) => f.lastModified().then((d) => (f, d))));
    stats.sort((a, b) => a.$2.compareTo(b.$2));
    for (final pair in stats.take(stats.length - maxEntries)) {
      try {
        await pair.$1.delete();
      } catch (_) {}
    }
  }

  Future<void> delete(String id) async {
    try {
      final dir = await _dir();
      await File(p.join(dir.path, '$id.json')).delete();
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      final dir = await _dir();
      await for (final entry in dir.list()) {
        if (entry is File) {
          try {
            await entry.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }
}
