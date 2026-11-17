// Kikoe Android. Single screen: pick a file (or receive one via share),
// transcribe fully on-device, then save or share the result.
import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share_plus/share_plus.dart';

import 'src/about_screen.dart';
import 'src/app_state.dart';
import 'src/faq_screen.dart';
import 'src/kikoe_theme.dart';
import 'src/model_menu.dart';

void main() {
  runApp(const KikoeApp());
}

class KikoeApp extends StatefulWidget {
  const KikoeApp({super.key, this.state});

  final AppState? state;

  @override
  State<KikoeApp> createState() => _KikoeAppState();
}

class _KikoeAppState extends State<KikoeApp> {
  late final AppState s;

  @override
  void initState() {
    super.initState();
    s = widget.state ?? AppState();
    s.ensureStarted();
    _listenForSharedMedia();
  }

  Future<void> _listenForSharedMedia() async {
    try {
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      if (initial.isNotEmpty) {
        _loadSharedList(initial.map((f) => f.path).toList());
      }
    } catch (e) {
      debugPrint('share intent read failed: $e');
    }
    ReceiveSharingIntent.instance.getMediaStream().listen((files) {
      if (files.isNotEmpty) {
        _loadSharedList(files.map((f) => f.path).toList());
      }
    });
  }

  void _loadSharedList(List<String> paths) {
    s.setInputs(paths);
    // Auto-start when a file arrives via share; the user asked for it.
    if (s.selectedModelCached) {
      s.transcribe();
    }
  }

  @override
  void dispose() {
    s.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kikoe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(
          primary: kBrand,
          secondary: kBrand,
          surface: kSurface,
          onSurface: kText,
        ),
        useMaterial3: true,
      ),
      home: KikoeHome(state: s),
    );
  }
}

class KikoeHome extends StatefulWidget {
  const KikoeHome({super.key, required this.state});

  final AppState state;

  @override
  State<KikoeHome> createState() => _KikoeHomeState();
}

class _KikoeHomeState extends State<KikoeHome> {
  AppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    state.addListener(_onStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowStorageNotice());
  }

  @override
  void dispose() {
    state.removeListener(_onStateChanged);
    super.dispose();
  }

  String? _notifiedLocation;
  String? _notifiedError;

  void _onStateChanged() {
    final loc = state.savedLocation.isEmpty ? null : state.savedLocation;
    if (loc != null && loc != _notifiedLocation && mounted) {
      _notifiedLocation = loc;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Saved to $loc'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
    final err = state.saveError;
    if (err != null && err != _notifiedError && mounted) {
      _notifiedError = err;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Could not save: $err'),
          backgroundColor: const Color(0xFF3A241E),
        ),
      );
    }
  }

  Future<void> _maybeShowStorageNotice() async {
    if (state.storageNoticeShown) return;
    if (state.legacyStorageState < 0) return; // worker not ready yet
    // 0 = not needed (API 29+), 1 = granted. Only the legacy case needs action.
    if (state.legacyStorageState == 2) {
      final allow = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.folder_open, color: kBrand),
          title: const Text('Save transcripts to Downloads'),
          content: const Text(
            'Kikoe saves your transcripts into Downloads/kikoe so they are easy to find. '
            'On this Android version, that needs the storage permission. '
            'Your audio files never leave the device either way.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Not now'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Allow'),
            ),
          ],
        ),
      );
      if (allow == true) {
        await state.requestLegacyStoragePermission();
      }
    }
    await state.markStorageNoticeShown();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: true,
      allowedExtensions: const [
        'wav', 'mp3', 'm4a', 'flac', 'ogg', 'aac', 'wma', 'opus',
        'mp4', 'mkv', 'mov', 'webm', 'avi', '3gp',
      ],
    );
    if (result == null) return;
    final paths = result.files.map((f) => f.path).whereType<String>().toList();
    if (paths.isEmpty) return;
    if (paths.length == 1) {
      state.setInput(paths.single);
    } else {
      state.setInputs(paths);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: kSurface,
            titleSpacing: 12,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.asset('assets/icon.png', width: 30, height: 30),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kikoe',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 17, color: kText, letterSpacing: 0.3)),
                    Text('聞こえ · offline', style: TextStyle(fontSize: 10, color: kDim)),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'FAQ',
                icon: const Icon(Icons.help_outline, color: kText),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FaqScreen()),
                ),
              ),
              IconButton(
                tooltip: 'About',
                icon: const Icon(Icons.info_outline, color: kText),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                if (state.inputPath == null)
                  _PickCard(onTap: _pickFile)
                else
                  _FileCard(state: state, onChange: _pickFile),
                if (state.queue.length > 1) ...[
                  const SizedBox(height: 10),
                  _QueueStrip(state: state),
                ],
                const SizedBox(height: 14),
                _ModelSection(state: state),
                const SizedBox(height: 14),
                _OptionsSection(state: state),
                const SizedBox(height: 16),
                _ActionButton(state: state),
                if (state.stage == JobStage.done && state.hasNextInQueue) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () {
                        state.advanceQueue();
                        if (state.selectedModelCached) {
                          state.transcribe();
                        }
                      },
                      icon: const Icon(Icons.skip_next),
                      label: Text('Next: ${p.basename(state.queue[state.queueIndex + 1])}'),
                    ),
                  ),
                ],
                if (state.stage == JobStage.decoding || state.stage == JobStage.transcribing) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: state.stage == JobStage.decoding ? null : state.progress / 100,
                    backgroundColor: kSurface2,
                    color: kBrand,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.stage == JobStage.decoding
                        ? 'Decoding media…'
                        : state.progress > 0
                            ? 'Transcribing… ${state.progress}%'
                            : 'Transcribing…',
                    style: const TextStyle(fontSize: 12, color: kDim),
                  ),
                ],
                if (state.error != null && state.stage == JobStage.failed) ...[
                  const SizedBox(height: 12),
                  _ErrorCard(message: state.error!),
                ],
                if (state.segments.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SectionLabel('Transcript'),
                      IconButton(
                        tooltip: 'Copy transcript',
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: state.segments.map((s) => s.text.trim()).where((t) => t.isNotEmpty).join('\n'),
                            ),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transcript copied to clipboard'),
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.content_copy, color: kDim, size: 20),
                      ),
                    ],
                  ),
                  SectionCard(
                    child: SelectableText(
                      state.segments.map((s) => s.text).join(),
                      style: const TextStyle(fontSize: 13.5, color: kText, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const SectionLabel('Save or share'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in AppState.formats)
                        FilledButton.tonalIcon(
                          onPressed: () => state.saveTranscription(f, (_) {}),
                          icon: const Icon(Icons.save_alt, size: 18),
                          label: Text(f.toUpperCase()),
                        ),
                      OutlinedButton.icon(
                        onPressed: () => state.shareTranscription('txt', (path) async {
                          await SharePlus.instance.share(
                            ShareParams(files: [XFile(path)], text: 'Kikoe transcript'),
                          );
                        }),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('Share'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Saves into Downloads/kikoe',
                      style: TextStyle(fontSize: 11, color: kDim)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QueueStrip extends StatelessWidget {
  const _QueueStrip({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.playlist_play, color: kBrand, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${state.queue.length} files queued · #${state.queueIndex + 1}',
              style: const TextStyle(fontSize: 12, color: kText, fontWeight: FontWeight.w600),
            ),
          ),
          const Text('Finish file, tap Next',
              style: TextStyle(fontSize: 10, color: kDim)),
        ],
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  const _PickCard({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const RadialGradient(
              center: Alignment(0, -0.9),
              radius: 1.4,
              colors: [kBrandSoft, Colors.transparent],
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 34, horizontal: 20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: kSurface2,
                  child: Icon(Icons.audio_file, size: 42, color: kBrand),
                ),
                SizedBox(height: 16),
                Text('Pick an audio or video file',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kText)),
                SizedBox(height: 8),
                Text(
                  'Or share a file to Kikoe from any app.\nFree, unlimited, 100% offline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: kDim, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.state, required this.onChange});

  final AppState state;
  final Future<void> Function() onChange;

  @override
  Widget build(BuildContext context) {
    final path = state.inputPath!;
    final name = p.basename(path);
    int? sizeKb;
    try {
      sizeKb = File(path).lengthSync() ~/ 1024;
    } catch (_) {
      sizeKb = null;
    }
    final isAudio = const ['.wav', '.mp3', '.m4a', '.flac', '.ogg', '.aac', '.wma', '.opus']
        .any((e) => path.toLowerCase().endsWith(e));
    return SectionCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: kSurface2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(isAudio ? Icons.audiotrack : Icons.movie, color: kBrand, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 14)),
                if (sizeKb != null)
                  Text(
                    (sizeKb / 1024) >= 1024
                        ? '${(sizeKb / 1024 / 1024).toStringAsFixed(2)} GB'
                        : '${(sizeKb / 1024).toStringAsFixed(1)} MB',
                    style: const TextStyle(color: kDim, fontSize: 11),
                  ),
              ],
            ),
          ),
          TextButton(onPressed: onChange, child: const Text('Change')),
        ],
      ),
    );
  }
}

class _ModelSection extends StatelessWidget {
  const _ModelSection({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final model = state.selectedModel!;
    final percent = state.downloadPercentOf(model.name);
    final cached = state.selectedModelCached;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Model'),
          DropdownButton<String>(
            value: state.modelName,
            isExpanded: true,
            dropdownColor: kSurface,
            underline: const SizedBox.shrink(),
            items: kMobileModels
                .map((m) => DropdownMenuItem(
                      value: m.name,
                      child: Text('${m.name}  ·  ${m.sizeMb.toStringAsFixed(0)} MB',
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) state.setModel(v);
            },
          ),
          const SizedBox(height: 10),
          if (percent != null) ...[
            Text('Downloading ${model.name}… $percent%',
                style: const TextStyle(fontSize: 12, color: kText)),
            const SizedBox(height: 8),
            LinearProgressIndicator(
                value: percent / 100, backgroundColor: kSurface2, color: kBrand),
          ] else if (!cached) ...[
            Text(
              'One-time download, then fully offline. ${model.sizeMb.toStringAsFixed(0)} MB.',
              style: const TextStyle(fontSize: 11, color: kDim),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () => state.downloadModel(model.name),
              icon: const Icon(Icons.download),
              label: Text('Download ${model.name}'),
            ),
            if (state.downloadError != null) ...[
              const SizedBox(height: 8),
              Text(state.downloadError!, style: const TextStyle(fontSize: 11, color: kBrand)),
            ],
          ] else
            Text('${model.note} · cached, works offline',
                style: const TextStyle(fontSize: 11, color: kDim)),
        ],
      ),
    );
  }
}

class _OptionsSection extends StatelessWidget {
  const _OptionsSection({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Options'),
          Row(
            children: [
              const Text('Language', style: TextStyle(fontSize: 12, color: kDim)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: state.language,
                  isExpanded: true,
                  dropdownColor: kSurface,
                  underline: const SizedBox.shrink(),
                  items: AppState.languages
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) state.setLanguage(v);
                  },
                ),
              ),
            ],
          ),
          SwitchListTile(
            value: state.translate,
            onChanged: state.setTranslate,
            title: const Text('Translate to English'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: state.useVad,
            onChanged: state.setUseVad,
            title: const Text('Filter silence (VAD)'),
            subtitle: state.useVad && !state.vadReady
                ? const Text('Silero model (0.9 MB) downloads once',
                    style: TextStyle(fontSize: 11))
                : const Text('Skip silent regions with Silero VAD',
                    style: TextStyle(fontSize: 11)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          if (state.downloadPercentOf('vad-silero') != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.download, size: 14, color: kDim),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Downloading Silero VAD model… ${state.downloadPercentOf('vad-silero')}%',
                      style: const TextStyle(fontSize: 11, color: kDim),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    if (state.stage == JobStage.decoding || state.stage == JobStage.transcribing) {
      return SizedBox(
        height: 54,
        child: FilledButton.icon(
          onPressed: state.cancelCurrent,
          style: FilledButton.styleFrom(backgroundColor: kSurface2, foregroundColor: kText),
          icon: const Icon(Icons.stop),
          label: const Text('Cancel'),
        ),
      );
    }
    final ready = state.inputPath != null && state.selectedModelCached;
    final done = state.stage == JobStage.done;
    return SizedBox(
      height: 54,
      child: FilledButton.icon(
        onPressed: ready ? state.transcribe : null,
        style: FilledButton.styleFrom(backgroundColor: kBrand, foregroundColor: Colors.white),
        icon: const Icon(Icons.play_arrow),
        label: Text(done
            ? 'Transcribe again'
            : ready
                ? 'Transcribe'
                : state.inputPath == null
                    ? 'Pick a file first'
                    : 'Download the model first'),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color.fromARGB(255, 46, 22, 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: kBrand),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 12, color: kText))),
          ],
        ),
      ),
    );
  }
}
