import '../gen_context.dart';
import '../generator.dart';
import '../question.dart';

/// Shapes, angles, triangles, circles and coordinate geometry.
///
/// Everything here is phrased in words rather than diagrams. That is a real
/// constraint - "find angle x in the figure" is impossible without a picture -
/// so each question describes the figure precisely enough to be answered from
/// the text alone.
void registerGeometry() {
  register('shapes_2d', (c) {
    const sides = {
      'triangle': 3, 'square': 4, 'rectangle': 4, 'pentagon': 5,
      'hexagon': 6, 'heptagon': 7, 'octagon': 8,
    };
    final name = c.pick(sides.keys.toList());
    final n = sides[name]!;
    return Question(
      skillId: c.skillId,
      prompt: 'How many sides does this $name have?',
      answer: '$n',
      difficulty: c.difficulty,
      // Shown, not just named. A child who has never seen a heptagon cannot
      // answer this from the word alone - and the word is what we are teaching.
      diagram: name == 'rectangle' ? 'polygon:rect' : 'polygon:$n',
      choices: c.choicesAround(n, distractors: [n - 1, n + 1, n + 2]),
      steps: ['Count the straight edges around the outside.', 'A $name has $n sides.'],
    );
  });

  register('shapes_3d', (c) {
    const solids = {
      'cube': [6, 12, 8],
      'cuboid': [6, 12, 8],
      'square pyramid': [5, 8, 5],
      'triangular prism': [5, 9, 6],
      'cylinder': [3, 2, 0],
    };
    const partNames = ['faces', 'edges', 'vertices'];
    final name = c.pick(solids.keys.toList());
    final idx = c.int_(0, name == 'cylinder' ? 0 : 2);
    final n = solids[name]![idx];
    return Question(
      skillId: c.skillId,
      prompt: 'How many ${partNames[idx]} does this $name have?',
      answer: '$n',
      difficulty: c.difficulty,
      diagram: 'solid:${name.replaceAll(' ', '-')}',
      choices: c.choicesAround(n, distractors: [n - 2, n + 2, n + 4]),
      steps: [
        idx == 0
            ? 'Faces are the flat surfaces, including the ones you cannot see.'
            : idx == 1
                ? 'Edges are the lines where two faces meet.'
                : 'Vertices are the corners.',
        'A $name has $n ${partNames[idx]}.',
      ],
    );
  });

  register('lines', (c) {
    const facts = {
      'How many endpoints does a line segment have?': '2',
      'How many endpoints does a ray have?': '1',
      'How many endpoints does a line have?': '0',
    };
    final q = c.pick(facts.keys.toList());
    final a = facts[q]!;
    return Question(
      skillId: c.skillId,
      prompt: q,
      answer: a,
      difficulty: c.difficulty,
      choices: const ['0', '1', '2'],
      steps: [
        'A line goes on forever both ways, a ray one way, a segment neither.',
        'Answer: $a.',
      ],
    );
  });

  register('angles', (c) {
    final kind = c.pick(['acute', 'right', 'obtuse', 'straight', 'reflex']);
    final deg = switch (kind) {
      'acute' => c.int_(10, 89),
      'right' => 90,
      'obtuse' => c.int_(91, 179),
      'straight' => 180,
      _ => c.int_(181, 350),
    };
    return Question(
      skillId: c.skillId,
      prompt: 'What type of angle is this?  ($deg degrees)',
      answer: kind,
      difficulty: c.difficulty,
      diagram: 'angle:$deg',
      choices: _withAnswer(
        const ['acute', 'right', 'obtuse', 'straight', 'reflex'],
        kind,
        c,
      ),
      // One rule per line. A single 24-word sentence listing all five types is
      // a wall of text, and a stuck student will not read it.
      steps: [
        'Smaller than 90 is acute.',
        'Exactly 90 is a right angle.',
        'Between 90 and 180 is obtuse.',
        'Exactly 180 is straight. Bigger than 180 is reflex.',
        'So $deg degrees is $kind.',
      ],
      hint: 'Compare it with 90 first, then with 180.',
    );
  });

  register('angle_pairs', (c) {
    final complement = c.coin();
    final total = complement ? 90 : 180;
    final a = c.int_(complement ? 10 : 20, total - 10);
    final b = total - a;
    return Question(
      skillId: c.skillId,
      prompt: 'What is the ${complement ? 'complement' : 'supplement'} '
          'of $a degrees?',
      answer: '$b',
      difficulty: c.difficulty,
      choices: c.choicesAround(b, distractors: [180 - a, 90 - a, a]),
      steps: [
        '${complement ? 'Complementary' : 'Supplementary'} angles add up to '
            '$total degrees.',
        '$total - $a = $b.',
      ],
      hint: complement ? 'Complementary pairs make 90.' : 'Supplementary pairs make 180.',
    );
  });

  register('parallel_lines', (c) {
    final a = c.int_(35, 145);
    final kind = c.pick(['corresponding', 'alternate', 'co-interior']);
    final ans = kind == 'co-interior' ? 180 - a : a;
    return Question(
      skillId: c.skillId,
      prompt: 'Two parallel lines are cut by a transversal. One angle measures '
          '$a degrees.\n\nWhat is its $kind angle?',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [180 - a, a, 90 - a.abs()]),
      steps: [
        kind == 'co-interior'
            ? 'Co-interior (allied) angles add up to 180.'
            : '$kind angles between parallel lines are equal.',
        kind == 'co-interior' ? '180 - $a = $ans.' : 'So it is also $ans.',
      ],
    );
  });

  register('triangle_angles', (c) {
    final a = c.int_(25, 100);
    final b = c.int_(20, 170 - a);
    final third = 180 - a - b;
    return Question(
      skillId: c.skillId,
      prompt: 'Two angles of a triangle are $a degrees and $b degrees.\n\n'
          'Find the third angle.',
      answer: '$third',
      difficulty: c.difficulty,
      choices: c.choicesAround(third, distractors: [180 - a, 90 - third.abs(), a + b]),
      steps: [
        'The three angles of a triangle always add up to 180.',
        '$a + $b = ${a + b}.',
        '180 - ${a + b} = $third.',
      ],
      hint: 'All three angles together make 180.',
    );
  });

  register('congruence', (c) {
    const cases = {
      'all three sides are equal': 'SSS',
      'two sides and the angle between them are equal': 'SAS',
      'two angles and the side between them are equal': 'ASA',
      'the right angle, hypotenuse and one side are equal': 'RHS',
    };
    final desc = c.pick(cases.keys.toList());
    final ans = cases[desc]!;
    return Question(
      skillId: c.skillId,
      prompt: 'Two triangles are congruent because $desc.\n\n'
          'Which congruence rule is this?',
      answer: ans,
      difficulty: c.difficulty,
      choices: _withAnswer(['SSS', 'SAS', 'ASA', 'RHS'], ans, c),
      steps: ['When $desc, the rule is $ans.'],
    );
  });

  register('similarity', (c) {
    final k = c.int_(2, c.band(3, 5));
    final small = c.int_(3, c.band(8, 15));
    final other = c.int_(3, c.band(8, 15));
    return Question(
      skillId: c.skillId,
      prompt: 'Two triangles are similar. A side of $small cm in the smaller '
          'triangle matches ${small * k} cm in the larger one.\n\n'
          'If another side of the smaller triangle is $other cm, what is the '
          'matching side of the larger triangle?',
      answer: '${other * k}',
      difficulty: c.difficulty,
      choices: c.choicesAround(other * k, distractors: [other + k, other * (k + 1)]),
      steps: [
        'Scale factor = ${small * k} / $small = $k.',
        'Every side scales by the same factor.',
        '$other x $k = ${other * k}.',
      ],
      hint: 'Find how many times bigger the second triangle is.',
    );
  });

  register('pythagoras', (c) {
    // Only Pythagorean triples, so answers are whole numbers. A student
    // fighting a calculator is not practising Pythagoras.
    final t = _pythagoreanTriple(c);
    final findHyp = c.coin();
    if (findHyp) {
      return Question(
        skillId: c.skillId,
        prompt: 'A right-angled triangle has legs of ${t[0]} cm and ${t[1]} cm.'
            '\n\nFind the hypotenuse.',
        answer: '${t[2]}',
        difficulty: c.difficulty,
        choices: c.choicesAround(t[2], distractors: [t[0] + t[1], t[2] + 1]),
        steps: [
          'Pythagoras: a^2 + b^2 = c^2.',
          '${t[0]}^2 + ${t[1]}^2 = ${t[0] * t[0]} + ${t[1] * t[1]} '
              '= ${t[2] * t[2]}.',
          'The square root of ${t[2] * t[2]} is ${t[2]}.',
        ],
        hint: 'Square both legs, add, then square root.',
      );
    }
    return Question(
      skillId: c.skillId,
      prompt: 'A right-angled triangle has a hypotenuse of ${t[2]} cm and one '
          'leg of ${t[1]} cm.\n\nFind the other leg.',
      answer: '${t[0]}',
      difficulty: c.difficulty,
      choices: c.choicesAround(t[0], distractors: [t[2] - t[1], t[0] + 2]),
      steps: [
        'Rearrange Pythagoras: a^2 = c^2 - b^2.',
        '${t[2] * t[2]} - ${t[1] * t[1]} = ${t[0] * t[0]}.',
        'The square root of ${t[0] * t[0]} is ${t[0]}.',
      ],
      hint: 'Subtract, do not add - the hypotenuse is the biggest side.',
    );
  });

  register('quadrilaterals', (c) {
    final a = c.int_(40, 140);
    return Question(
      skillId: c.skillId,
      prompt: 'One angle of a parallelogram measures $a degrees.\n\n'
          'What is the angle next to it (adjacent)?',
      answer: '${180 - a}',
      difficulty: c.difficulty,
      choices: c.choicesAround(180 - a, distractors: [a, 360 - a, 90]),
      steps: [
        'In a parallelogram, opposite angles are equal and adjacent angles '
            'add up to 180.',
        '180 - $a = ${180 - a}.',
      ],
    );
  });

  register('circle_parts', (c) {
    final r = c.int_(3, c.band(12, 40));
    if (c.coin()) {
      return Question(
        skillId: c.skillId,
        prompt: 'A circle has a radius of $r cm. What is its diameter?',
        answer: '${r * 2}',
        difficulty: c.difficulty,
        choices: c.choicesAround(r * 2, distractors: [r, r + 2, r * 4]),
        steps: ['Diameter = 2 x radius.', '2 x $r = ${r * 2}.'],
      );
    }
    return Question(
      skillId: c.skillId,
      prompt: 'A circle has a diameter of ${r * 2} cm. What is its radius?',
      answer: '$r',
      difficulty: c.difficulty,
      choices: c.choicesAround(r, distractors: [r * 2, r * 4, r + 1]),
      steps: ['Radius = diameter / 2.', '${r * 2} / 2 = $r.'],
    );
  });

  register('circle_theorems', (c) {
    final which = c.pick(['semicircle', 'centre', 'tangent']);
    if (which == 'semicircle') {
      return Question(
        skillId: c.skillId,
        prompt: 'What is the size of the angle in a semicircle '
            '(the angle standing on the diameter)?',
        answer: '90',
        difficulty: c.difficulty,
        choices: _withAnswer(['45', '60', '90', '180'], '90', c),
        steps: ['The angle in a semicircle is always a right angle: 90 degrees.'],
      );
    }
    if (which == 'tangent') {
      return Question(
        skillId: c.skillId,
        prompt: 'What angle does a tangent make with the radius at the point '
            'where it touches the circle?',
        answer: '90',
        difficulty: c.difficulty,
        choices: _withAnswer(['30', '45', '90', '180'], '90', c),
        steps: ['A tangent is always perpendicular to the radius: 90 degrees.'],
      );
    }
    final at = c.int_(20, 80);
    return Question(
      skillId: c.skillId,
      prompt: 'An angle at the circumference of a circle measures $at degrees.'
          '\n\nWhat is the angle at the centre standing on the same arc?',
      answer: '${at * 2}',
      difficulty: c.difficulty,
      choices: c.choicesAround(at * 2, distractors: [at, at ~/ 2, 180 - at]),
      steps: [
        'The angle at the centre is twice the angle at the circumference.',
        '2 x $at = ${at * 2}.',
      ],
    );
  });

  register('symmetry', (c) {
    const lines = {
      'square': 4, 'rectangle': 2, 'equilateral triangle': 3,
      'isosceles triangle': 1, 'regular pentagon': 5, 'regular hexagon': 6,
      'circle': 0,
    };
    final name = c.pick(lines.keys.where((k) => k != 'circle').toList());
    final n = lines[name]!;
    return Question(
      skillId: c.skillId,
      prompt: 'How many lines of symmetry does a $name have?',
      answer: '$n',
      difficulty: c.difficulty,
      choices: c.choicesAround(n, distractors: [n + 1, n - 1, n + 2]),
      steps: [
        'A line of symmetry folds the shape onto itself exactly.',
        'A $name has $n.',
      ],
    );
  });

  register('coordinates', (c) {
    final x = c.intExcept(-12, 12, {0});
    final y = c.intExcept(-12, 12, {0});
    final quadrant = x > 0 ? (y > 0 ? 'I' : 'IV') : (y > 0 ? 'II' : 'III');
    return Question(
      skillId: c.skillId,
      prompt: 'In which quadrant does the point ($x, $y) lie?\n\n'
          'Answer with I, II, III or IV.',
      answer: quadrant,
      difficulty: c.difficulty,
      choices: _withAnswer(['I', 'II', 'III', 'IV'], quadrant, c),
      steps: [
        'Quadrant I is (+,+), II is (-,+), III is (-,-), IV is (+,-).',
        'x is ${x > 0 ? 'positive' : 'negative'} and y is '
            '${y > 0 ? 'positive' : 'negative'}, so it is quadrant $quadrant.',
      ],
      hint: 'Check the sign of each coordinate.',
    );
  });

  register('distance_formula', (c) {
    const triples = [[3, 4, 5], [6, 8, 10], [5, 12, 13], [8, 15, 17], [9, 12, 15]];
    final t = c.pick(triples);
    final x1 = c.int_(-6, 6);
    final y1 = c.int_(-6, 6);
    final x2 = x1 + t[0];
    final y2 = y1 + t[1];
    return Question(
      skillId: c.skillId,
      prompt: 'Find the distance between the points ($x1, $y1) and ($x2, $y2).',
      answer: '${t[2]}',
      difficulty: c.difficulty,
      choices: c.choicesAround(t[2], distractors: [t[0] + t[1], t[2] + 1]),
      steps: [
        'Distance = square root of ((x2-x1) squared + (y2-y1) squared).',
        'Differences: ${t[0]} across and ${t[1]} up.',
        '${t[0]}x${t[0]} + ${t[1]}x${t[1]} = ${t[2] * t[2]}, and the square '
            'root of ${t[2] * t[2]} is ${t[2]}.',
      ],
      hint: 'It is Pythagoras with the two gaps as the legs.',
    );
  });
}

/// Builds a shuffled four-option list that always contains [answer].
List<String> _withAnswer(List<String> pool, String answer, GenContext c) {
  final others = pool.where((e) => e != answer).toList()..shuffle(c.rng);
  return [answer, ...others.take(3)]..shuffle(c.rng);
}

/// Builds a Pythagorean triple with whole-number sides.
///
/// Euclid's formula: for m > n >= 1, (m^2 - n^2, 2mn, m^2 + n^2) is always a
/// triple. Scaling by k keeps it one. A hardcoded list of ten triples meant a
/// twenty-question sheet repeated itself twice over; this covers hundreds while
/// keeping every side a whole number.
List<int> _pythagoreanTriple(GenContext c) {
  final m = c.int_(2, c.band(4, 9));
  final n = c.int_(1, m - 1);
  final k = c.int_(1, c.band(1, 3));
  final a = (m * m - n * n) * k;
  final b = 2 * m * n * k;
  final hyp = (m * m + n * n) * k;
  // Legs in ascending order, so "one leg of b" never names the longer one in a
  // way that makes the picture read oddly.
  return a <= b ? [a, b, hyp] : [b, a, hyp];
}
