/// A single generated practice question.
///
/// Every question carries its own worked solution. A student who gets stuck
/// must never hit a dead end - that is the difference between practice that
/// builds confidence and practice that kills it.
/// Turns the plain notation generators write into real mathematical notation.
///
/// Generators are easier to write and read using "x^2" and "root(50)", but a
/// student should never see that - it is not how maths is written on a board
/// or in a textbook, and to a child it just looks wrong.
///
/// Applied to displayed text only. Answers are left exactly as generated, so
/// what the student types still has to match what the generator produced.
/// Powers are deliberately LEFT as "x^2" here rather than converted to "x²".
///
/// Unicode superscripts cannot be trusted: a real Samsung phone rendered ³ and
/// ⁵ but silently dropped ⁴, turning "3^5 / 3^4" into "3⁵ / 3 " on screen. The
/// PDF font drops ⁴-⁹ and √ entirely. Both failures are invisible - no error,
/// just missing maths.
///
/// So the engine emits plain, portable text and each display surface raises the
/// digits itself: the app draws them smaller and higher using ordinary 0-9,
/// which exists in every font, and the worksheet keeps "x^4" as written.
String mathify(String s) =>
    // Only the bracketed form. Prose like "the square root of 49" stays as
    // words, and answers such as "1/root2" are left alone so typed answers
    // still match.
    s.replaceAllMapped(
      RegExp(r'root\(([^()]*)\)'),
      (m) => '√${m.group(1)}',
    );

/// Writes a coefficient against a variable the way algebra is written.
///
///     term(3, 'x')   ->  "3x"
///     term(1, 'x')   ->  "x"
///     term(-1, 'x')  ->  "-x"
///
/// Nobody writes "1x". Generators built terms by interpolating the coefficient
/// straight in - `'${a}x + $b'` - so whenever the coefficient came out 1 the
/// sheet printed "1x^2 + 7x", "Solve 2x + 1 = 1x + 11", and an answer key
/// saying "1x+10y". Each is correct arithmetic and none of it is how the
/// textbook the child is working from writes it.
///
/// [power] follows the same rule one level up, because "4x^1" is the same kind
/// of wrong as "1x" - the exponent of one is never written either:
///
///     term(4, 'x', power: 3)  ->  "4x^3"
///     term(4, 'x', power: 1)  ->  "4x"
///     term(4, 'x', power: 0)  ->  "4"
///
/// A coefficient of 0 is deliberately NOT dropped. A vanishing term has to be
/// left out by whoever is building the expression, because removing it here
/// would leave a dangling "+" in the middle of the line.
///
/// Takes any [Object] and judges it by what it prints as, so a [Fraction]
/// coefficient works too: `Fraction(2, 2)` reduces to 1, and "1x^2 + C" is as
/// wrong coming out of an integral as it is anywhere else.
String term(Object coefficient, String variable, {int power = 1}) {
  // x^0 is 1, so the variable disappears and the coefficient stands alone.
  if (power == 0) return '$coefficient';
  final body = power == 1 ? variable : '$variable^$power';
  return switch ('$coefficient') {
    '1' => body,
    '-1' => '-$body',
    final c => '$c$body',
  };
}

class Question {
  Question({
    required this.skillId,
    required String prompt,
    required this.answer,
    required this.difficulty,
    List<String> steps = const [],
    this.choices = const [],
    String? hint,
    this.diagram,
  })  : prompt = mathify(prompt),
        steps = steps.map(mathify).toList(growable: false),
        hint = hint == null ? null : mathify(hint);

  /// Which skill in skill-map.json this question tests.
  final String skillId;

  /// The question as shown to the student, e.g. "47 + 38 = ?".
  final String prompt;

  /// The correct answer in canonical form, e.g. "85".
  final String answer;

  /// 1 (easiest) to 5 (hardest) within this skill.
  final int difficulty;

  /// Worked solution, one line per step. Shown after a wrong answer.
  final List<String> steps;

  /// Multiple choice options including the answer. Empty means free entry.
  final List<String> choices;

  /// A nudge shown before the full solution, so the student still does the work.
  final String? hint;

  /// An optional picture to draw above the question, as a tiny spec string.
  ///
  /// Some questions are close to meaningless without one. Asking a six-year-old
  /// "how many sides does a hexagon have?" in words assumes they already know
  /// what a hexagon looks like - which is the very thing being taught.
  ///
  /// Kept as a spec rather than an image so the app draws it with code: no
  /// asset files, no app-size cost, sharp at any size, and the same shapes can
  /// be drawn into worksheet PDFs.
  ///
  ///   polygon:6            regular hexagon
  ///   solid:cube           a 3D solid
  ///   angle:115            an angle of that many degrees
  ///   bars:Mon=12,Tue=18   a bar chart
  ///   pie:25               a pie chart with that slice shaded
  final String? diagram;

  /// Accepts a student's typed answer, tolerating whitespace, case and
  /// harmless formatting differences like "1/2" vs "1 / 2" or "0.50" vs "0.5".
  bool isCorrect(String input) => _normalise(input) == _normalise(answer);

  static String _normalise(String s) {
    var t = s.trim().toLowerCase();
    // A student writing "9 remainder 2" has done the maths correctly and must
    // not be marked wrong over notation. Longest form first, since "remainder"
    // contains "rem".
    t = t.replaceAll('remainder', 'r').replaceAll('rem', 'r');
    t = t.replaceAll(' ', '');
    // "x + 10y" and "1x + 10y" are the same answer. The sheet now prints the
    // first, but a student who writes the coefficient in has done the algebra
    // correctly and must not be marked wrong over notation - and this also
    // keeps every answer key written before the change still matching.
    //
    // The lookbehind matters: the 1 in "21x" is part of twenty-one.
    t = t.replaceAll(RegExp(r'(?<![\d.])1(?=[a-z])'), '');
    // Trim trailing zeros on decimals so 0.50 == 0.5 and 4.0 == 4.
    if (RegExp(r'^-?\d+\.\d+$').hasMatch(t)) {
      t = t.replaceFirst(RegExp(r'0+$'), '');
      if (t.endsWith('.')) t = t.substring(0, t.length - 1);
    }
    return t;
  }

  @override
  String toString() => '$prompt  ->  $answer';
}
