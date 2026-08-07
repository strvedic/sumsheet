import 'dart:io';

import 'package:maths_engine/maths_engine.dart';

/// Dumps every hint and worked-solution line so the wording can be judged for
/// the age it is actually aimed at, and flags the ones most likely to be too
/// hard to read.
///
/// A Level 1 hint is read by a six-year-old. Anything long, passive, or full of
/// three-syllable words is a hint that will simply not be read.
void main(List<String> args) {
  final map = SkillMap.fromJsonString(
    File('../skill-map.json').readAsStringSync(),
  );
  ensureGeneratorsRegistered();

  final maxLevel = args.isEmpty ? 20 : int.parse(args.first);

  // Deliberately NOT a list of maths words. "multiply", "remainder" and
  // "denominator" are vocabulary the app is meant to be teaching - replacing
  // them with baby talk would make the app worse, not kinder. What actually
  // blocks a child is ordinary English that happens to be adult.
  const hardWords = [
    'approximately', 'corresponding', 'proportion', 'substituting',
    'eliminate', 'eliminating', 'respectively', 'consecutive', 'determine',
    'quantity', 'original', 'outcomes', 'obtain', 'derive', 'via',
    'utilise', 'compute', 'denote', 'expression is', 'thus', 'hence',
    'therefore', 'in order to', 'as follows',
  ];

  final skills = map.all.where(hasGenerator).where((s) => s.level <= maxLevel)
      .toList()
    ..sort((a, b) => a.level != b.level
        ? a.level.compareTo(b.level)
        : a.id.compareTo(b.id));

  var flagged = 0;
  for (final s in skills) {
    final q = generateQuestion(skill: s, difficulty: 3, seed: 7);
    final lines = <String>[if (q.hint != null) 'HINT: ${q.hint}',
      ...q.steps.map((e) => '      $e')];

    final problems = <String>[];
    for (final raw in [if (q.hint != null) q.hint!, ...q.steps]) {
      final words = raw.split(RegExp(r'\s+'));
      if (words.length > 14) problems.add('long(${words.length}w)');
      final hard = hardWords
          .where((h) => raw.toLowerCase().contains(h))
          .toSet();
      if (hard.isNotEmpty) problems.add('hard:${hard.join("/")}');
    }

    if (problems.isEmpty) continue;
    flagged++;
    print('L${s.level.toString().padLeft(2)}  ${s.id}');
    for (final l in lines) {
      print('     $l');
    }
    print('     >> ${problems.toSet().join('  ')}');
    print('');
  }
  print('=' * 60);
  print('$flagged of ${skills.length} skills flagged for wording');
}
