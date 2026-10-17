import 'package:flutter/foundation.dart';

import 'writing.dart';

enum DiffOp { same, added, removed }

/// A run of words that is the same in both drafts, or only in one.
@immutable
class DiffSegment {
  const DiffSegment(this.op, this.words);

  final DiffOp op;
  final List<String> words;

  String get text => words.join(' ');
}

/// Changes counted by type. A removal directly followed by an addition is
/// a replacement.
@immutable
class ChangeCounts {
  const ChangeCounts({this.added = 0, this.removed = 0, this.replaced = 0});

  /// Words added, not replacing anything.
  final int added;

  /// Words removed, not replaced.
  final int removed;

  /// Places where words were replaced by others.
  final int replaced;

  int get total => added + removed + replaced;

  ChangeCounts operator +(ChangeCounts o) => ChangeCounts(
    added: added + o.added,
    removed: removed + o.removed,
    replaced: replaced + o.replaced,
  );
}

/// One paragraph compared between drafts. [before] or [after] is null for
/// a paragraph that was added or removed.
@immutable
class ParagraphDiff {
  const ParagraphDiff({
    required this.index,
    required this.before,
    required this.after,
    required this.segments,
  });

  final int index;
  final String? before;
  final String? after;
  final List<DiffSegment> segments;

  bool get changed => segments.any((s) => s.op != DiffOp.same);

  ChangeCounts get counts {
    var added = 0, removed = 0, replaced = 0;
    for (var i = 0; i < segments.length; i++) {
      final s = segments[i];
      if (s.op == DiffOp.removed &&
          i + 1 < segments.length &&
          segments[i + 1].op == DiffOp.added) {
        replaced++;
        i++;
      } else if (s.op == DiffOp.added) {
        added += s.words.length;
      } else if (s.op == DiffOp.removed) {
        removed += s.words.length;
      }
    }
    return ChangeCounts(added: added, removed: removed, replaced: replaced);
  }
}

/// Compares two drafts paragraph by paragraph (by position), word by word.
List<ParagraphDiff> diffEssays(String before, String after) {
  final a = paragraphsOf(before);
  final b = paragraphsOf(after);
  return [
    for (var i = 0; i < (a.length > b.length ? a.length : b.length); i++)
      ParagraphDiff(
        index: i,
        before: i < a.length ? a[i] : null,
        after: i < b.length ? b[i] : null,
        segments: diffWords(
          i < a.length ? _words(a[i]) : const [],
          i < b.length ? _words(b[i]) : const [],
        ),
      ),
  ];
}

List<String> _words(String paragraph) =>
    paragraph.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

/// Longest-common-subsequence diff of two word lists. Punctuation stays
/// attached to its word, so "it's" → "its" is one replacement.
List<DiffSegment> diffWords(List<String> a, List<String> b) {
  final n = a.length, m = b.length;
  // lcs[i][j] = LCS length of a[i:] and b[j:].
  final lcs = List.generate(n + 1, (_) => List.filled(m + 1, 0));
  for (var i = n - 1; i >= 0; i--) {
    for (var j = m - 1; j >= 0; j--) {
      lcs[i][j] = a[i] == b[j]
          ? lcs[i + 1][j + 1] + 1
          : (lcs[i + 1][j] >= lcs[i][j + 1] ? lcs[i + 1][j] : lcs[i][j + 1]);
    }
  }
  final out = <DiffSegment>[];
  void push(DiffOp op, String word) {
    if (out.isNotEmpty && out.last.op == op) {
      out.last.words.add(word);
    } else {
      out.add(DiffSegment(op, [word]));
    }
  }

  var i = 0, j = 0;
  while (i < n && j < m) {
    if (a[i] == b[j]) {
      push(DiffOp.same, a[i]);
      i++;
      j++;
    } else if (lcs[i + 1][j] >= lcs[i][j + 1]) {
      push(DiffOp.removed, a[i++]);
    } else {
      push(DiffOp.added, b[j++]);
    }
  }
  while (i < n) {
    push(DiffOp.removed, a[i++]);
  }
  while (j < m) {
    push(DiffOp.added, b[j++]);
  }
  return out;
}
