// Generates every Listening line through the local VoiceStudio API
// (http://localhost:3900, or VOICESTUDIO_URL) as
// assets/listening/<set>/audio/<lineId>.wav.
//
//   dart run tool/generate_listening_voices.dart [set ...] [--redo id,id]
//
// - Each speaker gets a designed voice (the OmniVoice instruct and seed in
//   script.json's voiceDesign), never a clone of a real person. One short
//   reference clip is designed per voice, then every line is spoken from
//   that clip, so a speaker sounds the same on every line.
// - Lines are spoken as their `direction` asks: spelled words letter by
//   letter, phone numbers digit by digit.
// - Every line is transcribed and checked: the words must match, and a
//   line that gives an answer must contain it. A failed line is generated
//   again with another seed, up to 3 attempts in all; the best take is
//   kept and listed for checking by ear.
// - Resume-safe: progress is saved after each line to
//   build/listening_voices/<set>.json; finished lines are skipped. --redo
//   generates the given line ids again.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

const _root = 'assets/listening';
const _work = 'build/listening_voices';
const _maxAttempts = 3;

/// Words of a line the transcript must contain, for a pass.
const _minMatch = 0.8;

/// A neutral sentence spoken once per designed voice; every line is then
/// spoken from it.
const _referenceText =
    'Hello. I am reading some lines for a listening practice recording. '
    'Please listen carefully to each part.';

final Uri _api = Uri.parse(
  Platform.environment['VOICESTUDIO_URL'] ?? 'http://localhost:3900',
);

Future<void> main(List<String> args) async {
  final redo = <String>{};
  final sets = <String>[];
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--redo' && i + 1 < args.length) {
      redo.addAll(args[++i].split(','));
    } else if (!args[i].startsWith('--')) {
      sets.add(args[i]);
    }
  }
  await _checkServer();
  for (final setId in sets.isEmpty ? ['set_a', 'set_b'] : sets) {
    await _generateSet(setId, redo);
  }
}

void _log(String message) => stdout.writeln(message);

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}

Future<void> _checkServer() async {
  try {
    final r = await http
        .get(_api.resolve('/health'))
        .timeout(const Duration(seconds: 5));
    if (r.statusCode != 200) _fail('VoiceStudio /health: ${r.statusCode}');
  } on Exception catch (e) {
    _fail(
      'VoiceStudio is not reachable at $_api ($e).\n'
      'Start the VoiceStudio app (its API listens on port 3900).',
    );
  }
}

// ------------------------------------------------------------------ text

const _digitWords = [
  'oh', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight',
  'nine', //
];

/// [text] as the voice should say it: "H-A-L" letter by letter, and phone
/// numbers (5+ digits) digit by digit with "oh" for 0, pausing between
/// digit groups.
String spokenText(String text) => text
    .replaceAllMapped(
      RegExp(r'\b[A-Z](?:-[A-Z])+\b'),
      (m) => m[0]!.split('-').join(', '),
    )
    .replaceAllMapped(
      RegExp(r'\b\d{5,}(?: \d{3,})*\b'),
      (m) => [
        for (final group in m[0]!.split(' '))
          group.split('').map((d) => _digitWords[int.parse(d)]).join(' '),
      ].join(', '),
    );

const _numberWords = {
  'zero': '0', 'oh': '0', 'one': '1', 'two': '2', 'three': '3',
  'four': '4', 'five': '5', 'six': '6', 'seven': '7', 'eight': '8',
  'nine': '9', 'sixth': '6th', //
};

/// Lower case words without punctuation; number words become digits and
/// "double seven" becomes "7 7", so a transcript can be compared with the
/// script however the recogniser writes them.
List<String> _words(String text) {
  final raw = text
      .toLowerCase()
      .replaceAll(RegExp(r"[’']"), '')
      .replaceAll(RegExp(r'[^a-z0-9£]+'), ' ')
      .trim()
      .split(' ')
      .where((w) => w.isNotEmpty)
      .toList();
  final out = <String>[];
  for (var i = 0; i < raw.length; i++) {
    final w = raw[i];
    if (w == 'double' && i + 1 < raw.length) {
      final next = _numberWords[raw[i + 1]] ?? raw[i + 1];
      out
        ..add(next)
        ..add(next);
      i++;
    } else {
      out.add(_numberWords[w] ?? w);
    }
  }
  return out;
}

/// Everything joined, so spelled letters and digit groups compare however
/// they were spaced.
String _squashed(String text) => _words(text).join();

/// Share of the script's words found in the transcript, in order.
double _match(String script, String transcript) {
  final a = _words(script);
  final b = _words(transcript);
  if (a.isEmpty) return 1;
  // Longest common subsequence of words.
  final dp = List.generate(a.length + 1, (_) => List.filled(b.length + 1, 0));
  for (var i = 1; i <= a.length; i++) {
    for (var j = 1; j <= b.length; j++) {
      dp[i][j] = a[i - 1] == b[j - 1]
          ? dp[i - 1][j - 1] + 1
          : (dp[i - 1][j] > dp[i][j - 1] ? dp[i - 1][j] : dp[i][j - 1]);
    }
  }
  return dp[a.length][b.length] / a.length;
}

// ------------------------------------------------------------------ API

/// Designs (or reuses) the reference clip for a voice.
Future<File> _reference(Map<String, dynamic> design) async {
  final instruct = design['instruct'] as String;
  final seed = design['seed'] as int;
  final key = '${instruct.replaceAll(RegExp(r'[^a-z]+'), '_')}_$seed';
  final file = File('$_work/voices/$key.wav');
  if (file.existsSync() && file.lengthSync() > 0) return file;
  _log('  designing voice "$instruct" (seed $seed)…');
  final bytes = await _generate({
    'text': _referenceText,
    'language': 'en',
    'instruct': instruct,
    'seed': '$seed',
  });
  file.parent.createSync(recursive: true);
  await file.writeAsBytes(bytes);
  return file;
}

/// POST /generate; returns the WAV bytes.
Future<List<int>> _generate(
  Map<String, String> fields, {
  File? reference,
}) async {
  final request = http.MultipartRequest('POST', _api.resolve('/generate'))
    ..fields.addAll(fields);
  if (reference != null) {
    request.files.add(
      await http.MultipartFile.fromPath('ref_audio', reference.path),
    );
  }
  final response = await http.Response.fromStream(
    await request.send().timeout(const Duration(minutes: 10)),
  );
  if (response.statusCode != 200) {
    throw HttpException(
      '/generate ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 400))}',
    );
  }
  final type = response.headers['content-type'] ?? '';
  if (type.startsWith('audio/')) return response.bodyBytes;
  // Some versions answer with JSON pointing at the saved take.
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final url = json['audio_url'] ?? json['url'] ?? json['path'];
  if (url is! String) throw HttpException('/generate: no audio in $json');
  final audio = await http.get(_api.resolve(url));
  if (audio.statusCode != 200) {
    throw HttpException('GET $url: ${audio.statusCode}');
  }
  return audio.bodyBytes;
}

/// POST /v1/audio/transcriptions (OpenAI-compatible).
Future<String> _transcribe(File wav) async {
  final request =
      http.MultipartRequest('POST', _api.resolve('/v1/audio/transcriptions'))
        ..fields['language'] = 'en'
        ..fields['response_format'] = 'json'
        ..files.add(await http.MultipartFile.fromPath('file', wav.path));
  final response = await http.Response.fromStream(
    await request.send().timeout(const Duration(minutes: 5)),
  );
  if (response.statusCode != 200) {
    throw HttpException(
      'transcription ${response.statusCode}: ${response.body}',
    );
  }
  return (jsonDecode(response.body) as Map<String, dynamic>)['text']
          as String? ??
      '';
}

// ------------------------------------------------------------------ set

Future<void> _generateSet(String setId, Set<String> redo) async {
  final dir = '$_root/$setId';
  final script =
      jsonDecode(File('$dir/script.json').readAsStringSync())
          as Map<String, dynamic>;
  final questions =
      jsonDecode(File('$dir/questions.json').readAsStringSync())
          as Map<String, dynamic>;
  final speakers = {
    for (final s in (script['speakers'] as List).cast<Map<String, dynamic>>())
      s['id'] as String: s,
  };
  final lines = (script['lines'] as List).cast<Map<String, dynamic>>();

  // What each answer line must contain: the answer (or a variant) for
  // completion questions, the evidence words for the others.
  final mustHear = <String, List<List<String>>>{};
  for (final q
      in (questions['questions'] as List).cast<Map<String, dynamic>>()) {
    final options = <String>[
      if (q['wordLimit'] == null)
        q['evidence'] as String
      else ...[
        q['answer'] as String,
        ...(q['acceptedVariants'] as List).cast<String>(),
      ],
    ];
    (mustHear[q['evidenceLineId'] as String] ??= []).add(options);
  }

  final statusFile = File('$_work/$setId.json');
  final status = statusFile.existsSync()
      ? (jsonDecode(statusFile.readAsStringSync()) as Map<String, dynamic>)
      : <String, dynamic>{};
  void save() {
    statusFile.parent.createSync(recursive: true);
    statusFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(status),
    );
  }

  Directory('$dir/audio').createSync(recursive: true);
  _log('$setId: ${lines.length} lines');
  for (final (i, line) in lines.indexed) {
    final id = line['id'] as String;
    final out = File('$dir/audio/$id.wav');
    final done = status[id] as Map<String, dynamic>?;
    if (!redo.contains(id) && done != null && out.existsSync()) continue;

    final speaker = speakers[line['speaker']]!;
    final design = speaker['voiceDesign'] as Map<String, dynamic>;
    final reference = await _reference(design);
    final text = line['text'] as String;
    final spoken = spokenText(text);

    Map<String, dynamic>? best;
    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      final seed = (design['seed'] as int) * 1000 + i * 10 + attempt;
      final take = File('$_work/takes/$setId/$id.$attempt.wav');
      take.parent.createSync(recursive: true);
      await take.writeAsBytes(
        await _generate({
          'text': spoken,
          'language': 'en',
          'ref_text': _referenceText,
          'seed': '$seed',
        }, reference: reference),
      );
      final heard = await _transcribe(take);
      final match = _match(text, heard);
      final missing = [
        for (final options in mustHear[id] ?? const <List<String>>[])
          if (!options.any((o) => _squashed(heard).contains(_squashed(o))))
            options.first,
      ];
      final result = {
        'attempts': attempt,
        'seed': seed,
        'take': take.path,
        'transcript': heard,
        'match': double.parse(match.toStringAsFixed(2)),
        'missing': missing,
        'ok': match >= _minMatch && missing.isEmpty,
      };
      if (best == null ||
          (result['ok']! as bool) ||
          (missing.length < (best['missing'] as List).length) ||
          (missing.length == (best['missing'] as List).length &&
              match > (best['match'] as double))) {
        best = result;
      }
      final mark = result['ok']! as bool ? 'ok' : 'retry';
      _log(
        '  [${i + 1}/${lines.length}] $id try $attempt: $mark '
        '(match ${result['match']}${missing.isEmpty ? '' : ', missing $missing'})',
      );
      if (result['ok']! as bool) break;
    }
    await File(best!['take'] as String).copy(out.path);
    status[id] = {...best, 'attempts': (best['attempts'] as int)};
    save();
  }

  final review = [
    for (final MapEntry(:key, :value) in status.entries)
      if (!((value as Map<String, dynamic>)['ok'] as bool)) key,
  ];
  _log(
    '$setId: done. ${review.isEmpty ? 'Every line passed.' : 'Check by ear: ${review.join(', ')}'}',
  );
}
