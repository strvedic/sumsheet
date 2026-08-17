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

    // nPr and nCr were the only two questions. The chapter starts with the
    // multiplication principle and ends with arrangements of a word, and a
    // student who has only met the two formulas cannot tell which to reach for
    // - which is the actual difficulty of the topic.
    switch (c.variantByLevel(4)) {
      case 1:
        // The multiplication principle, before any formula exists.
        final shirts = c.int_(2, c.band(4, 8));
        final trousers = c.int_(2, c.band(4, 8));
        return Question(
          skillId: c.skillId,
          prompt: 'A boy has $shirts shirts and $trousers pairs of '
              'trousers.\n\nHow many different outfits can he make?',
          answer: '${shirts * trousers}',
          difficulty: c.difficulty,
          choices: c.choicesAround(shirts * trousers,
              distractors: [shirts + trousers, shirts, trousers]),
          steps: [
            'For each of the $shirts shirts there are $trousers choices of '
                'trousers.',
            '$shirts x $trousers = ${shirts * trousers} outfits.',
          ],
          hint: 'Multiply the choices, do not add them.',
        );
      case 2:
        // Arranging all of them - n! - which students confuse with nPr.
        final k = c.int_(3, c.band(4, 6));
        var fact = 1;
        for (var i = 2; i <= k; i++) {
          fact *= i;
        }
        return Question(
          skillId: c.skillId,
          prompt: 'In how many ways can $k different books be arranged on a '
              'shelf?',
          answer: '$fact',
          difficulty: c.difficulty,
          choices: c.choicesAround(fact, distractors: [k * k, k, fact ~/ k]),
          steps: [
            'All $k are being arranged, so this is $k!.',
            '$k! = ${List.generate(k, (i) => k - i).join(' x ')} = $fact.',
          ],
          hint: 'Every book is used, so it is n factorial.',
        );
      case 3:
        // Which one is it? Naming the tool is the skill; the arithmetic is
        // the easy part once you have chosen.
        final ordered = c.coin();
        return Question(
          skillId: c.skillId,
          prompt: ordered
              ? 'Three prizes - first, second and third - are given to 3 of '
                  '$n students.\n\nIs this a permutation or a combination?'
              : 'A team of 3 is picked from $n students, with no captain.\n\n'
                  'Is this a permutation or a combination?',
          answer: ordered ? 'permutation' : 'combination',
          difficulty: c.difficulty,
          choices: const ['permutation', 'combination'],
          steps: [
            ordered
                ? 'First and second are different prizes, so the ORDER matters.'
                : 'The three team members are just a group - swapping them '
                    'changes nothing.',
            'Order ${ordered ? 'matters' : 'does not matter'}, so it is a '
                '${ordered ? 'permutation' : 'combination'}.',
          ],
          hint: 'Ask whether swapping two of them gives a different result.',
        );
      default:
        break;
    }

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

    int nCr(int n, int r) {
      var v = 1;
      for (var i = 0; i < r; i++) {
        v = v * (n - i) ~/ (i + 1);
      }
      return v;
    }

    // One question - the coefficient of the second term - for a whole chapter
    // whose exam questions are almost always "find the middle term" or "find
    // the term independent of x". A student could learn nC1 and nothing else.
    switch (c.variantByLevel(4)) {
      case 0:
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
      case 1:
        // How many terms there are. Students answer n, and the answer is n+1 -
        // the off-by-one the chapter is built to catch.
        return Question(
          skillId: c.skillId,
          prompt: 'How many terms are there in the expansion of '
              '(x + $a)^$n?',
          answer: '${n + 1}',
          difficulty: c.difficulty,
          choices: c.choicesAround(n + 1, distractors: [n, n - 1, 2 * n]),
          steps: [
            'The powers of x run from $n all the way down to 0.',
            'That is $n, ${n - 1}, ..., 1, 0 - which is ${n + 1} terms, not $n.',
          ],
          hint: 'Do not forget the term where x has power 0.',
        );
      case 2:
        // A binomial coefficient on its own, which is what every other
        // question in the chapter is built out of.
        final r = c.int_(1, n - 1);
        return Question(
          skillId: c.skillId,
          prompt: 'In the expansion of (x + 1)^$n, what is the coefficient of '
              '${term(1, 'x', power: n - r)}?\n\n(That is ${n}C$r.)',
          answer: '${nCr(n, r)}',
          difficulty: c.difficulty,
          choices: c.choicesAround(nCr(n, r),
              distractors: [n * r, n + r, nCr(n, r) + 1]),
          steps: [
            '${n}C$r = ${List.generate(r, (i) => n - i).join(' x ')} / '
                '${List.generate(r, (i) => i + 1).join(' x ')}.',
            'That comes to ${nCr(n, r)}.',
          ],
          hint: 'nCr counts the ways of choosing r things from n.',
        );
      default:
        // The constant term - the one every board paper asks for, and the one
        // students cannot do because it needs the general term, not a shortcut.
        return Question(
          skillId: c.skillId,
          prompt: 'In the expansion of (x + $a)^$n,\n\n'
              'what is the term that has no x in it?',
          answer: '${_pow(a, n)}',
          difficulty: c.difficulty,
          choices: c.choicesAround(_pow(a, n),
              distractors: [a * n, _pow(a, n - 1), n]),
          steps: [
            'The term with no x comes from taking $a every single time.',
            'That is $a multiplied by itself $n times.',
            '$a^$n = ${_pow(a, n)}.',
          ],
          hint: 'Which term uses none of the x at all?',
        );
    }
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

    // One row times one column, every time. A Class 12 matrices chapter is
    // addition, scalar multiples, transposes and the order of a product -
    // and whether a product exists at all, which is the first thing the
    // chapter teaches and the thing students get wrong in the exam.
    switch (c.variantByLevel(5)) {
      case 1:
        // Addition. Element by element, and only when the orders match.
        final b12 = c.int_(lo, hi), b22 = c.int_(lo, hi);
        final wantRow = c.coin();
        return Question(
          skillId: c.skillId,
          prompt: 'A = [ $a11  $a12 ]        B = [ $b11  $b12 ]\n\n'
              'In A + B, what is the ${wantRow ? 'first' : 'second'} entry?',
          answer: '${wantRow ? a11 + b11 : a12 + b12}',
          difficulty: c.difficulty,
          choices: c.choicesAround(wantRow ? a11 + b11 : a12 + b12,
              distractors: [a11 + b12, a11 * b11, a12 + b22]),
          steps: [
            'Matrices are added entry by matching entry.',
            '${wantRow ? a11 : a12} + ${wantRow ? b11 : b12} = '
                '${wantRow ? a11 + b11 : a12 + b12}.',
          ],
          hint: 'Add the entries that sit in the same position.',
        );
      case 2:
        // A scalar multiple. Every entry, not just the first - which is the
        // slip.
        final k = c.int_(2, c.band(4, 9));
        return Question(
          skillId: c.skillId,
          prompt: 'A = [ $a11  $a12 ]\n\n'
              'In ${k}A, what is the second entry?',
          answer: '${k * a12}',
          difficulty: c.difficulty,
          choices: c.choicesAround(k * a12,
              distractors: [a12, k * a11, k + a12]),
          steps: [
            'A scalar multiplies EVERY entry, not just the first.',
            '$k x $a12 = ${k * a12}.',
          ],
          hint: 'Multiply each entry by $k.',
        );
      case 3:
        // Does the product even exist, and what order is it? This is the
        // question the chapter opens with and the sheet never asked.
        final p = c.int_(2, 4), q = c.int_(2, 4), r = c.int_(2, 4);
        final matches = c.coin();
        final bRows = matches ? q : c.intExcept(2, 4, {q});
        return Question(
          skillId: c.skillId,
          prompt: 'A is a $p x $q matrix and B is a $bRows x $r matrix.\n\n'
              'Does the product AB exist? Answer yes or no.',
          answer: bRows == q ? 'yes' : 'no',
          difficulty: c.difficulty,
          choices: const ['yes', 'no'],
          steps: [
            'AB exists only when the columns of A match the rows of B.',
            'A has $q columns and B has $bRows rows.',
            bRows == q
                ? 'They match, so AB exists and is $p x $r.'
                : 'They do not match, so AB does not exist.',
          ],
          hint: 'Compare the columns of the first with the rows of the second.',
        );
      case 4:
        // The transpose. Rows become columns, and the entry that moves is the
        // one worth asking about.
        final b12 = c.int_(lo, hi), b22 = c.int_(lo, hi);
        return Question(
          skillId: c.skillId,
          prompt: 'A = [ $a11  $a12 ]\n'
              '    [ $b12  $b22 ]\n\n'
              'In the transpose of A, what is the entry in row 1, column 2?',
          answer: '$b12',
          difficulty: c.difficulty,
          choices: c.choicesAround(b12, distractors: [a12, a11, b22]),
          steps: [
            'Transposing swaps rows and columns.',
            'The entry in row 2, column 1 of A moves to row 1, column 2.',
            'That entry is $b12.',
          ],
          hint: 'Read A down its first column instead of across its first row.',
        );
      default:
        break;
    }

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

    // ad - bc, twenty times. The chapter also asks when a matrix is singular,
    // solves for a missing entry, and uses the determinant for the area of a
    // triangle - which is the one place a Class 12 student sees what it means
    // rather than how to compute it.
    switch (c.variantByLevel(4)) {
      case 1:
        // Singular: det = 0. Built as a second row that is k times the first,
        // then nudged when the answer should be "no".
        //
        // The leading entry must not be zero. det here is top x (row2b - b x k),
        // so with top = 0 the whole first column is zeros, the determinant is 0
        // whatever the nudge does, and the generator answered "no" to a matrix
        // that was singular. Found by re-deriving the answers, not by reading.
        final top = c.intExcept(lo, hi, {0});
        final k = c.int_(2, c.band(3, 6));
        final singular = c.coin();
        final row2a = top * k;
        final row2b = singular ? b * k : b * k + c.int_(1, 5);
        return Question(
          skillId: c.skillId,
          prompt: 'Is this matrix singular (does it have determinant 0)?\n\n'
              '[ $top  $b ]\n[ $row2a  $row2b ]\n\nAnswer yes or no.',
          answer: singular ? 'yes' : 'no',
          difficulty: c.difficulty,
          choices: const ['yes', 'no'],
          steps: [
            'Determinant = ad - bc = ($top x $row2b) - ($b x $row2a).',
            '= ${top * row2b} - ${b * row2a} = ${top * row2b - b * row2a}.',
            singular
                ? 'That is 0, so the matrix is singular - the second row is '
                    'just $k times the first.'
                : 'That is not 0, so it is not singular.',
          ],
          hint: 'Work out the determinant and see whether it comes to zero.',
        );
      case 2:
        // Solve for a missing entry given the determinant.
        return Question(
          skillId: c.skillId,
          prompt: 'The determinant of\n\n[ $a  $b ]\n[ $cc  k ]\n\n'
              'is $det. Find k.',
          answer: '$d',
          difficulty: c.difficulty,
          choices: c.choicesAround(d, distractors: [det, b * cc, a]),
          steps: [
            'Determinant = ${term(a, 'k')} - ($b x $cc) = '
                '${term(a, 'k')} - ${b * cc}.',
            'So ${term(a, 'k')} - ${b * cc} = $det, giving '
                '${term(a, 'k')} = ${det + b * cc}.',
            'k = ${det + b * cc} / $a = $d.',
          ],
          hint: 'Write out ad - bc with k in it, then solve.',
        );
      case 3:
        // Area of a triangle. Built from a right-angled one so the area is a
        // whole number and the determinant does the work.
        final w = c.int_(2, c.band(5, 12));
        final h = c.int_(2, c.band(5, 12)) * 2;
        return Question(
          skillId: c.skillId,
          prompt: 'A triangle has vertices (0, 0), ($w, 0) and (0, $h).\n\n'
              'Use the determinant formula to find its area.',
          answer: '${w * h ~/ 2}',
          difficulty: c.difficulty,
          choices: c.choicesAround(w * h ~/ 2, distractors: [w * h, w + h, w]),
          steps: [
            'Area = half the absolute value of the determinant formed by the '
                'three points.',
            'That determinant comes to $w x $h = ${w * h}.',
            'Area = ${w * h} / 2 = ${w * h ~/ 2} square units.',
          ],
          hint: 'The determinant gives twice the area.',
        );
      default:
        break;
    }

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

    // The dot product, twenty times. Magnitude, unit vectors, adding, and the
    // perpendicular test are the rest of the chapter - and the last of those
    // is the reason the dot product is taught at all.
    switch (c.variantByLevel(4)) {
      case 1:
        // Magnitude, from a quadruple so the root is whole.
        final q = c.pickByLevel(const [[1, 2, 2, 3], [2, 3, 6, 7], [1, 4, 8, 9],
          [4, 4, 7, 9], [2, 6, 9, 11]]);
        final sign = c.coin() ? 1 : -1;
        return Question(
          skillId: c.skillId,
          prompt: 'Find the magnitude of the vector\n\n'
              'a = (${q[0] * sign}, ${q[1]}, ${q[2] * sign})',
          answer: '${q[3]}',
          difficulty: c.difficulty,
          choices: c.choicesAround(q[3],
              distractors: [q[0] + q[1] + q[2], q[3] + 1, q[2]]),
          steps: [
            'Magnitude = root(x^2 + y^2 + z^2). Signs disappear when squared.',
            '${q[0] * q[0]} + ${q[1] * q[1]} + ${q[2] * q[2]} = '
                '${q[3] * q[3]}.',
            'root(${q[3] * q[3]}) = ${q[3]}.',
          ],
          hint: 'Square each component, add, then take the root.',
        );
      case 2:
        // Adding vectors, component by component.
        final which = c.int_(0, 2);
        const names = ['first', 'second', 'third'];
        return Question(
          skillId: c.skillId,
          prompt: 'a = (${a.join(', ')})   and   b = (${b.join(', ')})\n\n'
              'In a + b, what is the ${names[which]} component?',
          answer: '${a[which] + b[which]}',
          difficulty: c.difficulty,
          choices: c.choicesAround(a[which] + b[which],
              distractors: [a[which] * b[which], a[which], b[which]]),
          steps: [
            'Vectors are added component by matching component.',
            '${a[which]} + ${b[which]} = ${a[which] + b[which]}.',
          ],
          hint: 'Add the components that sit in the same place.',
        );
      case 3:
        // Perpendicular or not. This is what the dot product is FOR, and the
        // sheet never once used it that way.
        final perp = c.coin();
        // (p, q, 0) and (-q, p, 0) are perpendicular; nudge one to break it.
        final p = c.int_(1, c.band(4, 9));
        final r = c.int_(1, c.band(4, 9));
        final second = perp ? [-r, p, 0] : [-r, p + c.int_(1, 4), 0];
        final d = p * second[0] + r * second[1];
        return Question(
          skillId: c.skillId,
          prompt: 'a = ($p, $r, 0)   and   b = (${second.join(', ')})\n\n'
              'Are these two vectors perpendicular? Answer yes or no.',
          answer: d == 0 ? 'yes' : 'no',
          difficulty: c.difficulty,
          choices: const ['yes', 'no'],
          steps: [
            'Two vectors are perpendicular exactly when their dot product '
                'is 0.',
            'a . b = ($p x ${second[0]}) + ($r x ${second[1]}) + 0 = $d.',
            d == 0
                ? 'The dot product is 0, so yes.'
                : 'The dot product is $d, not 0, so no.',
          ],
          hint: 'Work out the dot product and see whether it comes to zero.',
        );
      default:
        break;
    }

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

    // One question, and it was not even three-dimensional: dz was always 0, so
    // every "3D distance" was a flat 2D one with a third number carried along
    // unchanged. The chapter is about octants, distance from the axes and the
    // planes, and the midpoint - none of which was here.
    switch (c.variantByLevel(4)) {
      case 1:
        // A genuinely three-dimensional distance. (1,2,2), (2,3,6) and
        // (1,4,8) are the Pythagorean quadruples that keep the root whole.
        final q = c.pickByLevel(const [[1, 2, 2, 3], [2, 3, 6, 7], [1, 4, 8, 9],
          [4, 4, 7, 9], [2, 6, 9, 11]]);
        return Question(
          skillId: c.skillId,
          prompt: 'Find the distance between the points\n\n'
              '($x1, $y1, $z1)   and   '
              '(${x1 + q[0]}, ${y1 + q[1]}, ${z1 + q[2]})',
          answer: '${q[3]}',
          difficulty: c.difficulty,
          choices: c.choicesAround(q[3],
              distractors: [q[0] + q[1] + q[2], q[3] + 1, q[2]]),
          steps: [
            'Distance = root((dx)^2 + (dy)^2 + (dz)^2).',
            'Differences: ${q[0]}, ${q[1]} and ${q[2]}.',
            '${q[0] * q[0]} + ${q[1] * q[1]} + ${q[2] * q[2]} = '
                '${q[3] * q[3]}, and root(${q[3] * q[3]}) = ${q[3]}.',
          ],
          hint: 'Same as in two dimensions, with a third square added.',
        );
      case 2:
        // Which octant. The 3D version of "which quadrant", and there are
        // eight of them because each coordinate can go either way.
        final px = c.intExcept(-reach, reach, {0});
        final py = c.intExcept(-reach, reach, {0});
        final pz = c.intExcept(-reach, reach, {0});
        final octant = [px, py, pz].where((v) => v < 0).length;
        return Question(
          skillId: c.skillId,
          prompt: 'The point ($px, $py, $pz) is in three-dimensional space.\n\n'
              'How many of its coordinates are negative?',
          answer: '$octant',
          difficulty: c.difficulty,
          choices: const ['0', '1', '2', '3'],
          steps: [
            'Look at each coordinate in turn: $px, $py, $pz.',
            'Space is divided into 8 octants by the signs of the three '
                'coordinates.',
            '$octant of these are negative.',
          ],
          hint: 'Check the sign of x, then y, then z.',
        );
      case 3:
        // Distance from a coordinate plane. The xy-plane is where z is 0, so
        // the distance is |z| - and students reach for the whole formula.
        final plane = c.pick(const ['xy', 'yz', 'zx']);
        final away = switch (plane) {
          'xy' => z1.abs(),
          'yz' => x1.abs(),
          _ => y1.abs(),
        };
        return Question(
          skillId: c.skillId,
          prompt: 'How far is the point ($x1, $y1, $z1) from the '
              '$plane-plane?',
          answer: '$away',
          difficulty: c.difficulty,
          choices: c.choicesAround(away,
              distractors: [x1.abs(), y1.abs(), z1.abs()]),
          steps: [
            'On the $plane-plane, the '
                '${plane == 'xy' ? 'z' : (plane == 'yz' ? 'x' : 'y')} '
                'coordinate is 0.',
            'So the distance is how far that one coordinate is from 0.',
            'That is $away - distances are never negative.',
          ],
          hint: 'Which coordinate is zero everywhere on that plane?',
        );
      default:
        break;
    }

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

    // Evaluating Z at one corner was the whole skill. The method is: test
    // every corner and take the best - so a question that hands you a single
    // corner never asks the student to do the thing the chapter is about.
    switch (c.variantByLevel(3)) {
      case 1:
        // Test several corners and pick the winner. This is the method.
        final corners = <List<int>>[];
        while (corners.length < 3) {
          final p = [c.int_(0, c.band(8, 20)), c.int_(0, c.band(8, 20))];
          if (corners.every((e) => a * e[0] + b * e[1] != a * p[0] + b * p[1])) {
            corners.add(p);
          }
        }
        final maximise = c.coin();
        final values = [for (final p in corners) a * p[0] + b * p[1]];
        final best = maximise
            ? values.reduce((p, q) => p > q ? p : q)
            : values.reduce((p, q) => p < q ? p : q);
        return Question(
          skillId: c.skillId,
          prompt: 'Z = ${term(a, 'x')} + ${term(b, 'y')}.\n\n'
              'The corner points of the feasible region are '
              '${corners.map((p) => '(${p[0]}, ${p[1]})').join(', ')}.\n\n'
              'What is the ${maximise ? 'MAXIMUM' : 'MINIMUM'} value of Z?',
          answer: '$best',
          difficulty: c.difficulty,
          choices: c.choicesAround(best,
              distractors: [...values.where((v) => v != best)]),
          steps: [
            'Work out Z at every corner point.',
            for (var i = 0; i < corners.length; i++)
              'At (${corners[i][0]}, ${corners[i][1]}): $a x ${corners[i][0]} '
                  '+ $b x ${corners[i][1]} = ${values[i]}.',
            'The ${maximise ? 'largest' : 'smallest'} is $best.',
          ],
          hint: 'The best value always sits at a corner - so test them all.',
        );
      case 2:
        // Does a point satisfy the constraint? Before any optimising, a
        // student has to be able to check whether a point is even allowed.
        final limit = c.int_(c.band(20, 60), c.band(80, 200));
        final px = c.int_(1, c.band(8, 20)), py = c.int_(1, c.band(8, 20));
        final lhs = a * px + b * py;
        return Question(
          skillId: c.skillId,
          prompt: 'A constraint says  ${term(a, 'x')} + ${term(b, 'y')} '
              '<= $limit.\n\n'
              'Does the point ($px, $py) satisfy it? Answer yes or no.',
          answer: lhs <= limit ? 'yes' : 'no',
          difficulty: c.difficulty,
          choices: const ['yes', 'no'],
          steps: [
            'Put the point in: $a x $px + $b x $py = $lhs.',
            '$lhs is ${lhs <= limit ? 'not more than' : 'more than'} $limit, '
                'so the point ${lhs <= limit ? 'does' : 'does not'} satisfy '
                'the constraint.',
          ],
          hint: 'Substitute and compare with $limit.',
        );
      default:
        break;
    }

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
    final kind =
        c.pick(const ['twoheads', 'atleastone', 'dicesum', 'complement',
          'cards']);
    if (kind == 'complement') {
      // Given P(E), find P(not E). One subtraction, and the fact that the two
      // add to 1 is the backbone of the whole chapter.
      final den = c.pick(const [4, 5, 8, 10, 20]);
      final num = c.int_(1, den - 1);
      final p = Fraction(num, den);
      final notP = Fraction(den - num, den);
      return Question(
        skillId: c.skillId,
        prompt: 'The probability that it rains tomorrow is ${p.toString()}.'
            '\n\nWhat is the probability that it does NOT rain? '
            '(fraction in lowest terms)',
        answer: notP.toString(),
        difficulty: c.difficulty,
        steps: [
          'An event and its complement always add up to 1.',
          '1 - $num/$den = ${den - num}/$den.',
          'In lowest terms that is ${notP.toString()}.',
        ],
        hint: 'P(E) + P(not E) = 1.',
      );
    }
    if (kind == 'cards') {
      // A pack of cards, which every Class 12 probability exercise uses.
      final want = c.pickByLevel(const [
        ('a red card', 26), ('a spade', 13), ('an ace', 4),
        ('a face card', 12), ('a red king', 2),
      ]);
      final f = Fraction(want.$2, 52);
      return Question(
        skillId: c.skillId,
        prompt: 'One card is drawn from a well shuffled pack of 52.\n\n'
            'What is the probability it is ${want.$1}? '
            '(fraction in lowest terms)',
        answer: f.toString(),
        difficulty: c.difficulty,
        steps: [
          'A pack has 52 cards in 4 suits of 13.',
          '${want.$2} of them are ${want.$1}.',
          '${want.$2}/52 = ${f.toString()}.',
        ],
        hint: 'Count how many of the 52 fit, then simplify.',
      );
    }
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
    // Slope from two points was the whole chapter. Straight Lines is mostly
    // about turning a slope into an equation and comparing two lines, so the
    // other four questions live in _lineExtras.
    final variant = c.variantByLevel(5);
    if (variant > 0) return _lineExtras(c, variant);
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

    // Difference of two squares over (x - a), every single time. A student
    // learns "cancel and substitute" without ever meeting the limit that needs
    // no work at all, or one that factorises a different way - and so never
    // learns to check for 0/0 before reaching for the trick.
    switch (c.variantByLevel(3)) {
      case 1:
        // Direct substitution. Not every limit is 0/0, and a student who
        // always factorises is guessing rather than deciding.
        final b = c.int_(1, c.band(4, 12));
        return Question(
          skillId: c.skillId,
          prompt: 'Find the limit as x approaches $a of\n\n'
              '${term(1, 'x', power: 2)} + ${term(b, 'x')}',
          answer: '${a * a + b * a}',
          difficulty: c.difficulty,
          choices: c.choicesAround(a * a + b * a,
              distractors: [a + b, a * a, 2 * a + b]),
          steps: [
            'Put x = $a straight in and see what happens.',
            '$a^2 + $b x $a = ${a * a} + ${b * a} = ${a * a + b * a}.',
            'No 0/0, so there is nothing to factorise - that is the answer.',
          ],
          hint: 'Try substituting first. Only factorise if you get 0/0.',
        );
      case 2:
        // Factorises, but as (x - a)(x - b) rather than a difference of
        // squares - so the cancelling has to be found rather than recalled.
        final b = c.intExcept(1, c.band(5, 12), {a});
        return Question(
          skillId: c.skillId,
          prompt: 'Find the limit as x approaches $a of\n\n'
              '(${term(1, 'x', power: 2)} - ${term(a + b, 'x')} + ${a * b}) '
              '/ (x - $a)',
          answer: '${a - b}',
          difficulty: c.difficulty,
          choices: c.choicesAround(a - b, distractors: [a + b, a * b, b - a]),
          steps: [
            'Putting x = $a straight in gives 0/0, so factorise the top.',
            'It factorises as (x - $a)(x - $b).',
            'The (x - $a) cancels, leaving x - $b.',
            'Now put x = $a: $a - $b = ${a - b}.',
          ],
          hint: 'Find two numbers that multiply to ${a * b} and add to '
              '${a + b}.',
        );
      default:
        break;
    }

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

    // The slope of a tangent was the only application. Turning points,
    // increasing and decreasing, and rate of change are the rest of the
    // chapter, and the first of those is most of its exam marks.
    switch (c.variantByLevel(4)) {
      case 1:
        // The turning point of a quadratic - where the derivative is zero.
        final p = c.int_(1, c.band(4, 10));
        // y = x^2 - 2px + q has dy/dx = 2x - 2p, zero at x = p.
        return Question(
          skillId: c.skillId,
          prompt: 'For the curve  y = ${term(1, 'x', power: 2)} - '
              '${term(2 * p, 'x')} + 7,\n\n'
              'at what value of x is the tangent horizontal?',
          answer: '$p',
          difficulty: c.difficulty,
          choices: c.choicesAround(p, distractors: [2 * p, p * p, 7]),
          steps: [
            'A horizontal tangent means the derivative is 0.',
            'dy/dx = ${term(2, 'x')} - ${2 * p}.',
            '${term(2, 'x')} - ${2 * p} = 0 gives x = $p.',
          ],
          hint: 'Differentiate and set the result to zero.',
        );
      case 2:
        // Increasing or decreasing at a point - the sign of the derivative,
        // which is a different question from its value.
        final p = c.int_(1, c.band(4, 10));
        final at = c.intExcept(1, c.band(6, 14), {p});
        final slopeHere = 2 * at - 2 * p;
        return Question(
          skillId: c.skillId,
          prompt: 'For the curve  y = ${term(1, 'x', power: 2)} - '
              '${term(2 * p, 'x')},\n\n'
              'is the curve increasing or decreasing at x = $at?',
          answer: slopeHere > 0 ? 'increasing' : 'decreasing',
          difficulty: c.difficulty,
          choices: const ['increasing', 'decreasing'],
          steps: [
            'dy/dx = ${term(2, 'x')} - ${2 * p}.',
            'At x = $at: ${2 * at} - ${2 * p} = $slopeHere.',
            'The derivative is ${slopeHere > 0 ? 'positive' : 'negative'}, so '
                'the curve is ${slopeHere > 0 ? 'increasing' : 'decreasing'}.',
          ],
          hint: 'It is the SIGN of the derivative that matters, not its size.',
        );
      case 3:
        // Rate of change, which is what a derivative means outside a graph.
        final r = c.int_(1, c.band(3, 8));
        final t = c.int_(1, c.band(4, 9));
        return Question(
          skillId: c.skillId,
          prompt: 'The distance travelled is  s = ${term(r, 't', power: 2)}  '
              'metres after t seconds.\n\n'
              'What is the speed at t = $t seconds, in metres per second?',
          answer: '${2 * r * t}',
          difficulty: c.difficulty,
          choices: c.choicesAround(2 * r * t,
              distractors: [r * t * t, r * t, 2 * r]),
          steps: [
            'Speed is the rate of change of distance: ds/dt.',
            'ds/dt = ${term(2 * r, 't')}.',
            'At t = $t: 2 x $r x $t = ${2 * r * t} m/s.',
          ],
          hint: 'Differentiate the distance with respect to time.',
        );
      default:
        break;
    }

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

    // The integral of 2x from 0 to b, and nothing else - so the lower limit
    // was always 0, the "subtract the bottom" step never actually did
    // anything, and every question integrated to x^2 so the power rule was
    // never exercised. Application of Integrals is about areas, and this
    // generator serves that chapter too.
    switch (c.variantByLevel(5)) {
      case 1:
        // A lower limit that is not zero, so both limits are used.
        final lo = c.int_(1, b - 1);
        return Question(
          skillId: c.skillId,
          prompt: 'Evaluate the integral of  2x  from $lo to $b.',
          answer: '${b * b - lo * lo}',
          difficulty: c.difficulty,
          choices: c.choicesAround(b * b - lo * lo,
              distractors: [b * b, lo * lo, b - lo]),
          steps: [
            'The integral of 2x is x^2.',
            'Put in the limits: $b^2 - $lo^2.',
            '${b * b} - ${lo * lo} = ${b * b - lo * lo}.',
          ],
          hint: 'Top limit minus bottom limit - and the bottom is not 0 here.',
        );
      case 3:
        // A different integrand. With only 2x in the generator the power rule
        // was never exercised - every question integrated to x^2 and the
        // student could learn that one result instead of the rule.
        return Question(
          skillId: c.skillId,
          prompt: 'Evaluate the integral of  ${term(3, 'x', power: 2)}  '
              'from 0 to $b.',
          answer: '${b * b * b}',
          difficulty: c.difficulty,
          choices: c.choicesAround(b * b * b,
              distractors: [b * b, 3 * b * b, 3 * b]),
          steps: [
            'Raise the power by 1 and divide by the new power: '
                '${term(3, 'x', power: 2)} integrates to '
                '${term(1, 'x', power: 3)}.',
            'Put in the limits: $b^3 - 0^3.',
            '${b * b * b} - 0 = ${b * b * b}.',
          ],
          hint: 'Add one to the power, then divide by the new power.',
        );
      case 4:
        // Integrating a constant. The area is a rectangle, so a student can
        // check the calculus against something they can see - and nothing
        // else in this generator ever integrates anything but a power of x.
        final h = c.int_(2, c.band(5, 12));
        return Question(
          skillId: c.skillId,
          prompt: 'Find the area under the line  y = $h  between x = 0 and '
              'x = $b, above the x-axis.',
          answer: '${h * b}',
          difficulty: c.difficulty,
          choices: c.choicesAround(h * b, distractors: [h + b, b * b, h]),
          steps: [
            'The integral of the constant $h is ${term(h, 'x')}.',
            'Put in the limits: $h x $b - 0 = ${h * b}.',
            'It is a rectangle $b wide and $h high, so ${h * b} square units '
                'is right.',
          ],
          hint: 'Integrating a constant k gives kx.',
        );
      case 2:
        // Area under a curve, which is what the chapter is called. Same
        // integral, and the reason it exists.
        final k = c.int_(1, c.band(2, 5));
        return Question(
          skillId: c.skillId,
          prompt: 'Find the area under the curve  y = ${term(2 * k, 'x')}  '
              'between x = 0 and x = $b, above the x-axis.',
          answer: '${k * b * b}',
          difficulty: c.difficulty,
          choices: c.choicesAround(k * b * b,
              distractors: [2 * k * b, b * b, k * b]),
          steps: [
            'The area under a curve is the definite integral.',
            'The integral of ${term(2 * k, 'x')} is ${term(k, 'x')}^2.',
            'Put in the limits: $k x $b^2 - 0 = ${k * b * b} square units.',
          ],
          hint: 'Integrate, then subtract the value at the lower limit.',
        );
      default:
        break;
    }

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

    // One equation, dy/dx = kx, every time. Order and degree are the first
    // thing the chapter defines and are worth easy marks; a separable equation
    // is what the rest of it is about.
    switch (c.variantByLevel(3)) {
      case 1:
        // Order: the highest derivative that appears. Recall, and reliably
        // examined.
        final order = c.pickByLevel(const [1, 2, 3]);
        const written = {
          1: 'dy/dx + 5y = 0',
          2: 'd2y/dx2 + 3 dy/dx + 2y = 0',
          3: 'd3y/dx3 + y = 0',
        };
        return Question(
          skillId: c.skillId,
          prompt: 'What is the order of the differential equation\n\n'
              '${written[order]}',
          answer: '$order',
          difficulty: c.difficulty,
          choices: const ['1', '2', '3'],
          steps: [
            'The order is the highest derivative that appears.',
            'Here the highest is '
                '${order == 1 ? 'dy/dx' : (order == 2 ? 'd2y/dx2' : 'd3y/dx3')}'
                ', so the order is $order.',
          ],
          hint: 'Look for the highest derivative, not the highest power.',
        );
      case 2:
        // Using the constant. A general solution is a family of curves; the
        // initial condition picks one, and that is the step students skip.
        final y0 = c.int_(1, c.band(5, 15));
        return Question(
          skillId: c.skillId,
          prompt: 'The general solution of a differential equation is\n\n'
              'y = ${term(k, 'x')} + C\n\n'
              'If y = ${k + y0} when x = 1, what is C?',
          answer: '$y0',
          difficulty: c.difficulty,
          choices: c.choicesAround(y0, distractors: [k, k + y0, y0 + 1]),
          steps: [
            'Put x = 1 and y = ${k + y0} into y = ${term(k, 'x')} + C.',
            '${k + y0} = $k + C.',
            'C = ${k + y0} - $k = $y0.',
          ],
          hint: 'Substitute the given values and solve for C.',
        );
      default:
        break;
    }

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

/// Integer power. `pow` from dart:math returns a double, and a coefficient
/// printed as 81.0 on a worksheet is not a coefficient.
int _pow(int base, int exponent) {
  var v = 1;
  for (var i = 0; i < exponent; i++) {
    v *= base;
  }
  return v;
}

/// The rest of the Straight Lines chapter.
///
/// Slope from two points was the only question in it, and that one keeps its
/// own hand-built choices because a slope is often negative and
/// [GenContext.choicesAround] works in non-negatives. Split out rather than
/// nested so that special case stays readable.
Question _lineExtras(GenContext c, int variant) {
  final m = c.int_(1, c.band(3, 8)) * (c.coin() ? 1 : -1);
  final c0 = c.int_(-c.band(4, 12), c.band(4, 12));
  final x = c.int_(1, c.band(4, 9));

  switch (variant) {
    case 1:
      // Read the slope and intercept straight off y = mx + c.
      final wantSlope = c.coin();
      return Question(
        skillId: c.skillId,
        prompt: 'A line has the equation  y = ${term(m, 'x')} '
            '${c0 < 0 ? '-' : '+'} ${c0.abs()}\n\n'
            'What is its ${wantSlope ? 'slope' : 'y-intercept'}?',
        answer: '${wantSlope ? m : c0}',
        difficulty: c.difficulty,
        steps: [
          'In y = mx + c, m is the slope and c is where it crosses the '
              'y-axis.',
          'Here m = $m and c = $c0.',
          'So the ${wantSlope ? 'slope' : 'y-intercept'} is '
              '${wantSlope ? m : c0}.',
        ],
        hint: 'Compare it with y = mx + c.',
      );
    case 2:
      // Parallel and perpendicular. The negative reciprocal is the fact
      // students lose marks on, and it never appeared.
      final parallel = c.coin();
      // Perpendicular slopes stay whole only when the slope is 1 or -1, so
      // the question asks for the rule rather than an awkward fraction.
      return Question(
        skillId: c.skillId,
        prompt: 'A line has slope $m.\n\n'
            'What is the slope of a line ${parallel ? 'parallel' : 'perpendicular'} '
            'to it? ${parallel ? '' : 'Write a fraction like -1/2 if you need to.'}',
        answer: parallel
            ? '$m'
            : (m == 1 ? '-1' : (m == -1 ? '1' : '${m < 0 ? '' : '-'}1/${m.abs()}')),
        difficulty: c.difficulty,
        steps: [
          parallel
              ? 'Parallel lines have exactly the same slope.'
              : 'Perpendicular slopes multiply to -1, so you flip the '
                  'fraction and change the sign.',
          parallel
              ? 'So the slope is $m.'
              : 'The negative reciprocal of $m is '
                  '${m == 1 ? '-1' : (m == -1 ? '1' : '${m < 0 ? '' : '-'}1/${m.abs()}')}.',
        ],
        hint: parallel
            ? 'Parallel means same steepness.'
            : 'Turn it upside down and flip the sign.',
      );
    case 3:
      // Point-slope: build the equation, then evaluate it. Asking for the
      // value keeps the answer a single number the app can mark.
      final y = m * x + c0;
      return Question(
        skillId: c.skillId,
        prompt: 'A line has slope $m and passes through (0, $c0).\n\n'
            'What is y when x = $x?',
        answer: '$y',
        difficulty: c.difficulty,
        steps: [
          'It crosses the y-axis at $c0, so the line is '
              'y = ${term(m, 'x')} ${c0 < 0 ? '-' : '+'} ${c0.abs()}.',
          'Put x = $x in: $m x $x ${c0 < 0 ? '-' : '+'} ${c0.abs()} = $y.',
        ],
        hint: 'Write y = mx + c first, then substitute.',
      );
    default:
      // Where the line crosses the x-axis. Set y to 0 - the step students
      // forget, because every other question hands them x.
      final slope = c.int_(1, c.band(3, 6)) * (c.coin() ? 1 : -1);
      final root = c.int_(1, c.band(4, 9));
      // Chosen so the intercept is a whole number: y = m(x - root).
      return Question(
        skillId: c.skillId,
        prompt: 'A line has the equation  y = ${term(slope, 'x')} '
            '${-slope * root < 0 ? '-' : '+'} ${(slope * root).abs()}\n\n'
            'Where does it cross the x-axis? Give the value of x.',
        answer: '$root',
        difficulty: c.difficulty,
        choices: c.choicesAround(root,
            distractors: [slope, slope * root, root + 1]),
        steps: [
          'On the x-axis, y is 0.',
          'So ${term(slope, 'x')} = ${slope * root}.',
          'x = ${slope * root} / $slope = $root.',
        ],
        hint: 'Put y = 0 and solve for x.',
      );
  }
}
