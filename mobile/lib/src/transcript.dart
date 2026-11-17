/// Transcript rendering in Dart: TXT, SRT, VTT, JSON.
///
/// The apps render these themselves (instead of asking the native side)
/// so inline edits made by the user are honored with correct timestamps.
/// Kept byte-compatible with core/src/format/formatter.cpp.
library;

class RenderSegment {
  const RenderSegment(this.startMs, this.endMs, this.text);
  final int startMs;
  final int endMs;
  final String text;
}

String _timestamp(int ms, {required String msSep}) {
  final totalSeconds = ms ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final millis = ms % 1000;
  String pad(int n, [int width = 2]) => n.toString().padLeft(width, '0');
  return '${pad(hours)}:${pad(minutes)}:${pad(seconds)}$msSep${pad(millis, 3)}';
}

String _trim(String s) => s.trim();

String _jsonEscape(String s) {
  final out = StringBuffer();
  for (final cu in s.codeUnits) {
    switch (cu) {
      case 0x22:
        out.write('\\"');
        break;
      case 0x5C:
        out.write('\\\\');
        break;
      case 0x08:
        out.write('\\b');
        break;
      case 0x0C:
        out.write('\\f');
        break;
      case 0x0A:
        out.write('\\n');
        break;
      case 0x0D:
        out.write('\\r');
        break;
      case 0x09:
        out.write('\\t');
        break;
      default:
        if (cu < 0x20) {
          out.write('\\u${cu.toRadixString(16).padLeft(4, '0')}');
        } else {
          out.writeCharCode(cu);
        }
    }
  }
  return out.toString();
}

String renderTxt(List<RenderSegment> segments) {
  final out = StringBuffer();
  for (final s in segments) {
    final t = _trim(s.text);
    if (t.isEmpty) continue;
    out.writeln(t);
  }
  return out.toString();
}

String renderSrt(List<RenderSegment> segments) {
  final out = StringBuffer();
  var index = 1;
  for (final s in segments) {
    out
      ..writeln(index++)
      ..writeln('${_timestamp(s.startMs, msSep: ',')} --> ${_timestamp(s.endMs, msSep: ',')}')
      ..writeln(_trim(s.text))
      ..writeln();
  }
  return out.toString();
}

String renderVtt(List<RenderSegment> segments) {
  final out = StringBuffer()..writeln('WEBVTT\n');
  for (final s in segments) {
    out
      ..writeln('${_timestamp(s.startMs, msSep: '.')} --> ${_timestamp(s.endMs, msSep: '.')}')
      ..writeln(_trim(s.text))
      ..writeln();
  }
  return out.toString();
}

String renderJson(List<RenderSegment> segments) {
  final out = StringBuffer()..write('{\n  "segments": [\n');
  for (var i = 0; i < segments.length; i++) {
    final s = segments[i];
    out.write(
      '    {"start_ms": ${s.startMs}, "end_ms": ${s.endMs}, '
      '"text": "${_jsonEscape(_trim(s.text))}"}',
    );
    if (i + 1 < segments.length) out.write(',');
    out.writeln();
  }
  out.writeln('  ]\n}');
  return out.toString();
}

String renderFormat(List<RenderSegment> segments, String format) {
  switch (format) {
    case 'txt':
      return renderTxt(segments);
    case 'srt':
      return renderSrt(segments);
    case 'vtt':
      return renderVtt(segments);
    case 'json':
      return renderJson(segments);
    default:
      throw ArgumentError('unknown format: $format');
  }
}
