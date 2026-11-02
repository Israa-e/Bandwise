// Builds the pronunciation audio for the course's flashcard words.
//
//   dart run tool/build_word_audio.dart
//
// Takes build/word_voices/wav/<word>.wav (from
// tool/generate_word_voices.py, which also writes the README), trims the
// silence at both ends, normalises the loudness (two-pass EBU R128, linear)
// and writes one mono 48 kbps MP3: assets/audio/words/<word>.mp3.
//
// Needs ffmpeg with libmp3lame on PATH (or set FFMPEG=/path/to/ffmpeg).
import 'dart:io';

import 'src/ffmpeg_tools.dart';

const _in = 'build/word_voices/wav';
const _out = 'assets/audio/words';
const _targetLoudness = -16.0;
const _truePeak = -1.5;
const _trim =
    'silenceremove=start_periods=1:start_silence=0.05:start_threshold=-50dB';

Future<void> main() async {
  await checkFfmpeg();
  final wavs = Directory(_in).existsSync()
      ? (Directory(_in)
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.wav'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path)))
      : <File>[];
  if (wavs.isEmpty) {
    fail('No WAVs in $_in. Run tool/generate_word_voices.py first.');
  }
  Directory(_out).createSync(recursive: true);
  for (final (i, wav) in wavs.indexed) {
    final word = wav.uri.pathSegments.last.replaceAll('.wav', '');
    const trimBothEnds = '$_trim,areverse,$_trim,areverse';
    final m = await measureLoudness(
      wav.path,
      trimBothEnds,
      target: _targetLoudness,
      truePeak: _truePeak,
    );
    await runFfmpeg([
      '-i',
      wav.path,
      '-af',
      '$trimBothEnds,'
          '${loudnormFilter(m, target: _targetLoudness, truePeak: _truePeak)}',
      '-ar',
      '44100',
      '-ac',
      '1',
      '-c:a',
      'libmp3lame',
      '-b:a',
      '48k',
      '-map_metadata',
      '-1',
      '$_out/$word.mp3',
    ]);
    stdout.writeln('[${i + 1}/${wavs.length}] $_out/$word.mp3');
  }
}
