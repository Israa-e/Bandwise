import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_placeholder_screens.dart';
import '../../features/dev_gallery/presentation/component_gallery_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/learn/presentation/learn_screen.dart';
import '../../features/lesson/presentation/lesson_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/onboarding/domain/onboarding_state.dart';
import '../../features/onboarding/presentation/current_level_screen.dart';
import '../../features/onboarding/presentation/onboarding_controller.dart';
import '../../features/onboarding/presentation/daily_time_screen.dart';
import '../../features/onboarding/presentation/exam_date_screen.dart';
import '../../features/onboarding/presentation/onboarding_navigation.dart';
import '../../features/onboarding/presentation/placement_screen.dart';
import '../../features/onboarding/presentation/plan_screen.dart';
import '../../features/onboarding/presentation/skills_screen.dart';
import '../../features/onboarding/presentation/target_band_screen.dart';
import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/practice/presentation/practice_screen.dart';
import '../../features/practice/presentation/skill_coming_soon_screen.dart';
import '../../features/reading/domain/reading.dart';
import '../../features/reading/presentation/reading_hub_screen.dart';
import '../../features/reading/presentation/reading_session_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/review/presentation/review_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../models/skill.dart';
import '../widgets/app_bottom_nav.dart';
import 'app_routes.dart';

/// The app router.
///
/// The five tabs live in a [StatefulShellRoute] so each tab keeps its own
/// navigation stack. Routes that must hide the bottom nav (e.g. timed exams)
/// go at the top level and use `rootNavigatorKey`.
final routerProvider = Provider<GoRouter>((ref) {
  // One key per router: a shared global key would let a new router adopt
  // the previous router's Navigator (and its stale pages).
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) => _guard(ref, state.matchedLocation),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      for (final step in OnboardingStep.values)
        GoRoute(
          path: onboardingPath(step),
          builder: (context, state) => _onboardingScreen(step),
        ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.createAccount,
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.lesson}/:id',
        builder: (context, state) =>
            LessonScreen(lessonId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.review,
        builder: (context, state) => const ReviewScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.reading}/:id',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return ReadingSessionScreen(
            passageId: state.pathParameters['id']!,
            mode: query['mode'] == 'timed'
                ? ReadingMode.timed
                : ReadingMode.learning,
            type: ReadingQuestionType.values
                .where((t) => t.name == query['type'])
                .firstOrNull,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _TabShell(shell: shell),
        branches: [
          _branch(AppRoutes.home, const HomeScreen()),
          _branch(AppRoutes.learn, const LearnScreen()),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.practice,
                builder: (context, state) {
                  final name = state.uri.queryParameters['skill'];
                  return PracticeScreen(
                    initialSkill: Skill.values
                        .where((s) => s.name == name)
                        .firstOrNull,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'reading',
                    builder: (context, state) => const ReadingHubScreen(),
                  ),
                  GoRoute(
                    path: 'skill/:skill',
                    builder: (context, state) => SkillComingSoonScreen(
                      skill:
                          Skill.values
                              .where(
                                (s) => s.name == state.pathParameters['skill'],
                              )
                              .firstOrNull ??
                          Skill.listening,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _branch(AppRoutes.progress, const ProgressScreen()),
          _branch(AppRoutes.profile, const ProfileScreen()),
        ],
      ),
      if (kDebugMode)
        GoRoute(
          path: AppRoutes.componentGallery,
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) => const ComponentGalleryScreen(),
        ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Screens that need onboarding to be finished: the tabs and everything
/// opened from them.
const _mainPaths = [
  AppRoutes.home,
  AppRoutes.learn,
  AppRoutes.practice,
  AppRoutes.progress,
  AppRoutes.profile,
  AppRoutes.lesson,
  AppRoutes.review,
  AppRoutes.notifications,
  AppRoutes.reading,
];

bool _isMainPath(String location) =>
    _mainPaths.any((path) => location == path || location.startsWith('$path/'));

/// Keeps navigation consistent with saved onboarding state, including when
/// the platform restores a URL (web refresh, deep link):
/// - until saved state has loaded, everything goes through the splash;
/// - unfinished onboarding can't open the main tabs or screens under them;
/// - finished onboarding can't reopen onboarding screens.
String? _guard(Ref ref, String location) {
  final onboarding = ref.read(onboardingControllerProvider);
  if (!onboarding.hasValue) {
    return location == AppRoutes.splash ? null : AppRoutes.splash;
  }
  final state = onboarding.requireValue;
  final inOnboarding =
      location == AppRoutes.welcome ||
      location.startsWith('${AppRoutes.onboarding}/');
  if (!state.completed && _isMainPath(location)) {
    return onboardingPath(state.step);
  }
  if (state.completed && inOnboarding) return AppRoutes.home;
  return null;
}

Widget _onboardingScreen(OnboardingStep step) => switch (step) {
  OnboardingStep.welcome => const WelcomeScreen(),
  OnboardingStep.targetBand => const TargetBandScreen(),
  OnboardingStep.examDate => const ExamDateScreen(),
  OnboardingStep.currentLevel => const CurrentLevelScreen(),
  OnboardingStep.dailyTime => const DailyTimeScreen(),
  OnboardingStep.skills => const SkillsScreen(),
  OnboardingStep.placement => const PlacementScreen(),
  OnboardingStep.plan => const PlanScreen(),
};

StatefulShellBranch _branch(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);

class _TabShell extends StatelessWidget {
  const _TabShell({required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: AppBottomNav(
        currentIndex: shell.currentIndex,
        // Tapping the current tab again returns it to its root.
        onTap: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
    );
  }
}
