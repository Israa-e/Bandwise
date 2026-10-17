import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learn/presentation/learn_providers.dart';
import '../../onboarding/presentation/onboarding_controller.dart';
import '../../reading/presentation/reading_providers.dart';
import '../../writing/presentation/writing_providers.dart';
import '../data/live_home_repository.dart';
import '../data/mock_home_repository.dart';
import '../domain/home_repository.dart';
import '../domain/home_summary.dart';

/// Debug-only: a mock learner to show on Home instead of live progress.
/// Null (the default) shows live progress. Set from the component gallery.
final homeFixtureProvider =
    NotifierProvider<HomeFixtureController, HomeFixture?>(
      HomeFixtureController.new,
    );

class HomeFixtureController extends Notifier<HomeFixture?> {
  @override
  HomeFixture? build() => null;

  void select(HomeFixture? fixture) => state = fixture;
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final today = ref.watch(todayProvider);
  final fixture = ref.watch(homeFixtureProvider);
  if (fixture != null) {
    return MockHomeRepository(fixture: fixture, today: today);
  }
  // Rebuilt (so Home refetches) whenever progress changes.
  return LiveHomeRepository(
    path: ref.watch(learningPathProvider.future),
    passages: ref.watch(readingPassagesProvider.future),
    writing: ref.watch(writingSubmissionsProvider.future),
    today: today,
  );
});

final homeSummaryProvider = FutureProvider<HomeSummary>(
  (ref) => ref.watch(homeRepositoryProvider).fetchSummary(),
);
