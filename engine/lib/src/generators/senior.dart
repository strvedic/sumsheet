import '../fraction.dart';
import '../gen_context.dart';
import '../generator.dart';
import '../question.dart';

/// Class 8 to 10 topics: commercial maths, surds, polynomials, quadratics,
/// progressions, inequalities and grouped data.
///
/// This band is board-exam material, so the numbers are chosen to come out
/// whole wherever the real maths allows it. A student practising compound
/// interest should be practising compound interest, not decimal arithmetic.
void registerSenior() {
  // ------------------------------------------------------- commercial maths

  register('discount_tax', (c) {
    late int mrp, disc, gst, finalPrice;
    var guard = 0;
    do {
      mrp = c.int_(2, c.band(8, 30)) * 100;
      disc = c.pick([10, 20, 25, 40, 50]);
      gst = c.pick([5, 12, 18]);
      final afterDiscount = mrp * (100 - disc);
      finalPrice = afterDiscount * (100 + gst) ~/ 10000;
      guard++;
    } while (guard < 200 &&
        (mrp * (100 - disc) * (100 + gst)) % 10000 != 0);

    final afterDisc = mrp * (100 - disc) ~/ 100;
    return Question(
      skillId: c.skillId,
      prompt: 'A shirt is marked Rs $mrp. The shop gives $disc% discount, '
          'then adds $gst% GST.\n\nWhat is the final price?',
      answer: '$finalPrice',
      difficulty: c.difficulty,
      choices: c.choicesAround(finalPrice, distractors: [afterDisc, mrp]),
      steps: [
        'Take the discount off first.',
        '$disc% of $mrp = ${mrp * disc ~/ 100}, so the price becomes '
            'Rs $afterDisc.',
        'Now add GST on that reduced price, not on the marked price.',
        '$gst% of $afterDisc = ${afterDisc * gst ~/ 100}.',
        'Final price = $afterDisc + ${afterDisc * gst ~/ 100} = Rs $finalPrice.',
      ],
      hint: 'GST goes on the discounted price, not the marked price.',
    );
  });

  register('compound_interest', (c) {
    late int p, r, t, amount;
    var guard = 0;
    do {
      p = c.int_(1, c.band(5, 20)) * 10000;
      r = c.pick([5, 10, 20, 25]);
      t = c.int_(2, c.band(2, 3));
      var num = p;
      for (var i = 0; i < t; i++) {
        num = num * (100 + r);
      }
      var den = 1;
      for (var i = 0; i < t; i++) {
        den *= 100;
      }
      amount = num ~/ den;
      guard++;
      if (num % den == 0) break;
    } while (guard < 200);

    final ci = amount - p;
    return Question(
      skillId: c.skillId,
      prompt: 'Find the compound interest on Rs $p at $r% per year for '
          '$t years.',
      answer: '$ci',
      difficulty: c.difficulty,
      choices: c.choicesAround(ci,
          distractors: [amount, p * r * t ~/ 100, p + ci]),
      steps: [
        'With compound interest the interest itself earns interest.',
        'Amount = P x (1 + R/100) to the power T.',
        '= $p x (1 + $r/100)^$t = Rs $amount.',
        'Interest = Amount - Principal = $amount - $p = Rs $ci.',
      ],
      hint: 'Work out the total amount first, then take away what you started '
          'with.',
    );
  });

  register('time_work_speed', (c) {
    final kind = c.pick(['speed', 'distance', 'time']);
    final speed = c.int_(2, c.band(8, 20)) * 10;
    final time = c.int_(2, c.band(4, 9));
    final distance = speed * time;
    return switch (kind) {
      'speed' => Question(
          skillId: c.skillId,
          prompt: 'A bus covers $distance km in $time hours.\n\n'
              'What is its speed in km per hour?',
          answer: '$speed',
          difficulty: c.difficulty,
          choices: c.choicesAround(speed, distractors: [distance, time * 10]),
          steps: [
            'Speed = distance / time.',
            '$distance / $time = $speed km/h.',
          ],
          hint: 'Divide the distance by the time.',
        ),
      'distance' => Question(
          skillId: c.skillId,
          prompt: 'A bus travels at $speed km/h for $time hours.\n\n'
              'How far does it go?',
          answer: '$distance',
          difficulty: c.difficulty,
          choices: c.choicesAround(distance, distractors: [speed + time, speed]),
          steps: [
            'Distance = speed x time.',
            '$speed x $time = $distance km.',
          ],
        ),
      _ => Question(
          skillId: c.skillId,
          prompt: 'A bus travels $distance km at $speed km/h.\n\n'
              'How many hours does it take?',
          answer: '$time',
          difficulty: c.difficulty,
          choices: c.choicesAround(time, distractors: [distance, speed]),
          steps: [
            'Time = distance / speed.',
            '$distance / $speed = $time hours.',
          ],
        ),
    };
  });

  // ------------------------------------------------------ numbers and surds

  register('rational_ops', (c) {
    final a = Fraction(
      c.int_(1, c.band(5, 9)) * (c.coin() ? 1 : -1),
      c.int_(2, c.band(6, 12)),
    );
    final b = Fraction(
      c.int_(1, c.band(5, 9)) * (c.coin() ? 1 : -1),
      c.int_(2, c.band(6, 12)),
    );
    final add = c.coin();
    final r = add ? a + b : a - b;
    final lcm = Fraction.lcm(a.den, b.den);
    return Question(
      skillId: c.skillId,
      prompt: '(${a.toString()}) ${add ? '+' : '-'} (${b.toString()}) = ?  '
          '(lowest terms)',
      answer: r.toString(),
      difficulty: c.difficulty,
      steps: [
        'Same as ordinary fractions - the only extra care is the signs.',
        'LCM of ${a.den} and ${b.den} is $lcm.',
        '${a.num * (lcm ~/ a.den)}/$lcm ${add ? '+' : '-'} '
            '${b.num * (lcm ~/ b.den)}/$lcm',
        '= ${r.toString()}.',
      ],
      hint: 'Watch the signs, then treat it like any fraction sum.',
    );
  });

  register('surds', (c) {
    final outside = c.int_(2, c.band(4, 9));
    final inside = c.pick([2, 3, 5, 6, 7, 10, 11, 13]);
    final under = outside * outside * inside;
    return Question(
      skillId: c.skillId,
      prompt: 'Simplify root($under).\n\n'
          'It can be written as k x root($inside). What is k?',
      answer: '$outside',
      difficulty: c.difficulty,
      choices: c.choicesAround(outside,
          distractors: [outside * outside, inside, under ~/ 2]),
      steps: [
        'Look for a square number hiding inside $under.',
        '$under = ${outside * outside} x $inside.',
        'root(${outside * outside}) = $outside, so root($under) = '
            '$outside root($inside).',
      ],
      hint: 'Split it into a perfect square times something else.',
    );
  });

  // ----------------------------------------------------------- geometry

  register('constructions', (c) {
    // Easiest first. Which instrument to reach for is recall; what a compass
    // width has to be, or what bisecting twice leaves you with, is the part
    // that only makes sense once the construction has been done by hand.
    //
    // Three facts also meant this skill could only ever make three questions,
    // so a sheet asking for twenty came back with three.
    const facts = {
      'Which two instruments do you need to bisect an angle?':
          'compass and ruler',
      'Which instrument is never used in a ruler-and-compass construction?':
          'protractor',
      'To copy an angle exactly, which instrument keeps the width fixed?':
          'compass',
      'A perpendicular bisector cuts a line segment into how many equal '
              'parts?':
          '2',
      'Which angle can you construct with a compass alone, using one arc the '
              'same width as the radius?':
          '60 degrees',
      'To construct a perpendicular bisector, where must the compass width be '
              'set?':
          'more than half the line',
      'Bisecting a right angle gives which angle?': '45 degrees',
      'Bisecting a 60 degree angle gives which angle?': '30 degrees',
    };
    final options = facts.values.toSet().toList();
    final q = c.pickByLevel(facts.keys.toList());
    final a = facts[q]!;
    return Question(
      skillId: c.skillId,
      prompt: q,
      answer: a,
      difficulty: c.difficulty,
      choices: _withAnswer(options, a, c),
      steps: ['$a.'],
      hint: 'Constructions use compass and ruler, never a protractor.',
    );
  });

  // ------------------------------------------------------------- algebra

  register('equation_word', (c) {
    final start = c.int_(2, c.band(15, 60));
    final total = start + (start + 1) + (start + 2);
    return Question(
      skillId: c.skillId,
      prompt: 'Three consecutive numbers add up to $total.\n\n'
          'What is the smallest of them?',
      answer: '$start',
      difficulty: c.difficulty,
      choices: c.choicesAround(start,
          distractors: [start + 1, start + 2, total ~/ 3]),
      steps: [
        'Call the smallest one x. The next two are x + 1 and x + 2.',
        'x + (x + 1) + (x + 2) = $total',
        '3x + 3 = $total, so 3x = ${total - 3}.',
        'x = $start.',
      ],
      hint: 'Let the smallest be x and write the other two in terms of it.',
    );
  });

  register('polynomials', (c) {
    final deg = c.int_(2, c.band(3, 5));
    final lead = c.int_(2, 9);
    final mid = c.int_(1, 9);
    final constant = c.int_(1, 9);
    if (c.coin()) {
      return Question(
        skillId: c.skillId,
        prompt: 'What is the degree of  ${term(lead, 'x')}^$deg + ${term(mid, 'x')} + $constant ?',
        answer: '$deg',
        difficulty: c.difficulty,
        choices: c.choicesAround(deg, distractors: [lead, deg + 1, 1]),
        steps: [
          'The degree is the highest power of x.',
          'Here the highest power is $deg.',
        ],
        hint: 'Look for the biggest power, not the biggest number.',
      );
    }
    final a2 = c.int_(1, 9);
    final b2 = c.int_(1, 9);
    return Question(
      skillId: c.skillId,
      prompt: 'Add:  (${term(lead, 'x')}^2 + ${term(mid, 'x')}) + (${term(a2, 'x')}^2 + ${term(b2, 'x')})\n\n'
          'What is the coefficient of x^2 in the answer?',
      answer: '${lead + a2}',
      difficulty: c.difficulty,
      choices: c.choicesAround(lead + a2, distractors: [mid + b2, lead * a2]),
      steps: [
        'Only add terms with the same power.',
        'x^2 terms: $lead + $a2 = ${lead + a2}.',
      ],
      hint: 'x^2 adds with x^2 only.',
    );
  });

  register('linear_two_var', (c) {
    final a = c.int_(1, c.band(3, 6));
    final b = c.int_(1, c.band(3, 6));
    final x = c.int_(1, c.band(4, 9));
    final y = c.int_(1, c.band(4, 9));
    final rhs = a * x + b * y;
    return Question(
      skillId: c.skillId,
      prompt: 'In the equation  ${term(a, 'x')} + ${term(b, 'y')} = $rhs,\n\n'
          'if x = $x, what is y?',
      answer: '$y',
      difficulty: c.difficulty,
      choices: c.choicesAround(y, distractors: [rhs, x, y + 1]),
      steps: [
        'Put x = $x into the equation.',
        '$a x $x = ${a * x}, so ${a * x} + ${term(b, 'y')} = $rhs.',
        '${term(b, 'y')} = $rhs - ${a * x} = ${rhs - a * x}.',
        'y = ${rhs - a * x} / $b = $y.',
      ],
      hint: 'Substitute x first, then solve what is left.',
    );
  });

  register('quadratic_formula', (c) {
    // Chosen so the discriminant is a perfect square and the roots are whole.
    final r1 = c.int_(1, c.band(5, 9));
    final r2 = c.int_(1, c.band(5, 9));
    final b = -(r1 + r2);
    final cc = r1 * r2;
    final disc = b * b - 4 * cc;
    if (c.coin()) {
      return Question(
        skillId: c.skillId,
        prompt: 'For  x^2 ${b < 0 ? '-' : '+'} ${term(b.abs(), 'x')} + $cc = 0,\n\n'
            'find the discriminant.',
        answer: '$disc',
        difficulty: c.difficulty,
        choices: c.choicesAround(disc.abs(), distractors: [b * b, 4 * cc]),
        steps: [
          'Discriminant = b^2 - 4ac.',
          'Here a = 1, b = $b, c = $cc.',
          '${b * b} - ${4 * cc} = $disc.',
        ],
        hint: 'It is b squared minus 4ac.',
      );
    }
    final lo = r1 <= r2 ? r1 : r2;
    final hi = r1 <= r2 ? r2 : r1;
    return Question(
      skillId: c.skillId,
      prompt: 'Solve  x^2 ${b < 0 ? '-' : '+'} ${term(b.abs(), 'x')} + $cc = 0 '
          'using the formula.\n\nGive both roots, smallest first:  a,b',
      answer: '$lo,$hi',
      difficulty: c.difficulty,
      steps: [
        'a = 1, b = $b, c = $cc.',
        'Discriminant = $disc, and root($disc) = ${_isqrt(disc)}.',
        'x = (-b +/- root(disc)) / 2a = (${-b} +/- ${_isqrt(disc)}) / 2.',
        'So x = $lo or x = $hi.',
      ],
      hint: 'x = (-b plus or minus the square root of the discriminant), all '
          'over 2a.',
    );
  });

  register('inequalities', (c) {
    final a = c.int_(2, c.band(4, 8));
    final x = c.int_(1, c.band(6, 15));
    final b = c.int_(1, c.band(8, 25));
    final rhs = a * x + b;
    final less = c.coin();
    return Question(
      skillId: c.skillId,
      prompt: 'Solve:  ${term(a, 'x')} + $b ${less ? '<' : '>'} $rhs\n\n'
          'The answer is x ${less ? '<' : '>'} k. What is k?',
      answer: '$x',
      difficulty: c.difficulty,
      choices: c.choicesAround(x, distractors: [rhs, rhs - b, a * x]),
      steps: [
        'Solve it exactly like an equation.',
        'Take $b from both sides: ${term(a, 'x')} ${less ? '<' : '>'} ${rhs - b}.',
        'Divide both sides by $a: x ${less ? '<' : '>'} $x.',
        'Note: dividing by a NEGATIVE number would flip the sign. Here $a is '
            'positive, so it stays.',
      ],
      hint: 'Treat it like an equation, but watch the sign if you divide by a '
          'negative.',
    );
  });

  register('ap', (c) {
    final first = c.int_(1, c.band(8, 20));
    final diff = c.int_(2, c.band(5, 12));
    final n = c.int_(5, c.band(10, 25));
    final nth = first + (n - 1) * diff;
    if (c.difficulty >= 4 && c.coin()) {
      final sum = n * (2 * first + (n - 1) * diff) ~/ 2;
      return Question(
        skillId: c.skillId,
        prompt: 'An AP starts $first, ${first + diff}, ${first + 2 * diff}, ...'
            '\n\nFind the sum of the first $n terms.',
        answer: '$sum',
        difficulty: c.difficulty,
        choices: c.choicesAround(sum, distractors: [nth, first * n]),
        steps: [
          'First term a = $first, common difference d = $diff.',
          'Sum = n/2 x (2a + (n-1)d).',
          '= $n/2 x (${2 * first} + ${(n - 1) * diff}) = $sum.',
        ],
      );
    }
    return Question(
      skillId: c.skillId,
      prompt: 'An AP starts $first, ${first + diff}, ${first + 2 * diff}, ...'
          '\n\nFind the ${n}th term.',
      answer: '$nth',
      difficulty: c.difficulty,
      choices: c.choicesAround(nth,
          distractors: [first + n * diff, first * n, nth - diff]),
      steps: [
        'First term a = $first. Common difference d = ${first + diff} - '
            '$first = $diff.',
        'nth term = a + (n - 1)d.',
        '= $first + ${n - 1} x $diff = $nth.',
      ],
      hint: 'It is (n - 1) jumps from the first term, not n.',
    );
  });

  register('gp', (c) {
    final first = c.int_(1, c.band(3, 6));
    final ratio = c.int_(2, c.band(2, 4));
    final n = c.int_(4, c.band(5, 7));
    var nth = first;
    for (var i = 1; i < n; i++) {
      nth *= ratio;
    }
    return Question(
      skillId: c.skillId,
      prompt: 'A GP starts $first, ${first * ratio}, ${first * ratio * ratio}, '
          '...\n\nFind the ${n}th term.',
      answer: '$nth',
      difficulty: c.difficulty,
      choices: c.choicesAround(nth, distractors: [nth * ratio, first * n]),
      steps: [
        'Each term is the one before multiplied by the same number.',
        'Common ratio r = ${first * ratio} / $first = $ratio.',
        'nth term = a x r^(n-1) = $first x $ratio^${n - 1} = $nth.',
      ],
      hint: 'Multiply, do not add - that is what makes it a GP.',
    );
  });

  // ---------------------------------------------------------------- data

  register('grouped_data', (c) {
    final values = <int>[];
    for (var i = 0; i < 6; i++) {
      values.add(c.int_(5, c.band(30, 90)));
    }
    final sorted = [...values]..sort();
    return Question(
      skillId: c.skillId,
      prompt: 'Marks scored by six students:\n\n${values.join(', ')}\n\n'
          'What is the range?',
      answer: '${sorted.last - sorted.first}',
      difficulty: c.difficulty,
      choices: c.choicesAround(sorted.last - sorted.first,
          distractors: [sorted.last, sorted.first]),
      steps: [
        'Range = highest value - lowest value.',
        'Highest is ${sorted.last}, lowest is ${sorted.first}.',
        '${sorted.last} - ${sorted.first} = ${sorted.last - sorted.first}.',
      ],
      hint: 'Just the biggest take away the smallest.',
    );
  });
}

int _isqrt(int n) {
  var i = 0;
  while ((i + 1) * (i + 1) <= n) {
    i++;
  }
  return i;
}

List<String> _withAnswer(List<String> pool, String answer, GenContext c) {
  final others = pool.where((e) => e != answer).toList()..shuffle(c.rng);
  return [answer, ...others.take(3)]..shuffle(c.rng);
}
