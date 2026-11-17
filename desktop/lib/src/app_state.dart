/// Application state for the Kikoe desktop UI.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

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

  // Settings, persisted in shared_preferences.
  String modelName = 'small';
  String language = 'auto';
  bool translate = false;
  int nThreads = 0; // 0 = auto
  bool useGpu = false;
  String saveFormat = 'srt';
  bool useVad = false;

  /// null = default (Downloads/kikoe on Windows, ~/Downloads/kikoe elsewhere).
  String? customOutDir;

  /// The effective default output directory: Downloads/kikoe on this device.
  String get defaultOutDir {
    final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
    return p.join(home, 'Downloads', 'kikoe');
  }

  /// The directory transcripts are currently written to.
  String get effectiveOutDir => customOutDir ?? defaultOutDir;

  // Runtime info from the worker.
  String cacheDir = '';
  int abiVersion = -1;
  String? ffiError;
  bool get ffiReady => abiVersion >= 0;

  // Downloads currently in flight, by model name. Progress is not reported
  // through FFI; the UI shows an indeterminate indicator while a name is present.
  final Set<String> downloads = {};

  /// Last model download error, shown in the UI so failures are not silent.
  String? downloadError;

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

  bool downloadingOf(String name) => downloads.contains(name);

  /// Silero VAD model name in the core registry (see kikoe.h / model_registry.cpp).
  static const vadModelName = 'vad-silero';
  static const vadModelFile = 'ggml-silero-v6.2.0.bin';

  /// Path of the Silero VAD model inside the cache directory.
  String get vadModelPath => p.join(cacheDir, vadModelFile);

  bool get vadReady => cacheDir.isNotEmpty && File(vadModelPath).existsSync();

  /// Toggle VAD silence filtering. Enabling it downloads the Silero model on
  /// first use; the UI shows the download like any other model.
  void setUseVad(bool value) {
    useVad = value;
    notifyListeners();
    _saveSettings();
    if (value && !vadReady && !downloads.contains(vadModelName)) {
      downloads.add(vadModelName);
      notifyListeners();
      transcriber.downloadModel(vadModelName);
    }
  }

  /// The VAD download completed (or was already cached).
  void _vadModelReady() {
    downloads.remove(vadModelName);
    notifyListeners();
  }

  /// Kick off worker startup. Called once from the UI.
  Future<void> ensureStarted() async {
    await _loadSettings();
    try {
      await Directory(defaultOutDir).create(recursive: true);
    } catch (_) {
      // If Downloads is not writable, the first save will surface the error.
    }
    try {
      await transcriber.start();
    } catch (e) {
      // FFI load failure: app still opens, but every action is blocked.
      debugPrint('worker start failed: $e');
    }
  }

  static const _kPrefsModel = 'kikoe_model';
  static const _kPrefsLanguage = 'kikoe_language';
  static const _kPrefsTranslate = 'kikoe_translate';
  static const _kPrefsThreads = 'kikoe_threads';
  static const _kPrefsGpu = 'kikoe_gpu';
  static const _kPrefsFormat = 'kikoe_format';
  static const _kPrefsOutDir = 'kikoe_outdir';
  static const _kPrefsVad = 'kikoe_vad';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      modelName = prefs.getString(_kPrefsModel) ?? modelName;
      language = prefs.getString(_kPrefsLanguage) ?? language;
      translate = prefs.getBool(_kPrefsTranslate) ?? translate;
      nThreads = prefs.getInt(_kPrefsThreads) ?? nThreads;
      useGpu = prefs.getBool(_kPrefsGpu) ?? useGpu;
      saveFormat = prefs.getString(_kPrefsFormat) ?? saveFormat;
      useVad = prefs.getBool(_kPrefsVad) ?? useVad;
      final custom = prefs.getString(_kPrefsOutDir);
      if (custom != null && custom.isNotEmpty) customOutDir = custom;
      notifyListeners();
    } catch (_) {
      // Preferences are best-effort; defaults are fine.
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefsModel, modelName);
      await prefs.setString(_kPrefsLanguage, language);
      await prefs.setBool(_kPrefsTranslate, translate);
      await prefs.setInt(_kPrefsThreads, nThreads);
      await prefs.setBool(_kPrefsGpu, useGpu);
      await prefs.setString(_kPrefsFormat, saveFormat);
      await prefs.setBool(_kPrefsVad, useVad);
      if (customOutDir != null) {
        await prefs.setString(_kPrefsOutDir, customOutDir!);
      } else {
        await prefs.remove(_kPrefsOutDir);
      }
    } catch (_) {
      // Best-effort persistence.
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
      vadModelPath: useVad && vadReady ? vadModelPath : null,
    );
  }

  void cancelCurrent() {
    transcriber.cancel();
  }

  void downloadSelectedModel() {
    final model = selectedModel;
    if (model == null || downloads.contains(model.name)) return;
    downloads.add(model.name);
    notifyListeners();
    transcriber.downloadModel(model.name);
  }

  /// Copy the full transcript of [item] to the clipboard.
  Future<void> copyTranscript(QueueItem item) async {
    if (item.segments.isEmpty) return;
    final text = item.segments.map((s) => s.text.trim()).where((t) => t.isNotEmpty).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// Open the folder containing [path] in the system file manager.
  Future<void> revealInFolder(String path) async {
    final dir = p.dirname(path);
    try {
      if (Platform.isWindows) {
        await Process.run('explorer.exe', [dir]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [dir]);
      } else {
        await Process.run('xdg-open', [dir]);
      }
    } catch (_) {
      // Best effort; ignore platforms where no opener exists.
    }
  }

  void setCustomOutDir(String? dir) {
    customOutDir = dir;
    notifyListeners();
    _saveSettings();
  }

  void setModel(String name) {
    modelName = name;
    downloadError = null;
    notifyListeners();
    _saveSettings();
  }

  void setLanguage(String value) {
    language = value;
    notifyListeners();
    _saveSettings();
  }

  void setTranslate(bool value) {
    translate = value;
    notifyListeners();
    _saveSettings();
  }

  void setThreads(int value) {
    nThreads = value;
    notifyListeners();
    _saveSettings();
  }

  void setUseGpu(bool value) {
    useGpu = value;
    notifyListeners();
    _saveSettings();
  }

  void setSaveFormat(String value) {
    saveFormat = value;
    notifyListeners();
    _saveSettings();
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
      case DownloadDone():
        downloads.remove(event.name);
        if (event.name == vadModelName) _vadModelReady();
        notifyListeners();
      case DownloadFailed():
        downloads.remove(event.name);
        downloadError = 'Download of ${event.name} failed: ${event.message}';
        notifyListeners();
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
    // Never overwrite an existing transcript silently: append -2, -3, ...
    var candidate = p.join(effectiveOutDir, '$stem.$format');
    var attempt = 2;
    while (File(candidate).existsSync()) {
      candidate = p.join(effectiveOutDir, '$stem-$attempt.$format');
      attempt++;
    }
    return candidate;
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
