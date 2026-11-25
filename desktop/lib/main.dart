// Kikoe desktop app. Dark, single-window, drag & drop friendly.
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'src/l10n.dart';
import 'src/about_screen.dart';
import 'src/app_state.dart';
import 'src/faq_screen.dart';
import 'src/history_screen.dart';
import 'src/kikoe_theme.dart';
import 'src/model_menu.dart';
import 'src/queue_item.dart';
import 'src/transcript_editor_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await L10n.instance.load();
  runApp(const KikoeApp());
}

class KikoeApp extends StatelessWidget {
  const KikoeApp({super.key, this.state});

  final AppState? state;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: L10n.instance,
      builder: (context, _) => MaterialApp(
      title: 'Kikoe',
      locale: L10n.instance.flutterLocale,
      supportedLocales: const [Locale('en'), Locale('id')],
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
      ),
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
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): _pickFiles,
        const SingleActivator(LogicalKeyboardKey.keyO, meta: true): _pickFiles,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          if (s.items.any((i) => i.status == QueueStatus.pending)) s.start();
        },
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): () {
          if (s.items.any((i) => i.status == QueueStatus.pending)) s.start();
        },
        const SingleActivator(LogicalKeyboardKey.escape, control: true): s.cancelCurrent,
        const SingleActivator(LogicalKeyboardKey.escape, meta: true): s.cancelCurrent,
      },
      child: Focus(
        autofocus: true,
        child: AnimatedBuilder(
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
        ),
      ),
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
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history, color: kText),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
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
          _SectionLabel(tr('Model')),
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
          SizedBox(height: 6),
          if (!s.selectedModelCached)
            _DownloadBlock(state: s, model: model, downloading: downloading)
          else
            Text(
              model.note,
              style: const TextStyle(fontSize: 11, color: kDim),
            ),
          SizedBox(height: 18),
          _SectionLabel(tr('Language')),
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
          SizedBox(height: 18),
          _SectionLabel(tr('Save format')),
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
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  s.customOutDir ?? '${s.defaultOutDir} (default)',
                  maxLines: 2,
                  style: const TextStyle(fontSize: 11, color: kDim),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: onPickOutDir,
                child: Text(tr('Choose…')),
              ),
              if (s.customOutDir != null)
                TextButton(
                  onPressed: () => s.setCustomOutDir(null),
                  child: Text(tr('Reset')),
                ),
            ],
          ),
          SizedBox(height: 18),
          _SectionLabel(tr('Threads')),
          DropdownButton<int>(
            value: s.nThreads,
            isExpanded: true,
            dropdownColor: kSurface,
            items: [
              DropdownMenuItem(value: 0, child: Text(tr('auto'))),
              for (var i = 1; i <= 16; i++)
                DropdownMenuItem(value: i, child: Text(tr('$i'))),
            ],
            onChanged: (v) {
              if (v != null) s.setThreads(v);
            },
          ),
          SizedBox(height: 6),
          SwitchListTile(
            value: s.translate,
            onChanged: s.setTranslate,
            title: Text(tr('Translate to English')),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: s.useGpu,
            onChanged: s.setUseGpu,
            title: Text(tr('Use GPU (GPU build)')),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: s.useVad,
            onChanged: s.setUseVad,
            title: Text(tr('Filter silence (VAD)')),
            subtitle: s.useVad && !s.vadReady
                ? Text(tr('Silero model (0.9 MB) downloads once'), style: TextStyle(fontSize: 11))
                : Text(tr('Skip silent regions with Silero VAD'), style: TextStyle(fontSize: 11)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          SizedBox(height: 4),
          Text(tr('Custom vocabulary (optional)'),
              style: TextStyle(fontSize: 10, color: kDim, letterSpacing: 0.6)),
          const SizedBox(height: 4),
          _PromptField(state: s),
          if (s.downloadError != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.error_outline, color: kBrand, size: 16),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    s.downloadError!,
                    style: const TextStyle(fontSize: 11, color: kBrand),
                  ),
                ),
              ],
            ),
          ],
          SwitchListTile(
            value: s.autoSave,
            onChanged: s.setAutoSave,
            title: Text(tr('Save automatically')),
            subtitle: Text(tr('Write transcripts to the output folder when done'),
                style: TextStyle(fontSize: 11)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
          SizedBox(height: 18),
          _StartButton(state: s),
          SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: onPickFiles,
            icon: const Icon(Icons.file_open_outlined),
            label: Text(tr('Add files…')),
          ),
        ],
      ),
    );
  }
}

class _PromptField extends StatefulWidget {
  const _PromptField({required this.state});

  final AppState state;

  @override
  State<_PromptField> createState() => _PromptFieldState();
}

class _PromptFieldState extends State<_PromptField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.initialPrompt);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.state.setInitialPrompt,
      minLines: 1,
      maxLines: 3,
      style: const TextStyle(fontSize: 12, color: kText),
      decoration: InputDecoration(
        hintText: 'Names, jargon, e.g. Kikoe, Prasetyo…',
        hintStyle: const TextStyle(fontSize: 11, color: kDim),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kSurface2),
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
          Text(tr('Downloading ${model.name}.'),
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
          tr('Not downloaded yet. Kikoe needs the model file on this device once; after that, everything runs offline.'),
          style: const TextStyle(fontSize: 11, color: kDim),
        ),
        SizedBox(height: 6),
        FilledButton.tonalIcon(
          onPressed: state.downloadSelectedModel,
          icon: const Icon(Icons.download),
          label: Text(tr('Download ${model.name} (${model.sizeMb.toStringAsFixed(0)} MB)')),
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
          label: Text(tr('Cancel')),
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
              SizedBox(height: 16),
              Text(
                tr('Drop audio or video files here'),
                style: TextStyle(fontSize: 17, color: kText, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 6),
              Text(tr('or click to browse'), style: TextStyle(color: kDim)),
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
            SizedBox(height: 4),
            Text(_status, style: const TextStyle(fontSize: 11, color: kDim)),
            if (running) ...[
              SizedBox(height: 8),
              LinearProgressIndicator(value: item.progress > 0 ? item.progress / 100 : null, color: kBrand),
            ],
            if (item.segments.isNotEmpty) ...[
              SizedBox(height: 8),
              ExpansionTile(
                title: Text(tr('Preview'), style: TextStyle(fontSize: 12, color: kDim)),
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
                    Text(tr('… ${item.segments.length - 50} more lines'),
                        style: const TextStyle(fontSize: 11, color: kDim)),
                ],
              ),
            ],
            if (item.status == QueueStatus.done)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Expanded(
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
                                child: Text(tr('Save ${f.toUpperCase()}')),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit transcript',
                      icon: const Icon(Icons.edit_outlined, size: 18, color: kDim),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TranscriptEditorScreen(
                            segments: item.segments
                                .map((s) => SegmentEntry(s.startMs, s.endMs, s.text))
                                .toList(),
                            onSave: (entries) {
                              state.replaceItemSegments(
                                item,
                                entries
                                    .map((e) => Segment(e.startMs, e.endMs, e.text.trim()))
                                    .toList(),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy transcript',
                      icon: const Icon(Icons.content_copy, size: 18, color: kDim),
                      onPressed: () => state.copyTranscript(item),
                    ),
                    if (item.outputPath != null)
                      IconButton(
                        tooltip: 'Open output folder',
                        icon: const Icon(Icons.folder_open, size: 18, color: kDim),
                        onPressed: () => state.revealInFolder(item.outputPath!),
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
            tr('100% offline · no telemetry'),
            style: const TextStyle(fontSize: 11, color: kDim),
          ),
        ],
      ),
    );
  }
}
