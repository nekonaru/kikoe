/// One file in the transcription queue.
library;

enum QueueStatus { pending, transcribing, done, failed, cancelled }

class Segment {
  const Segment(this.startMs, this.endMs, this.text);
  final int startMs;
  final int endMs;
  final String text;
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
