import '../fraction.dart';
import '../gen_context.dart';
import '../generator.dart';
import '../question.dart';

/// Class 11 and 12: sets, functions, counting, complex numbers, matrices,
/// vectors, trigonometry, statistics and calculus.
///
/// Numbers are chosen so answers come out whole or as a simple fraction. At
/// this level the difficulty should be the method, not the arithmetic.
void registerAdvanced() {
  // ------------------------------------------------------------------ sets

  register('sets', (c) {
    final a = <int>{};
    final b = <int>{};
    while (a.length < 4) {
      a.add(c.int_(1, 9));
    }
    while (b.length < 4) {
      b.add(c.int_(1, 9));
    }
    final union = c.coin();
    final result = union ? {...a, ...b} : a.intersection(b);
    final sorted = result.toList()..sort();
    final aS = (a.toList()..sort()).join(', ');
    final bS = (b.toList()..sort()).join(', ');
    return Question(
      skillId: c.skillId,
      prompt: 'A = {$aS} and B = {$bS}\n\n'
          'How many elements are in A ${union ? 'union' : 'intersection'} B?',
      answer: '${sorted.length}',
      difficulty: c.difficulty,
      choices: c.choicesAround(sorted.length,
          distractors: [a.length + b.length, a.length, 0]),
      steps: [
        union
            ? 'Union means everything in either set, counted once.'
            : 'Intersection means only what is in BOTH sets.',
        union
            ? 'Together: ${sorted.join(', ')}'
            : (sorted.isEmpty
                ? 'Nothing appears in both, so the answer is 0.'
                : 'In both: ${sorted.join(', ')}'),
        'That is ${sorted.length} element${sorted.length == 1 ? '' : 's'}.',
      ],
      hint: union ? 'Do not count anything twice.' : 'Only what appears in both.',
    );
  });

  register('functions', (c) {
    final a = c.int_(2, c.band(4, 9));
    final b = c.int_(1, c.band(5, 15));
    final x = c.int_(2, c.band(5, 12));
    final squared = c.difficulty >= 4;
    final ans = squared ? a * x * x + b : a * x + b;
    return Question(
      skillId: c.skillId,
      prompt: squared
          ? 'If f(x) = ${a}x^2 + $b, find f($x).'
          : 'If f(x) = ${a}x + $b, find f($x).',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [a * x + b, a + b + x]),
      steps: [
        'f($x) means put $x wherever you see x.',
        squared
            ? '$a x $x^2 + $b = $a x ${x * x} + $b = $ans.'
            : '$a x $x + $b = ${a * x} + $b = $ans.',
      ],
      hint: 'Just replace every x with $x.',
    );
  });

  register('perm_comb', (c) {
    final n = c.int_(4, c.band(6, 9));
    final r = c.int_(2, n - 1);
    final perm = c.coin();
    var p = 1;
    for (var i = 0; i < r; i++) {
      p *= (n - i);
    }
    var rFact = 1;
    for (var i = 1; i <= r; i++) {
      rFact *= i;
    }
    final ans = perm ? p : p ~/ rFact;
    return Question(
      skillId: c.skillId,
      prompt: perm
          ? 'In how many ways can $r people be arranged in a row, chosen from '
              '$n people?  (that is ${n}P$r)'
          : 'In how many ways can $r people be chosen from $n people, when the '
              'order does not matter?  (that is ${n}C$r)',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [p, n * r, p ~/ rFact]),
      steps: [
        perm
            ? 'Order matters, so it is a permutation: nPr = n!/(n-r)!'
            : 'Order does not matter, so it is a combination: nCr = n!/(r!(n-r)!)',
        '${n}P$r = ${List.generate(r, (i) => n - i).join(' x ')} = $p.',
        if (!perm) 'Divide by $r! = $rFact to ignore order: $p / $rFact = $ans.',
      ],
      hint: perm
          ? 'Order matters here.'
          : 'Order does not matter - divide by r! at the end.',
    );
  });

  register('binomial', (c) {
    final n = c.int_(3, c.band(4, 6));
    final a = c.int_(1, c.band(2, 4));
    // Coefficient of x^(n-1) in (x + a)^n is nC1 * a = n*a.
    final coeff = n * a;
    return Question(
      skillId: c.skillId,
      prompt: 'In the expansion of (x + $a)^$n,\n\n'
          'what is the coefficient of x^${n - 1}?',
      answer: '$coeff',
      difficulty: c.difficulty,
      choices: c.choicesAround(coeff, distractors: [n + a, a * a, n]),
      steps: [
        'The term with x^${n - 1} comes from choosing $a exactly once.',
        'That is ${n}C1 x $a = $n x $a = $coeff.',
      ],
      hint: 'Use nC1 for the second term of the expansion.',
    );
  });

  register('complex_numbers', (c) {
    final a = c.int_(1, c.band(4, 8));
    final b = c.int_(1, c.band(4, 8));
    final d = c.int_(1, c.band(4, 8));
    final e = c.int_(1, c.band(4, 8));
    // (a + bi)(d + ei) = (ad - be) + (ae + bd)i
    final real = a * d - b * e;
    final imag = a * e + b * d;
    final wantReal = c.coin();
    return Question(
      skillId: c.skillId,
      prompt: 'Multiply ($a + ${b}i)($d + ${e}i).\n\n'
          'What is the ${wantReal ? 'real' : 'imaginary'} part of the answer?',
      answer: '${wantReal ? real : imag}',
      difficulty: c.difficulty,
      steps: [
        'Expand as usual: $a x $d + $a x ${e}i + ${b}i x $d + ${b}i x ${e}i.',
        'The last term has i x i = -1, so ${b}i x ${e}i = ${-b * e}.',
        'Real part: ${a * d} - ${b * e} = $real.',
        'Imaginary part: ${a * e} + ${b * d} = $imag.',
      ],
      hint: 'Remember i x i = -1.',
    );
  });

  register('matrices', (c) {
    final a11 = c.int_(1, 9), a12 = c.int_(1, 9);
    final b11 = c.int_(1, 9), b21 = c.int_(1, 9);
    final result = a11 * b11 + a12 * b21;
    return Question(
      skillId: c.skillId,
      prompt: 'Multiply these matrices:\n\n'
          'A = [ $a11  $a12 ]        B = [ $b11 ]\n'
          '                              [ $b21 ]\n\n'
          'What is the single value of A x B?',
      answer: '$result',
      difficulty: c.difficulty,
      choices: c.choicesAround(result,
          distractors: [a11 * b11, a12 * b21, a11 + a12 + b11 + b21]),
      steps: [
        'Go along the row of A and down the column of B.',
        '($a11 x $b11) + ($a12 x $b21)',
        '= ${a11 * b11} + ${a12 * b21} = $result.',
      ],
      hint: 'Row times column, then add.',
    );
  });

  register('determinants', (c) {
    final a = c.int_(1, 9), b = c.int_(1, 9);
    final cc = c.int_(1, 9), d = c.int_(1, 9);
    final det = a * d - b * cc;
    return Question(
      skillId: c.skillId,
      prompt: 'Find the determinant of\n\n'
          '[ $a  $b ]\n[ $cc  $d ]',
      answer: '$det',
      difficulty: c.difficulty,
      choices: c.choicesAround(det, distractors: [a * d, b * cc, -det]),
      steps: [
        'For a 2x2 matrix the determinant is ad - bc.',
        '($a x $d) - ($b x $cc) = ${a * d} - ${b * cc} = $det.',
      ],
      hint: 'Multiply the diagonals, then subtract.',
    );
  });

  register('vectors', (c) {
    final a = [c.int_(1, 8), c.int_(1, 8), c.int_(0, 6)];
    final b = [c.int_(1, 8), c.int_(0, 6), c.int_(1, 8)];
    final dot = a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
    return Question(
      skillId: c.skillId,
      prompt: 'Find the dot product of\n\n'
          'a = (${a.join(', ')})   and   b = (${b.join(', ')})',
      answer: '$dot',
      difficulty: c.difficulty,
      choices: c.choicesAround(dot,
          distractors: [a[0] * b[0], a.reduce((x, y) => x + y)]),
      steps: [
        'Multiply matching components, then add them all.',
        '(${a[0]}x${b[0]}) + (${a[1]}x${b[1]}) + (${a[2]}x${b[2]})',
        '= ${a[0] * b[0]} + ${a[1] * b[1]} + ${a[2] * b[2]} = $dot.',
      ],
      hint: 'The dot product gives a single number, not a vector.',
    );
  });

  register('geometry_3d', (c) {
    const triples = [[3, 4, 5], [6, 8, 10], [5, 12, 13], [8, 15, 17]];
    final t = c.pick(triples);
    final x1 = c.int_(-5, 5), y1 = c.int_(-5, 5), z1 = c.int_(-5, 5);
    return Question(
      skillId: c.skillId,
      prompt: 'Find the distance between the points\n\n'
          '($x1, $y1, $z1)   and   (${x1 + t[0]}, ${y1 + t[1]}, $z1)',
      answer: '${t[2]}',
      difficulty: c.difficulty,
      choices: c.choicesAround(t[2], distractors: [t[0] + t[1], t[2] + 1]),
      steps: [
        'Distance = root((dx)^2 + (dy)^2 + (dz)^2).',
        'Differences: ${t[0]}, ${t[1]} and 0.',
        '${t[0] * t[0]} + ${t[1] * t[1]} + 0 = ${t[2] * t[2]}, and '
            'root(${t[2] * t[2]}) = ${t[2]}.',
      ],
      hint: 'It is Pythagoras again, just with three differences.',
    );
  });

  register('lpp', (c) {
    final a = c.int_(2, 9), b = c.int_(2, 9);
    final x = c.int_(1, 9), y = c.int_(1, 9);
    final z = a * x + b * y;
    return Question(
      skillId: c.skillId,
      prompt: 'For the objective function Z = ${a}x + ${b}y,\n\n'
          'find the value of Z at the corner point ($x, $y).',
      answer: '$z',
      difficulty: c.difficulty,
      choices: c.choicesAround(z, distractors: [a + b + x + y, a * b]),
      steps: [
        'Put x = $x and y = $y into Z.',
        '$a x $x = ${a * x}, and $b x $y = ${b * y}.',
        'Z = ${a * x} + ${b * y} = $z.',
      ],
      hint: 'The maximum always sits at a corner point, so you test each one.',
    );
  });

  // -------------------------------------------------------------- trig

  register('trig_identities', (c) {
    final which = c.pick(['pythagorean', 'tan', 'complement']);
    return switch (which) {
      'pythagorean' => Question(
          skillId: c.skillId,
          prompt: 'Simplify:  sin^2 A + cos^2 A',
          answer: '1',
          difficulty: c.difficulty,
          choices: _withAnswer(const ['0', '1', '2', 'sin A'], '1', c),
          steps: [
            'This is the identity every other one is built from.',
            'sin^2 A + cos^2 A = 1, always.',
          ],
        ),
      'tan' => Question(
          skillId: c.skillId,
          prompt: 'tan A is the same as which of these?',
          answer: 'sin A / cos A',
          difficulty: c.difficulty,
          choices: _withAnswer(
            const ['sin A / cos A', 'cos A / sin A', 'sin A x cos A', '1 / sin A'],
            'sin A / cos A',
            c,
          ),
          steps: ['tan A = sin A / cos A.'],
        ),
      _ => Question(
          skillId: c.skillId,
          prompt: 'sin(90 - A) is the same as what?',
          answer: 'cos A',
          difficulty: c.difficulty,
          choices: _withAnswer(
            const ['cos A', 'sin A', 'tan A', '-cos A'],
            'cos A',
            c,
          ),
          steps: [
            'Angles that add to 90 swap sin and cos.',
            'sin(90 - A) = cos A.',
          ],
        ),
    };
  });

  register('trig_equations', (c) {
    const table = {'1/2': 30, '1': 90, '0': 0};
    final key = c.pick(table.keys.toList());
    final deg = table[key]!;
    return Question(
      skillId: c.skillId,
      prompt: 'Solve  sin x = $key  for x between 0 and 90 degrees.\n\n'
          'Give the answer in degrees.',
      answer: '$deg',
      difficulty: c.difficulty,
      choices: _withAnswer(const ['0', '30', '45', '60', '90'], '$deg', c),
      steps: [
        'Read the standard angle table backwards.',
        'sin $deg = $key, so x = $deg degrees.',
      ],
      hint: 'Which standard angle has that sine?',
    );
  });

  // -------------------------------------------------------------- statistics

  register('std_dev', (c) {
    // Two values either side of the mean, so the variance is exactly d^2.
    final mean = c.int_(c.band(10, 30), c.band(25, 60));
    final d = c.int_(2, c.band(5, 10));
    final values = [mean - d, mean - d, mean + d, mean + d]..shuffle(c.rng);
    return Question(
      skillId: c.skillId,
      prompt: 'Find the standard deviation of:\n\n${values.join(', ')}',
      answer: '$d',
      difficulty: c.difficulty,
      choices: c.choicesAround(d, distractors: [d * d, mean, 2 * d]),
      steps: [
        'Mean = ${values.reduce((a, b) => a + b)} / 4 = $mean.',
        'Each value is $d away from the mean.',
        'Variance = average of the squared distances = ${d * d}.',
        'Standard deviation = root(${d * d}) = $d.',
      ],
      hint: 'Find the mean first, then how far each value sits from it.',
    );
  });

  register('probability_events', (c) {
    final kind = c.pick(['twoheads', 'atleastone', 'sumseven']);
    return switch (kind) {
      'twoheads' => Question(
          skillId: c.skillId,
          prompt: 'Two fair coins are tossed.\n\n'
              'What is the probability of getting two heads? '
              '(fraction in lowest terms)',
          answer: '1/4',
          difficulty: c.difficulty,
          steps: [
            'The four equally likely results are HH, HT, TH, TT.',
            'Only HH is two heads.',
            'P = 1/4.',
          ],
        ),
      'atleastone' => Question(
          skillId: c.skillId,
          prompt: 'Two fair coins are tossed.\n\n'
              'What is the probability of getting at least one head? '
              '(fraction in lowest terms)',
          answer: '3/4',
          difficulty: c.difficulty,
          steps: [
            'The four results are HH, HT, TH, TT.',
            'Three of them have at least one head.',
            'P = 3/4.',
          ],
          hint: 'It is easier to count the one case with NO heads.',
        ),
      _ => Question(
          skillId: c.skillId,
          prompt: 'Two dice are rolled.\n\n'
              'What is the probability the total is 7? '
              '(fraction in lowest terms)',
          answer: Fraction(6, 36).toString(),
          difficulty: c.difficulty,
          steps: [
            'There are 6 x 6 = 36 equally likely results.',
            'Totals of 7: (1,6) (2,5) (3,4) (4,3) (5,2) (6,1) - that is 6.',
            '6/36 = ${Fraction(6, 36)}.',
          ],
        ),
    };
  });

  register('straight_line', (c) {
    final x1 = c.int_(-6, 4);
    final run = c.int_(1, c.band(3, 6));
    final slope = c.int_(1, c.band(3, 8)) * (c.coin() ? 1 : -1);
    final y1 = c.int_(-6, 6);
    final x2 = x1 + run;
    final y2 = y1 + slope * run;
    return Question(
      skillId: c.skillId,
      prompt: 'Find the slope of the line through\n\n'
          '($x1, $y1)   and   ($x2, $y2)',
      answer: '$slope',
      difficulty: c.difficulty,
      // Built by hand: slope is often negative, and choicesAround() works in
      // non-negatives only, so it would leave the real answer off the list.
      // The sign error is the distractor that matters here anyway.
      choices: ({slope, -slope, y2 - y1, run}.toList()..shuffle(c.rng))
          .map((e) => e.toString())
          .toList(),
      steps: [
        'Slope = (change in y) / (change in x).',
        'Change in y = $y2 - $y1 = ${y2 - y1}.',
        'Change in x = $x2 - $x1 = $run.',
        '${y2 - y1} / $run = $slope.',
      ],
      hint: 'Rise over run, and mind the sign.',
    );
  });

  // ---------------------------------------------------------------- calculus

  register('limits', (c) {
    final a = c.int_(2, c.band(5, 12));
    return Question(
      skillId: c.skillId,
      prompt: 'Find the limit as x approaches $a of\n\n'
          '(x^2 - ${a * a}) / (x - $a)',
      answer: '${2 * a}',
      difficulty: c.difficulty,
      choices: c.choicesAround(2 * a, distractors: [a, a * a, 0]),
      steps: [
        'Putting x = $a straight in gives 0/0, so factorise first.',
        'x^2 - ${a * a} = (x - $a)(x + $a).',
        'The (x - $a) cancels, leaving x + $a.',
        'Now put x = $a: $a + $a = ${2 * a}.',
      ],
      hint: 'Factorise the top - something will cancel.',
    );
  });

  register('derivatives', (c) {
    final a = c.int_(2, c.band(5, 12));
    final n = c.int_(2, c.band(3, 6));
    final coeff = a * n;
    return Question(
      skillId: c.skillId,
      prompt: 'Differentiate  y = ${a}x^$n\n\n'
          'The answer is kx^${n - 1}. What is k?',
      answer: '$coeff',
      difficulty: c.difficulty,
      choices: c.choicesAround(coeff, distractors: [a, n, a + n]),
      steps: [
        'Bring the power down to the front, then take one off the power.',
        '$a x $n = $coeff, and the power becomes ${n - 1}.',
        'dy/dx = ${coeff}x^${n - 1}.',
      ],
      hint: 'Multiply by the power, then reduce the power by 1.',
    );
  });

  register('derivative_apps', (c) {
    final a = c.int_(1, c.band(3, 6));
    final x = c.int_(1, c.band(3, 8));
    // y = ax^2, slope at x is 2ax
    final slope = 2 * a * x;
    return Question(
      skillId: c.skillId,
      prompt: 'For the curve  y = ${a}x^2,\n\n'
          'find the slope of the tangent at x = $x.',
      answer: '$slope',
      difficulty: c.difficulty,
      choices: c.choicesAround(slope, distractors: [a * x * x, a * x]),
      steps: [
        'The slope of a curve at a point is the derivative there.',
        'dy/dx = ${2 * a}x.',
        'At x = $x: ${2 * a} x $x = $slope.',
      ],
      hint: 'Differentiate first, then substitute.',
    );
  });

  register('integration', (c) {
    final n = c.int_(1, c.band(2, 5));
    final a = (n + 1) * c.int_(1, c.band(3, 7));
    final coeff = a ~/ (n + 1);
    return Question(
      skillId: c.skillId,
      prompt: 'Integrate  ${a}x^$n  with respect to x.\n\n'
          'The answer is kx^${n + 1} + C. What is k?',
      answer: '$coeff',
      difficulty: c.difficulty,
      choices: c.choicesAround(coeff, distractors: [a, a * (n + 1), n + 1]),
      steps: [
        'Integration is the reverse of differentiating.',
        'Raise the power by 1, then divide by the new power.',
        '$a / ${n + 1} = $coeff, so the answer is ${coeff}x^${n + 1} + C.',
      ],
      hint: 'Add one to the power, then divide by that new power.',
    );
  });

  register('definite_integrals', (c) {
    final b = c.int_(2, c.band(4, 8));
    // integral from 0 to b of 2x dx = b^2
    final ans = b * b;
    return Question(
      skillId: c.skillId,
      prompt: 'Evaluate the integral of  2x  from 0 to $b.',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [2 * b, b, ans ~/ 2]),
      steps: [
        'The integral of 2x is x^2.',
        'Now put in the limits: (top)^2 - (bottom)^2.',
        '$b^2 - 0^2 = $ans.',
      ],
      hint: 'Integrate first, then top limit minus bottom limit.',
    );
  });

  register('diff_equations', (c) {
    final k = c.int_(2, c.band(4, 9));
    return Question(
      skillId: c.skillId,
      prompt: 'Solve  dy/dx = ${k}x\n\n'
          'The answer is y = kx^2 + C. What is k?',
      answer: (Fraction(k, 2)).toString(),
      difficulty: c.difficulty,
      steps: [
        'Integrate both sides with respect to x.',
        'The integral of ${k}x is $k x^2 / 2.',
        'So y = ${Fraction(k, 2)}x^2 + C.',
      ],
      hint: 'Integrate the right hand side, and do not forget the + C.',
    );
  });
}

List<String> _withAnswer(List<String> pool, String answer, GenContext c) {
  final others = pool.where((e) => e != answer).toList()..shuffle(c.rng);
  return [answer, ...others.take(3)]..shuffle(c.rng);
}
