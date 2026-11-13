/// Application state for the Kikoe desktop UI.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'model_menu.dart';
import 'queue_item.dart';
import 'transcriber.dart';

class AppState extends ChangeNotifier {
  AppState() {
    _sub = transcriber.events.listen(_onEvent);
  }

  final Transcriber transcriber = Transcriber();
  StreamSubscription<TranscriberEvent>? _sub;

  final List<QueueItem> items = [];

  // Settings.
  String modelName = 'small';
  String language = 'auto';
  bool translate = false;
  int nThreads = 0; // 0 = auto
  bool useGpu = false;
  String saveFormat = 'srt';
  String? customOutDir; // null = next to source file

  // Runtime info from the worker.
  String cacheDir = '';
  int abiVersion = -1;
  String? ffiError;
  bool get ffiReady => abiVersion >= 0;

  // Downloads in flight, percent per model name.
  final Map<String, int> downloads = {};

  bool busy = false;
  final Set<String> _saveRequested = {}; // '$id:$format' pairs in flight

  static const List<String> languages = [
    'auto', 'id', 'en', 'ja', 'zh', 'ko', 'ms', 'vi', 'th',
    'ar', 'tr', 'de', 'es', 'fr', 'it', 'pt', 'ru', 'hi', 'nl', 'pl',
  ];

  static const List<String> formats = ['srt', 'txt', 'vtt', 'json'];

  ModelEntry? get selectedModel => findModel(modelName);

  bool get selectedModelCached {
    final model = selectedModel;
    if (model == null || cacheDir.isEmpty) return false;
    return model.isCached(cacheDir);
  }

  int? downloadPercentOf(String name) => downloads[name];

  /// Kick off worker startup. Called once from the UI.
  Future<void> ensureStarted() async {
    try {
      await transcriber.start();
    } catch (e) {
      // FFI load failure: app still opens, but every action is blocked.
      debugPrint('worker start failed: $e');
    }
  }

  void addFiles(Iterable<String> paths) {
    var changed = false;
    for (final path in paths) {
      if (items.any((i) => i.path == path)) continue;
      items.add(QueueItem(id: '${DateTime.now().microsecondsSinceEpoch}-$path', path: path));
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void removeItem(QueueItem item) {
    if (item.status == QueueStatus.transcribing) {
      transcriber.cancel();
      return;
    }
    items.remove(item);
    notifyListeners();
  }

  /// Start the queue. No-op while busy or when nothing is pending, or when
  /// the selected model is not available offline.
  void start() {
    if (busy) return;
    if (!selectedModelCached) return;
    final next = items.where((i) => i.status == QueueStatus.pending).firstOrNull;
    if (next == null) return;

    busy = true;
    next.status = QueueStatus.transcribing;
    next.progress = 0;
    notifyListeners();

    transcriber.transcribe(
      id: next.id,
      mediaPath: next.path,
      modelPath: selectedModel!.cachedPath(cacheDir),
      language: language,
      translate: translate,
      nThreads: nThreads,
      useGpu: useGpu,
    );
  }

  void cancelCurrent() {
    transcriber.cancel();
  }

  void downloadSelectedModel() {
    final model = selectedModel;
    if (model == null || downloads.containsKey(model.name)) return;
    downloads[model.name] = 0;
    notifyListeners();
    transcriber.downloadModel(model.name);
  }

  void setCustomOutDir(String? dir) {
    customOutDir = dir;
    notifyListeners();
  }

  void setModel(String name) {
    modelName = name;
    notifyListeners();
  }

  void setLanguage(String value) {
    language = value;
    notifyListeners();
  }

  void setTranslate(bool value) {
    translate = value;
    notifyListeners();
  }

  void setThreads(int value) {
    nThreads = value;
    notifyListeners();
  }

  void setUseGpu(bool value) {
    useGpu = value;
    notifyListeners();
  }

  void setSaveFormat(String value) {
    saveFormat = value;
    notifyListeners();
  }

  /// Request a save of [item] in [format]; the worker renders it via
  /// kk_format_last and we write the file when the result arrives.
  void saveItem(QueueItem item, String format) {
    if (item.segments.isEmpty) return;
    final key = '${item.id}:$format';
    if (_saveRequested.contains(key)) return;
    _saveRequested.add(key);
    notifyListeners();
    transcriber.formatLast(item.id, format);
  }

  void _onEvent(TranscriberEvent event) {
    switch (event) {
      case FfiError():
        ffiError = event.message;
        notifyListeners();
      case Ready():
        cacheDir = event.cacheDir;
        abiVersion = event.abiVersion;
        notifyListeners();
      case DownloadProgress():
        downloads[event.name] = event.percent;
        notifyListeners();
      case DownloadDone():
        downloads.remove(event.name);
        notifyListeners();
      case DownloadFailed():
        downloads.remove(event.name);
        _pauseWithError('Download of ${event.name} failed: ${event.message}');
      case TranscribeProgress():
        final item = _find(event.id);
        if (item != null) {
          item.progress = event.percent;
          notifyListeners();
        }
      case SegmentReady():
        final item = _find(event.id);
        if (item != null) {
          item.segments.add(Segment(event.startMs, event.endMs, event.text));
          notifyListeners();
        }
      case TranscribeDone():
        final item = _find(event.id);
        if (item != null) {
          item.status = QueueStatus.done;
          item.progress = 100;
        }
        busy = false;
        notifyListeners();
        start(); // drain the queue
      case TranscribeFailed():
        final item = _find(event.id);
        if (item != null) {
          item.status = event.cancelled ? QueueStatus.cancelled : QueueStatus.failed;
          item.error = event.message;
        }
        busy = false;
        notifyListeners();
        start();
      case FormatResult():
        final item = _find(event.id);
        _saveRequested.remove('${event.id}:${event.format}');
        if (item != null && event.content.isNotEmpty) {
          final path = _outputPathFor(item, event.format);
          try {
            File(path).writeAsStringSync(event.content);
            item.outputPath = path;
          } catch (e) {
            item.error = 'could not write $path: $e';
          }
        }
        notifyListeners();
    }
  }

  void _pauseWithError(String message) {
    debugPrint(message);
    notifyListeners();
  }

  QueueItem? _find(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  String _outputPathFor(QueueItem item, String format) {
    final name = item.name;
    final dot = name.lastIndexOf('.');
    final stem = dot <= 0 ? name : name.substring(0, dot);
    final dir = customOutDir ?? p.dirname(item.path);
    return p.join(dir, '$stem.$format');
  }

  @override
  void dispose() {
    _sub?.cancel();
    transcriber.dispose();
    super.dispose();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
