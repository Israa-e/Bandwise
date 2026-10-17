import 'home_summary.dart';

/// Source of the learner's history for Home.
abstract interface class HomeRepository {
  Future<HomeSummary> fetchSummary();
}
