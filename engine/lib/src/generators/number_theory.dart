import '../fraction.dart';
import '../gen_context.dart';
import '../generator.dart';
import '../question.dart';

/// Factors, multiples, primes, HCF/LCM, powers and roots.
void registerNumberTheory() {
  register('even_odd', (c) {
    final n = c.int_(2, c.band(50, 999));
    final even = n % 2 == 0;
    return Question(
      skillId: c.skillId,
      prompt: 'Is $n even or odd?',
      answer: even ? 'even' : 'odd',
      difficulty: c.difficulty,
      choices: const ['even', 'odd'],
      steps: [
        'Look only at the last digit: ${n % 10}.',
        'Last digits 0, 2, 4, 6, 8 are even. The rest are odd.',
        '$n is ${even ? 'even' : 'odd'}.',
      ],
      hint: 'You only need the last digit.',
    );
  });

  register('factors', (c) {
    // Any composite in range will do, so long as it has enough factors to be
    // worth listing and few enough that the answer still fits on one line.
    // Picking from a fixed list of ten numbers meant a worksheet of twenty
    // questions could only ever hold ten different ones.
    final n = _pickComposite(c, c.band(12, 40), c.band(30, 140),
        minFactors: 4, maxFactors: 12);
    final f = _factorsOf(n);
    return Question(
      skillId: c.skillId,
      prompt: 'List all the factors of $n (smallest first, separated by commas).',
      answer: f.join(','),
      difficulty: c.difficulty,
      steps: [
        'Check each number from 1 upwards: does it divide $n exactly?',
        'Factors come in pairs: ${_factorPairs(n)}.',
        'Factors of $n: ${f.join(', ')}.',
      ],
      hint: 'Work in pairs - if 2 divides it, so does $n / 2.',
    );
  });

  register('multiples', (c) {
    final n = c.int_(2, c.band(9, 15));
    final k = c.int_(4, 6);
    final list = List.generate(k, (i) => n * (i + 1));
    return Question(
      skillId: c.skillId,
      prompt: 'Write the first $k multiples of $n (separated by commas).',
      answer: list.join(','),
      difficulty: c.difficulty,
      steps: [
        'Multiples are $n x 1, $n x 2, $n x 3, and so on.',
        'Answer: ${list.join(', ')}.',
      ],
      hint: 'Multiples of a number never stop - factors do.',
    );
  });

  register('divisibility', (c) {
    final by = c.pick([2, 3, 4, 5, 6, 9, 10]);
    final n = c.int_(100, c.band(999, 9999));
    final yes = n % by == 0;
    const rules = {
      2: 'the last digit is even',
      3: 'the digit sum is divisible by 3',
      4: 'the last two digits form a number divisible by 4',
      5: 'the last digit is 0 or 5',
      6: 'it is divisible by both 2 and 3',
      9: 'the digit sum is divisible by 9',
      10: 'the last digit is 0',
    };
    final digitSum =
        n.toString().split('').map(int.parse).reduce((a, b) => a + b);
    return Question(
      skillId: c.skillId,
      prompt: 'Is $n divisible by $by?',
      answer: yes ? 'yes' : 'no',
      difficulty: c.difficulty,
      choices: const ['yes', 'no'],
      steps: [
        'Rule for $by: ${rules[by]}.',
        if (by == 3 || by == 9 || by == 6)
          'Digit sum of $n is $digitSum.',
        '$n / $by = ${(n / by).toStringAsFixed(2)}, so the answer is ${yes ? 'yes' : 'no'}.',
      ],
      hint: 'Use the rule, do not do the full division.',
    );
  });

  register('prime_composite', (c) {
    final n = c.difficulty <= 2
        ? c.int_(2, 30)
        : c.pick([37, 39, 41, 49, 51, 53, 57, 59, 61, 63, 67, 71, 73, 77, 79, 83, 87, 89, 91, 97]);
    final prime = _isPrime(n);
    return Question(
      skillId: c.skillId,
      prompt: 'Is $n a prime number or a composite number?',
      answer: prime ? 'prime' : 'composite',
      difficulty: c.difficulty,
      choices: const ['prime', 'composite'],
      steps: [
        'A prime has exactly two factors: 1 and itself.',
        prime
            ? 'Nothing between 2 and ${_isqrt(n)} divides $n, so it is prime.'
            : '$n = ${_smallestFactor(n)} x ${n ~/ _smallestFactor(n)}, so it is composite.',
      ],
      hint: 'You only need to test divisors up to the square root of $n.',
    );
  });

  register('prime_factorise', (c) {
    // Needs at least two prime factors or there is nothing to factorise, and
    // a cap so the product does not run off the edge of the page.
    final n = _pickForPrimeFactorisation(c, c.band(12, 60), c.band(50, 320));
    final f = _primeFactors(n);
    return Question(
      skillId: c.skillId,
      prompt: 'Write $n as a product of prime factors '
          '(smallest first, use x between them).',
      answer: f.join('x'),
      difficulty: c.difficulty,
      steps: [
        'Divide by the smallest prime that fits, then keep going.',
        '$n = ${f.join(' x ')}.',
      ],
      hint: 'Start with 2, then 3, then 5...',
    );
  });

  register('hcf', (c) {
    final a = c.int_(c.band(8, 20), c.band(40, 120));
    final b = c.int_(c.band(8, 20), c.band(40, 120));
    final h = Fraction.gcd(a, b);
    return Question(
      skillId: c.skillId,
      prompt: 'Find the HCF of $a and $b.',
      answer: '$h',
      difficulty: c.difficulty,
      choices: c.choicesAround(h, distractors: [Fraction.lcm(a, b), h * 2, 1]),
      steps: [
        'Break each one into primes.',
        '$a = ${_primeFactors(a).join(' x ')}',
        '$b = ${_primeFactors(b).join(' x ')}',
        'Now take only the primes that appear in BOTH lists.',
        'Multiply those together: HCF = $h.',
      ],
      hint: 'HCF is the biggest number that divides BOTH.',
    );
  });

  register('lcm', (c) {
    final a = c.int_(c.band(3, 8), c.band(12, 30));
    final b = c.int_(c.band(3, 8), c.band(12, 30));
    final l = Fraction.lcm(a, b);

    // Taught WITHOUT mentioning HCF. In the skill map, HCF is a sibling of
    // LCM, not a prerequisite - so "LCM x HCF = the product" explains one
    // unknown using another unknown. Both methods below rely only on skills
    // the student has definitely already done: listing multiples, and prime
    // factorisation.
    final small = a <= 12 && b <= 12;
    final steps = small
        ? [
            'Write out the multiples of each until they meet.',
            '$a: ${_multiplesUpTo(a, l).join(', ')}',
            '$b: ${_multiplesUpTo(b, l).join(', ')}',
            'The first number in BOTH lists is $l.',
          ]
        : [
            'Break each number into primes.',
            '$a = ${_primeFactors(a).join(' x ')}',
            '$b = ${_primeFactors(b).join(' x ')}',
            'Now take each prime as many times as it appears in EITHER one.',
            '${_lcmFactors(a, b).join(' x ')} = $l.',
          ];

    return Question(
      skillId: c.skillId,
      prompt: 'Find the LCM of $a and $b.',
      answer: '$l',
      difficulty: c.difficulty,
      choices: c.choicesAround(l, distractors: [a * b, a + b, l ~/ 2]),
      steps: steps,
      hint: 'The LCM is the smallest number that BOTH of them divide into.',
    );
  });

  register('squares', (c) {
    if (c.coin()) {
      final n = c.int_(2, c.band(12, 30));
      return Question(
        skillId: c.skillId,
        prompt: 'What is $n squared?',
        answer: '${n * n}',
        difficulty: c.difficulty,
        choices: c.choicesAround(n * n, distractors: [n * 2, n * n + n, n * n - n]),
        steps: ['$n squared means $n x $n.', '$n x $n = ${n * n}.'],
        hint: 'Squared means multiply by itself, not by 2.',
      );
    }
    final root = c.int_(2, c.band(12, 40));
    return Question(
      skillId: c.skillId,
      prompt: 'Find the square root of ${root * root}.',
      answer: '$root',
      difficulty: c.difficulty,
      choices: c.choicesAround(root, distractors: [root * 2, root + 1, root * root ~/ 2]),
      steps: [
        'Ask: what number times itself gives ${root * root}?',
        '$root x $root = ${root * root}, so the square root is $root.',
      ],
    );
  });

  register('cubes', (c) {
    final n = c.int_(2, c.band(6, 12));
    if (c.coin()) {
      return Question(
        skillId: c.skillId,
        prompt: 'What is $n cubed?',
        answer: '${n * n * n}',
        difficulty: c.difficulty,
        choices: c.choicesAround(n * n * n, distractors: [n * 3, n * n, n * n * n + n]),
        steps: ['$n cubed means $n x $n x $n.', '= ${n * n} x $n = ${n * n * n}.'],
      );
    }
    return Question(
      skillId: c.skillId,
      prompt: 'Find the cube root of ${n * n * n}.',
      answer: '$n',
      difficulty: c.difficulty,
      choices: c.choicesAround(n, distractors: [n * n, n + 1, n * 3]),
      steps: [
        'Ask: what number cubed gives ${n * n * n}?',
        '$n x $n x $n = ${n * n * n}, so the cube root is $n.',
      ],
    );
  });

  register('exponents', (c) {
    final base = c.int_(2, c.band(4, 9));
    final p1 = c.int_(2, 5);
    final p2 = c.int_(2, 5);
    final multiply = c.coin();
    final ansPow = multiply ? p1 + p2 : (p1 > p2 ? p1 - p2 : p2 - p1);
    final hi = multiply ? p1 : (p1 > p2 ? p1 : p2);
    final lo = multiply ? p2 : (p1 > p2 ? p2 : p1);
    return Question(
      skillId: c.skillId,
      // Asked as a fill-in-the-power, not "what is n". Written the old way, a
      // student simplifying 3^4 / 3^3 sees the value 3 and types 3 - but the
      // expected answer was the power, 1. Being marked wrong for doing the
      // maths correctly is the fastest way to lose them.
      prompt: multiply
          ? 'Fill in the missing power:\n\n'
              '$base^$p1 x $base^$p2 = $base^?'
          : 'Fill in the missing power:\n\n'
              '$base^$hi / $base^$lo = $base^?',
      answer: '$ansPow',
      difficulty: c.difficulty,
      choices: c.choicesAround(ansPow, distractors: [p1 * p2, ansPow + 1, ansPow - 1]),
      steps: [
        multiply
            ? 'Same base multiplied: ADD the powers.'
            : 'Same base divided: SUBTRACT the powers.',
        multiply ? '$p1 + $p2 = $ansPow.' : '$hi - $lo = $ansPow.',
        'Answer: $base^$ansPow.',
      ],
      hint: multiply
          ? 'Do not multiply the powers - add them.'
          : 'Do not divide the powers - subtract them.',
    );
  });
}

List<int> _factorsOf(int n) =>
    [for (var i = 1; i <= n; i++) if (n % i == 0) i];

String _factorPairs(int n) {
  final pairs = <String>[];
  for (var i = 1; i * i <= n; i++) {
    if (n % i == 0) pairs.add('$i x ${n ~/ i}');
  }
  return pairs.join(', ');
}

bool _isPrime(int n) {
  if (n < 2) return false;
  for (var i = 2; i * i <= n; i++) {
    if (n % i == 0) return false;
  }
  return true;
}

int _smallestFactor(int n) {
  for (var i = 2; i * i <= n; i++) {
    if (n % i == 0) return i;
  }
  return n;
}

int _isqrt(int n) {
  var i = 1;
  while ((i + 1) * (i + 1) <= n) {
    i++;
  }
  return i;
}

/// Multiples of [n] up to and including [limit], for showing the two lists
/// side by side until they meet.
List<int> _multiplesUpTo(int n, int limit) =>
    [for (var k = n; k <= limit; k += n) k];

/// The prime factors of the LCM: every prime at the higher of its two powers.
List<int> _lcmFactors(int a, int b) {
  final fa = <int, int>{};
  final fb = <int, int>{};
  for (final p in _primeFactors(a)) {
    fa[p] = (fa[p] ?? 0) + 1;
  }
  for (final p in _primeFactors(b)) {
    fb[p] = (fb[p] ?? 0) + 1;
  }
  final primes = {...fa.keys, ...fb.keys}.toList()..sort();
  final out = <int>[];
  for (final p in primes) {
    final times = (fa[p] ?? 0) > (fb[p] ?? 0) ? fa[p]! : fb[p]!;
    out.addAll(List.filled(times, p));
  }
  return out;
}

List<int> _primeFactors(int n) {
  final out = <int>[];
  var v = n;
  for (var p = 2; p * p <= v; p++) {
    while (v % p == 0) {
      out.add(p);
      v ~/= p;
    }
  }
  if (v > 1) out.add(v);
  return out;
}

/// The biggest prime factor a question here is allowed to contain.
///
/// Without this, "write 158 as a product of primes" is a valid question whose
/// answer is 2 x 79 - and the child's real task becomes proving 79 is prime,
/// which is a different skill. The hardcoded lists this replaced were all
/// smooth numbers for exactly that reason; the ceiling keeps that property
/// while still leaving dozens of numbers to choose from.
const _largestUsefulPrime = 13;

/// Picks a composite number in [min]..[max] whose factor count sits inside the
/// given window, so the question is neither trivial nor a wall of numbers.
///
/// Falls back to scanning the range rather than looping forever, and finally to
/// a known-good number, so a generator can never hang or throw.
int _pickComposite(GenContext c, int min, int max,
    {required int minFactors, required int maxFactors}) {
  bool ok(int n) {
    final k = _factorsOf(n).length;
    return k >= minFactors &&
        k <= maxFactors &&
        _primeFactors(n).last <= _largestUsefulPrime;
  }

  for (var i = 0; i < 60; i++) {
    final n = c.int_(min, max);
    if (ok(n)) return n;
  }
  for (var n = min; n <= max; n++) {
    if (ok(n)) return n;
  }
  return 24;
}

/// Picks a number worth writing as a product of primes: composite, with at
/// least two prime factors counted with multiplicity.
int _pickForPrimeFactorisation(GenContext c, int min, int max) {
  bool ok(int n) {
    final f = _primeFactors(n);
    return f.length >= 2 && f.last <= _largestUsefulPrime;
  }

  for (var i = 0; i < 60; i++) {
    final n = c.int_(min, max);
    if (ok(n)) return n;
  }
  for (var n = min; n <= max; n++) {
    if (ok(n)) return n;
  }
  return 72;
}
