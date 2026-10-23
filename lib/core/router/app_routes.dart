import '../models/skill.dart';

/// Route paths.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const createAccount = '/create-account';
  static const forgotPassword = '/forgot-password';

  /// Log in with [email] filled in.
  static String loginWith(String email) => email.isEmpty
      ? login
      : Uri(path: login, queryParameters: {'email': email}).toString();

  /// Password reset with [email] filled in.
  static String forgotPasswordWith(String email) => email.isEmpty
      ? forgotPassword
      : Uri(path: forgotPassword, queryParameters: {'email': email}).toString();

  static const home = '/home';
  static const learn = '/learn';
  static const practice = '/practice';
  static const progress = '/progress';
  static const profile = '/profile';

  // Full-screen routes outside the tab shell (no bottom nav).
  static const lesson = '/lesson';
  static const review = '/review';
  static const notifications = '/notifications';
  static const reading = '/reading';
  static const listening = '/listening';
  static const speaking = '/speaking';
  static const writing = '/writing';

  /// Reading hub, inside the Practice tab.
  static const readingHub = '$practice/reading';

  /// The Reading hub in learning mode with question type [typeName]
  /// preselected.
  static String readingHubFor(String typeName) =>
      Uri(path: readingHub, queryParameters: {'type': typeName}).toString();

  /// Listening hub, inside the Practice tab.
  static const listeningHub = '$practice/listening';

  /// The Listening hub with a set that has question type [typeName]
  /// preselected.
  static String listeningHubFor(String typeName) =>
      Uri(path: listeningHub, queryParameters: {'type': typeName}).toString();

  /// A listening session.
  static String listeningSession(String setId, {required bool timed}) => Uri(
    path: '$listening/$setId',
    queryParameters: {'mode': timed ? 'timed' : 'learning'},
  ).toString();

  /// Speaking hub, inside the Practice tab.
  static const speakingHub = '$practice/speaking';

  /// Practice or Confidence mode ([mode] by name) on one Part 1 topic or
  /// one cue card ([setId]) for [part] 1–3.
  static String speakingPractice({
    required String mode,
    required int part,
    required String setId,
    bool transcript = false,
  }) => Uri(
    path: '$speaking/$mode',
    queryParameters: {
      'part': '$part',
      'set': setId,
      if (transcript) 'transcript': '1',
    },
  ).toString();

  /// The Timed test.
  static String speakingTest({bool transcript = false}) => Uri(
    path: '$speaking/test',
    queryParameters: transcript ? {'transcript': '1'} : null,
  ).toString();

  /// The self-review of a finished attempt.
  static String speakingReview(String attemptId) =>
      '$speaking/review/$attemptId';

  /// Notebooks, inside the Progress tab.
  static const mistakeNotebook = '$progress/mistakes';
  static const vocabularyNotebook = '$progress/vocabulary';

  /// Profile screens, inside the Profile tab.
  static const privacy = '$profile/privacy';
  static const privacyPolicy = '$profile/privacy/policy';
  static const terms = '$profile/privacy/terms';

  /// Editing one part of the study plan (no bottom nav).
  static const editPlan = '/plan';
  static const editTarget = '$editPlan/target';
  static const editExamDate = '$editPlan/exam-date';
  static const editDailyTime = '$editPlan/daily-time';
  static const editSkills = '$editPlan/skills';

  /// Writing hub, inside the Practice tab.
  static const writingHub = '$practice/writing';

  /// The editor for a new essay on [taskId], or its saved draft.
  static String writingTask(String taskId, {required bool timed}) => Uri(
    path: '$writing/task/$taskId',
    queryParameters: {'mode': timed ? 'timed' : 'learning'},
  ).toString();

  /// The editor for revising [submissionId].
  static String writingRevise(String submissionId) =>
      '$writing/revise/$submissionId';

  /// Feedback on a submitted essay. [timeUp] notes that it was submitted
  /// when the time ran out.
  static String writingResult(String submissionId, {bool timeUp = false}) =>
      Uri(
        path: '$writing/submission/$submissionId',
        queryParameters: timeUp ? {'timeUp': '1'} : null,
      ).toString();

  static String writingCriterion(String submissionId, String criterionId) =>
      '$writing/submission/$submissionId/criterion/$criterionId';

  static String writingEssay(String submissionId) =>
      '$writing/submission/$submissionId/essay';

  static String writingCompare(String submissionId) =>
      '$writing/submission/$submissionId/compare';

  /// "Coming soon" page for a skill without practice yet.
  static String practiceSkill(Skill skill) => '$practice/skill/${skill.name}';

  /// A reading session. [type] limits it to one question type.
  static String readingSession(
    String passageId, {
    required bool timed,
    String? type,
  }) => Uri(
    path: '$reading/$passageId',
    queryParameters: {'mode': timed ? 'timed' : 'learning', 'type': ?type},
  ).toString();

  static String lessonPath(String lessonId) => '$lesson/$lessonId';

  /// The Practice tab, optionally with [skill] preselected.
  static String practiceFor(Skill? skill) =>
      skill == null ? practice : '$practice?skill=${skill.name}';

  /// Debug-only component gallery.
  static const componentGallery = '/dev/gallery';
}
