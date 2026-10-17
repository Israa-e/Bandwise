import '../domain/reading.dart';
import '../domain/reading_repository.dart';
import 'reading_content.dart';

/// Serves the bundled [readingPassages].
class MockReadingRepository implements ReadingRepository {
  const MockReadingRepository();

  @override
  Future<List<ReadingPassage>> fetchPassages() async => readingPassages;
}
