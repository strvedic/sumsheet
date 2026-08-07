import 'dart:io';

import 'package:maths_engine/maths_engine.dart';

/// Reports, for each likely placement target, how much of a student's study
/// plan is actually playable. Any "locked" step is a dead end the student hits
/// in the app, so this number needs to be zero for the classes we care about.
void main() {
  final map = SkillMap.fromJsonString(
    File('../skill-map.json').readAsStringSync(),
  );
  ensureGeneratorsRegistered();

  const targets = [
    'tables-3-4-6',
    'div-remainder',
    'long-division',
    'fraction-addsub-unlike',
    'percentage-of-quantity',
    'linear-eq-multistep',
    'factorisation',
    'quadratic-factorise',
    'pythagoras',
    'trig-ratios',
  ];

  print('target                    chain  plan  locked');
  print('-' * 48);
  var worst = 0;
  for (final t in targets) {
    final session = PlacementSession(map: map, targetSkillId: t);
    // Worst case: the gap is at the very bottom, so the plan is longest.
    final gap = session.chain.first.id;
    final path = map.practicePath(from: gap, to: t);
    final locked = path.where((s) => !hasGenerator(s)).toList();
    if (locked.length > worst) worst = locked.length;
    print('${t.padRight(24)} '
        '${session.chain.length.toString().padLeft(5)} '
        '${path.length.toString().padLeft(5)} '
        '${locked.length.toString().padLeft(7)}'
        '${locked.isEmpty ? '' : '  <- ${locked.map((s) => s.id).join(", ")}'}');
  }
  print('');
  print(worst == 0
      ? 'No dead ends: every step of every plan is playable.'
      : 'WARNING: $worst locked step(s) - students will hit "coming soon".');
}
