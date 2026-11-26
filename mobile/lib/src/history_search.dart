/// Pure filter used by the history search field.
library;

/// Case-insensitive match against either the file name or the transcript.
/// An empty query matches everything.
bool historyMatches(String fileName, String transcript, String query) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return true;
  return fileName.toLowerCase().contains(needle) ||
      transcript.toLowerCase().contains(needle);
}
