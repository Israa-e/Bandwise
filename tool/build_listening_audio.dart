// Builds the audio for each Listening set in assets/listening/<set>/.
//
//   dart run tool/build_listening_audio.dart [set ...]           build audio
//   dart run tool/build_listening_audio.dart --readme [set ...]  write READMEs
//
// With no set ids, every folder in assets/listening is processed.
//
// Audio build: reads script.json and joins audio/<lineId>.wav in script order.
// Each line is trimmed of leading/trailing silence and gain-matched to the
// same loudness, then followed by its pauseAfterMs of silence. The joined
// track is loudness-normalised (two-pass EBU R128) and exported as one mono
// 64 kbps MP3 (listening.mp3), plus timestamps.json with the start/end of
// each line in ms so the app can jump to the evidence in the transcript.
//
// Needs ffmpeg with libmp3lame on PATH (or set FFMPEG=/path/to/ffmpeg).
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

const _root = 'assets/listening';
const _sampleRate = 44100;
const _bitrate = '64k';
const _lineLoudness = -18.0; // LUFS each line is matched to
const _targetLoudness = -16.0; // LUFS of the final track
const _truePeak = -1.5;
const _maxLineGainDb = 20.0;
const _trimThreshold = '-50dB';

final String _ffmpeg = Platform.environment['FFMPEG'] ?? 'ffmpeg';

Future<void> main(List<String> args) async {
  final readme = args.contains('--readme');
  final setIds = args.where((a) => !a.startsWith('--')).toList();
  final sets = setIds.isEmpty ? _allSets() : setIds;
  if (sets.isEmpty) _fail('No sets found in $_root.');

  if (readme) {
    for (final id in sets) {
      final script = _loadScript(id);
      File('$_root/$id/README.md').writeAsStringSync(_readme(id, script));
      stdout.writeln('Wrote $_root/$id/README.md');
    }
    return;
  }

  await _checkFfmpeg();
  for (final id in sets) {
    await _buildSet(id);
  }
}

List<String> _allSets() {
  final dir = Directory(_root);
  if (!dir.existsSync()) return [];
  return [
    for (final e in dir.listSync()..sort((a, b) => a.path.compareTo(b.path)))
      if (e is Directory && File('${e.path}/script.json').existsSync())
        e.uri.pathSegments.where((s) => s.isNotEmpty).last,
  ];
}

Map<String, dynamic> _loadScript(String setId) {
  final file = File('$_root/$setId/script.json');
  if (!file.existsSync()) _fail('Missing ${file.path}.');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

List<Map<String, dynamic>> _lines(Map<String, dynamic> script) =>
    (script['lines'] as List).cast<Map<String, dynamic>>();

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}

// ---------------------------------------------------------------- ffmpeg

Future<void> _checkFfmpeg() async {
  ProcessResult result;
  try {
    result = await Process.run(_ffmpeg, ['-hide_banner', '-encoders']);
  } on ProcessException {
    _fail(
      'ffmpeg was not found ($_ffmpeg).\n'
      'Install it first:\n'
      '  Ubuntu/Debian: sudo apt install ffmpeg\n'
      '  macOS:         brew install ffmpeg\n'
      'or point FFMPEG at an ffmpeg binary.',
    );
  }
  if (result.exitCode != 0) _fail('ffmpeg failed to start:\n${result.stderr}');
  if (!(result.stdout as String).contains('libmp3lame')) {
    _fail('This ffmpeg build has no MP3 encoder (libmp3lame).');
  }
}

Future<String> _run(List<String> args) async {
  final result = await Process.run(_ffmpeg, [
    '-hide_banner',
    '-nostdin',
    '-y',
    ...args,
  ]);
  if (result.exitCode != 0) {
    _fail('ffmpeg ${args.join(' ')}\n${result.stderr}');
  }
  return result.stderr as String;
}

/// Runs a loudnorm analysis pass and returns its measurements.
Future<Map<String, dynamic>> _measure(String input, String filters) async {
  final log = await _run([
    '-nostats',
    '-i',
    input,
    '-af',
    '$filters${filters.isEmpty ? '' : ','}'
        'loudnorm=I=$_targetLoudness:TP=$_truePeak:LRA=20:print_format=json',
    '-f',
    'null',
    '-',
  ]);
  final start = log.lastIndexOf('{');
  final end = log.lastIndexOf('}');
  if (start < 0 || end < start) _fail('No loudness data for $input.');
  return jsonDecode(log.substring(start, end + 1)) as Map<String, dynamic>;
}

/// Number of sample frames in a PCM WAV file written by ffmpeg.
int _wavFrames(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(bytes);
  final channels = data.getUint16(22, Endian.little);
  final bits = data.getUint16(34, Endian.little);
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final chunk = ascii.decode(bytes.sublist(offset, offset + 4));
    final size = data.getUint32(offset + 4, Endian.little);
    if (chunk == 'data') {
      final available = bytes.length - offset - 8;
      final dataSize = size > available ? available : size;
      return dataSize ~/ (channels * bits ~/ 8);
    }
    offset += 8 + size + (size.isOdd ? 1 : 0);
  }
  _fail('No data chunk in $path.');
}

int _framesToMs(int frames) => (frames * 1000 / _sampleRate).round();

// ---------------------------------------------------------------- build

Future<void> _buildSet(String setId) async {
  final dir = '$_root/$setId';
  final script = _loadScript(setId);
  final lines = _lines(script);

  final missing = [
    for (final line in lines)
      if (!File('$dir/audio/${line['id']}.wav').existsSync())
        'audio/${line['id']}.wav',
  ];
  if (missing.isNotEmpty) {
    _fail(
      '$setId: ${missing.length} audio file(s) missing:\n  '
      '${missing.join('\n  ')}',
    );
  }
  final known = {for (final line in lines) '${line['id']}.wav'};
  for (final f in Directory('$dir/audio').listSync().whereType<File>()) {
    final name = f.uri.pathSegments.last;
    if (name.endsWith('.wav') && !known.contains(name)) {
      stderr.writeln('$setId: ignoring audio/$name (not in script.json)');
    }
  }

  stdout.writeln('$setId: processing ${lines.length} lines…');
  final tmp = await Directory.systemTemp.createTemp('bandwise_listening_');
  try {
    const trim =
        'silenceremove=start_periods=1:start_silence=0.05:'
        'start_threshold=$_trimThreshold';
    const trimBothEnds = '$trim,areverse,$trim,areverse';

    final parts = <String>[];
    final timestamps = <Map<String, Object>>[];
    final silences = <int, String>{};
    var position = 0; // in sample frames

    for (final line in lines) {
      final id = line['id'] as String;
      final source = '$dir/audio/$id.wav';
      final measured = await _measure(source, trimBothEnds);
      final input = double.tryParse('${measured['input_i']}');
      var gain = 0.0;
      if (input != null && input.isFinite && input > -70) {
        gain = (_lineLoudness - input).clamp(-_maxLineGainDb, _maxLineGainDb);
      } else {
        stderr.writeln('$setId: $id is silent or too short to measure');
      }

      final clip = '${tmp.path}/$id.wav';
      await _run([
        '-i',
        source,
        '-af',
        '$trimBothEnds,volume=${gain.toStringAsFixed(2)}dB',
        ..._pcmOut,
        clip,
      ]);
      final frames = _wavFrames(clip);
      if (frames == 0) _fail('$setId: $id is empty after trimming silence.');
      parts.add(clip);
      timestamps.add({
        'id': id,
        'startMs': _framesToMs(position),
        'endMs': _framesToMs(position + frames),
      });
      position += frames;

      final pause = line['pauseAfterMs'] as int;
      if (pause > 0) {
        final silence = silences[pause] ??= await _silence(tmp.path, pause);
        parts.add(silence);
        position += _wavFrames(silence);
      }
    }

    final list = File('${tmp.path}/list.txt')
      ..writeAsStringSync(parts.map((p) => "file '$p'\n").join());
    final joined = '${tmp.path}/joined.wav';
    await _run([
      '-f',
      'concat',
      '-safe',
      '0',
      '-i',
      list.path,
      '-c',
      'copy',
      joined,
    ]);

    stdout.writeln('$setId: normalising loudness and encoding MP3…');
    final m = await _measure(joined, '');
    final out = '$dir/listening.mp3';
    await _run([
      '-i',
      joined,
      '-af',
      'loudnorm=I=$_targetLoudness:TP=$_truePeak:LRA=20'
          ':measured_I=${m['input_i']}:measured_TP=${m['input_tp']}'
          ':measured_LRA=${m['input_lra']}:measured_thresh=${m['input_thresh']}'
          ':offset=${m['target_offset']}:linear=true',
      '-ar',
      '$_sampleRate',
      '-ac',
      '1',
      '-c:a',
      'libmp3lame',
      '-b:a',
      _bitrate,
      '-map_metadata',
      '-1',
      out,
    ]);

    const encoder = JsonEncoder.withIndent('  ');
    File('$dir/timestamps.json').writeAsStringSync(
      '${encoder.convert({'setId': setId, 'audio': 'listening.mp3', 'durationMs': _framesToMs(position), 'lines': timestamps})}\n',
    );
    stdout.writeln(
      '$setId: wrote $out and $dir/timestamps.json '
      '(${(_framesToMs(position) / 1000).toStringAsFixed(1)} s)',
    );
  } finally {
    await tmp.delete(recursive: true);
  }
}

const _pcmOut = [
  '-ar',
  '$_sampleRate',
  '-ac',
  '1',
  '-c:a',
  'pcm_s16le',
  '-map_metadata',
  '-1',
  '-bitexact',
];

Future<String> _silence(String tmp, int ms) async {
  final path = '$tmp/silence_$ms.wav';
  final frames = (ms * _sampleRate / 1000).round();
  await _run([
    '-f',
    'lavfi',
    '-i',
    'anullsrc=r=$_sampleRate:cl=mono',
    '-af',
    'atrim=end_sample=$frames',
    ..._pcmOut,
    path,
  ]);
  return path;
}

// ---------------------------------------------------------------- README

String _readme(String setId, Map<String, dynamic> script) {
  final speakers = {
    for (final s in (script['speakers'] as List).cast<Map<String, dynamic>>())
      s['id'] as String: s,
  };
  final lines = _lines(script);
  final b = StringBuffer()
    ..writeln('# Listening $setId: ${script['title']} (Part ${script['part']})')
    ..writeln()
    ..writeln(
      'Original practice material written for Bandwise. It is not an '
      'IELTS recording or script.',
    )
    ..writeln()
    ..writeln(
      '> Generated from script.json by '
      '`dart run tool/build_listening_audio.dart --readme $setId`. '
      'Edit script.json, then regenerate; do not edit this file by hand.',
    )
    ..writeln()
    ..writeln('## Voices to create in VoiceStudio')
    ..writeln()
    ..writeln(
      'Create one voice per speaker and use it for every line by that '
      'speaker.',
    )
    ..writeln()
    ..writeln('| Speaker id | Name | Role | Accent | Age | Tone |')
    ..writeln('| --- | --- | --- | --- | --- | --- |');
  for (final s in speakers.values) {
    final notes = s['voiceNotes'] as Map<String, dynamic>;
    b.writeln(
      '| `${s['id']}` | ${s['name']} | ${s['role']} | ${s['accent']} '
      '| ${notes['age']} | ${notes['tone']} |',
    );
  }
  b
    ..writeln()
    ..writeln('## Files to generate, in this order')
    ..writeln()
    ..writeln(
      'Save each line as `audio/<lineId>.wav` in this folder (any '
      'sample rate, mono or stereo). One file per line; don\'t add silence '
      'yourself. The build trims each clip and inserts the pause listed.',
    )
    ..writeln()
    ..writeln(
      'Numbers are written as digits. Phone numbers are read digit by '
      'digit ("0" as "oh"), and hyphenated capitals (H-A-L-L…) are spelled '
      'letter by letter.',
    )
    ..writeln()
    ..writeln('| # | File | Speaker | Text | Pause after |')
    ..writeln('| --- | --- | --- | --- | --- |');
  for (final (i, line) in lines.indexed) {
    final speaker = speakers[line['speaker']]?['name'] ?? line['speaker'];
    final direction = line['direction'];
    final text = '${line['text']}'.replaceAll('|', r'\|');
    b.writeln(
      '| ${i + 1} | `audio/${line['id']}.wav` | $speaker | $text'
      '${direction == null ? '' : ' _(${direction.toString().replaceAll('|', r'\|')})_'} '
      '| ${line['pauseAfterMs']} ms |',
    );
  }
  b
    ..writeln()
    ..writeln('## Build')
    ..writeln()
    ..writeln('Needs ffmpeg with libmp3lame.')
    ..writeln()
    ..writeln('```sh')
    ..writeln('dart run tool/build_listening_audio.dart $setId')
    ..writeln('```')
    ..writeln()
    ..writeln(
      'This writes `listening.mp3` (mono, 64 kbps, loudness-normalised) '
      'and `timestamps.json` (start/end ms of every line) to this folder.',
    );
  return b.toString();
}
