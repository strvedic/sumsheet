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
    // Easiest first, so the level can slide along it. A four-year-old knows a
    // square before a triangle and has never met a heptagon; the shape asked
    // about IS the difficulty here, because there is no number to make bigger.
    // Nonagon and decagon are here for the hard end rather than because a
    // Class 2 child is expected to name one. Without them the level had only
    // seven shapes to slide along, and a window narrow enough to make Easiest
    // and Hardest differ was also too narrow to fill a twenty-question sheet.
    const sides = {
      'square': 4, 'rectangle': 4, 'triangle': 3, 'pentagon': 5,
      'hexagon': 6, 'heptagon': 7, 'octagon': 8, 'nonagon': 9, 'decagon': 10,
    };
    String diagramFor(String name) =>
        name == 'rectangle' ? 'polygon:rect' : 'polygon:${sides[name]}';
    final names = sides.keys.toList();

    switch (c.int_(0, 3)) {
      case 0:
        final name = c.pickByLevel(names);
        final n = sides[name]!;
        return Question(
          skillId: c.skillId,
          prompt: 'How many sides does this $name have?',
          answer: '$n',
          difficulty: c.difficulty,
          // Shown, not just named. A child who has never seen a heptagon
          // cannot answer from the word alone - and the word is what we are
          // teaching.
          diagram: diagramFor(name),
          choices: c.choicesAround(n, distractors: [n - 1, n + 1, n + 2]),
          steps: [
            'Count the straight edges around the outside.',
            '${_a(name)} has $n sides.',
          ],
        );
      case 1:
        final name = c.pickByLevel(names);
        final n = sides[name]!;
        return Question(
          skillId: c.skillId,
          prompt: 'How many corners does this $name have?',
          answer: '$n',
          difficulty: c.difficulty,
          diagram: diagramFor(name),
          choices: c.choicesAround(n, distractors: [n - 1, n + 1, n + 2]),
          steps: [
            'A corner is where two sides meet.',
            'Every side ends at a corner, so a shape has as many corners as '
                'sides.',
            '${_a(name)} has $n corners.',
          ],
        );
      case 2:
        // Named from the picture, not from a description. Recognising the
        // shape on sight is the skill; the side count is the way in.
        final name = c.pickByLevel(names);
        final n = sides[name]!;
        return Question(
          skillId: c.skillId,
          prompt: 'What is the name of this shape?',
          answer: name,
          difficulty: c.difficulty,
          diagram: diagramFor(name),
          choices: _withAnswer(names, name, c),
          steps: [
            'Count the straight sides: there are $n.',
            'A shape with $n straight sides drawn like this is ${_a(name)}.',
          ],
        );
      default:
        final n = c.pickByLevel(const [4, 3, 5, 6, 7, 8, 9, 10]);
        return Question(
          skillId: c.skillId,
          prompt: 'This shape has $n straight sides.\n\n'
              'How many corners does it have?',
          answer: '$n',
          difficulty: c.difficulty,
          diagram: 'polygon:$n',
          choices: c.choicesAround(n, distractors: [n - 1, n + 1, n * 2]),
          steps: [
            'Follow the outline: each side ends where the next one begins.',
            'So the number of corners is the same as the number of sides, $n.',
          ],
          hint: 'Trace round the shape with your finger and count the turns.',
        );
    }
  });

  register('shapes_3d', (c) {
    // Faces, edges, vertices. Counted the way NCERT counts them.
    //
    // In order of how hard the solid is to hold in the head, easiest first: a
    // cube is a dice, a hexagonal prism is a pencil seen properly for the first
    // time. Nothing about a face count grows with the level, so the choice of
    // solid is where the level has to live - without this a Class 1 sheet on
    // "What is Long? What is Round?" asked for the vertices of a pentagonal
    // pyramid, and asked the same thing whichever level the teacher picked.
    const flat = {
      'cube': [6, 12, 8],
      'cuboid': [6, 12, 8],
      'square pyramid': [5, 8, 5],
      'triangular pyramid': [4, 6, 4],
      'triangular prism': [5, 9, 6],
      'pentagonal pyramid': [6, 10, 6],
      'pentagonal prism': [7, 15, 10],
      'hexagonal pyramid': [7, 12, 7],
      'hexagonal prism': [8, 18, 12],
    };
    // A curved surface makes "how many edges" a matter of convention rather
    // than of counting, so these are only ever asked about their faces.
    const curved = {'sphere': 1, 'cylinder': 3, 'cone': 2};
    const partNames = ['faces', 'edges', 'vertices'];

    String explain(int idx) => switch (idx) {
          0 => 'Faces are the flat surfaces, including the ones you cannot see.',
          1 => 'Edges are the lines where two faces meet.',
          _ => 'Vertices are the corners.',
        };

    // Named from the picture. A cube and a cuboid share the same 6, 12 and 8,
    // so the counts alone could never have picked one out anyway.
    if (c.int_(0, 3) == 3) {
      final all = [...curved.keys, ...flat.keys];
      final name = c.pickByLevel(all);
      return Question(
        skillId: c.skillId,
        prompt: 'What is the name of this solid?',
        answer: name,
        difficulty: c.difficulty,
        diagram: 'solid:${name.replaceAll(' ', '-')}',
        choices: _withAnswer(all, name, c),
        steps: [
          'Look at the flat faces and at how they meet.',
          'This solid is ${_a(name)}.',
        ],
      );
    }

    if (c.int_(0, 4) == 4) {
      final name = c.pick(curved.keys.toList());
      final n = curved[name]!;
      return Question(
        skillId: c.skillId,
        prompt: 'How many faces does this $name have?',
        answer: '$n',
        difficulty: c.difficulty,
        diagram: 'solid:$name',
        choices: c.choicesAround(n, distractors: [n + 1, n + 2, n + 3]),
        steps: [
          'Count the flat faces, then add the curved surface.',
          '${_a(name)} has $n.',
        ],
      );
    }

    final name = c.pickByLevel(flat.keys.toList());
    // Faces you can see and point at. Edges and vertices need the hidden back
    // of the solid held in mind, which is a harder job than counting.
    final idx = c.pickByLevel(const [0, 2, 1]);
    final n = flat[name]![idx];
    return Question(
      skillId: c.skillId,
      prompt: 'How many ${partNames[idx]} does this $name have?',
      answer: '$n',
      difficulty: c.difficulty,
      diagram: 'solid:${name.replaceAll(' ', '-')}',
      choices: c.choicesAround(n, distractors: [n - 2, n + 2, n + 4]),
      steps: [explain(idx), '${_a(name)} has $n ${partNames[idx]}.'],
    );
  });

  register('lines', (c) {
    const figures = {
      'line segment': 2,
      'ray': 1,
      'line': 0,
    };
    const polygonSides = {
      'triangle': 3, 'quadrilateral': 4, 'pentagon': 5,
      'hexagon': 6, 'heptagon': 7, 'octagon': 8,
    };

    switch (c.int_(0, 5)) {
      case 0:
        final name = c.pick(figures.keys.toList());
        final n = figures[name]!;
        return Question(
          skillId: c.skillId,
          prompt: 'How many endpoints does ${_a(name)} have?',
          answer: '${n}',
          difficulty: c.difficulty,
          choices: const ['0', '1', '2'],
          steps: [
            'A line goes on forever both ways, a ray one way, a segment '
                'neither.',
            'Answer: ${n}.',
          ],
        );
      case 1:
        // The same three facts, asked the other way round: from the property
        // to the name. Recognising the word is half of what this skill is.
        final name = c.pick(figures.keys.toList());
        final n = figures[name]!;
        final describe = switch (n) {
          2 => 'has two endpoints and can be measured',
          1 => 'starts at one point and goes on forever in one direction',
          _ => 'goes on forever in both directions',
        };
        return Question(
          skillId: c.skillId,
          prompt: 'Which figure ${describe}?',
          answer: name,
          difficulty: c.difficulty,
          choices: _withAnswer(figures.keys.toList(), name, c),
          steps: ['${_a(name)} ${describe}.'],
        );
      case 2:
        final name = c.pick(polygonSides.keys.toList());
        final n = polygonSides[name]!;
        return Question(
          skillId: c.skillId,
          prompt: 'How many line segments make up ${_a(name)}?',
          answer: '${n}',
          difficulty: c.difficulty,
          choices: c.choicesAround(n, distractors: [n - 1, n + 1, n + 2]),
          steps: [
            'Each side of ${_a(name)} is a line segment with two endpoints.',
            '${_a(name)} has ${n} sides, so ${n} line segments.',
          ],
        );
      case 3:
        // Class 2 territory: which way a line runs on the page.
        final kind = c.pick(['horizontal', 'vertical', 'slanting']);
        final describe = switch (kind) {
          'horizontal' => 'runs flat across the page, like the horizon',
          'vertical' => 'runs straight up and down the page',
          _ => 'runs neither flat nor straight up, but at a tilt',
        };
        return Question(
          skillId: c.skillId,
          prompt: 'What do we call a line that ${describe}?',
          answer: kind,
          difficulty: c.difficulty,
          choices: _withAnswer(
              const ['horizontal', 'vertical', 'slanting'], kind, c),
          steps: ['A line that ${describe} is called ${kind}.'],
        );
      case 4:
        final kind = c.pick(['parallel', 'perpendicular', 'intersecting']);
        final describe = switch (kind) {
          'parallel' => 'stay the same distance apart and never meet',
          'perpendicular' => 'cross each other at a right angle',
          _ => 'cross each other at a point',
        };
        return Question(
          skillId: c.skillId,
          prompt: 'What do we call two lines that ${describe}?',
          answer: kind,
          difficulty: c.difficulty,
          choices: _withAnswer(
              const ['parallel', 'perpendicular', 'intersecting'], kind, c),
          steps: ['Two lines that ${describe} are ${kind} lines.'],
        );
      default:
        // Points in a row on one line, which is the first real thing a child
        // computes with segments rather than just naming them.
        final ab = c.int_(2, c.band(9, 40));
        final bc = c.int_(2, c.band(9, 40));
        return Question(
          skillId: c.skillId,
          prompt: 'A, B and C lie on a straight line in that order.\n\n'
              'AB = ${ab} cm and BC = ${bc} cm. How long is AC?',
          answer: '${ab + bc}',
          difficulty: c.difficulty,
          choices: c.choicesAround(ab + bc,
              distractors: [(ab - bc).abs(), ab, bc]),
          steps: [
            'B lies between A and C, so AB and BC join end to end.',
            'AB + BC = AC.',
            '${ab} + ${bc} = ${ab + bc} cm.',
          ],
          hint: 'The two shorter segments together make the long one.',
        );
    }
  });

  register('angles', (c) {
    // Right and straight are recognised at a glance. Reflex is the one that
    // catches children out, because the angle being named is the side of the
    // arms nobody looks at first - so it belongs at the hard end.
    final kind = c.pickByLevel(
        const ['right', 'straight', 'acute', 'obtuse', 'reflex']);
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
    // A multiple of ten to take from 90 is a different sum from 47 from 180.
    // The rule being tested is the same either way; the arithmetic in front of
    // it is what the level can honestly change.
    final round = c.pickByLevel(const [10, 5, 1, 1, 1]);
    final a = c.int_((complement ? 10 : 20) ~/ round, (total - 10) ~/ round) *
        round;
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
    final round = c.pickByLevel(const [5, 5, 1, 1, 1]);
    final a = c.int_(35 ~/ round, 145 ~/ round) * round;
    // Corresponding and alternate angles are equal - one step. Co-interior
    // needs the subtraction as well, so it is the one to save for later.
    final kind =
        c.pickByLevel(const ['corresponding', 'alternate', 'co-interior']);
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
    // Two angles in tens leave a third in tens. Once they are any number at
    // all, the same rule needs a two-step subtraction with a carry in it.
    final round = c.pickByLevel(const [10, 10, 5, 1, 1]);
    final a = c.int_(25 ~/ round, 100 ~/ round) * round;
    final b = c.int_(20 ~/ round, (170 - a) ~/ round) * round;
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
    // SSS is the one every child meets first and RHS the one that only makes
    // sense once right-angled triangles have been done properly.
    final desc = c.pickByLevel(cases.keys.toList());
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
    final round = c.pickByLevel(const [10, 10, 5, 1, 1]);
    final a = c.int_(40 ~/ round, 140 ~/ round) * round;
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
    // Every level sees all three, on purpose. The first two are single facts
    // with one question each in them, so holding them back for the easy levels
    // left those levels with two questions in total - a twenty-question sheet
    // came back with two. The level goes into the numbers below instead.
    final which = c.pick(const ['semicircle', 'tangent', 'centre']);
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
    final atRound = c.pickByLevel(const [10, 10, 5, 1, 1]);
    final at = c.int_(20 ~/ atRound, 80 ~/ atRound) * atRound;
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
    // A circle is left out on purpose: it has infinitely many lines of
    // symmetry, and no whole number is the right answer.
    //
    // Every one of these lists is written easiest first, because that is the
    // only thing the level has to work with here - there is no number in "how
    // many lines of symmetry does a kite have" to make bigger. The shapes with
    // none come late: a child who has just learnt to fold shapes in half
    // expects every shape to fold, and a parallelogram is the counterexample,
    // not the introduction.
    const lines = {
      'square': 4, 'rectangle': 2, 'equilateral triangle': 3,
      'isosceles triangle': 1, 'kite': 1, 'semicircle': 1, 'rhombus': 2,
      'regular pentagon': 5, 'regular hexagon': 6, 'regular octagon': 8,
      'parallelogram': 0, 'scalene triangle': 0,
    };
    // Capital letters, the way NCERT introduces the idea. Drawn plainly, with
    // no serifs or slant - which is why O and Q are not here, since how many
    // lines they have depends entirely on how they are written.
    //
    // Fold down the middle first (A T V M U W Y), then across (B C D E), then
    // the ones that do both (H I X), then the ones that do neither.
    const letters = {
      'A': 1, 'T': 1, 'V': 1, 'M': 1, 'U': 1, 'W': 1, 'Y': 1,
      'B': 1, 'C': 1, 'D': 1, 'E': 1,
      'H': 2, 'I': 2, 'X': 2,
      'N': 0, 'S': 0, 'Z': 0,
    };
    // How many times a shape looks unchanged in one full turn. Everything has
    // an order of at least 1 - the turn all the way back to the start, which
    // is why the shapes of order 1 sit at the hard end: answering "none" is
    // the mistake the question is built to catch.
    const order = {
      'square': 4, 'rectangle': 2, 'equilateral triangle': 3, 'rhombus': 2,
      'regular pentagon': 5, 'regular hexagon': 6, 'regular octagon': 8,
      'parallelogram': 2, 'isosceles triangle': 1, 'scalene triangle': 1,
      'kite': 1,
    };

    // Counting folds comes before naming an order of rotation, which comes
    // before working back from an order to the angle that turns it.
    switch (c.variantByLevel(4)) {
      case 0:
        final name = c.pickByLevel(lines.keys.toList());
        final n = lines[name]!;
        return Question(
          skillId: c.skillId,
          prompt: 'How many lines of symmetry does ${_a(name)} have?',
          answer: '${n}',
          difficulty: c.difficulty,
          choices: c.choicesAround(n, distractors: [n + 1, n - 1, n + 2]),
          steps: [
            'A line of symmetry folds the shape onto itself exactly.',
            '${_a(name)} has ${n}.',
          ],
        );
      case 1:
        final letter = c.pickByLevel(letters.keys.toList());
        final n = letters[letter]!;
        return Question(
          skillId: c.skillId,
          prompt: 'How many lines of symmetry does the capital letter '
              '${letter} have?',
          answer: '${n}',
          difficulty: c.difficulty,
          choices: c.choicesAround(n, distractors: [n + 1, n + 2, n - 1]),
          steps: [
            'Try folding the letter in half: across, down, and slanting.',
            n == 0
                ? 'No fold puts ${letter} exactly on top of itself, so it has 0.'
                : 'The letter ${letter} folds onto itself ${n} ${n == 1 ? 'way' : 'ways'}.',
          ],
          hint: 'Fold it down the middle first, then across.',
        );
      case 2:
        final name = c.pickByLevel(order.keys.toList());
        final n = order[name]!;
        return Question(
          skillId: c.skillId,
          prompt: 'What is the order of rotational symmetry of ${_a(name)}?',
          answer: '${n}',
          difficulty: c.difficulty,
          choices: c.choicesAround(n, distractors: [n + 1, n - 1, n + 2]),
          steps: [
            'Turn the shape one full circle and count how many times it looks '
                'exactly as it started.',
            '${_a(name)} looks the same ${n} ${n == 1 ? 'time' : 'times'} in a full turn, so '
                'is ${n}.',
          ],
          hint: 'Every shape counts at least once - the full turn back to the '
              'start.',
        );
      default:
        // Only shapes that actually turn onto themselves. "Through what angle
        // does a scalene triangle rotate onto itself" has no answer short of a
        // full turn.
        final name =
            c.pickByLevel(order.keys.where((k) => order[k]! > 1).toList());
        final n = order[name]!;
        final angle = 360 ~/ n;
        return Question(
          skillId: c.skillId,
          prompt: 'Through what smallest angle, in degrees, can ${_a(name)} '
              'be turned so that it looks exactly the same?',
          answer: '${angle}',
          difficulty: c.difficulty,
          choices: c.choicesAround(angle, distractors: [360, angle * 2, 180]),
          steps: [
            '${_a(name)} has rotational symmetry of order ${n}.',
            'A full turn is 360 degrees, shared into ${n} equal turns.',
            '360 / ${n} = ${angle} degrees.',
          ],
        );
    }
  });

  register('coordinates', (c) {
    final reach = c.band(6, 40);
    final x = c.intExcept(-reach, reach, {0});
    final y = c.intExcept(-reach, reach, {0});
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
    // 3-4-5 first: a student who knows one triple by heart can check their
    // working against it. The bigger ones have to be computed.
    const triples = [[3, 4, 5], [6, 8, 10], [9, 12, 15], [5, 12, 13], [8, 15, 17]];
    final t = c.pickByLevel(triples);
    // Both points in the first quadrant is a picture the student can draw.
    // Negatives mean the differences have to be handled as well as the squares.
    final low = c.pickByLevel(const [0, 0, -3, -6, -9]);
    final x1 = c.int_(low, 6);
    final y1 = c.int_(low, 6);
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
        '${t[0]} x ${t[0]} + ${t[1]} x ${t[1]} = ${t[2] * t[2]}, and the square '
            'root of ${t[2] * t[2]} is ${t[2]}.',
      ],
      hint: 'It is Pythagoras with the two gaps as the legs.',
    );
  });
}

/// "a hexagon" but "an octagon". Worth the four lines: these questions are for
/// children who are learning to read as well as to count, and "a octagon" on a
/// printed sheet from their teacher is a small thing taught wrong.
String _a(String noun) =>
    'aeiou'.contains(noun[0].toLowerCase()) ? 'an $noun' : 'a $noun';

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
