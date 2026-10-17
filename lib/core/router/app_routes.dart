import '../models/skill.dart';

/// Route paths.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const createAccount = '/create-account';

  static const home = '/home';
  static const learn = '/learn';
  static const practice = '/practice';
  static const progress = '/progress';
  static const profile = '/profile';

  // Full-screen routes outside the tab shell (no bottom nav).
  static const lesson = '/lesson';
  static const review = '/review';
  static const notifications = '/notifications';

  static String lessonPath(String lessonId) => '$lesson/$lessonId';

  /// The Practice tab, optionally with [skill] preselected.
  static String practiceFor(Skill? skill) =>
      skill == null ? practice : '$practice?skill=${skill.name}';

  /// Debug-only component gallery.
  static const componentGallery = '/dev/gallery';
}
