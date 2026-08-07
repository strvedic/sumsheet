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
