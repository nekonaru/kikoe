/// One file in the transcription queue.
library;

import 'transcriber.dart';

enum QueueStatus { pending, transcribing, done, failed, cancelled }

class Segment {
  const Segment(this.startMs, this.endMs, this.text,
      {this.confidence = 0, this.speaker = 0, this.words = const []});
  final int startMs;
  final int endMs;
  final String text;
  final int confidence; // permille
  final int speaker;
  final List<TranscribedWord> words;
}

class QueueItem {
  QueueItem({required this.id, required this.path});

  final String id;
  final String path;

  QueueStatus status = QueueStatus.pending;
  int progress = 0; // 0-100 while transcribing
  String? error;
  String? outputPath; // set after the user saves (or auto-save succeeds)
  final List<Segment> segments = [];

  String get name {
    final slash = path.lastIndexOf(RegExp(r'[/\\]'));
    return slash < 0 ? path : path.substring(slash + 1);
  }
}
