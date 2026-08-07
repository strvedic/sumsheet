import '../fraction.dart';
import '../generator.dart';
import '../question.dart';

/// Fractions and decimals.
///
/// All arithmetic here goes through [Fraction] or scaled integers. Nothing
/// touches floating point, so 1/3 + 1/6 is exactly 1/2 and 0.1 + 0.2 is
/// exactly 0.3 - a student is never marked wrong by a rounding artefact.
void registerFractions() {
  // ------------------------------------------------------------- fractions

  register('fraction_concept', (c) {
    final den = c.pick([2, 3, 4, 5, 6, 8]);
    final num = c.int_(1, den - 1);
    final whole = den * c.int_(2, c.band(3, 8));
    return Question(
      skillId: c.skillId,
      prompt: 'What is $num/$den of $whole?',
      answer: '${whole ~/ den * num}',
      difficulty: c.difficulty,
      choices: c.choicesAround(whole ~/ den * num,
          distractors: [whole ~/ den, whole - num, whole * num]),
      steps: [
        'Split $whole into $den equal parts: $whole / $den = ${whole ~/ den}.',
        'Take $num of those parts: ${whole ~/ den} x $num = ${whole ~/ den * num}.',
      ],
      hint: 'The bottom number tells you how many parts to split into.',
    );
  });

  register('fraction_equivalent', (c) {
    final den = c.pick([2, 3, 4, 5, 6, 7, 8]);
    final num = c.int_(1, den - 1);
    final k = c.int_(2, c.band(4, 9));
    return Question(
      skillId: c.skillId,
      prompt: 'Fill in the missing number:   $num/$den = ?/${den * k}',
      answer: '${num * k}',
      difficulty: c.difficulty,
      choices: c.choicesAround(num * k, distractors: [num + k, num * k + 1, den * k]),
      steps: [
        'The bottom went from $den to ${den * k}, so it was multiplied by $k.',
        'Do the same on top: $num x $k = ${num * k}.',
      ],
      hint: 'Whatever you do to the bottom, do to the top.',
    );
  });

  register('fraction_simplify', (c) {
    final f = Fraction(c.int_(2, 12), c.int_(2, 12));
    final k = c.int_(2, c.band(4, 9));
    final n = f.num * k;
    final d = f.den * k;
    final simple = Fraction(n, d);
    return Question(
      skillId: c.skillId,
      prompt: 'Simplify $n/$d to its lowest terms.',
      answer: simple.toString(),
      difficulty: c.difficulty,
      steps: [
        'Find the HCF of $n and $d: ${Fraction.gcd(n, d)}.',
        'Divide top and bottom by ${Fraction.gcd(n, d)}.',
        '$n/$d = ${simple.toString()}.',
      ],
      hint: 'Divide top and bottom by their highest common factor.',
    );
  });

  register('fraction_compare', (c) {
    final like = c.skillId.contains('compare-like');
    late Fraction a, b;
    if (like) {
      final den = c.pick([5, 6, 7, 8, 9, 10]);
      final n1 = c.int_(1, den - 1);
      final n2 = c.intExcept(1, den - 1, {n1});
      a = Fraction(n1, den);
      b = Fraction(n2, den);
    } else {
      do {
        a = Fraction(c.int_(1, 9), c.int_(2, 12));
        b = Fraction(c.int_(1, 9), c.int_(2, 12));
      } while (a == b);
    }
    final bigger = a > b ? a : b;
    return Question(
      skillId: c.skillId,
      prompt: 'Which is greater:  ${a.toString()}  or  ${b.toString()} ?',
      answer: bigger.toString(),
      difficulty: c.difficulty,
      choices: [a.toString(), b.toString()],
      steps: like
          ? [
              'Same bottom number, so just compare the tops.',
              '${bigger.toString()} is greater.',
            ]
          : [
              'Make the bottoms the same. LCM of ${a.den} and ${b.den} is '
                  '${Fraction.lcm(a.den, b.den)}.',
              '${a.toString()} = ${a.num * (Fraction.lcm(a.den, b.den) ~/ a.den)}/'
                  '${Fraction.lcm(a.den, b.den)}, '
                  '${b.toString()} = ${b.num * (Fraction.lcm(a.den, b.den) ~/ b.den)}/'
                  '${Fraction.lcm(a.den, b.den)}.',
              '${bigger.toString()} is greater.',
            ],
      hint: like ? 'Same bottom - just look at the top.' : 'Make the bottoms match first.',
    );
  });

  register('fraction_addsub', (c) {
    final unlike = c.skillId.contains('unlike');
    late Fraction a, b;
    if (unlike) {
      final d1 = c.pick([2, 3, 4, 5, 6]);
      final d2 = c.intExcept(2, 9, {d1});
      a = Fraction(c.int_(1, d1 - 1), d1);
      b = Fraction(c.int_(1, d2 - 1), d2);
    } else {
      final den = c.pick([5, 6, 7, 8, 9, 10, 12]);
      a = Fraction(c.int_(1, den - 2), den);
      b = Fraction(c.int_(1, den - a.num * den ~/ den - 1).clamp(1, den - 1), den);
    }
    final add = c.coin() || a < b;
    final result = add ? a + b : a - b;
    final lcmD = Fraction.lcm(a.den, b.den);
    return Question(
      skillId: c.skillId,
      prompt: '${a.toString()} ${add ? '+' : '-'} ${b.toString()} = ? '
          '(give the answer in lowest terms)',
      answer: result.toString(),
      difficulty: c.difficulty,
      steps: [
        if (unlike) ...[
          'The bottoms are different. LCM of ${a.den} and ${b.den} is $lcmD.',
          'Rewrite: ${a.num * (lcmD ~/ a.den)}/$lcmD ${add ? '+' : '-'} '
              '${b.num * (lcmD ~/ b.den)}/$lcmD.',
        ] else
          'The bottoms are the same, so just ${add ? 'add' : 'subtract'} the tops.',
        '= ${add ? a.num * (lcmD ~/ a.den) + b.num * (lcmD ~/ b.den) : a.num * (lcmD ~/ a.den) - b.num * (lcmD ~/ b.den)}/$lcmD',
        'In lowest terms: ${result.toString()}.',
      ],
      hint: unlike
          ? 'You cannot add until the bottom numbers match.'
          : 'Add the tops only - the bottom stays the same.',
    );
  });

  register('fraction_mixed', (c) {
    final den = c.pick([3, 4, 5, 6, 7, 8]);
    final whole = c.int_(1, c.band(3, 9));
    final rem = c.int_(1, den - 1);
    final improper = whole * den + rem;
    if (c.coin()) {
      return Question(
        skillId: c.skillId,
        prompt: 'Convert $improper/$den to a mixed number '
            '(write like  2 1/3 ).',
        answer: '$whole $rem/$den',
        difficulty: c.difficulty,
        steps: [
          'How many whole ${den}s fit into $improper? $improper / $den = $whole remainder $rem.',
          'So $improper/$den = $whole $rem/$den.',
        ],
        hint: 'Divide the top by the bottom.',
      );
    }
    return Question(
      skillId: c.skillId,
      prompt: 'Convert the mixed number  $whole $rem/$den  to an improper fraction.',
      answer: '$improper/$den',
      difficulty: c.difficulty,
      steps: [
        'Multiply the whole number by the bottom: $whole x $den = ${whole * den}.',
        'Add the top: ${whole * den} + $rem = $improper.',
        'Keep the same bottom: $improper/$den.',
      ],
      hint: 'Whole x bottom, then add the top.',
    );
  });

  register('fraction_multiply', (c) {
    final a = Fraction(c.int_(1, c.band(4, 9)), c.int_(2, c.band(6, 12)));
    final b = Fraction(c.int_(1, c.band(4, 9)), c.int_(2, c.band(6, 12)));
    final r = a * b;
    return Question(
      skillId: c.skillId,
      prompt: '${a.toString()} x ${b.toString()} = ? (lowest terms)',
      answer: r.toString(),
      difficulty: c.difficulty,
      steps: [
        'Multiply straight across: tops together, bottoms together.',
        '${a.num} x ${b.num} = ${a.num * b.num}, and ${a.den} x ${b.den} = ${a.den * b.den}.',
        '${a.num * b.num}/${a.den * b.den} simplifies to ${r.toString()}.',
      ],
      hint: 'No common denominator needed for multiplying.',
    );
  });

  register('fraction_divide', (c) {
    final a = Fraction(c.int_(1, c.band(4, 9)), c.int_(2, c.band(6, 12)));
    final b = Fraction(c.int_(1, c.band(4, 9)), c.int_(2, c.band(6, 12)));
    final r = a / b;
    return Question(
      skillId: c.skillId,
      prompt: '${a.toString()} / ${b.toString()} = ? (lowest terms)',
      answer: r.toString(),
      difficulty: c.difficulty,
      steps: [
        'Dividing by a fraction = multiplying by its flip.',
        'Flip ${b.toString()} to get ${b.den}/${b.num}.',
        '${a.toString()} x ${b.den}/${b.num} = ${r.toString()}.',
      ],
      hint: 'Keep, change, flip.',
    );
  });

  // -------------------------------------------------------------- decimals

  register('decimal_place', (c) {
    const names = ['tenths', 'hundredths', 'thousandths'];
    final places = c.band(2, 3);
    final whole = c.int_(1, 99);
    final frac = c.int_(_pow10(places - 1), _pow10(places) - 1);
    final text = '$whole.${frac.toString().padLeft(places, '0')}';
    final pos = c.int_(0, places - 1);
    final digit = int.parse(text.split('.')[1][pos]);
    return Question(
      skillId: c.skillId,
      prompt: 'In $text, which digit is in the ${names[pos]} place?',
      answer: '$digit',
      difficulty: c.difficulty,
      choices: c.choicesAround(digit,
          distractors: text.split('.')[1].split('').map(int.parse).toList()),
      steps: [
        'After the decimal point the places are: tenths, hundredths, thousandths.',
        'The ${names[pos]} digit of $text is $digit.',
      ],
      hint: 'Count places to the RIGHT of the point.',
    );
  });

  register('decimal_convert', (c) {
    final den = c.pick([2, 4, 5, 8, 10, 20, 25, 50]);
    final num = c.int_(1, den - 1);
    final f = Fraction(num, den);
    final scaled = 1000 * f.num ~/ f.den;
    final text = _trimZeros((scaled / 1000).toStringAsFixed(3));
    return Question(
      skillId: c.skillId,
      prompt: 'Write ${f.toString()} as a decimal.',
      answer: text,
      difficulty: c.difficulty,
      steps: [
        'Make the bottom a power of ten, or just divide top by bottom.',
        '${f.num} / ${f.den} = $text.',
      ],
      hint: 'Divide the top by the bottom.',
    );
  });

  register('decimal_compare', (c) {
    final places = c.band(1, 3);
    final vals = <int>{};
    while (vals.length < 3) {
      vals.add(c.int_(1, _pow10(places + 1) - 1));
    }
    final sorted = vals.toList()..sort();
    // Never present them already sorted, or the student just copies the line
    // back without comparing anything.
    var shown = vals.toList()..shuffle(c.rng);
    if (shown.join(',') == sorted.join(',')) shown = shown.reversed.toList();
    final texts = shown.map((v) => _scaledToText(v, places)).toList();

    return Question(
      skillId: c.skillId,
      prompt: 'Arrange in ascending order:\n\n${texts.join(', ')}',
      answer: sorted.map((v) => _scaledToText(v, places)).join(','),
      difficulty: c.difficulty,
      steps: [
        'Line up the decimal points and compare place by place.',
        'Answer: ${sorted.map((v) => _scaledToText(v, places)).join(', ')}.',
      ],
      hint: 'More digits does not mean bigger - 0.7 is more than 0.07.',
    );
  });

  register('decimal_addsub', (c) {
    final places = c.band(1, 2);
    final scale = _pow10(places);
    final a = c.int_(scale, scale * c.band(20, 100));
    final b = c.int_(scale ~/ 2 + 1, a - 1);
    final add = c.coin();
    final r = add ? a + b : a - b;
    return Question(
      skillId: c.skillId,
      prompt: '${_scaledToText(a, places)} ${add ? '+' : '-'} '
          '${_scaledToText(b, places)} = ?',
      answer: _scaledToText(r, places),
      difficulty: c.difficulty,
      steps: [
        'Line up the decimal points, one under the other.',
        'Fill empty places with zeros, then ${add ? 'add' : 'subtract'} as usual.',
        'Answer: ${_scaledToText(r, places)}.',
      ],
      hint: 'Line up the points, not the last digits.',
    );
  });

  register('decimal_multiply', (c) {
    final pa = c.band(1, 2);
    final pb = c.band(1, 2);
    final a = c.int_(11, _pow10(pa + 1) * 5);
    final b = c.int_(11, _pow10(pb + 1) * 3);
    final r = a * b;
    return Question(
      skillId: c.skillId,
      prompt: '${_scaledToText(a, pa)} x ${_scaledToText(b, pb)} = ?',
      answer: _scaledToText(r, pa + pb),
      difficulty: c.difficulty,
      steps: [
        'Ignore the points first: $a x $b = $r.',
        'Count decimal places: $pa + $pb = ${pa + pb}.',
        'Put the point back ${pa + pb} places from the right: '
            '${_scaledToText(r, pa + pb)}.',
      ],
      hint: 'Multiply as whole numbers, then count the decimal places.',
    );
  });

  register('decimal_divide', (c) {
    final places = c.band(1, 2);
    final divisor = c.int_(2, c.band(6, 12));
    final q = c.int_(_pow10(places), _pow10(places) * c.band(10, 40));
    final dividend = q * divisor;
    return Question(
      skillId: c.skillId,
      prompt: '${_scaledToText(dividend, places)} / $divisor = ?',
      answer: _scaledToText(q, places),
      difficulty: c.difficulty,
      steps: [
        'Divide as if there were no decimal point: $dividend / $divisor = $q.',
        'The dividend had $places decimal place${places == 1 ? '' : 's'}, '
            'so the answer does too.',
        'Answer: ${_scaledToText(q, places)}.',
      ],
      hint: 'Dividing by a whole number keeps the decimal places the same.',
    );
  });

  register('decimal_round', (c) {
    final to = c.band(1, 2);
    final raw = c.int_(1000, 99999);
    final text = _scaledToText(raw, 3);
    final scale = _pow10(3 - to);
    final rounded = (raw / scale).round() * scale;
    return Question(
      skillId: c.skillId,
      prompt: 'Round $text to $to decimal place${to == 1 ? '' : 's'}.',
      answer: _trimZeros(_scaledToText(rounded, 3)),
      difficulty: c.difficulty,
      steps: [
        'Look at the digit just after the ${to == 1 ? 'first' : 'second'} decimal place.',
        'If it is 5 or more round up, otherwise leave it.',
        'Answer: ${_trimZeros(_scaledToText(rounded, 3))}.',
      ],
    );
  });
}

int _pow10(int n) {
  var v = 1;
  for (var i = 0; i < n; i++) {
    v *= 10;
  }
  return v;
}

/// Renders an integer scaled by 10^places as a decimal string, exactly.
String _scaledToText(int scaled, int places) {
  if (places == 0) return '$scaled';
  final neg = scaled < 0;
  final v = scaled.abs();
  final p = _pow10(places);
  final whole = v ~/ p;
  final frac = (v % p).toString().padLeft(places, '0');
  return '${neg ? '-' : ''}$whole.$frac';
}

String _trimZeros(String s) {
  if (!s.contains('.')) return s;
  var t = s.replaceFirst(RegExp(r'0+$'), '');
  if (t.endsWith('.')) t = t.substring(0, t.length - 1);
  return t;
}
