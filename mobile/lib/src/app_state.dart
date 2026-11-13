/// Application state for the Kikoe Android app.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'model_downloader.dart';
import 'model_menu.dart';
import 'notification_service.dart';
import 'transcriber.dart';

enum JobStage { idle, decoding, transcribing, done, failed, cancelled }

class Segment {
  const Segment(this.startMs, this.endMs, this.text);
  final int startMs;
  final int endMs;
  final String text;
}

class AppState extends ChangeNotifier {
  AppState() {
    _sub = transcriber.events.listen(_onEvent);
    NotificationService.instance.onCancelRequested = cancelCurrent;
  }

  final Transcriber transcriber = Transcriber();
  StreamSubscription<TranscriberEvent>? _sub;

  // Input.
  String? inputPath;

  // Job state.
  JobStage stage = JobStage.idle;
  int progress = 0;
  String? error;
  final List<Segment> segments = [];
  String? outputPath;

  // Settings.
  String modelName = 'small-q5_1';
  String language = 'auto';
  bool translate = false;

  // Model cache.
  String? modelsDir;
  final Map<String, int> _downloadPercent = {};
  String? downloadError;
  bool get downloading => _downloadPercent.isNotEmpty;
  int? downloadPercentOf(String name) => _downloadPercent[name];

  int abiVersion = -1;
  bool get ffiReady => abiVersion >= 0;

  MobileModel? get selectedModel => findMobileModel(modelName);

  bool modelCached(MobileModel model) {
    final dir = modelsDir;
    if (dir == null) return false;
    return File(p.join(dir, model.filename)).existsSync();
  }

  bool get selectedModelCached =>
      selectedModel != null && modelCached(selectedModel!);

  String? get selectedModelPath {
    final model = selectedModel;
    final dir = modelsDir;
    if (model == null || dir == null) return null;
    return p.join(dir, model.filename);
  }

  static const List<String> languages = [
    'auto', 'id', 'en', 'ja', 'zh', 'ko', 'ms', 'vi', 'th',
    'ar', 'de', 'es', 'fr', 'pt', 'ru', 'hi',
  ];

  static const List<String> formats = ['srt', 'txt', 'vtt', 'json'];

  Future<void> ensureStarted() async {
    try {
      await NotificationService.instance.init();
    } catch (e) {
      debugPrint('notifications unavailable: $e');
    }
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, 'kikoe_models'));
      await dir.create(recursive: true);
      modelsDir = dir.path;
      await transcriber.start();
    } catch (e) {
      debugPrint('worker start failed: $e');
    }
    notifyListeners();
  }

  /// Set the input file and reset state. Does not start the job; call
  /// [transcribe] or let the UI trigger it.
  void setInput(String path) {
    inputPath = path;
    stage = JobStage.idle;
    progress = 0;
    error = null;
    segments.clear();
    outputPath = null;
    notifyListeners();
  }

  void setModel(String name) {
    modelName = name;
    downloadError = null;
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

  /// Decode media through the platform, transcribe with the FFI core, and
  /// report progress. Safe to call once per [setInput]; a new job is ignored
  /// while one is running.
  Future<void> transcribe() async {
    final path = inputPath;
    if (path == null) return;
    if (stage == JobStage.decoding || stage == JobStage.transcribing) return;
    final modelPath = selectedModelPath;
    if (modelPath == null) return;

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

    stage = JobStage.transcribing;
    notifyListeners();
    await NotificationService.instance.showProgress(0);

    transcriber.transcribePcm(
      id: _jobId(path),
      samples: samples,
      modelPath: modelPath,
      language: language,
      translate: translate,
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

  /// Ask the worker to render the last transcription as [format]. The result
  /// arrives as a FormatResult event; [onReady] is called with the file path
  /// once the content is written.
  void exportTranscription(String format, void Function(String path) onReady) {
    if (segments.isEmpty) return;
    transcriber.formatLast('export', format);
    _pendingExport = (path, _) => onReady(path);
  }

  void Function(String path, String content)? _pendingExport;

  void _onEvent(TranscriberEvent event) {
    switch (event) {
      case Ready():
        abiVersion = event.abiVersion;
        notifyListeners();
      case TranscribeProgress():
        progress = event.percent;
        NotificationService.instance.showProgress(progress);
        notifyListeners();
      case SegmentReady():
        segments.add(Segment(event.startMs, event.endMs, event.text));
        notifyListeners();
      case TranscribeDone():
        stage = JobStage.done;
        progress = 100;
        NotificationService.instance.cancel();
        NotificationService.instance.showDone(p.basename(inputPath ?? 'file'));
        notifyListeners();
      case TranscribeFailed():
        stage = event.cancelled ? JobStage.cancelled : JobStage.failed;
        error = event.message;
        NotificationService.instance.cancel();
        notifyListeners();
      case FormatResult():
        final pending = _pendingExport;
        _pendingExport = null;
        if (pending != null && event.content.isNotEmpty) {
          unawaited(_writeExport(event.content, event.format, pending));
        }
        break;
    }
  }

  Future<void> _writeExport(String content, String format, void Function(String, String) cb) async {
    final name = (inputPath != null) ? p.basenameWithoutExtension(inputPath!) : 'kikoe';
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, '${name}_kikoe.$format'));
    await file.writeAsString(content);
    outputPath = file.path;
    notifyListeners();
    cb(file.path, content);
  }

  @override
  void dispose() {
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
