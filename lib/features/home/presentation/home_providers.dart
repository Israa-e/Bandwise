import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/presentation/onboarding_controller.dart';
import '../data/mock_home_repository.dart';
import '../domain/home_repository.dart';
import '../domain/home_summary.dart';

/// Which mock learner Home shows. Switchable from the debug component
/// gallery.
final homeFixtureProvider =
    NotifierProvider<HomeFixtureController, HomeFixture>(
      HomeFixtureController.new,
    );

class HomeFixtureController extends Notifier<HomeFixture> {
  @override
  HomeFixture build() => HomeFixture.newUser;

  void select(HomeFixture fixture) => state = fixture;
}

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => MockHomeRepository(
    fixture: ref.watch(homeFixtureProvider),
    today: ref.watch(todayProvider),
  ),
);

final homeSummaryProvider = FutureProvider<HomeSummary>(
  (ref) => ref.watch(homeRepositoryProvider).fetchSummary(),
);
