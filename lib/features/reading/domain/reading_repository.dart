import 'reading.dart';

/// Source of reading passages.
abstract interface class ReadingRepository {
  Future<List<ReadingPassage>> fetchPassages();
}
