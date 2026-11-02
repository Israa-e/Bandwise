import 'dart:io';

import 'package:bandwise/core/theme/app_theme.dart';
import 'package:bandwise/features/learn/data/course_content.dart';
import 'package:bandwise/features/learn/domain/course.dart';
import 'package:bandwise/features/lesson/domain/word_audio.dart';
import 'package:bandwise/features/lesson/presentation/widgets/exercise_views.dart';
import 'package:bandwise/features/lesson/presentation/word_audio_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeWordAudio implements WordAudioPlayer {
  final played = <String>[];
  var fail = false;

  @override
  Future<void> play(String asset) async {
    if (fail) throw StateError('no audio device');
    played.add(asset);
  }

  @override
  Future<void> dispose() async {}
}

final _words = [
  for (final l in course.lessons)
    for (final c in l.exercises.whereType<FlashcardExercise>()) c.word,
];

Future<void> _pump(
  WidgetTester tester, {
  required FlashcardExercise card,
  required Set<String> available,
  required _FakeWordAudio audio,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        wordAudioAssetsProvider.overrideWith((ref) async => available),
        wordAudioPlayerProvider.overrideWithValue(audio),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(body: FlashcardView(exercise: card, revealed: false)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  final card = course
      .lessonById('u1-l2')!
      .exercises
      .whereType<FlashcardExercise>()
      .first;

  group('pronunciation button', () {
    testWidgets('plays the word\'s recording', (tester) async {
      final audio = _FakeWordAudio();
      await _pump(
        tester,
        card: card,
        available: {wordAudioAsset(card.word)},
        audio: audio,
      );
      await tester.tap(find.byTooltip('Pronunciation'));
      await tester.pumpAndSettle();
      expect(audio.played, ['assets/audio/words/${card.word}.mp3']);
      expect(find.text('Audio coming soon'), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('is hidden when the word has no recording', (tester) async {
      await _pump(
        tester,
        card: card,
        available: {'assets/audio/words/other.mp3'},
        audio: _FakeWordAudio(),
      );
      expect(find.byTooltip('Pronunciation'), findsNothing);
      expect(find.text(card.word), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a playback failure shows no error', (tester) async {
      final audio = _FakeWordAudio()..fail = true;
      await _pump(
        tester,
        card: card,
        available: {wordAudioAsset(card.word)},
        audio: audio,
      );
      await tester.tap(find.byTooltip('Pronunciation'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('bundled word audio', () {
    test('every flashcard word has a non-empty mp3', () {
      expect(_words, isNotEmpty);
      for (final word in _words) {
        final file = File('assets/audio/words/$word.mp3');
        expect(file.existsSync(), isTrue, reason: '$word.mp3 is missing');
        expect(file.lengthSync(), greaterThan(1000), reason: word);
      }
    });

    test('there are no recordings for words that are not in the course', () {
      final files = [
        for (final f in Directory('assets/audio/words').listSync())
          if (f.path.endsWith('.mp3')) f.uri.pathSegments.last,
      ];
      expect(files.toSet(), {for (final w in _words) '$w.mp3'});
    });

    test('the folder is registered and recorded in its README', () {
      expect(
        File('pubspec.yaml').readAsStringSync(),
        contains('- assets/audio/words/'),
      );
      final readme = File('assets/audio/words/README.md').readAsStringSync();
      expect(readme, contains('bf_emma'));
      for (final word in _words) {
        expect(readme, contains('`$word`'));
      }
    });

    testWidgets('the app bundle lists every word', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final assets = await container.read(wordAudioAssetsProvider.future);
      expect(assets, {for (final w in _words) wordAudioAsset(w)});
    });
  });
}
