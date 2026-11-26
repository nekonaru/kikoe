/// Pure helpers behind the transcript editor, kept separate from widgets so
/// find/replace and timing shifts can be unit tested.
library;

/// Replace [needle] with [replacement] in every [texts] entry.
/// Returns how many entries changed. When [caseSensitive] is false, matching
/// ignores case but the replacement keeps the original text casing elsewhere.
int replaceAcross(List<String> texts, String needle, String replacement,
    {required bool caseSensitive}) {
  if (needle.isEmpty) return 0;
  final pattern = RegExp(RegExp.escape(needle), caseSensitive: caseSensitive);
  var count = 0;
  for (var i = 0; i < texts.length; i++) {
    if (!pattern.hasMatch(texts[i])) continue;
    texts[i] = texts[i].replaceAll(pattern, replacement);
    count++;
  }
  return count;
}

/// Shift every timestamp by [milliseconds], clamping at zero.
void shiftTiming(List<int> starts, List<int> ends, int milliseconds) {
  for (var i = 0; i < starts.length; i++) {
    starts[i] = (starts[i] + milliseconds) < 0 ? 0 : starts[i] + milliseconds;
    ends[i] = (ends[i] + milliseconds) < 0 ? 0 : ends[i] + milliseconds;
  }
}
