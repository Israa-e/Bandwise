import 'listening.dart';

/// Source of listening sets.
abstract interface class ListeningRepository {
  Future<List<ListeningSet>> fetchSets();
}
