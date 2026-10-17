import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_reading_repository.dart';
import '../domain/reading.dart';
import '../domain/reading_repository.dart';

final readingRepositoryProvider = Provider<ReadingRepository>(
  (ref) => const MockReadingRepository(),
);

final readingPassagesProvider = FutureProvider<List<ReadingPassage>>(
  (ref) => ref.watch(readingRepositoryProvider).fetchPassages(),
);
