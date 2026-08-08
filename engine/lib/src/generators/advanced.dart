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
    // Bigger sets drawn from a wider pool: more to hold in the head, and an
    // overlap that has to be found rather than seen.
    final size = c.band(3, 6);
    final pool = c.band(9, 20);
    final a = <int>{};
    final b = <int>{};
    while (a.length < size) {
      a.add(c.int_(1, pool));
    }
    while (b.length < size) {
      b.add(c.int_(1, pool));
    }
    // Union is counting what you can see. Intersection is the one where the
    // answer can be nothing at all, which students do not expect.
    final union = c.difficulty <= 2 || (c.difficulty <= 4 && c.coin());
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
    // Substituting into f(x) is one thing a Class 11 functions chapter does,
    // and it used to be the only thing on the sheet. Running the function
    // backwards, composing two of them, and finding where a denominator dies
    // are the rest of the chapter, and each one fails differently - which is
    // the point of asking.
    final a = c.int_(2, c.band(4, 9));
    final b = c.int_(1, c.band(5, 15));
    final x = c.int_(2, c.band(5, 12));

    switch (c.variantByLevel(4)) {
      case 0:
        final squared = c.difficulty >= 4;
        final ans = squared ? a * x * x + b : a * x + b;
        return Question(
          skillId: c.skillId,
          prompt: squared
              ? 'If f(x) = ${term(a, 'x')}^2 + $b, find f($x).'
              : 'If f(x) = ${term(a, 'x')} + $b, find f($x).',
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
      case 1:
        // Backwards: given the output, find the input. Same function, opposite
        // direction, and it is where students first meet the idea of undoing.
        final out = a * x + b;
        return Question(
          skillId: c.skillId,
          prompt: 'If f(x) = ${term(a, 'x')} + $b and f(k) = $out, find k.',
          answer: '$x',
          difficulty: c.difficulty,
          choices: c.choicesAround(x, distractors: [out - b, out ~/ a, a + b]),
          steps: [
            'Write it out: $a k + $b = $out.',
            'Take $b off both sides: $a k = ${out - b}.',
            'Divide by $a: k = $x.',
          ],
          hint: 'Undo the function: subtract first, then divide.',
        );
      case 2:
        // Composition. The whole difficulty is that g runs first even though f
        // is written first, and nothing else on the sheet tests that.
        final g = c.int_(1, c.band(4, 9));
        final inner = x + g;
        final ans = a * inner + b;
        return Question(
          skillId: c.skillId,
          prompt: 'If f(x) = ${term(a, 'x')} + $b and g(x) = x + $g,\n\n'
              'find f(g($x)).',
          answer: '$ans',
          difficulty: c.difficulty,
          choices: c.choicesAround(ans,
              distractors: [a * x + b + g, (a * x + b) + g, a * x + g]),
          steps: [
            'Work from the inside out: g runs first.',
            'g($x) = $x + $g = $inner.',
            'Now f($inner) = $a x $inner + $b = $ans.',
          ],
          hint: 'g goes first, even though f is written first.',
        );
      default:
        // Domain. The answer is the one value that breaks the function, which
        // is a different kind of question from anything above it.
        return Question(
          skillId: c.skillId,
          prompt: 'For f(x) = 1 / (x - $b), which value of x must be left out '
              'of the domain?',
          answer: '$b',
          difficulty: c.difficulty,
          choices: c.choicesAround(b, distractors: [-b, 0, b + 1]),
          steps: [
            'A fraction has no value when its bottom is zero.',
            'x - $b = 0 when x = $b.',
            'So the domain is every real number except $b.',
          ],
          hint: 'What would make the bottom of the fraction zero?',
        );
    }
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
    // Row-times-column is one procedure at every level, so the level lives in
    // the arithmetic it runs on: small positives first, then two-digit
    // entries, then the negatives that make the signs worth watching.
    final lo = c.band(1, -9);
    final hi = c.band(9, 20);
    final a11 = c.int_(lo, hi), a12 = c.int_(lo, hi);
    final b11 = c.int_(lo, hi), b21 = c.int_(lo, hi);
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
    final lo = c.band(1, -9);
    final hi = c.band(9, 20);
    final a = c.int_(lo, hi), b = c.int_(lo, hi);
    final cc = c.int_(lo, hi), d = c.int_(lo, hi);
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
    final lo = c.band(0, -8);
    final hi = c.band(8, 15);
    final a = [c.int_(lo, hi), c.int_(lo, hi), c.int_(lo, hi)];
    final b = [c.int_(lo, hi), c.int_(lo, hi), c.int_(lo, hi)];
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
        // Spaces round the times sign, because these components are signed.
        // Written closed up, "(1x-2)" reads as the algebraic 1x - 2 rather
        // than as 1 multiplied by -2.
        '(${a[0]} x ${b[0]}) + (${a[1]} x ${b[1]}) + (${a[2]} x ${b[2]})',
        '= ${a[0] * b[0]} + ${a[1] * b[1]} + ${a[2] * b[2]} = $dot.',
      ],
      hint: 'The dot product gives a single number, not a vector.',
    );
  });

  register('geometry_3d', (c) {
    const triples = [[3, 4, 5], [6, 8, 10], [5, 12, 13], [8, 15, 17]];
    final t = c.pickByLevel(triples);
    final reach = c.band(3, 12);
    final x1 = c.int_(-reach, reach),
        y1 = c.int_(-reach, reach),
        z1 = c.int_(-reach, reach);
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
    final a = c.int_(2, c.band(9, 25)), b = c.int_(2, c.band(9, 25));
    final x = c.int_(1, c.band(9, 30)), y = c.int_(1, c.band(9, 30));
    final z = a * x + b * y;
    return Question(
      skillId: c.skillId,
      prompt: 'For the objective function Z = ${term(a, 'x')} + ${term(b, 'y')},\n\n'
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
    // The Pythagorean identity is the one that gets quoted in class every
    // week. The complementary-angle one is the one students have to think
    // about, because nothing in it looks like anything else.
    final which = c.pickByLevel(const ['pythagorean', 'tan', 'complement']);
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
    // Reading the table backwards for sin is the first step. Doing it for cos
    // means remembering that cos runs the other way, and tan is a third table
    // again - so which function is asked about is where the level sits.
    final fn = c.pickByLevel(const ['sin', 'sin', 'cos', 'tan']);
    const table = {
      'sin': {'0': 0, '1/2': 30, '1': 90},
      'cos': {'1': 0, '1/2': 60, '0': 90},
      'tan': {'0': 0, '1': 45},
    };
    final options = table[fn]!;
    final key = c.pick(options.keys.toList());
    final deg = options[key]!;
    return Question(
      skillId: c.skillId,
      prompt: 'Solve  $fn x = $key  for x between 0 and 90 degrees.\n\n'
          'Give the answer in degrees.',
      answer: '$deg',
      difficulty: c.difficulty,
      choices: _withAnswer(const ['0', '30', '45', '60', '90'], '$deg', c),
      steps: [
        'Read the standard angle table backwards.',
        '$fn $deg = $key, so x = $deg degrees.',
      ],
      hint: 'Which standard angle has that $fn?',
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
    // All three at every level. The two coin questions are fixed - one
    // question each - so keeping them for the easy levels and the dice for the
    // hard ones left Easiest with two questions in total. The dice total below
    // is where the level actually lives.
    final kind = c.pick(const ['twoheads', 'atleastone', 'dicesum']);
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
      // Any total, not just seven. Fixing it at seven meant this whole skill
      // had exactly three questions in it, so a worksheet asking for twenty
      // was handed three - and the two-dice one is the question worth asking
      // more than once anyway.
      _ => _diceSum(c),
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
      prompt: 'Differentiate  y = ${term(a, 'x', power: n)}\n\n'
          'The answer is k${term(1, 'x', power: n - 1)}. What is k?',
      answer: '$coeff',
      difficulty: c.difficulty,
      choices: c.choicesAround(coeff, distractors: [a, n, a + n]),
      steps: [
        'Bring the power down to the front, then take one off the power.',
        '$a x $n = $coeff, and the power becomes ${n - 1}.',
        'dy/dx = ${term(coeff, 'x', power: n - 1)}.',
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
      prompt: 'For the curve  y = ${term(a, 'x')}^2,\n\n'
          'find the slope of the tangent at x = $x.',
      answer: '$slope',
      difficulty: c.difficulty,
      choices: c.choicesAround(slope, distractors: [a * x * x, a * x]),
      steps: [
        'The slope of a curve at a point is the derivative there.',
        'dy/dx = ${term(2 * a, 'x')}.',
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
      prompt: 'Integrate  ${term(a, 'x', power: n)}  with respect to x.\n\n'
          'The answer is k${term(1, 'x', power: n + 1)} + C. What is k?',
      answer: '$coeff',
      difficulty: c.difficulty,
      choices: c.choicesAround(coeff, distractors: [a, a * (n + 1), n + 1]),
      steps: [
        'Integration is the reverse of differentiating.',
        'Raise the power by 1, then divide by the new power.',
        '$a / ${n + 1} = $coeff, so the answer is '
            '${term(coeff, 'x', power: n + 1)} + C.',
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
      prompt: 'Solve  dy/dx = ${term(k, 'x')}\n\n'
          'The answer is y = kx^2 + C. What is k?',
      answer: (Fraction(k, 2)).toString(),
      difficulty: c.difficulty,
      steps: [
        'Integrate both sides with respect to x.',
        'The integral of ${term(k, 'x')} is $k x^2 / 2.',
        'So y = ${term(Fraction(k, 2), 'x')}^2 + C.',
      ],
      hint: 'Integrate the right hand side, and do not forget the + C.',
    );
  });
}

List<String> _withAnswer(List<String> pool, String answer, GenContext c) {
  final others = pool.where((e) => e != answer).toList()..shuffle(c.rng);
  return [answer, ...others.take(3)]..shuffle(c.rng);
}

/// The probability that two dice total a given number.
///
/// Seven is the one every textbook asks, and the ends of the range are the
/// ones students find easiest, because there is only one way to roll them.
/// So the level walks inwards from 2 and 12 towards the middle.
Question _diceSum(GenContext c) {
  final target = c.pickByLevel(const [2, 12, 3, 11, 4, 10, 5, 9, 6, 8, 7]);
  final ways = 6 - (7 - target).abs();
  final pairs = [
    for (var d = 1; d <= 6; d++)
      if (target - d >= 1 && target - d <= 6) '($d,${target - d})',
  ];
  return Question(
    skillId: c.skillId,
    prompt: 'Two dice are rolled.\n\n'
        'What is the probability the total is $target? '
        '(fraction in lowest terms)',
    answer: Fraction(ways, 36).toString(),
    difficulty: c.difficulty,
    steps: [
      'There are 6 x 6 = 36 equally likely results.',
      'Totals of $target: ${pairs.join(' ')} - that is $ways.',
      '$ways/36 = ${Fraction(ways, 36)}.',
    ],
    hint: 'Count the pairs that add to $target, out of 36.',
  );
}
