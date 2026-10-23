import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/log_in_screen.dart';
import '../../features/auth/presentation/sign_up_screen.dart';
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
import '../../features/listening/domain/listening.dart';
import '../../features/listening/presentation/listening_hub_screen.dart';
import '../../features/listening/presentation/listening_session_screen.dart';
import '../../features/reading/domain/reading.dart';
import '../../features/speaking/domain/speaking.dart';
import '../../features/speaking/presentation/speaking_hub_screen.dart';
import '../../features/speaking/presentation/speaking_practice_screen.dart';
import '../../features/speaking/presentation/speaking_review_screen.dart';
import '../../features/speaking/presentation/speaking_test_screen.dart';
import '../../features/reading/presentation/reading_hub_screen.dart';
import '../../features/reading/presentation/reading_session_screen.dart';
import '../../features/profile/presentation/privacy_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/progress/presentation/mistake_notebook_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/progress/presentation/vocabulary_notebook_screen.dart';
import '../../features/review/presentation/review_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/writing/domain/writing.dart';
import '../../features/writing/presentation/annotated_essay_screen.dart';
import '../../features/writing/presentation/criterion_detail_screen.dart';
import '../../features/writing/presentation/revision_compare_screen.dart';
import '../../features/writing/presentation/writing_editor_screen.dart';
import '../../features/writing/presentation/writing_hub_screen.dart';
import '../../features/writing/presentation/writing_result_screen.dart';
import '../models/skill.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/coming_soon_scaffold.dart';
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
        builder: (context, state) =>
            LogInScreen(initialEmail: state.uri.queryParameters['email']),
      ),
      GoRoute(
        path: AppRoutes.createAccount,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => ForgotPasswordScreen(
          initialEmail: state.uri.queryParameters['email'],
        ),
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
        path: '${AppRoutes.speaking}/test',
        builder: (context, state) => SpeakingTestScreen(
          transcript: state.uri.queryParameters['transcript'] == '1',
        ),
      ),
      GoRoute(
        path: '${AppRoutes.speaking}/review/:id',
        builder: (context, state) =>
            SpeakingReviewScreen(attemptId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '${AppRoutes.speaking}/:mode',
        builder: (context, state) {
          final query = state.uri.queryParameters;
          final part = int.tryParse(query['part'] ?? '') ?? 1;
          return SpeakingPracticeScreen(
            mode: state.pathParameters['mode'] == 'confidence'
                ? SpeakingMode.confidence
                : SpeakingMode.practice,
            part: SpeakingPart.values[(part - 1).clamp(0, 2)],
            setId: query['set'] ?? '',
            transcript: query['transcript'] == '1',
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.listening}/:id',
        builder: (context, state) => ListeningSessionScreen(
          setId: state.pathParameters['id']!,
          mode: state.uri.queryParameters['mode'] == 'timed'
              ? ListeningMode.timed
              : ListeningMode.learning,
        ),
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
        path: '${AppRoutes.writing}/task/:id',
        builder: (context, state) => WritingEditorScreen(
          taskId: state.pathParameters['id']!,
          mode: state.uri.queryParameters['mode'] == 'timed'
              ? WritingMode.timed
              : WritingMode.learning,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.writing}/revise/:id',
        builder: (context, state) => WritingEditorScreen.revise(
          submissionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '${AppRoutes.writing}/submission/:id',
        builder: (context, state) => WritingResultScreen(
          submissionId: state.pathParameters['id']!,
          timeUp: state.uri.queryParameters['timeUp'] == '1',
        ),
        routes: [
          GoRoute(
            path: 'criterion/:criterion',
            builder: (context, state) => CriterionDetailScreen(
              submissionId: state.pathParameters['id']!,
              criterionId: state.pathParameters['criterion']!,
            ),
          ),
          GoRoute(
            path: 'essay',
            builder: (context, state) =>
                AnnotatedEssayScreen(submissionId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'compare',
            builder: (context, state) => RevisionCompareScreen(
              submissionId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      // The study plan edited from the Profile, on the onboarding screens.
      GoRoute(
        path: AppRoutes.editTarget,
        builder: (context, state) => const TargetBandScreen(editing: true),
      ),
      GoRoute(
        path: AppRoutes.editExamDate,
        builder: (context, state) => const ExamDateScreen(editing: true),
      ),
      GoRoute(
        path: AppRoutes.editDailyTime,
        builder: (context, state) => const DailyTimeScreen(editing: true),
      ),
      GoRoute(
        path: AppRoutes.editSkills,
        builder: (context, state) => const SkillsScreen(editing: true),
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
                    builder: (context, state) => ReadingHubScreen(
                      initialType: ReadingQuestionType.values
                          .where(
                            (t) => t.name == state.uri.queryParameters['type'],
                          )
                          .firstOrNull,
                    ),
                  ),
                  GoRoute(
                    path: 'listening',
                    builder: (context, state) => ListeningHubScreen(
                      initialType: ListeningQuestionType.values
                          .where(
                            (t) => t.name == state.uri.queryParameters['type'],
                          )
                          .firstOrNull,
                    ),
                  ),
                  GoRoute(
                    path: 'speaking',
                    builder: (context, state) => const SpeakingHubScreen(),
                  ),
                  GoRoute(
                    path: 'writing',
                    builder: (context, state) => const WritingHubScreen(),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.progress,
                builder: (context, state) => const ProgressScreen(),
                routes: [
                  GoRoute(
                    path: 'mistakes',
                    builder: (context, state) => const MistakeNotebookScreen(),
                  ),
                  GoRoute(
                    path: 'vocabulary',
                    builder: (context, state) =>
                        const VocabularyNotebookScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'privacy',
                    builder: (context, state) => const PrivacyScreen(),
                    routes: [
                      GoRoute(
                        path: 'policy',
                        builder: (context, state) => const ComingSoonScaffold(
                          title: 'Privacy Policy',
                          icon: Icons.policy_outlined,
                          heading: 'Privacy Policy',
                          message:
                              'The full Privacy Policy will be published '
                              'here before accounts and AI review launch.',
                        ),
                      ),
                      GoRoute(
                        path: 'terms',
                        builder: (context, state) => const ComingSoonScaffold(
                          title: 'Terms of Use',
                          icon: Icons.description_outlined,
                          heading: 'Terms of Use',
                          message:
                              'The Terms of Use will be published here '
                              'before accounts launch.',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
  AppRoutes.listening,
  AppRoutes.speaking,
  AppRoutes.writing,
  AppRoutes.editPlan,
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
