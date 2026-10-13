import '../domain/onboarding_repository.dart';
import '../domain/placement.dart';

/// Eight original placement questions: grammar, vocabulary and reading.
class MockPlacementRepository implements PlacementRepository {
  const MockPlacementRepository({
    this.delay = const Duration(milliseconds: 300),
  });

  /// Simulated network latency.
  final Duration delay;

  @override
  Future<List<PlacementQuestion>> fetchQuestions() async {
    await Future<void>.delayed(delay);
    return _questions;
  }
}

const _campusPassage =
    'Many universities now open their libraries 24 hours a day during exam '
    'periods. Supporters say this helps students who work part-time, while '
    'critics argue that it encourages unhealthy sleep habits. A recent '
    'campus survey found that most late-night users were studying in groups '
    'rather than alone.';

const _questions = [
  PlacementQuestion(
    category: 'Grammar',
    type: 'Sentence completion',
    prompt: 'Choose the word that completes the sentence.',
    passage: 'Neither the lecturer nor the students ____ aware of the change.',
    options: ['was', 'were', 'has been', 'is'],
    correctIndex: 1,
    explanation:
        'With "neither … nor", the verb agrees with the nearer subject. '
        '"Students" is plural, so "were" is correct.',
  ),
  PlacementQuestion(
    category: 'Grammar',
    type: 'Sentence completion',
    prompt: 'Choose the correct verb form.',
    passage:
        'By the time the conference ended, the delegates ____ several key '
        'agreements.',
    options: ['have finalised', 'had finalised', 'were finalising', 'finalise'],
    correctIndex: 1,
    explanation:
        'The past perfect ("had finalised") shows an action completed before '
        'another past event ("the conference ended").',
  ),
  PlacementQuestion(
    category: 'Vocabulary',
    type: 'Word meaning',
    prompt: 'Which word is closest in meaning to "substantial"?',
    options: ['Considerable', 'Temporary', 'Doubtful', 'Narrow'],
    correctIndex: 0,
    explanation:
        '"Substantial" means large in size or importance, like '
        '"considerable".',
  ),
  PlacementQuestion(
    category: 'Grammar',
    type: 'Sentence completion',
    prompt: 'Choose the word that completes the sentence.',
    passage:
        'The number of applicants rose sharply, ____ the deadline was '
        'extended by a week.',
    options: ['despite', 'so', 'although', 'unless'],
    correctIndex: 1,
    explanation:
        '"So" introduces a result: the deadline was extended because '
        'applications rose.',
  ),
  PlacementQuestion(
    category: 'Vocabulary',
    type: 'Collocation',
    prompt: 'Which verb best completes the phrase?',
    passage: 'Researchers ____ a survey of 500 households.',
    options: ['made', 'did', 'conducted', 'performed up'],
    correctIndex: 2,
    explanation: '"Conduct a survey" is the natural academic collocation.',
  ),
  PlacementQuestion(
    category: 'Reading',
    type: 'Main idea',
    prompt: 'What is the passage mainly about?',
    passage: _campusPassage,
    options: [
      'Why students prefer studying alone',
      'Different views on keeping libraries open all night',
      'How exams affect part-time work',
      'Rules for using university libraries',
    ],
    correctIndex: 1,
    explanation:
        'The passage presents supporters\' and critics\' views on 24-hour '
        'library opening.',
  ),
  PlacementQuestion(
    category: 'Reading',
    type: 'True / False / Not Given',
    prompt:
        'Statement: "Most students who used the library late at night '
        'studied alone."',
    passage: _campusPassage,
    options: ['True', 'False', 'Not Given'],
    correctIndex: 1,
    explanation:
        'The survey found most late-night users studied in groups, so the '
        'statement is false.',
  ),
  PlacementQuestion(
    category: 'Vocabulary',
    type: 'Word in context',
    prompt: 'In the sentence, "mitigate" means…',
    passage: 'New flood barriers were built to mitigate the risk to homes.',
    options: ['increase', 'reduce', 'measure', 'ignore'],
    correctIndex: 1,
    explanation: '"Mitigate" means to make something less severe.',
  ),
];
