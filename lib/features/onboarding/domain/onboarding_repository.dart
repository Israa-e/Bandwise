import 'onboarding_state.dart';
import 'placement.dart';

/// Stores onboarding answers on the device.
abstract interface class OnboardingRepository {
  /// Returns the saved state, or a fresh state if nothing is saved.
  Future<OnboardingState> load();

  Future<void> save(OnboardingState state);

  Future<void> clear();
}

/// Supplies placement check questions.
abstract interface class PlacementRepository {
  Future<List<PlacementQuestion>> fetchQuestions();
}
