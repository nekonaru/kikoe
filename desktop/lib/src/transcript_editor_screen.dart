// Full-screen transcript editor with find & replace and timing shift.
//
// Each segment is one editable row with its timestamps shown read-only,
// so edits can never corrupt the timing data. Saving replaces the segment
// list through onSave; the edited text then flows into every export.
library;

import 'package:flutter/material.dart';

import 'kikoe_theme.dart';
import 'l10n.dart';
import 'transcript_editor_logic.dart';

class SegmentEntry {
  SegmentEntry(this.startMs, this.endMs, this.text);
  int startMs;
  int endMs;
  String text;
}

class TranscriptEditorScreen extends StatefulWidget {
  const TranscriptEditorScreen({
    super.key,
    required this.segments,
    required this.onSave,
  });

  final List<SegmentEntry> segments;
  final void Function(List<SegmentEntry> edited) onSave;

  @override
  State<TranscriptEditorScreen> createState() => _TranscriptEditorScreenState();
}

class _TranscriptEditorScreenState extends State<TranscriptEditorScreen> {
  late final List<TextEditingController> _controllers;
  late final List<SegmentEntry> _working;
  final _findController = TextEditingController();
  final _replaceController = TextEditingController();
  final _shiftController = TextEditingController(text: '0');
  bool _showTools = false;
  bool _caseSensitive = false;

  @override
  void initState() {
    super.initState();
    // Edit against a working copy so Cancel can discard everything.
    _working = widget.segments
        .map((s) => SegmentEntry(s.startMs, s.endMs, s.text))
        .toList();
    _controllers = _working
        .map((s) => TextEditingController(text: s.text))
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _findController.dispose();
    _replaceController.dispose();
    _shiftController.dispose();
    super.dispose();
  }

  String _formatMs(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _save() {
    for (var i = 0; i < _controllers.length; i++) {
      _working[i].text = _controllers[i].text;
    }
    widget.onSave(_working);
    Navigator.of(context).pop();
  }

  void _replaceAll() {
    final needle = _findController.text;
    if (needle.isEmpty) return;
    final texts = _controllers.map((c) => c.text).toList();
    final count = replaceAcross(texts, needle, _replaceController.text,
        caseSensitive: _caseSensitive);
    for (var i = 0; i < _controllers.length; i++) {
      _controllers[i].text = texts[i];
    }
    _showSnack('$count ${tr('segments changed')}');
  }

  void _applyShift() {
    final milliseconds = int.tryParse(_shiftController.text.trim()) ?? 0;
    if (milliseconds == 0) return;
    shiftTiming(
      _working.map((s) => s.startMs).toList(),
      _working.map((s) => s.endMs).toList(),
      milliseconds,
    );
    setState(() {});
    _showSnack('${tr('Shifted by')} $milliseconds ms');
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _tools() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _findController,
            style: const TextStyle(fontSize: 12, color: kText),
            decoration: InputDecoration(
              labelText: tr('Find'),
              labelStyle: const TextStyle(fontSize: 11, color: kDim),
            ),
          ),
          TextField(
            controller: _replaceController,
            style: const TextStyle(fontSize: 12, color: kText),
            decoration: InputDecoration(
              labelText: tr('Replace with'),
              labelStyle: const TextStyle(fontSize: 11, color: kDim),
            ),
          ),
          Row(
            children: [
              Checkbox(
                value: _caseSensitive,
                onChanged: (v) => setState(() => _caseSensitive = v ?? false),
              ),
              Text(tr('Case sensitive'),
                  style: const TextStyle(fontSize: 11, color: kDim)),
              const Spacer(),
              FilledButton.tonal(
                onPressed: _replaceAll,
                child: Text(tr('Replace all')),
              ),
            ],
          ),
          const Divider(color: kSurface2),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _shiftController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 12, color: kText),
                  decoration: InputDecoration(
                    labelText: tr('Shift timing (ms)'),
                    labelStyle: const TextStyle(fontSize: 11, color: kDim),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _applyShift,
                child: Text(tr('Apply')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kSurface,
        title: Text(tr('Edit transcript')),
        actions: [
          IconButton(
            tooltip: tr('Find and replace'),
            icon: Icon(_showTools ? Icons.find_replace : Icons.search,
                color: kBrand),
            onPressed: () => setState(() => _showTools = !_showTools),
          ),
          TextButton(
            onPressed: _save,
            child: Text(tr('SAVE'),
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: _working.length + (_showTools ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            if (_showTools && i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _tools(),
              );
            }
            final seg = _working[_showTools ? i - 1 : i];
            return Container(
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatMs(seg.startMs)} → ${_formatMs(seg.endMs)}',
                    style: const TextStyle(
                        fontSize: 10.5, color: kDim, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _controllers[_showTools ? i - 1 : i],
                    maxLines: null,
                    minLines: 1,
                    style: const TextStyle(
                        fontSize: 13, color: kText, height: 1.45),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: tr('Segment text…'),
                      hintStyle: const TextStyle(color: kDim),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: const BoxDecoration(
          color: kSurface,
          border: Border(top: BorderSide(color: kSurface2)),
        ),
        child: Text(
          tr('Editing replaces the saved text; timestamps change only when shifted.'),
          style: const TextStyle(fontSize: 10.5, color: kDim),
        ),
      ),
    );
  }
}
