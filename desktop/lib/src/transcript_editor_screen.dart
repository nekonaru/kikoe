// Full-screen transcript editor.
//
// Each segment is one editable row with its timestamps shown read-only,
// so edits can never corrupt the timing data. Saving replaces the segment
// list through onSave; the edited text then flows into every export.
library;

import 'l10n.dart';
import 'package:flutter/material.dart';

import 'kikoe_theme.dart';

class SegmentEntry {
  SegmentEntry(this.startMs, this.endMs, this.text);
  final int startMs;
  final int endMs;
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

  @override
  void initState() {
    super.initState();
    // Edit against a working copy so Cancel can discard everything.
    _working = widget.segments.map((s) => SegmentEntry(s.startMs, s.endMs, s.text)).toList();
    _controllers = _working.map((s) => TextEditingController(text: s.text)).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kSurface,
        title: Text(tr('Edit transcript')),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(tr('SAVE'), style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(14),
          itemCount: _working.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final seg = _working[i];
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
                    style: const TextStyle(fontSize: 10.5, color: kDim, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _controllers[i],
                    maxLines: null,
                    minLines: 1,
                    style: const TextStyle(fontSize: 13, color: kText, height: 1.45),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Segment text…',
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
        child: const Text(
          'Editing replaces the saved text; timestamps never change.',
          style: TextStyle(fontSize: 10.5, color: kDim),
        ),
      ),
    );
  }
}
