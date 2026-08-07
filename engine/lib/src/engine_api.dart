import 'gen_context.dart';
import 'generator.dart';
import 'generators/advanced.dart';
import 'generators/arithmetic.dart';
import 'generators/data_trig.dart';
import 'generators/fractions.dart';
import 'generators/geometry.dart';
import 'generators/mensuration.dart';
import 'generators/number_theory.dart';
import 'generators/ratio_algebra.dart';
import 'generators/senior.dart';
import 'question.dart';
import 'skill_map.dart';

var _registered = false;

/// Wires up every generator. Safe to call repeatedly.
void ensureGeneratorsRegistered() {
  if (_registered) return;
  _registered = true;
  registerArithmetic();
  registerNumberTheory();
  registerFractions();
  registerRatioAlgebra();
  registerGeometry();
  registerMensuration();
  registerDataAndTrig();
  registerSenior();
  registerAdvanced();
}

/// True when this skill can currently produce questions.
bool hasGenerator(Skill skill) {
  ensureGeneratorsRegistered();
  return generatorRegistry.containsKey(skill.generator);
}

/// Builds one question for [skill].
///
/// [seed] makes generation reproducible: the same seed always yields the same
/// question, so a printed worksheet and its answer key can never drift apart.
Question generateQuestion({
  required Skill skill,
  required int difficulty,
  required int seed,
}) {
  ensureGeneratorsRegistered();
  final gen = generatorRegistry[skill.generator];
  if (gen == null) {
    throw UnimplementedError(
      'No generator "${skill.generator}" for skill "${skill.id}" yet.',
    );
  }
  return gen(GenContext(
    skillId: skill.id,
    difficulty: difficulty.clamp(1, 5),
    seed: seed,
  ));
}

/// What makes two questions the same question: everything the student sees.
///
/// The prompt alone is not enough. A bar-graph question carries its numbers in
/// [Question.diagram] and asks the same words every time, so deduplicating on
/// the prompt threw away every chart but the first two - a worksheet asking
/// for 20 questions got 2.
///
/// The answer is deliberately not part of this. Two questions that look
/// identical but expect different answers must never both reach one sheet,
/// and including the answer here would let exactly that pair through.
String questionIdentity(Question q) => '${q.prompt} ${q.diagram ?? ''}';

/// A set of questions for one skill, with duplicates avoided.
///
/// Returns fewer than [count] when the skill cannot produce that many distinct
/// questions - counting to ten has only ten questions in it. Callers printing a
/// worksheet must check the length rather than assume it.
List<Question> generatePractice({
  required Skill skill,
  required int count,
  int difficulty = 3,
  int seed = 1,
}) {
  final out = <Question>[];
  final seen = <String>{};
  for (var i = 0; out.length < count && i < count * 30; i++) {
    final q = generateQuestion(
      skill: skill,
      difficulty: difficulty,
      seed: seed * 104729 + i * 7717,
    );
    if (seen.add(questionIdentity(q))) out.add(q);
  }
  return out;
}
