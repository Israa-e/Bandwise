import 'dart:math';

/// A shuffled display order for [count] answer options: a permutation of
/// 0..count-1. The same [seed] and [key] always give the same order, so a
/// question keeps its order for the whole session (seed) and each question
/// gets its own (key).
List<int> shuffledOptionOrder(
  int count, {
  required int seed,
  required String key,
}) {
  var keyHash = 0;
  // A stable string hash (String.hashCode may differ between runs).
  for (final unit in key.codeUnits) {
    keyHash = (keyHash * 31 + unit) & 0x3fffffff;
  }
  return List.generate(count, (i) => i)..shuffle(Random(seed ^ keyHash));
}
