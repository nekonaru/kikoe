/// Pure helpers behind the live transcription progress display.
///
/// Kept separate from Flutter widgets so the estimate can be unit tested.
/// The value is derived from observed progress, never invented.
library;

/// Estimate remaining milliseconds from elapsed time and progress percent.
/// Returns null until there is enough data for a meaningful estimate.
int? estimateRemainingMs(int elapsedMs, int percent) {
  if (percent < 5 || percent >= 100) return null;
  if (elapsedMs < 1000) return null;
  final rate = elapsedMs / percent;
  final remaining = (rate * (100 - percent)).round();
  if (remaining <= 0 || remaining > 86400000) return null;
  return remaining;
}

/// Exponential moving average so the estimate does not jump each update.
int smoothEtaMs(int? previousMs, int sampleMs) {
  if (previousMs == null) return sampleMs;
  return ((previousMs * 3 + sampleMs) / 4).round();
}

/// Language neutral compact label, for example "~12s" or "~2m 05s".
String formatEtaLabel(int ms) {
  final seconds = (ms / 1000).round();
  if (seconds < 60) return '~${seconds}s';
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  if (rest == 0) return '~${minutes}m';
  return '~${minutes}m ${rest.toString().padLeft(2, '0')}s';
}
