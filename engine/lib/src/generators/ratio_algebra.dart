import '../fraction.dart';
import '../generator.dart';
import '../question.dart';

/// Ratio, percentage, commercial maths, integers and early algebra.
void registerRatioAlgebra() {
  // ----------------------------------------------------------- ratio/percent

  register('ratio_basic', (c) {
    final k = c.int_(2, c.band(5, 12));
    final f = Fraction(c.int_(1, 9), c.int_(1, 9));
    final a = f.num * k;
    final b = f.den * k;
    return Question(
      skillId: c.skillId,
      prompt: 'Write the ratio $a : $b in its simplest form (use a colon).',
      answer: '${f.num}:${f.den}',
      difficulty: c.difficulty,
      steps: [
        'HCF of $a and $b is ${Fraction.gcd(a, b)}.',
        'Divide both sides by ${Fraction.gcd(a, b)}.',
        '$a : $b = ${f.num} : ${f.den}.',
      ],
      hint: 'Simplify a ratio the same way you simplify a fraction.',
    );
  });

  register('ratio_divide', (c) {
    final p = c.int_(1, c.band(5, 9));
    final q = c.int_(1, c.band(5, 9));
    final unit = c.int_(c.band(5, 20), c.band(30, 90));
    final total = (p + q) * unit;
    return Question(
      skillId: c.skillId,
      prompt: 'Divide $total in the ratio $p : $q. '
          'What is the LARGER share?',
      answer: '${(p > q ? p : q) * unit}',
      difficulty: c.difficulty,
      choices: c.choicesAround((p > q ? p : q) * unit,
          distractors: [(p < q ? p : q) * unit, total ~/ 2, unit]),
      steps: [
        'Total parts = $p + $q = ${p + q}.',
        'One part = $total / ${p + q} = $unit.',
        'Shares are ${p * unit} and ${q * unit}. Larger = ${(p > q ? p : q) * unit}.',
      ],
      hint: 'First find what ONE part is worth.',
    );
  });

  register('unitary_method', (c) {
    final n1 = c.int_(2, c.band(6, 12));
    final perUnit = c.int_(c.band(5, 20), c.band(30, 150));
    final n2 = c.intExcept(2, c.band(9, 20), {n1});
    final cost1 = n1 * perUnit;
    final item = c.pick(['pens', 'books', 'apples', 'notebooks']);
    return Question(
      skillId: c.skillId,
      prompt: 'If $n1 $item cost Rs $cost1, what do $n2 $item cost?',
      answer: '${n2 * perUnit}',
      difficulty: c.difficulty,
      choices: c.choicesAround(n2 * perUnit,
          distractors: [perUnit, cost1 + n2, n1 * n2]),
      steps: [
        'Cost of 1 = $cost1 / $n1 = Rs $perUnit.',
        'Cost of $n2 = $n2 x $perUnit = Rs ${n2 * perUnit}.',
      ],
      hint: 'Always find the cost of ONE first.',
    );
  });

  register('percent_basic', (c) {
    final den = c.pick([2, 4, 5, 10, 20, 25, 50]);
    final num = c.int_(1, den - 1);
    final pct = num * 100 ~/ den;
    return Question(
      skillId: c.skillId,
      prompt: 'Write $num/$den as a percentage.',
      answer: '$pct',
      difficulty: c.difficulty,
      choices: c.choicesAround(pct, distractors: [num * 10, 100 - pct, den]),
      steps: [
        'Percentage means "out of 100".',
        '$num/$den x 100 = $pct.',
        'So $num/$den = $pct%.',
      ],
      hint: 'Multiply the fraction by 100.',
    );
  });

  register('percent_of', (c) {
    final pct = c.pick([5, 10, 12, 15, 20, 25, 30, 40, 50, 60, 75, 80]);
    final base = c.int_(1, c.band(8, 40)) * 100 ~/ Fraction.gcd(pct, 100) *
        Fraction.gcd(pct, 100);
    final n = (base ~/ 100) * 100;
    final ans = n * pct ~/ 100;
    return Question(
      skillId: c.skillId,
      prompt: 'Find $pct% of $n.',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [n - ans, pct, ans * 2]),
      steps: [
        '$pct% means $pct/100.',
        '$pct/100 x $n = $ans.',
      ],
      hint: '10% is easy - find that first, then scale it.',
    );
  });

  register('percent_change', (c) {
    final pct = c.pick([10, 20, 25, 40, 50]);
    final old = c.int_(2, c.band(6, 20)) * 100 ~/ Fraction.gcd(pct, 100) *
        Fraction.gcd(pct, 100);
    final oldV = (old ~/ 100) * 100;
    final up = c.coin();
    final change = oldV * pct ~/ 100;
    final newV = up ? oldV + change : oldV - change;
    return Question(
      skillId: c.skillId,
      prompt: 'A price changed from Rs $oldV to Rs $newV. '
          'What is the percentage ${up ? 'increase' : 'decrease'}?',
      answer: '$pct',
      difficulty: c.difficulty,
      choices: c.choicesAround(pct, distractors: [pct + 5, pct - 5, 100 - pct]),
      steps: [
        'First find how much it changed by: ${(newV - oldV).abs()}.',
        'Now compare that to the price you STARTED with, not the new one.',
        '${(newV - oldV).abs()} out of $oldV, as a percentage:',
        '${(newV - oldV).abs()} / $oldV x 100 = $pct%.',
      ],
      hint: 'Divide by the price you started with.',
    );
  });

  register('profit_loss', (c) {
    final pct = c.pick([5, 10, 12, 15, 20, 25]);
    final cp = c.int_(2, c.band(6, 20)) * 100;
    final profit = c.coin();
    final diff = cp * pct ~/ 100;
    final sp = profit ? cp + diff : cp - diff;
    return Question(
      skillId: c.skillId,
      prompt: 'Cost price is Rs $cp and selling price is Rs $sp. '
          'Find the ${profit ? 'profit' : 'loss'} percentage.',
      answer: '$pct',
      difficulty: c.difficulty,
      choices: c.choicesAround(pct, distractors: [pct + 5, pct - 2, 100 - pct]),
      steps: [
        '${profit ? 'Profit' : 'Loss'} = |$sp - $cp| = $diff.',
        '${profit ? 'Profit' : 'Loss'}% = $diff / CP x 100.',
        '$diff / $cp x 100 = $pct%.',
      ],
      hint: 'Profit % is always calculated on the COST price.',
    );
  });

  register('simple_interest', (c) {
    final p = c.int_(1, c.band(10, 60)) * 1000;
    final r = c.pick([4, 5, 6, 8, 10, 12]);
    final t = c.int_(1, c.band(3, 6));
    final si = p * r * t ~/ 100;
    return Question(
      skillId: c.skillId,
      prompt: 'Find the simple interest on Rs $p at $r% per year for $t years.',
      answer: '$si',
      difficulty: c.difficulty,
      choices: c.choicesAround(si, distractors: [p + si, si ~/ t, p * r ~/ 100]),
      steps: [
        'SI = P x R x T / 100.',
        '= $p x $r x $t / 100',
        '= Rs $si.',
      ],
      hint: 'SI = PRT/100.',
    );
  });

  // ---------------------------------------------------------------- integers

  register('integer_concept', (c) {
    final a = c.int_(-c.band(10, 50), c.band(10, 50));
    final b = c.intExcept(-c.band(10, 50), c.band(10, 50), {a});
    final bigger = a > b ? a : b;
    return Question(
      skillId: c.skillId,
      prompt: 'Which is greater:  $a  or  $b ?',
      answer: '$bigger',
      difficulty: c.difficulty,
      choices: ['$a', '$b'],
      steps: [
        'On the number line, the number further RIGHT is greater.',
        '$bigger is greater.',
      ],
      hint: 'With negatives, the one closer to zero is the bigger one.',
    );
  });

  register('integer_addsub', (c) {
    final hi = c.band(10, 40);
    final a = c.int_(-hi, hi);
    final b = c.int_(-hi, hi);
    if (c.difficulty >= 4) {
      final d = c.int_(-hi, hi);
      final ans = a + b + d;
      return Question(
        skillId: c.skillId,
        prompt: '${_signed(a, first: true)} ${_signed(b)} ${_signed(d)} = ?',
        answer: '$ans',
        difficulty: c.difficulty,
        choices: c.choicesAround(ans, distractors: [a - b + d, -ans]),
        steps: [
          'Work left to right.',
          '$a ${b < 0 ? '-' : '+'} ${b.abs()} = ${a + b}.',
          '${a + b} ${d < 0 ? '-' : '+'} ${d.abs()} = $ans.',
        ],
      );
    }
    final ans = a + b;
    return Question(
      skillId: c.skillId,
      prompt: '${_signed(a, first: true)} ${_signed(b)} = ?',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [a - b, -ans, ans.abs()]),
      steps: [
        b < 0
            ? 'Adding a negative is the same as subtracting: $a - ${b.abs()}.'
            : 'Start at $a on the number line and move $b to the right.',
        'Answer: $ans.',
      ],
      hint: 'Think of the number line - which way do you move?',
    );
  });

  register('integer_muldiv', (c) {
    final hi = c.band(6, 12);
    final a = c.int_(2, hi) * (c.coin() ? 1 : -1);
    final b = c.int_(2, hi) * (c.coin() ? 1 : -1);
    final mul = c.coin();
    if (mul) {
      final r = a * b;
      // The distractor that matters here is the sign error, so it has to be
      // on the list. choicesAround() only deals in non-negatives, so these
      // are built by hand.
      final opts = <int>{r, -r, a * b.abs(), -(a.abs() * b.abs())};
      final list = opts.toList()..shuffle(c.rng);
      return Question(
        skillId: c.skillId,
        prompt: '(${a}) x (${b}) = ?',
        answer: '$r',
        difficulty: c.difficulty,
        choices: list.map((e) => e.toString()).toList(),
        steps: [
          'Multiply the numbers: ${a.abs()} x ${b.abs()} = ${(a * b).abs()}.',
          'Signs: same signs give +, different signs give -.',
          'Answer: $r.',
        ],
        hint: 'Two negatives multiply to a positive.',
      );
    }
    final product = a * b;
    return Question(
      skillId: c.skillId,
      prompt: '(${product}) / (${b}) = ?',
      answer: '$a',
      difficulty: c.difficulty,
      steps: [
        'Divide the numbers: ${product.abs()} / ${b.abs()} = ${a.abs()}.',
        'Signs: same signs give +, different signs give -.',
        'Answer: $a.',
      ],
      hint: 'The sign rule for division is the same as for multiplication.',
    );
  });

  // ----------------------------------------------------------------- algebra

  register('patterns', (c) {
    final start = c.int_(1, c.band(9, 30));
    final step = c.int_(2, c.band(6, 15));
    final seq = List.generate(5, (i) => start + i * step);
    return Question(
      skillId: c.skillId,
      prompt: 'What is the next term?\n\n${seq.take(4).join(', ')}, __',
      answer: '${seq[4]}',
      difficulty: c.difficulty,
      choices: c.choicesAround(seq[4], distractors: [seq[4] + step, seq[4] - step]),
      steps: [
        'Find the difference: ${seq[1]} - ${seq[0]} = $step.',
        'Add $step to the last term: ${seq[3]} + $step = ${seq[4]}.',
      ],
      hint: 'Look at the gap between each pair of terms.',
    );
  });

  register('like_terms', (c) {
    final a = c.int_(2, c.band(6, 12));
    final b = c.int_(1, c.band(5, 10));
    final d = c.int_(1, a - 1);
    final e = c.int_(1, c.band(5, 10));
    return Question(
      skillId: c.skillId,
      prompt: 'Simplify:  ${a}x + ${b}y - ${d}x + ${e}y',
      answer: '${a - d}x+${b + e}y',
      difficulty: c.difficulty,
      steps: [
        'Group the x terms: ${a}x - ${d}x = ${a - d}x.',
        'Group the y terms: ${b}y + ${e}y = ${b + e}y.',
        'Answer: ${a - d}x + ${b + e}y.',
      ],
      hint: 'You can only combine terms with the SAME letter.',
    );
  });

  register('substitute', (c) {
    final x = c.int_(2, c.band(5, 9));
    final a = c.int_(2, c.band(4, 9));
    final b = c.int_(1, c.band(5, 12));
    final cc = c.int_(1, c.band(5, 15));
    final ans = a * x * x - b * x + cc;
    return Question(
      skillId: c.skillId,
      prompt: 'If x = $x, find the value of  ${a}x^2 - ${b}x + $cc',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [a * x * 2 - b * x + cc, ans + b]),
      steps: [
        'x^2 = $x x $x = ${x * x}.',
        '${a}x^2 = $a x ${x * x} = ${a * x * x}.',
        '${b}x = $b x $x = ${b * x}.',
        '${a * x * x} - ${b * x} + $cc = $ans.',
      ],
      hint: 'Square x BEFORE multiplying by $a.',
    );
  });

  register('linear_equation', (c) {
    final multiStep = c.skillId.contains('multistep');
    final x = c.int_(1, c.band(9, 20));
    if (!multiStep) {
      final b = c.int_(1, c.band(9, 30));
      final add = c.coin();
      final rhs = add ? x + b : x - b;
      return Question(
        skillId: c.skillId,
        prompt: 'Solve for x:   x ${add ? '+' : '-'} $b = $rhs',
        answer: '$x',
        difficulty: c.difficulty,
        choices: c.choicesAround(x, distractors: [rhs, add ? rhs + b : rhs - b]),
        steps: [
          'Do the opposite to both sides: ${add ? 'subtract' : 'add'} $b.',
          'x = $rhs ${add ? '-' : '+'} $b = $x.',
        ],
        hint: 'Whatever is done to x, undo it on both sides.',
      );
    }
    final a = c.int_(2, c.band(5, 9));
    final b = c.int_(1, a - 1);
    final p = c.int_(1, c.band(9, 20));
    // a*x + p = b*x + q  ->  (a-b)x = q-p
    final q = (a - b) * x + p;
    return Question(
      skillId: c.skillId,
      prompt: 'Solve for x:   ${a}x + $p = ${b}x + $q',
      answer: '$x',
      difficulty: c.difficulty,
      choices: c.choicesAround(x, distractors: [x + 1, x - 1, q - p]),
      steps: [
        'Move the x terms to one side: ${a}x - ${b}x = ${a - b}x.',
        'Move the numbers to the other side: $q - $p = ${q - p}.',
        '${a - b}x = ${q - p}, so x = ${q - p} / ${a - b} = $x.',
      ],
      hint: 'Get all the x terms on one side first.',
    );
  });

  register('factorise', (c) {
    final r1 = c.int_(1, c.band(6, 12));
    final r2 = c.int_(1, c.band(6, 12));
    final b = r1 + r2;
    final cc = r1 * r2;
    return Question(
      skillId: c.skillId,
      prompt: 'Factorise:  x^2 + ${b}x + $cc\n\n'
          'Write as (x+p)(x+q) with p <= q, answer format:  p,q',
      answer: '${r1 <= r2 ? r1 : r2},${r1 <= r2 ? r2 : r1}',
      difficulty: c.difficulty,
      steps: [
        'Find two numbers that MULTIPLY to $cc and ADD to $b.',
        '$r1 x $r2 = $cc and $r1 + $r2 = $b.',
        'So x^2 + ${b}x + $cc = (x + ${r1 <= r2 ? r1 : r2})(x + ${r1 <= r2 ? r2 : r1}).',
      ],
      hint: 'Two numbers: multiply to the last term, add to the middle term.',
    );
  });

  register('quadratic_factor', (c) {
    final r1 = c.int_(1, c.band(6, 10));
    final r2 = c.int_(1, c.band(6, 10));
    final b = r1 + r2;
    final cc = r1 * r2;
    final lo = r1 <= r2 ? r1 : r2;
    final hi = r1 <= r2 ? r2 : r1;
    return Question(
      skillId: c.skillId,
      prompt: 'Solve by factorisation:  x^2 - ${b}x + $cc = 0\n\n'
          'Give both roots smallest first, format:  a,b',
      answer: '$lo,$hi',
      difficulty: c.difficulty,
      steps: [
        'Find two numbers that multiply to $cc and add to $b.',
        'They are $r1 and $r2.',
        '(x - $lo)(x - $hi) = 0.',
        'So x = $lo or x = $hi.',
      ],
      hint: 'Factorise first, then set each bracket to zero.',
    );
  });

  _registerLaterAlgebra();
}

/// Variables, identities and simultaneous equations.
///
/// Split out from the block above only for readability - these are registered
/// by the same call.
void _registerLaterAlgebra() {
  register('algebra_expression', (c) {
    final k = c.int_(2, c.band(4, 9));
    // n must differ from k, or the distractor "${n}x+$k" collides with the
    // answer "${k}x+$n" and the same option appears twice.
    final n = c.intExcept(1, c.band(6, 15), {k});
    final more = c.coin();
    final answer = more ? '${k}x+$n' : '$k(x+$n)';
    return Question(
      skillId: c.skillId,
      prompt: more
          ? 'Which expression means: $n more than $k times a number x?'
          : 'Which expression means: add $n to a number x, then multiply the '
              'result by $k?',
      answer: answer,
      difficulty: c.difficulty,
      choices: ({
        '${k}x+$n',
        '$k(x+$n)',
        '${n}x+$k',
        'x+$k+$n',
      }.toList()..shuffle(c.rng)),
      steps: more
          ? [
              '"$k times a number" is ${k}x.',
              '"$n more" means add $n.',
              'So it is ${k}x + $n.',
            ]
          : [
              'Do the adding first, so it goes in brackets: (x + $n).',
              'Then multiply the whole thing by $k: $k(x + $n).',
            ],
      hint: more
          ? 'Multiply first, then add.'
          : 'The brackets show what happens first.',
    );
  });

  register('identities', (c) {
    final a = c.int_(1, c.band(3, 7));
    final b = c.int_(1, c.band(5, 12));
    final minus = c.coin();
    // Asking only for the middle coefficient keeps the answer a single clean
    // number, so the student is tested on the identity rather than on typing
    // a whole polynomial exactly the way the app expects.
    final middle = (minus ? -1 : 1) * 2 * a * b;
    return Question(
      skillId: c.skillId,
      prompt: 'Expand (${a}x ${minus ? '-' : '+'} $b)^2.\n\n'
          'What is the coefficient of x?',
      answer: '$middle',
      difficulty: c.difficulty,
      steps: [
        '(p ${minus ? '-' : '+'} q)^2 = p^2 ${minus ? '-' : '+'} 2pq + q^2.',
        'Here p = ${a}x and q = $b.',
        '2pq = 2 x $a x $b = ${2 * a * b}, so the x term is ${middle}x.',
      ],
      hint: 'The middle term is always 2 times the two parts multiplied.',
    );
  });

  register('simultaneous', (c) {
    final x = c.int_(1, c.band(5, 9));
    final y = c.int_(1, c.band(5, 9));
    late int a1, b1, a2, b2;
    var guard = 0;
    do {
      a1 = c.int_(1, 5);
      b1 = c.int_(1, 5);
      a2 = c.int_(1, 5);
      b2 = c.int_(1, 5);
      guard++;
    } while (guard < 100 && a1 * b2 - a2 * b1 == 0);
    final c1 = a1 * x + b1 * y;
    final c2 = a2 * x + b2 * y;
    return Question(
      skillId: c.skillId,
      prompt: 'Solve these equations together:\n\n'
          '${a1}x + ${b1}y = $c1\n'
          '${a2}x + ${b2}y = $c2\n\n'
          'Give your answer as  x,y',
      answer: '$x,$y',
      difficulty: c.difficulty,
      steps: [
        'Aim to get rid of one letter first.',
        'Multiply the equations so the number in front of y matches in both.',
        'Now subtract one from the other. The y terms cancel out.',
        'That leaves only x, and x = $x.',
        'Put x = $x back into the first equation to get y = $y.',
      ],
      hint: 'Make the number in front of one letter match, then subtract.',
    );
  });
}

String _signed(int v, {bool first = false}) {
  if (first) return v < 0 ? '($v)' : '$v';
  return v < 0 ? '- ${v.abs()}' : '+ $v';
}
