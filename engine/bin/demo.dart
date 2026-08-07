import 'dart:io';

import 'package:maths_engine/maths_engine.dart';

/// Prints a coverage report, sample questions, and a simulated placement run.
void main(List<String> args) {
  final map = SkillMap.fromJsonString(
    File('../skill-map.json').readAsStringSync(),
  );
  ensureGeneratorsRegistered();

  final covered = map.all.where(hasGenerator).toList();
  final missing = map.all.where((s) => !hasGenerator(s)).toList();
  final missingCritical = missing.where((s) => s.critical).toList();

  print('=' * 68);
  print('COVERAGE');
  print('=' * 68);
  print('Skills in map        : ${map.all.length}');
  print('Have generators      : ${covered.length}');
  print('Still to write       : ${missing.length}');
  print('Gateway skills done  : '
      '${map.all.where((s) => s.critical && hasGenerator(s)).length}'
      ' of ${map.all.where((s) => s.critical).length}');
  print('');
  print('Gateway skills still missing a generator:');
  for (final s in missingCritical) {
    print('  - ${s.id.padRight(28)} ${s.name}');
  }

  print('');
  print('=' * 68);
  print('SAMPLE QUESTIONS  (same skill, difficulty 1 vs 5)');
  print('=' * 68);
  for (final id in ['add-2digit-carry', 'tables-7-8-9', 'long-division',
      'fraction-addsub-unlike', 'percentage-of-quantity', 'integer-muldiv']) {
    final skill = map[id];
    if (!hasGenerator(skill)) continue;
    print('\n${skill.name}  [${skill.id}]');
    for (final d in [1, 5]) {
      final q = generateQuestion(skill: skill, difficulty: d, seed: 42 + d);
      print('  d$d  ${q.prompt.replaceAll('\n', ' ')}');
      print('      answer: ${q.answer}');
    }
  }

  print('');
  print('=' * 68);
  print('WORKED SOLUTION  (what a stuck student sees)');
  print('=' * 68);
  final q = generateQuestion(
      skill: map['fraction-addsub-unlike'], difficulty: 3, seed: 7);
  print('Q: ${q.prompt}');
  if (q.hint != null) print('Hint: ${q.hint}');
  for (final s in q.steps) {
    print('  - $s');
  }
  print('Answer: ${q.answer}');

  print('');
  print('=' * 68);
  print('PLACEMENT RUN');
  print('=' * 68);
  // Simulate a Class 10 student who is fine until integer sign rules.
  const brokenAt = 'integer-muldiv';
  final session = PlacementSession(
      map: map, targetSkillId: 'quadratic-factorise', seed: 5);
  final chain = session.chain;
  final breakIndex = chain.indexWhere((s) => s.id == brokenAt);
  print('Target skill : quadratic-factorise (class 10)');
  print('Chain length : ${chain.length} testable gateway skills');
  print('Simulated student secretly breaks at: $brokenAt\n');

  var n = 0;
  while (!session.isComplete) {
    final question = session.nextQuestion();
    if (question == null) break;
    final idx = chain.indexWhere((s) => s.id == question.skillId);
    final correct = idx < breakIndex;
    n++;
    print('  Q$n [${question.skillId.padRight(22)}] '
        '${question.prompt.split('\n').first.padRight(28)} '
        '-> ${correct ? 'correct' : 'WRONG'}');
    session.submit(correct: correct);
  }

  final r = session.result!;
  print('\nQuestions asked : ${r.questionsAsked}  '
      '(a linear scan would have taken ${chain.length})');
  print('Mastered up to  : ${r.masteredUpTo?.name ?? '-'}');
  print('GAP FOUND       : ${r.gapSkill?.name ?? 'none'}');
  print('');
  print(r.summary);

  if (r.gapSkill != null) {
    final path = map.practicePath(
      from: r.gapSkill!.id,
      to: 'quadratic-factorise',
    );
    print('\nStudy plan - the climb from the gap back up to class 10:');
    for (var i = 0; i < path.length; i++) {
      print('  ${(i + 1).toString().padLeft(2)}. ${path[i].name} '
          '(class ${path[i].typicalClass})');
    }
  }
}
