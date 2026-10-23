// ffmpeg helpers shared by the audio build tools.
import 'dart:convert';
import 'dart:io';

/// ffmpeg on PATH, or FFMPEG=/path/to/ffmpeg.
final String ffmpegPath = Platform.environment['FFMPEG'] ?? 'ffmpeg';

Never fail(String message) {
  stderr.writeln(message);
  exit(1);
}

/// Stops with install instructions unless ffmpeg with an MP3 encoder runs.
Future<void> checkFfmpeg() async {
  ProcessResult result;
  try {
    result = await Process.run(ffmpegPath, ['-hide_banner', '-encoders']);
  } on ProcessException {
    fail(
      'ffmpeg was not found ($ffmpegPath).\n'
      'Install it first:\n'
      '  Ubuntu/Debian: sudo apt install ffmpeg\n'
      '  macOS:         brew install ffmpeg\n'
      'or point FFMPEG at an ffmpeg binary.',
    );
  }
  if (result.exitCode != 0) fail('ffmpeg failed to start:\n${result.stderr}');
  if (!(result.stdout as String).contains('libmp3lame')) {
    fail('This ffmpeg build has no MP3 encoder (libmp3lame).');
  }
}

/// Runs ffmpeg (overwriting outputs) and returns its log; stops on failure.
Future<String> runFfmpeg(List<String> args) async {
  final result = await Process.run(ffmpegPath, [
    '-hide_banner',
    '-nostdin',
    '-y',
    ...args,
  ]);
  if (result.exitCode != 0) {
    fail('ffmpeg ${args.join(' ')}\n${result.stderr}');
  }
  return result.stderr as String;
}

/// Runs a loudnorm analysis pass on [input] after [filters] and returns
/// its measurements (input_i, input_tp, input_lra, input_thresh,
/// target_offset).
Future<Map<String, dynamic>> measureLoudness(
  String input,
  String filters, {
  required double target,
  required double truePeak,
}) async {
  final log = await runFfmpeg([
    '-nostats',
    '-i',
    input,
    '-af',
    '$filters${filters.isEmpty ? '' : ','}'
        'loudnorm=I=$target:TP=$truePeak:LRA=20:print_format=json',
    '-f',
    'null',
    '-',
  ]);
  final start = log.lastIndexOf('{');
  final end = log.lastIndexOf('}');
  if (start < 0 || end < start) fail('No loudness data for $input.');
  return jsonDecode(log.substring(start, end + 1)) as Map<String, dynamic>;
}

/// The second loudnorm pass for [m] (from [measureLoudness]), in linear
/// mode so the speech isn't compressed.
String loudnormFilter(
  Map<String, dynamic> m, {
  required double target,
  required double truePeak,
}) =>
    'loudnorm=I=$target:TP=$truePeak:LRA=20'
    ':measured_I=${m['input_i']}:measured_TP=${m['input_tp']}'
    ':measured_LRA=${m['input_lra']}:measured_thresh=${m['input_thresh']}'
    ':offset=${m['target_offset']}:linear=true';
