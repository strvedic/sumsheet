import 'dart:math';

/// Everything a generator needs to build one question.
///
/// The random source is seeded, so the same seed always reproduces the same
/// worksheet. That matters for teachers: "worksheet #4812" must print
/// identically every time, and the answer key must match.
class GenContext {
  GenContext({
    required this.skillId,
    required this.difficulty,
    required int seed,
  }) : rng = Random(seed);

  final String skillId;

  /// 1 (easiest) to 5 (hardest) within this skill.
  final int difficulty;

  final Random rng;

  /// Random integer in [min, max] inclusive.
  int int_(int min, int max) => min + rng.nextInt(max - min + 1);

  /// Random integer in [min, max] inclusive, excluding [avoid].
  int intExcept(int min, int max, Set<int> avoid) {
    for (var i = 0; i < 200; i++) {
      final v = int_(min, max);
      if (!avoid.contains(v)) return v;
    }
    // Fall back to a linear scan so we can never hang.
    for (var v = min; v <= max; v++) {
      if (!avoid.contains(v)) return v;
    }
    return min;
  }

  T pick<T>(List<T> options) => options[rng.nextInt(options.length)];

  bool coin() => rng.nextBool();

  /// Scales a value band by difficulty. At difficulty 1 you get [easy],
  /// at difficulty 5 you get [hard], linearly interpolated in between.
  int band(int easy, int hard) {
    final t = (difficulty - 1) / 4.0;
    return (easy + (hard - easy) * t).round();
  }

  /// Picks from [options], **written easiest first**, letting the level decide
  /// which end of the list is in play.
  ///
  /// [band] only ever scaled numbers, which meant a whole class of skills had
  /// nowhere to put the level. "How many faces does this solid have?" has no
  /// number to grow - the difficulty is entirely in *which* solid is asked
  /// about - so those generators picked from the full list every time and a
  /// teacher who chose Hardest was handed the same sheet as Easiest. Forty-three
  /// of the hundred and fifty-five skills behaved that way.
  ///
  /// The window slides rather than jumps, and it is wider than a fifth of the
  /// list, so neighbouring levels still overlap. A sheet has to stay varied: a
  /// Hardest window of one item would print the same question twenty times.
  T pickByLevel<T>(List<T> options) {
    if (options.length < 2) return options.first;
    final width = max(2, (options.length * 0.6).ceil());
    final slide = options.length - width;
    final lo = (slide * (difficulty - 1) / 4.0).round();
    return options[lo + rng.nextInt(width)];
  }

  /// Which of several question shapes to ask, [easiest first].
  ///
  /// The same idea as [pickByLevel], named for how it reads at the call site:
  /// `switch (c.variantByLevel(4))` says the four branches below are in order
  /// of how hard they are, which is a claim worth making out loud.
  int variantByLevel(int count) =>
      pickByLevel(List<int>.generate(count, (i) => i));

  /// Builds multiple-choice options around a correct numeric answer.
  /// Distractors are near misses, which is what makes MCQ diagnostic:
  /// picking "carry forgotten" tells you more than picking a random number.
  List<String> choicesAround(int correct, {List<int> distractors = const []}) {
    // Most answers here are counts or lengths, where a negative option is
    // obviously wrong and wastes a slot. But when the answer itself IS
    // negative - a determinant, a slope, an integer sum - the distractors have
    // to be allowed negative too, or every wrong option gives the sign away.
    bool sensible(int v) => correct < 0 || v >= 0;

    final set = <int>{correct};
    for (final d in distractors) {
      if (d != correct && sensible(d)) set.add(d);
    }
    var guard = 0;
    while (set.length < 4 && guard++ < 100) {
      final spread = max(2, (correct.abs() * 0.2).round());
      final cand = correct + int_(-spread, spread);
      if (cand != correct && sensible(cand)) set.add(cand);
    }
    // Top up with simple offsets if the spread was too tight to find four.
    var off = 1;
    while (set.length < 4 && off < 500) {
      if (sensible(correct + off)) set.add(correct + off);
      off++;
    }
    final list = set.toList()..shuffle(rng);
    return list.map((e) => e.toString()).toList();
  }
}
