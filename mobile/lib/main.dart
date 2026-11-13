// Kikoe Android. Single screen: pick a file (or receive one via share),
// transcribe fully on-device, then share or save the result.
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:share_plus/share_plus.dart';

import 'src/app_state.dart';
import 'src/model_menu.dart';

const kBrand = Color(0xFFE8492D);
const kBg = Color(0xFF141414);
const kSurface = Color(0xFF1F1F1F);
const kSurface2 = Color(0xFF2A2A2A);
const kText = Color(0xFFF4F1EC);
const kDim = Color(0xFF9B988F);

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
        _loadShared(initial.first.path);
      }
    } catch (e) {
      debugPrint('share intent read failed: $e');
    }
    ReceiveSharingIntent.instance.getMediaStream().listen((files) {
      if (files.isNotEmpty) {
        _loadShared(files.first.path);
      }
    });
  }

  void _loadShared(String path) {
    s.setInput(path);
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

class KikoeHome extends StatelessWidget {
  const KikoeHome({super.key, required this.state});

  final AppState state;

  Future<void> _pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'wav', 'mp3', 'm4a', 'flac', 'ogg', 'aac', 'wma', 'opus',
        'mp4', 'mkv', 'mov', 'webm', 'avi', '3gp',
      ],
    );
    if (result == null || result.files.single.path == null) return;
    state.setInput(result.files.single.path!);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: kSurface,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset('assets/icon.png', width: 28, height: 28),
                ),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kikoe',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: kText)),
                    Text('聞こえ · offline', style: TextStyle(fontSize: 10, color: kDim)),
                  ],
                ),
              ],
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.inputPath == null)
                  _PickCard(onTap: () => _pickFile(context))
                else
                  _FileCard(state: state, onChange: () => _pickFile(context)),
                const SizedBox(height: 14),
                _ModelSection(state: state),
                const SizedBox(height: 14),
                _OptionsSection(state: state),
                const SizedBox(height: 16),
                _ActionButton(state: state),
                if (state.stage == JobStage.decoding || state.stage == JobStage.transcribing) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: state.stage == JobStage.decoding ? null : state.progress / 100,
                    backgroundColor: kSurface2,
                    color: kBrand,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    state.stage == JobStage.decoding ? 'Decoding media…' : 'Transcribing… ${state.progress}%',
                    style: const TextStyle(fontSize: 12, color: kDim),
                  ),
                ],
                if (state.error != null && state.stage == JobStage.failed) ...[
                  const SizedBox(height: 12),
                  _ErrorCard(message: state.error!),
                ],
                if (state.segments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text('TRANSCRIPT',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.4,
                          color: kDim,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Card(
                    color: kSurface,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: SelectableText(
                        state.segments.map((s) => s.text).join(),
                        style: const TextStyle(fontSize: 13, color: kText, height: 1.45),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in AppState.formats)
                        FilledButton.tonal(
                          onPressed: () => _shareExport(state, f),
                          child: Text('Share ${f.toUpperCase()}'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareExport(AppState state, String format) async {
    state.exportTranscription(format, (path) async {
      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: 'Kikoe transcript'),
      );
    });
  }
}

class _PickCard extends StatelessWidget {
  const _PickCard({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: kSurface2,
                child: Icon(Icons.audio_file, size: 38, color: kBrand),
              ),
              SizedBox(height: 14),
              Text('Pick an audio or video file',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: kText)),
              SizedBox(height: 6),
              Text(
                'Or share a file to Kikoe from any app.\nEverything runs on this device.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: kDim, height: 1.4),
              ),
            ],
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
    return Card(
      color: kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(isAudio ? Icons.audiotrack : Icons.movie, color: kBrand, size: 28),
        title: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: kText, fontWeight: FontWeight.w600)),
        subtitle: Text(
          sizeKb == null ? '' : '${(sizeKb / 1024).toStringAsFixed(1)} MB',
          style: const TextStyle(color: kDim, fontSize: 11),
        ),
        trailing: TextButton(onPressed: onChange, child: const Text('Change')),
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
    return Card(
      color: kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MODEL', style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: kDim, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
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
            const SizedBox(height: 8),
            if (percent != null) ...[
              Text('Downloading ${model.name}… $percent%', style: const TextStyle(fontSize: 12, color: kText)),
              const SizedBox(height: 6),
              LinearProgressIndicator(value: percent / 100, backgroundColor: kSurface2, color: kBrand),
            ] else if (!cached) ...[
              Text(
                'One-time download, then fully offline. ${model.sizeMb.toStringAsFixed(0)} MB.',
                style: const TextStyle(fontSize: 11, color: kDim),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => state.downloadModel(model.name),
                icon: const Icon(Icons.download),
                label: Text('Download ${model.name}'),
              ),
              if (state.downloadError != null) ...[
                const SizedBox(height: 6),
                Text(state.downloadError!, style: const TextStyle(fontSize: 11, color: kBrand)),
              ],
            ] else
              Text('${model.note} · cached, works offline', style: const TextStyle(fontSize: 11, color: kDim)),
          ],
        ),
      ),
    );
  }
}

class _OptionsSection extends StatelessWidget {
  const _OptionsSection({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('OPTIONS', style: TextStyle(fontSize: 10, letterSpacing: 1.4, color: kDim, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
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
          ],
        ),
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
        height: 52,
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
      height: 52,
      child: FilledButton.icon(
        onPressed: ready ? state.transcribe : null,
        style: FilledButton.styleFrom(backgroundColor: kBrand),
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
      color: Color.fromARGB(255, 46, 22, 18),
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
