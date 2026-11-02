# Course content review (Phase 9)

Every new question (95: 12 lessons × 3–4 scored exercises, plus 30 checkpoint
questions) was re-solved before shipping. The Lesson 1s predate this review.

## How it was checked

1. **Automated** (`test/course_content_test.dart`): unique ids; 6 exercises per
   lesson and 10 per checkpoint (two from each of the unit's five lessons);
   four distinct options and one `correctIndex`; one gap per fill-in-the-blank;
   flashcard words unique across the course; no "band" text or decimals; British
   spelling (colour, organise, analyse, centre, behaviour, programme…); no
   explanation that cites an option letter or position ("the first option"),
   because review shuffles the options; correct answers spread evenly over
   positions A–D (24/24/24/23).
2. **Blind solve.** A separate reader was given only the questions and options
   (no answers, no explanations, no access to the project) and asked to answer
   each as a teacher would and to flag anything with a second defensible answer
   or confusing wording.
   Result: 95/95 answers matched the key. Two questions were flagged.
3. **Explanation pass** by the author: every explanation says why the answer is
   right and why the most tempting wrong option is wrong.

## Fixed after review

| Id | Problem | Change |
| --- | --- | --- |
| `u1-l4-e3` ("a conclusion") | "make a conclusion" is used by many writers, so *make* was a second defensible answer. | Replaced the option *make* with *put*; the explanation now says why learners are tempted by "make a decision". |
| `u3-l5-e1` (what comes next in a paragraph) | An example can follow a topic sentence directly; "next" relied on an unstated point → explanation → example convention. | The prompt now states the pattern. |
| `u3-l2-e3`, `u3-l3-e4`, `u3-l4-e2`, `u3-l4-e6`, `u3-l5-e4`, `u2-l3-e3`, `u2-l4-e3`, `u2-l5-e5`, `u1-l5-e3`, `u1-l5-e6` | Explanations pointed at options by position ("the first version", "option A"). Options are shuffled in the review queue, so these would be wrong there. | Reworded to quote the option's content; a test now rejects positional wording. |
| `u3-l4-e4` | One distractor ("wonder that") was merely odd, not clearly wrong. | Replaced by *regret*, which is grammatical but contradicts the argument. |
| all new questions | Correct answers sat at position A only 3 times in 95. | Options re-ordered; now evenly spread. |

## Changed for pronunciation audio

| Id | Change |
| --- | --- |
| `u1-l2-e1` | The flashcard word *assert* became *maintain* (same reporting-verb purpose, same `that` pattern). The speech check could not confirm any take of "assert" (the recogniser heard "A 30" or "assertive" every time, alone or after a carrier phrase) and an unchecked recording should not ship. |

## Kept, but worth knowing

These have exactly one best answer, but a learner can reach the wrong one for a
reason the explanation addresses. They were left as they are on purpose.

- `u2-checkpoint-l1-e2` ("The sample was small, ____ the results should be
  treated with caution"): *although* is grammatical here, but gives an illogical
  contrast. The explanation says so.
- `u2-l4-e6` ("If the experiment ____ repeated"): *is repeated* would also be
  correct English, but it is not offered; *are*, *will be* and *would be* are all
  wrong.
- `u2-l3-e5` ("most direct way"): the passive versions are grammatical; the
  question asks for the most direct one.
- `u3-l4-e5` (position of the thesis): relies on the standard short-essay
  convention of stating the position in the introduction, which the
  explanation states.
- `u3-checkpoint-l1-e1`: "significant" can mean statistically significant; in
  this sentence *notable* is still the only fit.

## Fill-in-the-blank answers

The brief asks for every accepted typed variant to be listed. `FillBlankExercise`
in this app is option-based (the learner picks one of four options), not typed,
so there is no free-text matching. Each question has exactly one correct option
and the options are checked to be distinct, ignoring case and spacing.
