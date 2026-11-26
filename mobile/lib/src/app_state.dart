/// Application state for the Kikoe Android app.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'kikoe_ffi.dart';
import 'model_downloader.dart';
import 'model_menu.dart';
import 'notification_service.dart';
import 'transcript.dart';
import 'transcriber.dart';
import 'eta.dart';
import 'history_store.dart';

enum JobStage { idle, decoding, transcribing, done, failed, cancelled }

class Segment {
  const Segment(this.startMs, this.endMs, this.text);
  final int startMs;
  final int endMs;
  final String text;
}

class AppState extends ChangeNotifier {
  AppState({Transcriber? transcriber})
      : transcriber = transcriber ?? Transcriber() {
    _sub = this.transcriber.events.listen(_onEvent);
    NotificationService.instance.onCancelRequested = cancelCurrent;
  }

  final Transcriber transcriber;
  StreamSubscription<TranscriberEvent>? _sub;

  // Input.
  String? inputPath;
  String savedLocation = '';
  String? saveError;

  // Session-only queue for multi-file shares. setInputs() replaces it with a
  // fresh batch; setInput() alone uses a single-element batch implicitly.
  List<String> queue = [];
  int queueIndex = 0;
  bool get hasNextInQueue => queue.length > 1 && queueIndex + 1 < queue.length;

  // First-launch storage permission state: notNeeded (API 29+), granted, or denied.
  // 0 = not needed, 1 = granted, 2 = needs requesting, 3 = asked, waiting for result.
  int legacyStorageState = -1;
  bool storageNoticeShown = false;

  // Job state. [activeJobId] correlates worker events with the current job so
  // a stale job finishing after a new share cannot pollute the new transcript.
  JobStage stage = JobStage.idle;
  int progress = 0;
  String? error;
  String? activeJobId;
  final List<Segment> segments = [];
  String? outputPath;

  // Settings.
  String modelName = 'small-q5_1';
  String language = 'auto';
  bool translate = false;
  bool useVad = false;
  String initialPrompt = '';
  bool autoSave = false;

  // Decoding quality: 0 balanced, 1 fast, 2 accurate (beam search).
  int quality = 0;
  String speedMode = 'balanced';

  // Live progress display. Derived from observed progress, never invented.
  int? etaMs;
  DateTime? _jobStarted;

  // Model cache.
  String? modelsDir;
  final Map<String, int> _downloadPercent = {};
  String? downloadError;
  bool get downloading => _downloadPercent.isNotEmpty;
  int? downloadPercentOf(String name) => _downloadPercent[name];

  int abiVersion = -1;
  bool get ffiReady => abiVersion >= 0;

  // Engine pointer for direct native polling of kk_last_progress() while the
  // worker isolate is blocked inside whisper_full().
  int? _enginePtr;
  Timer? _progressTimer;

  void _updateProgress(int pct) {
    // Reused engines keep the previous job's percentage until the new decode
    // starts. Progress outside the transcribing stage is therefore stale.
    if (stage != JobStage.transcribing) return;
    progress = pct;
    final started = _jobStarted;
    if (started != null) {
      final sample = estimateRemainingMs(
        DateTime.now().difference(started).inMilliseconds,
        pct,
      );
      if (sample != null) etaMs = smoothEtaMs(etaMs, sample);
    }
    NotificationService.instance.showProgress(pct);
    notifyListeners();
  }

  void _startProgressPolling() {
    _progressTimer?.cancel();
    final addr = _enginePtr;
    if (addr == null) return;
    _progressTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      // A reused engine keeps the previous job's percentage until the new
      // decode starts. Ignore polling outside the transcribing stage so that
      // stale value can never flash 100 percent on a fresh job.
      if (stage != JobStage.transcribing) return;
      try {
        final lib = KikoeFFI.load();
        final pct = lib.lastProgress(Pointer<Void>.fromAddress(addr));
        if (pct >= 0 && pct <= 100 && pct != progress) {
          _updateProgress(pct);
        }
      } catch (_) {
        // If FFI is unavailable we simply show the indeterminate bar.
      }
    });
  }

  void _stopProgressPolling() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  /// User-imported ggml models (persisted as JSON in SharedPreferences).
  List<MobileModel> customModels = [];

  MobileModel? get selectedModel {
    final builtIn = findMobileModel(modelName);
    if (builtIn != null) return builtIn;
    for (final m in customModels) {
      if (m.name == modelName) return m;
    }
    return null;
  }

  bool modelCached(MobileModel model) {
    final dir = modelsDir;
    if (dir == null) return false;
    return File(p.join(dir, model.filename)).existsSync();
  }

  bool get selectedModelCached =>
      selectedModel != null && modelCached(selectedModel!);

  /// Replace the segment list wholesale (used by the transcript editor).
  void replaceSegments(List<Segment> edited) {
    segments
      ..clear()
      ..addAll(edited);
    notifyListeners();
  }

  String? get selectedModelPath {
    final model = selectedModel;
    final dir = modelsDir;
    if (model == null || dir == null) return null;
    return model.cachedPath(dir);
  }

  static const List<String> languages = [
    'auto', 'id', 'en', 'ja', 'zh', 'ko', 'ms', 'vi', 'th',
    'ar', 'de', 'es', 'fr', 'pt', 'ru', 'hi',
  ];

  static const List<String> formats = ['srt', 'txt', 'vtt', 'json', 'md', 'csv'];

  Future<void> ensureStarted() async {
    await _loadSettings();
    try {
      await NotificationService.instance.init();
    } catch (e) {
      if (kDebugMode) debugPrint('notifications unavailable: $e');
    }
    try {
      const channel = MethodChannel('kikoe/files');
      legacyStorageState = await channel.invokeMethod<int>('legacyStoragePermissionState') ?? 0;
      // Detect first launch with a marker file so the notice shows once.
      final docs = await getApplicationDocumentsDirectory();
      storageNoticeShown = File(p.join(docs.path, '.kikoe_storage_notice_shown')).existsSync();
      final dir = Directory(p.join(docs.path, 'kikoe_models'));
      await dir.create(recursive: true);
      modelsDir = dir.path;
      await transcriber.start();
    } catch (e) {
      debugPrint('worker start failed: $e');
    }
    notifyListeners();
  }

  static const _kPrefsModel = 'kikoe_model';
  static const _kPrefsLanguage = 'kikoe_language';
  static const _kPrefsTranslate = 'kikoe_translate';
  static const _kPrefsVad = 'kikoe_vad';
  static const _kPrefsPrompt = 'kikoe_initial_prompt';
  static const _kPrefsAutoSave = 'kikoe_auto_save';
  static const _kPrefsCustomModels = 'kikoe_custom_models';
  static const _kPrefsQuality = 'kikoe_quality';
  static const _kPrefsSpeedMode = 'kikoe_speed_mode';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      modelName = prefs.getString(_kPrefsModel) ?? modelName;
      language = prefs.getString(_kPrefsLanguage) ?? language;
      translate = prefs.getBool(_kPrefsTranslate) ?? translate;
      useVad = prefs.getBool(_kPrefsVad) ?? useVad;
      initialPrompt = prefs.getString(_kPrefsPrompt) ?? initialPrompt;
      autoSave = prefs.getBool(_kPrefsAutoSave) ?? autoSave;
      quality = prefs.getInt(_kPrefsQuality) ?? quality;
      speedMode = prefs.getString(_kPrefsSpeedMode) ?? speedMode;
      final rawCustom = prefs.getString(_kPrefsCustomModels);
      if (rawCustom != null && rawCustom.isNotEmpty) {
        try {
          final list = jsonDecode(rawCustom) as List<dynamic>;
          customModels = list
              .map((e) => MobileModel(
                    e['name'] as String,
                    e['filename'] as String,
                    e['size'] as int,
                    '',
                    'imported model',
                    customPath: e['path'] as String,
                  ))
              .toList();
        } catch (_) {
          customModels = [];
        }
      }
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
      await prefs.setBool(_kPrefsVad, useVad);
      await prefs.setBool(_kPrefsAutoSave, autoSave);
      await prefs.setInt(_kPrefsQuality, quality);
      await prefs.setString(_kPrefsSpeedMode, speedMode);
      await prefs.setString(
          _kPrefsCustomModels,
          jsonEncode(customModels
              .map((m) => {
                    'name': m.name,
                    'filename': m.filename,
                    'size': m.sizeBytes,
                    'path': m.customPath,
                  })
              .toList()));
      if (initialPrompt.isEmpty) {
        await prefs.remove(_kPrefsPrompt);
      } else {
        await prefs.setString(_kPrefsPrompt, initialPrompt);
      }
    } catch (_) {
      // Best-effort persistence.
    }
  }

  /// Silero VAD model name (no whisper picker entry; downloads on first toggle).
  static const vadModelName = 'vad-silero';
  static const vadModelFile = 'ggml-silero-v6.2.0.bin';

  String get vadModelPath => p.join(modelsDir ?? '', vadModelFile);

  bool get vadReady => modelsDir != null && File(vadModelPath).existsSync();

  /// Toggle VAD silence filtering; downloads the Silero model on first use.
  void setUseVad(bool value) {
    useVad = value;
    notifyListeners();
    _saveSettings();
    if (value && !vadReady && !_downloadPercent.containsKey(vadModelName)) {
      downloadModel(vadModelName);
    }
  }

  /// Marks the storage notice as shown (first-launch flag).
  Future<void> markStorageNoticeShown() async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      await File(p.join(docs.path, '.kikoe_storage_notice_shown')).writeAsString('1');
    } catch (_) {
      // Best-effort; the notice may show again next launch.
    }
    storageNoticeShown = true;
    notifyListeners();
  }

  /// Request WRITE_EXTERNAL_STORAGE on Android 9 and below.
  Future<void> requestLegacyStoragePermission() async {
    try {
      const channel = MethodChannel('kikoe/files');
      await channel.invokeMethod<int>('requestLegacyStoragePermission');
      legacyStorageState = 3;
    } catch (_) {
      // Non-fatal; saves via MediaStore on Android 10+ anyway.
    }
    notifyListeners();
  }

  /// Reset all job state when the input changes. A job still running for the
  /// old file is cancelled so its late events cannot land in the new result.
  void _resetJobState() {
    if (stage == JobStage.decoding || stage == JobStage.transcribing) {
      transcriber.cancel();
    }
    activeJobId = null;
    _jobStarted = null;
    etaMs = null;
    _stopProgressPolling();
    stage = JobStage.idle;
    progress = 0;
    error = null;
    segments.clear();
    outputPath = null;
    savedLocation = '';
    saveError = null;
  }

  /// Set the input file and reset state. Does not start the job; call
  /// [transcribe] or let the UI trigger it. A single file share resets the
  /// queue to just this file.
  void setInput(String path) {
    _resetJobState();
    queue = [path];
    queueIndex = 0;
    inputPath = path;
    notifyListeners();
  }

  /// Queue several files (multi-file share or multi-pick). The first file
  /// becomes the active input.
  void setInputs(List<String> paths) {
    final cleaned = paths.where((p) => p.isNotEmpty).toList();
    if (cleaned.isEmpty) return;
    _resetJobState();
    queue = cleaned;
    queueIndex = 0;
    inputPath = cleaned.first;
    notifyListeners();
  }

  /// Advance to the next queued file. Returns true when there is one.
  bool advanceQueue() {
    if (!hasNextInQueue) return false;
    _resetJobState();
    queueIndex += 1;
    inputPath = queue[queueIndex];
    notifyListeners();
    return true;
  }

  void setModel(String name) {
    modelName = name;
    downloadError = null;
    notifyListeners();
    _saveSettings();
  }

  /// Apply one of the three speed and quality presets. All registry models
  /// stay available through the model picker; a preset only sets a starting
  /// point that the user can override afterwards.
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
    if (!vadReady && !_downloadPercent.containsKey(vadModelName)) {
      downloadModel(vadModelName);
    }
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

  /// Copy an imported ggml model into the models dir and register it.
  Future<void> importModel(String sourcePath, String displayName) async {
    final dir = modelsDir;
    if (dir == null) return;
    await Directory(dir).create(recursive: true);
    final safe = displayName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final name = safe.endsWith('.bin') ? safe : '$safe.bin';
    final target = p.join(dir, 'custom_${DateTime.now().millisecondsSinceEpoch}_$name');
    final size = await File(sourcePath).length();
    await File(sourcePath).copy(target);
    customModels.add(MobileModel(name, p.basename(target), size, '', 'imported model',
        customPath: target));
    modelName = name;
    notifyListeners();
    await _saveSettings();
  }

  /// Delete a custom model file and its registry entry.
  Future<void> removeCustomModel(MobileModel model) async {
    try {
      await File(model.customPath!).delete();
    } catch (_) {}
    customModels.removeWhere((m) => m.name == model.name);
    if (modelName == model.name) modelName = 'small-q5_1';
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

  /// Decode media through the platform, transcribe with the FFI core, and
  /// report progress. Safe to call once per [setInput]; a new job is ignored
  /// while one is running.
  Future<void> transcribe() async {
    final path = inputPath;
    if (path == null) return;
    if (stage == JobStage.decoding || stage == JobStage.transcribing) return;
    final modelPath = selectedModelPath;
    if (modelPath == null) return;

    final jobId = _jobId(path);
    activeJobId = jobId;
    _jobStarted = null;
    etaMs = null;
    stage = JobStage.decoding;
    progress = 0;
    error = null;
    segments.clear();
    outputPath = null;
    notifyListeners();

    Float32List samples;
    try {
      samples = await _decodeToPcm(path);
    } on PlatformException catch (e) {
      _fail('Decode failed: ${e.message ?? e.code}');
      return;
    } catch (e) {
      _fail('Decode failed: $e');
      return;
    }
    // A new input may have replaced this one while decoding. Its reset already
    // cleared activeJobId, so drop this stale job instead of running it.
    if (activeJobId != jobId) return;

    // Start the clock here, not before decoding. Media decode emits no
    // percentage, so counting it would inflate the finish estimate.
    _jobStarted = DateTime.now();
    stage = JobStage.transcribing;
    notifyListeners();
    await NotificationService.instance.showProgress(0);

    transcriber.transcribePcm(
      id: jobId,
      samples: samples,
      modelPath: modelPath,
      language: language,
      translate: translate,
      initialPrompt: initialPrompt,
      vadModelPath: useVad && vadReady ? vadModelPath : null,
      quality: quality,
    );
  }

  void cancelCurrent() {
    if (stage == JobStage.transcribing) {
      transcriber.cancel();
    }
    NotificationService.instance.cancel();
  }

  void downloadModel(String name) {
    final model = findMobileModel(name);
    if (model == null || _downloadPercent.containsKey(name)) return;
    final dir = modelsDir;
    if (dir == null) return;
    _downloadPercent[name] = 0;
    downloadError = null;
    notifyListeners();
    unawaited(_download(model, dir));
  }

  Future<void> _download(MobileModel model, String dir) async {
    try {
      await ModelDownloader.instance.download(
        model,
        modelDir: dir,
        onProgress: (percent) {
          _downloadPercent[model.name] = percent;
          notifyListeners();
        },
      );
      _downloadPercent.remove(model.name);
    } catch (e) {
      _downloadPercent.remove(model.name);
      downloadError = e.toString();
    }
    notifyListeners();
  }

  void _fail(String message) {
    stage = JobStage.failed;
    error = message;
    notifyListeners();
  }

  String _jobId(String path) =>
      '${DateTime.now().microsecondsSinceEpoch}-${path.hashCode}';

  Future<Float32List> _decodeToPcm(String path) async {
    const channel = MethodChannel('kikoe/decode');
    final result = await channel.invokeMethod<Uint8List>('decode', {'path': path});
    if (result == null || result.length < 4 || result.length % 4 != 0) {
      throw Exception('decoder returned invalid PCM (${result?.length ?? 0} bytes)');
    }
    // The platform may hand us a view into a larger buffer at any byte
    // offset, so decode with byte-level reads into a fresh aligned list.
    final data = ByteData.sublistView(result);
    final out = Float32List(result.lengthInBytes ~/ 4);
    for (var i = 0; i < out.length; i++) {
      out[i] = data.getFloat32(i * 4, Endian.little);
    }
    return out;
  }

  /// Render [format] from the current segments and save it into
  /// Downloads/kikoe. Fire-and-forget; [onReady] is called once written.
  void saveTranscription(String format, void Function(String location) onReady) {
    final rendered = _renderNow(format);
    if (rendered.isEmpty) return;
    unawaited(_saveExport(rendered, format, onReady));
  }

  Future<void> _saveExport(String content, String format, void Function(String location) onReady) async {
    final name = (inputPath != null) ? p.basenameWithoutExtension(inputPath!) : 'kikoe';
    final fileName = '${name}_kikoe.$format';
    try {
      const channel = MethodChannel('kikoe/files');
      final location = await channel.invokeMethod<String>('saveToDownloads', {
        'name': fileName,
        'content': content,
      });
      savedLocation = location ?? 'Downloads/kikoe/$fileName';
      notifyListeners();
      onReady(savedLocation);
    } catch (e) {
      saveError = '$e';
      notifyListeners();
    }
  }

  /// Share the last transcription via the system share sheet.
  void shareTranscription(String format, void Function(String path) onReady) {
    final rendered = _renderNow(format);
    if (rendered.isEmpty) return;
    unawaited(_writeShareFile(rendered, format, onReady));
  }

  Future<void> _writeShareFile(String content, String format, void Function(String path) onReady) async {
    final name = (inputPath != null) ? p.basenameWithoutExtension(inputPath!) : 'kikoe';
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, '${name}_kikoe.$format'));
    await file.writeAsString(content);
    outputPath = file.path;
    notifyListeners();
    onReady(file.path);
  }

  /// Render the current segments as [format] using the Dart renderer.
  String _renderNow(String format) {
    if (segments.isEmpty) return '';
    return renderFormat(
      segments.map((s) => RenderSegment(s.startMs, s.endMs, s.text)).toList(),
      format,
    );
  }

  /// Empty ids come from engine-level failures before a job exists; those are
  /// always applied. Everything else must match the active job.
  bool _isCurrentJob(String id) => id.isEmpty || id == activeJobId;

  void _onEvent(TranscriberEvent event) {
    switch (event) {
      case Ready():
        abiVersion = event.abiVersion;
        notifyListeners();
      case EngineReady():
        _enginePtr = event.ptr;
        _startProgressPolling();
        notifyListeners();
      case TranscribeProgress():
        if (!_isCurrentJob(event.id)) return;
        _updateProgress(event.percent);
      case SegmentReady():
        if (!_isCurrentJob(event.id)) return;
        segments.add(Segment(event.startMs, event.endMs, event.text));
        notifyListeners();
      case TranscribeDone():
        if (!_isCurrentJob(event.id)) return;
        activeJobId = null;
        _jobStarted = null;
        etaMs = null;
        stage = JobStage.done;
        progress = 100;
        _stopProgressPolling();
        NotificationService.instance.cancel();
        NotificationService.instance.showDone(p.basename(inputPath ?? 'file'));
        // Persist to history (bounded, local JSON files).
        final snapshot = segments.toList();
        unawaited(HistoryStore.instance.add(
          fileName: p.basename(inputPath ?? 'file'),
          segments: snapshot
              .map((s) => RenderSegment(s.startMs, s.endMs, s.text))
              .toList(),
        ));
        if (autoSave) saveTranscription('srt', (_) {});
        notifyListeners();
      case TranscribeFailed():
        if (!_isCurrentJob(event.id)) return;
        activeJobId = null;
        _jobStarted = null;
        etaMs = null;
        stage = event.cancelled ? JobStage.cancelled : JobStage.failed;
        error = event.message;
        _stopProgressPolling();
        NotificationService.instance.cancel();
        notifyListeners();
      case FormatResult():
        // Formats are rendered locally now; the worker's format result is unused.
        break;
    }
  }

  @override
  void dispose() {
    _stopProgressPolling();
    _sub?.cancel();
    try {
      NotificationService.instance.cancel();
    } catch (_) {
      // Notifications plugin may be unavailable (tests, headless runs).
    }
    transcriber.dispose();
    super.dispose();
  }
}
