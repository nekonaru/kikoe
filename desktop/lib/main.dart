// Kikoe desktop app. Dark, single-window, drag & drop friendly.
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import 'src/app_state.dart';
import 'src/model_menu.dart';
import 'src/queue_item.dart';

const kBrand = Color(0xFFE8492D);
const kBg = Color(0xFF141414);
const kSurface = Color(0xFF1F1F1F);
const kSurface2 = Color(0xFF2A2A2A);
const kText = Color(0xFFF4F1EC);
const kDim = Color(0xFF9B988F);

void main() {
  runApp(const KikoeApp());
}

class KikoeApp extends StatelessWidget {
  const KikoeApp({super.key, this.state});

  final AppState? state;

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
        fontFamily: 'Segoe UI',
      ),
      home: KikoeHome(state: state ?? AppState()),
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
  AppState get s => widget.state;

  @override
  void initState() {
    super.initState();
    s.ensureStarted();
  }

  @override
  void dispose() {
    s.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const [
        'wav', 'mp3', 'm4a', 'flac', 'ogg', 'aac', 'wma', 'opus',
        'mp4', 'mkv', 'mov', 'webm', 'avi',
      ],
    );
    if (result == null) return;
    s.addFiles(result.paths.whereType<String>());
  }

  Future<void> _pickOutDir() async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choose output folder',
    );
    if (dir != null) s.setCustomOutDir(dir);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: s,
      builder: (context, _) {
        return Scaffold(
          body: Column(
            children: [
              _Header(state: s),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ControlPanel(
                      state: s,
                      onPickFiles: _pickFiles,
                      onPickOutDir: _pickOutDir,
                    ),
                    Expanded(
                      child: _QueuePanel(state: s, onPickFiles: _pickFiles),
                    ),
                  ],
                ),
              ),
              _StatusBar(state: s),
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kSurface2)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset('assets/icon.png', width: 44, height: 44),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kikoe',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kText,
                  letterSpacing: 0.2,
                ),
              ),
              const Text(
                '聞こえ · offline audio & video transcription',
                style: TextStyle(fontSize: 12, color: kDim),
              ),
            ],
          ),
          const Spacer(),
          if (!state.ffiReady)
            Tooltip(
              message: state.ffiError ?? 'The kikoe_ffi library did not load. Transcription is unavailable.',
              child: const Icon(Icons.warning_amber_rounded, color: kBrand),
            ),
        ],
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.state,
    required this.onPickFiles,
    required this.onPickOutDir,
  });

  final AppState state;
  final Future<void> Function() onPickFiles;
  final Future<void> Function() onPickOutDir;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final model = s.selectedModel!;
    final downloading = s.downloadingOf(model.name);

    return Container(
      width: 340,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: kSurface2)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionLabel('Model'),
          DropdownButton<String>(
            value: s.modelName,
            isExpanded: true,
            dropdownColor: kSurface,
            items: kModels
                .map((m) => DropdownMenuItem(
                      value: m.name,
                      child: Text(
                        '${m.name}  ·  ${m.sizeMb.toStringAsFixed(0)} MB',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) s.setModel(v);
            },
          ),
          const SizedBox(height: 6),
          if (!s.selectedModelCached)
            _DownloadBlock(state: s, model: model, downloading: downloading)
          else
            Text(
              model.note,
              style: const TextStyle(fontSize: 11, color: kDim),
            ),
          const SizedBox(height: 18),
          const _SectionLabel('Language'),
          DropdownButton<String>(
            value: s.language,
            isExpanded: true,
            dropdownColor: kSurface,
            items: AppState.languages
                .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                .toList(),
            onChanged: (v) {
              if (v != null) s.setLanguage(v);
            },
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Save format'),
          DropdownButton<String>(
            value: s.saveFormat,
            isExpanded: true,
            dropdownColor: kSurface,
            items: AppState.formats
                .map((f) => DropdownMenuItem(value: f, child: Text(f.toUpperCase())))
                .toList(),
            onChanged: (v) {
              if (v != null) s.setSaveFormat(v);
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.customOutDir ?? 'Next to source files',
                  style: const TextStyle(fontSize: 11, color: kDim),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: onPickOutDir,
                child: const Text('Choose…'),
              ),
              if (s.customOutDir != null)
                TextButton(
                  onPressed: () => s.setCustomOutDir(null),
                  child: const Text('Reset'),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const _SectionLabel('Threads'),
          DropdownButton<int>(
            value: s.nThreads,
            isExpanded: true,
            dropdownColor: kSurface,
            items: [
              const DropdownMenuItem(value: 0, child: Text('auto')),
              for (var i = 1; i <= 16; i++)
                DropdownMenuItem(value: i, child: Text('$i')),
            ],
            onChanged: (v) {
              if (v != null) s.setThreads(v);
            },
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            value: s.translate,
            onChanged: s.setTranslate,
            title: const Text('Translate to English'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: s.useGpu,
            onChanged: s.setUseGpu,
            title: const Text('Use GPU (GPU build)'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 18),
          _StartButton(state: s),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onPickFiles,
            icon: const Icon(Icons.file_open_outlined),
            label: const Text('Add files…'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          letterSpacing: 1.4,
          color: kDim,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DownloadBlock extends StatelessWidget {
  const _DownloadBlock({required this.state, required this.model, required this.downloading});

  final AppState state;
  final ModelEntry model;
  final bool downloading;

  @override
  Widget build(BuildContext context) {
    if (downloading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Downloading ${model.name}.',
              style: const TextStyle(fontSize: 12, color: kText)),
          const SizedBox(height: 6),
          const LinearProgressIndicator(color: kBrand),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Not downloaded yet. Kikoe needs the model file on this device once; after that, everything runs offline.',
          style: const TextStyle(fontSize: 11, color: kDim),
        ),
        const SizedBox(height: 6),
        FilledButton.tonalIcon(
          onPressed: state.downloadSelectedModel,
          icon: const Icon(Icons.download),
          label: Text('Download ${model.name} (${model.sizeMb.toStringAsFixed(0)} MB)'),
        ),
      ],
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final pending = state.items.any((i) => i.status == QueueStatus.pending);
    if (state.busy) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: state.cancelCurrent,
          style: FilledButton.styleFrom(backgroundColor: kSurface2, foregroundColor: kText),
          icon: const Icon(Icons.stop),
          label: const Text('Cancel'),
        ),
      );
    }
    final canStart = pending && state.selectedModelCached;
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: FilledButton.icon(
        onPressed: canStart ? state.start : null,
        style: FilledButton.styleFrom(backgroundColor: kBrand),
        icon: const Icon(Icons.play_arrow),
        label: Text(state.selectedModelCached ? 'Transcribe' : 'Download the model first'),
      ),
    );
  }
}

class _QueuePanel extends StatelessWidget {
  const _QueuePanel({required this.state, required this.onPickFiles});

  final AppState state;
  final Future<void> Function() onPickFiles;

  static const _supported =
      'wav, mp3, m4a, flac, ogg, aac · mp4, mkv, mov, webm';

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (details) => state.addFiles(
        details.files.map((f) => f.path).whereType<String>(),
      ),
      child: Container(
        decoration: const BoxDecoration(color: kBg),
        child: state.items.isEmpty
            ? _DropHint(onTap: onPickFiles)
            : ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: state.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) => _ItemTile(item: state.items[i], state: state),
              ),
      ),
    );
  }
}

class _DropHint extends StatelessWidget {
  const _DropHint({required this.onTap});

  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(36),
          decoration: BoxDecoration(
            border: Border.all(color: kSurface2, width: 2, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.audio_file, size: 56, color: kBrand),
              const SizedBox(height: 16),
              const Text(
                'Drop audio or video files here',
                style: TextStyle(fontSize: 17, color: kText, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              const Text('or click to browse', style: TextStyle(color: kDim)),
              const SizedBox(height: 14),
              Text(
                'Supports ${_QueuePanel._supported}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: kDim),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({required this.item, required this.state});

  final QueueItem item;
  final AppState state;

  IconData get _icon {
    final ext = p.extension(item.path).toLowerCase();
    const audio = {'.wav', '.mp3', '.m4a', '.flac', '.ogg', '.aac', '.wma', '.opus'};
    return audio.contains(ext) ? Icons.audiotrack : Icons.movie;
  }

  String get _status {
    switch (item.status) {
      case QueueStatus.pending:
        return 'pending';
      case QueueStatus.transcribing:
        return 'transcribing… ${item.progress}%';
      case QueueStatus.done:
        return item.outputPath != null ? 'saved to ${item.outputPath}' : 'done';
      case QueueStatus.failed:
        return 'failed: ${item.error ?? 'unknown error'}';
      case QueueStatus.cancelled:
        return 'cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    final running = item.status == QueueStatus.transcribing;
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: running ? kBrand : kSurface2,
          width: running ? 1.6 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_icon, color: kDim),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: kText, fontWeight: FontWeight.w600),
                  ),
                ),
                if (item.status == QueueStatus.done)
                  const Icon(Icons.check_circle, color: Color(0xFF6FCF97), size: 18)
                else if (item.status == QueueStatus.failed)
                  const Icon(Icons.error_outline, color: kBrand, size: 18),
                IconButton(
                  icon: Icon(running ? Icons.stop_circle_outlined : Icons.close),
                  onPressed: () => state.removeItem(item),
                  tooltip: running ? 'Cancel' : 'Remove',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(_status, style: const TextStyle(fontSize: 11, color: kDim)),
            if (running) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: item.progress > 0 ? item.progress / 100 : null, color: kBrand),
            ],
            if (item.segments.isNotEmpty) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                title: const Text('Preview', style: TextStyle(fontSize: 12, color: kDim)),
                tilePadding: EdgeInsets.zero,
                dense: true,
                children: [
                  for (final seg in item.segments.take(50))
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Text(
                          seg.text,
                          style: const TextStyle(fontSize: 12, color: kText),
                        ),
                      ),
                    ),
                  if (item.segments.length > 50)
                    Text('… ${item.segments.length - 50} more lines',
                        style: const TextStyle(fontSize: 11, color: kDim)),
                ],
              ),
            ],
            if (item.status == QueueStatus.done)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    for (final f in AppState.formats)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: OutlinedButton(
                          onPressed: () => state.saveItem(item, f),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            minimumSize: const Size(0, 30),
                          ),
                          child: Text('Save ${f.toUpperCase()}'),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final done = state.items.where((i) => i.status == QueueStatus.done).length;
    final total = state.items.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: kSurface2)),
      ),
      child: Row(
        children: [
          Text(
            total == 0 ? 'No files queued' : '$done/$total done',
            style: const TextStyle(fontSize: 11, color: kDim),
          ),
          const Spacer(),
          Text(
            '100% offline · no telemetry',
            style: const TextStyle(fontSize: 11, color: kDim),
          ),
        ],
      ),
    );
  }
}
