/// Application state for the Kikoe desktop UI.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import 'kikoe_ffi.dart';
import 'model_menu.dart';
import 'queue_item.dart';
import 'transcript.dart';
import 'transcriber.dart';
import 'eta.dart';
import 'history_store.dart';

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
  bool gpuBuildAvailable = false;
  String saveFormat = 'srt';
  String initialPrompt = '';
  bool autoSave = false; // save each finished transcript in saveFormat
  bool useVad = false;

  // Decoding quality: 0 balanced, 1 fast, 2 accurate (beam search).
  int quality = 0;
  String speedMode = 'balanced';
  bool wordTimestamps = false;
  bool diarize = false;

  /// Saved prompt presets, keyed by display name.
  final Map<String, String> promptLibrary = {};
  String? activePromptName;

  // Live ETA for the active job, derived from observed progress.
  int? etaMs;
  DateTime? _jobStarted;

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

  // Engine pointer for polling kk_last_progress() while the worker is blocked.
  int? _enginePtr;
  Timer? _progressTimer;

  int? _currentEnginePtr() => _enginePtr;

  void _setActiveProgress(int pct) {
    // The worker decodes media before reporting progress. Start the ETA clock
    // at the first real percentage, and never accept a stale 100 from a
    // reused engine before that point.
    if (_jobStarted == null) {
      if (pct <= 0 || pct >= 100) return;
      _jobStarted = DateTime.now();
    }
    var changed = false;
    for (final item in items) {
      if (item.status == QueueStatus.transcribing && item.progress != pct) {
        item.progress = pct;
        changed = true;
      }
    }
    final before = etaMs;
    final started = _jobStarted;
    if (started != null) {
      final sample = estimateRemainingMs(
        DateTime.now().difference(started).inMilliseconds,
        pct,
      );
      if (sample != null) etaMs = smoothEtaMs(etaMs, sample);
    }
    if (changed || before != etaMs) notifyListeners();
  }

  void _startProgressPolling() {
    _progressTimer?.cancel();
    final addr = _currentEnginePtr();
    if (addr == null) return;
    _progressTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      try {
        final lib = KikoeFFI.load();
        final pct = lib.lastProgress(Pointer<Void>.fromAddress(addr));
        if (pct < 0 || pct > 100) return;
        _setActiveProgress(pct);
      } catch (_) {
        // If FFI is unavailable we simply keep the old indeterminate display.
      }
    });
  }

  void _stopProgressPolling() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  static const List<String> languages = [
    'auto', 'id', 'en', 'ja', 'zh', 'ko', 'ms', 'vi', 'th',
    'ar', 'tr', 'de', 'es', 'fr', 'it', 'pt', 'ru', 'hi', 'nl', 'pl',
  ];

  static const List<String> formats = ['srt', 'txt', 'vtt', 'json', 'md', 'csv'];

  /// User-imported ggml models (persisted as JSON in SharedPreferences).
  List<ModelEntry> customModels = [];

  ModelEntry? get selectedModel {
    final builtIn = findModel(modelName);
    if (builtIn != null) return builtIn;
    for (final m in customModels) {
      if (m.name == modelName) return m;
    }
    return null;
  }

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
      gpuBuildAvailable = KikoeFFI.load().gpuEnabled == 1;
    } catch (_) {
      gpuBuildAvailable = false;
    }
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
  static const _kPrefsPrompt = 'kikoe_initial_prompt';
  static const _kPrefsAutoSave = 'kikoe_auto_save';
  static const _kPrefsCustomModels = 'kikoe_custom_models';
  static const _kPrefsQuality = 'kikoe_quality';
  static const _kPrefsSpeedMode = 'kikoe_speed_mode';
  static const _kPrefsWordTimestamps = 'kikoe_word_timestamps';
  static const _kPrefsDiarize = 'kikoe_diarize';
  static const _kPrefsPromptLibrary = 'kikoe_prompt_library';
  static const _kPrefsActivePrompt = 'kikoe_active_prompt';

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
      autoSave = prefs.getBool(_kPrefsAutoSave) ?? autoSave;
      initialPrompt = prefs.getString(_kPrefsPrompt) ?? initialPrompt;
      quality = prefs.getInt(_kPrefsQuality) ?? quality;
      speedMode = prefs.getString(_kPrefsSpeedMode) ?? speedMode;
      wordTimestamps = prefs.getBool(_kPrefsWordTimestamps) ?? wordTimestamps;
      diarize = prefs.getBool(_kPrefsDiarize) ?? diarize;
      final rawPrompts = prefs.getString(_kPrefsPromptLibrary);
      if (rawPrompts != null && rawPrompts.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawPrompts) as Map<String, dynamic>;
          promptLibrary.clear();
          decoded.forEach((k, v) => promptLibrary[k.toString()] = v.toString());
        } catch (_) {
          // Keep the library empty on corrupt data.
        }
      }
      activePromptName = prefs.getString(_kPrefsActivePrompt);
      final rawCustom = prefs.getString(_kPrefsCustomModels);
      if (rawCustom != null && rawCustom.isNotEmpty) {
        try {
          final list = jsonDecode(rawCustom) as List<dynamic>;
          customModels = list
              .map((e) => ModelEntry(
                    e['name'] as String,
                    e['filename'] as String,
                    e['size'] as int,
                    e['note'] as String,
                    customPath: e['path'] as String,
                  ))
              .toList();
        } catch (_) {
          customModels = [];
        }
      }
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
      await prefs.setBool(_kPrefsAutoSave, autoSave);
      await prefs.setInt(_kPrefsQuality, quality);
      await prefs.setString(_kPrefsSpeedMode, speedMode);
      await prefs.setBool(_kPrefsWordTimestamps, wordTimestamps);
      await prefs.setBool(_kPrefsDiarize, diarize);
      await prefs.setString(_kPrefsPromptLibrary, jsonEncode(promptLibrary));
      if (activePromptName == null) {
        await prefs.remove(_kPrefsActivePrompt);
      } else {
        await prefs.setString(_kPrefsActivePrompt, activePromptName!);
      }
      if (initialPrompt.isEmpty) {
        await prefs.remove(_kPrefsPrompt);
      } else {
        await prefs.setString(_kPrefsPrompt, initialPrompt);
      }
      await prefs.setString(
          _kPrefsCustomModels,
          jsonEncode(customModels
              .map((m) => {
                    'name': m.name,
                    'filename': m.filename,
                    'size': m.sizeBytes,
                    'note': m.note,
                    'path': m.customPath,
                  })
              .toList()));
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
    _jobStarted = null;
    etaMs = null;
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
      initialPrompt: initialPrompt,
      vadModelPath: useVad && vadReady ? vadModelPath : null,
      quality: quality,
      wordTimestamps: wordTimestamps,
      diarize: diarize,
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

  /// Replace an item's segments wholesale (used by the transcript editor).
  void replaceItemSegments(QueueItem item, List<Segment> edited) {
    item.segments
      ..clear()
      ..addAll(edited);
    notifyListeners();
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

  /// Apply one of the three speed and quality presets. Every registry model,
  /// including medium and large turbo, stays available in the picker.
  void setSpeedMode(String mode) {
    speedMode = mode;
    useVad = true;
    switch (mode) {
      case 'fast':
        quality = 1;
        modelName = 'base-q5_1';
        break;
      case 'accurate':
        quality = 2;
        modelName = 'small-q5_1';
        break;
      default:
        speedMode = 'balanced';
        quality = 0;
        modelName = 'small-q5_1';
    }
    if (!vadReady && !downloads.contains(vadModelName)) {
      downloads.add(vadModelName);
      transcriber.downloadModel(vadModelName);
    }
    notifyListeners();
    _saveSettings();
  }

  /// Store the current prompt under a name and make it active.
  void savePrompt(String name, String text) {
    final key = name.trim();
    if (key.isEmpty) return;
    promptLibrary[key] = text.trim();
    activePromptName = key;
    initialPrompt = text.trim();
    notifyListeners();
    _saveSettings();
  }

  /// Load a saved prompt into the active input field.
  void applyPrompt(String name) {
    final text = promptLibrary[name];
    if (text == null) return;
    activePromptName = name;
    initialPrompt = text;
    notifyListeners();
    _saveSettings();
  }

  void removePrompt(String name) {
    promptLibrary.remove(name);
    if (activePromptName == name) activePromptName = null;
    notifyListeners();
    _saveSettings();
  }

  void setWordTimestamps(bool value) {
    wordTimestamps = value;
    notifyListeners();
    _saveSettings();
  }

  void setDiarize(bool value) {
    diarize = value;
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

  /// Copy an imported ggml model into the cache dir and register it.
  Future<void> importModel(String sourcePath, String displayName) async {
    final dir = await Directory(cacheDir).create(recursive: true);
    final safe = displayName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final name = safe.endsWith('.bin') ? safe : '$safe.bin';
    final target = p.join(dir.path, 'custom_${DateTime.now().millisecondsSinceEpoch}_$name');
    final size = await File(sourcePath).length();
    await File(sourcePath).copy(target);
    customModels.add(ModelEntry(name, p.basename(target), size, 'imported model',
        customPath: target));
    modelName = name;
    notifyListeners();
    await _saveSettings();
  }

  /// Delete a custom model file and its registry entry.
  Future<void> removeCustomModel(ModelEntry model) async {
    try {
      await File(model.customPath!).delete();
    } catch (_) {}
    customModels.removeWhere((m) => m.name == model.name);
    if (modelName == model.name) {
      modelName = 'small';
    }
    notifyListeners();
    await _saveSettings();
  }

  void setAutoSave(bool value) {
    autoSave = value;
    notifyListeners();
    _saveSettings();
  }

  void setInitialPrompt(String value) {
    initialPrompt = value;
    notifyListeners();
    _saveSettings();
  }

  /// Render [format] from [item]'s (possibly edited) segments and write it
  /// to the output path. No FFI round-trip; the Dart renderer honors edits.
  void saveItem(QueueItem item, String format) {
    if (item.segments.isEmpty) return;
    final content = renderFormat(
      item.segments.map((s) => RenderSegment(s.startMs, s.endMs, s.text)).toList(),
      format,
    );
    if (content.isEmpty) return;
    final path = _outputPathFor(item, format);
    try {
      File(path).writeAsStringSync(content);
      item.outputPath = path;
    } catch (e) {
      item.error = 'could not write $path: $e';
    }
    notifyListeners();
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
      case EngineReady():
        _enginePtr = event.ptr;
        _startProgressPolling();
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
        if (event.id.isEmpty || _find(event.id) != null) {
          _setActiveProgress(event.percent);
        }
      case SegmentReady():
        final item = _find(event.id);
        if (item != null) {
          item.segments.add(Segment(
            event.startMs,
            event.endMs,
            event.text,
            confidence: event.confidence,
            speaker: event.speaker,
            words: event.words,
          ));
          notifyListeners();
        }
      case TranscribeDone():
        final item = _find(event.id);
        if (item != null) {
          item.status = QueueStatus.done;
          item.progress = 100;
          final snapshot = item.segments.toList();
          unawaited(HistoryStore.instance.add(
            fileName: item.name,
            segments: snapshot
                .map((s) => RenderSegment(s.startMs, s.endMs, s.text))
                .toList(),
          ));
          if (autoSave) saveItem(item, saveFormat);
        }
        busy = false;
        _jobStarted = null;
        etaMs = null;
        _stopProgressPolling();
        notifyListeners();
        start(); // drain the queue
      case TranscribeFailed():
        final item = _find(event.id);
        if (item != null) {
          item.status = event.cancelled ? QueueStatus.cancelled : QueueStatus.failed;
          item.error = event.message;
        }
        busy = false;
        _jobStarted = null;
        etaMs = null;
        _stopProgressPolling();
        notifyListeners();
        start();
      case FormatResult():
        // Formats are rendered locally now; the worker's format result is unused.
        break;
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
