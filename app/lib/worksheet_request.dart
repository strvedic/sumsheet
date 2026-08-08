import 'dart:typed_data';

import 'package:maths_engine/maths_engine.dart';

import 'catalogue.dart';

/// One worksheet, as asked for on the form.
class WorksheetRequest {
  const WorksheetRequest({
    required this.skills,
    required this.heading,
    required this.curriculumLabel,
    required this.count,
    required this.difficulty,
    required this.centreName,
    required this.includeAnswerKey,
    required this.includeSolutions,
    required this.workingLines,
  });

  final List<Skill> skills;
  final String heading;
  final String? curriculumLabel;
  final int count;
  final int difficulty;
  final String? centreName;
  final bool includeAnswerKey;
  final bool includeSolutions;
  final int workingLines;
}

/// A worksheet that has been built: the PDF, and what it actually contains.
class BuiltWorksheet {
  const BuiltWorksheet(this.bytes, this.filename, this.questionCount);

  final Uint8List bytes;
  final String filename;

  /// How many questions the sheet really has, which is not always how many
  /// were asked for.
  final int questionCount;
}

/// Builds the PDF for [request].
///
/// [seed] fixes the questions. Two teachers who ask for the same thing on the
/// same day should not receive the same sheet, so the caller passes a fresh
/// one - but keeping it means "worksheet 4812" can be reprinted exactly.
Future<BuiltWorksheet> buildWorksheet(
  WorksheetRequest request, {
  required int seed,
}) async {
  final questions = spreadQuestions(
    skills: request.skills,
    count: request.count,
    difficulty: request.difficulty,
    seed: seed,
  );

  final pdf = await WorksheetBuilder(
    skill: request.skills.first,
    questions: questions,
    centreName: request.centreName,
    heading: request.heading,
    curriculumLabel: request.curriculumLabel,
    includeAnswerKey: request.includeAnswerKey,
    includeSolutions: request.includeSolutions,
    workingLines: request.workingLines,
  ).build();

  return BuiltWorksheet(pdf, _filename(request), questions.length);
}

/// A filename a teacher can find again in a downloads folder six weeks later.
String _filename(WorksheetRequest r) {
  final slug = r.heading
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-|-\$'), '');
  final now = DateTime.now();
  final date = '${now.year}-${_two(now.month)}-${_two(now.day)}';
  return 'sumsheet-$slug-$date.pdf';
}

String _two(int n) => n.toString().padLeft(2, '0');

/// The complete list of skills a form selection covers.
List<Skill> skillsForSelection({
  required Catalogue catalogue,
  Chapter? chapter,
  Skill? skill,
}) {
  if (skill != null) return [skill];
  if (chapter != null) return catalogue.playableSkills(chapter);
  return const [];
}

/// The most questions this selection can produce without repeating one.
///
/// Measured by actually building the set rather than by adding up what each
/// skill could manage alone. The two are not the same, and when the slider
/// promised the sum it was over by six.
int maxQuestionsFor({
  required List<Skill> skills,
  required int difficulty,
  required int ceiling,
}) =>
    spreadQuestions(
      skills: skills,
      count: ceiling,
      difficulty: difficulty,
      seed: 1,
    ).length;

/// Draws [count] questions from [skills], as evenly as they can bear it.
///
/// Dividing the count equally and taking what comes back is not enough: if one
/// skill in the chapter runs out early, the sheet is short by that much even
/// though its other skills had more to give. A teacher told the sheet holds 28
/// then handed 22 has been lied to by the slider.
///
/// So it goes round again, asking the skills that still have something left,
/// until the count is met or nothing new comes back from anyone.
List<Question> spreadQuestions({
  required List<Skill> skills,
  required int count,
  required int difficulty,
  required int seed,
}) {
  final out = <Question>[];
  final seen = <String>{};

  // First pass takes an even share, so a chapter's sheet covers the chapter
  // rather than filling up on whichever skill came first.
  final share = (count / skills.length).ceil();

  for (var round = 0; round < 8 && out.length < count; round++) {
    final before = out.length;
    for (final s in skills) {
      if (out.length >= count) break;
      // Later rounds ask for the whole shortfall from every skill rather than
      // a slice of it. generatePractice gives itself an attempt budget from
      // the number asked for, so asking for a little means it gives up early -
      // and the rare questions left at that point are exactly the ones that
      // need the attempts.
      final want = round == 0 ? share : count;
      for (final q in generatePractice(
        skill: s,
        count: want,
        difficulty: difficulty,
        seed: seed + s.id.hashCode + round * 7717,
      )) {
        if (out.length >= count) break;
        if (seen.add(questionIdentity(q))) out.add(q);
      }
    }
    if (out.length == before) break;
  }
  return out;
}
