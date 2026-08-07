import '../fraction.dart';
import '../gen_context.dart';
import '../generator.dart';
import '../question.dart';

/// Data handling, probability and trigonometry.
void registerDataAndTrig() {
  // ------------------------------------------------------------------- data

  register('pictograph', (c) {
    final per = c.pick([2, 5, 10]);
    final symbols = c.int_(3, c.band(6, 12));
    return Question(
      skillId: c.skillId,
      prompt: 'In a pictograph, one symbol stands for $per books.\n\n'
          'A shelf shows $symbols symbols. How many books is that?',
      answer: '${per * symbols}',
      difficulty: c.difficulty,
      choices: c.choicesAround(per * symbols,
          distractors: [per + symbols, per * symbols ~/ 2]),
      steps: ['Each symbol = $per books.', '$symbols x $per = ${per * symbols}.'],
    );
  });

  register('bar_graph', (c) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
    final values = <int>[];
    while (values.toSet().length < 5) {
      values.clear();
      for (var i = 0; i < 5; i++) {
        values.add(c.int_(4, c.band(20, 60)));
      }
    }
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final minV = values.reduce((a, b) => a < b ? a : b);
    final wantDiff = c.coin();
    return Question(
      skillId: c.skillId,
      // The topic is reading a chart, so it has to be an actual chart. Listing
      // the numbers in text turns it into arithmetic and tests nothing about
      // graphs.
      prompt: 'Books sold each day:\n\n'
          '${wantDiff ? 'What is the difference between the highest and '
              'lowest day?' : 'How many were sold altogether?'}',
      diagram: 'bars:${[for (var i = 0; i < 5; i++) '${days[i]}=${values[i]}'].join(',')}',
      answer: '${wantDiff ? maxV - minV : values.reduce((a, b) => a + b)}',
      difficulty: c.difficulty,
      steps: wantDiff
          ? [
              'Highest is $maxV, lowest is $minV.',
              '$maxV - $minV = ${maxV - minV}.',
            ]
          : [
              'Add every bar: ${values.join(' + ')}.',
              '= ${values.reduce((a, b) => a + b)}.',
            ],
    );
  });

  register('pie_chart', (c) {
    final pct = c.pick([10, 20, 25, 40, 50, 75]);
    return Question(
      skillId: c.skillId,
      prompt: 'The shaded slice is $pct% of the whole.\n\n'
          'What is its angle, in degrees?',
      diagram: 'pie:$pct',
      answer: '${360 * pct ~/ 100}',
      difficulty: c.difficulty,
      choices: c.choicesAround(360 * pct ~/ 100,
          distractors: [pct, 180 * pct ~/ 100, 360 - 360 * pct ~/ 100]),
      steps: [
        'A full pie chart is 360 degrees.',
        '$pct% of 360 = $pct/100 x 360 = ${360 * pct ~/ 100}.',
      ],
      hint: 'The whole circle is 360, not 100.',
    );
  });

  register('central_tendency', (c) {
    final n = c.pick([5, 5, 7]);
    // Values are chosen so the mean lands on a whole number - the skill being
    // tested is finding the mean, not long division with a remainder.
    final base = c.int_(c.band(5, 20), c.band(25, 60));
    final offsets = <int>[];
    var sum = 0;
    for (var i = 0; i < n - 1; i++) {
      final o = c.int_(-8, 8);
      offsets.add(o);
      sum += o;
    }
    offsets.add(-sum);
    final values = offsets.map((o) => base + o).toList()..shuffle(c.rng);

    final which = c.pick(['mean', 'median', 'range']);
    final sorted = [...values]..sort();
    final answer = switch (which) {
      'mean' => base,
      'median' => sorted[n ~/ 2],
      _ => sorted.last - sorted.first,
    };
    return Question(
      skillId: c.skillId,
      prompt: 'Find the $which of these numbers:\n\n${values.join(', ')}',
      answer: '$answer',
      difficulty: c.difficulty,
      choices: c.choicesAround(answer,
          distractors: [sorted[n ~/ 2], sorted.last - sorted.first, base]),
      steps: switch (which) {
        'mean' => [
            'Add them all: ${values.reduce((a, b) => a + b)}.',
            'Divide by how many there are: ${values.reduce((a, b) => a + b)} / $n = $answer.',
          ],
        'median' => [
            'Put them in order: ${sorted.join(', ')}.',
            'The middle one is $answer.',
          ],
        _ => [
            'Range = biggest minus smallest.',
            '${sorted.last} - ${sorted.first} = $answer.',
          ],
      },
      hint: switch (which) {
        'mean' => 'Add everything, then divide by how many.',
        'median' => 'Sort them first, then take the middle.',
        _ => 'Biggest take away smallest.',
      },
    );
  });

  register('probability', (c) {
    final kind = c.pick(['die', 'coin', 'ball']);
    if (kind == 'coin') {
      return Question(
        skillId: c.skillId,
        prompt: 'A fair coin is tossed once.\n\n'
            'What is the probability of getting heads? '
            '(give a fraction in lowest terms)',
        answer: '1/2',
        difficulty: c.difficulty,
        steps: [
          'A coin can land 2 ways: heads or tails.',
          'Only 1 of those is heads.',
          'So the chance is 1 out of 2, written 1/2.',
        ],
        hint: 'How many ways can it land? How many of those are heads?',
      );
    }
    if (kind == 'die') {
      final target = c.int_(1, 6);
      final even = c.coin();
      final f = even ? Fraction(3, 6) : Fraction(1, 6);
      return Question(
        skillId: c.skillId,
        prompt: even
            ? 'A fair die is rolled once.\n\nWhat is the probability of getting '
                'an even number? (fraction in lowest terms)'
            : 'A fair die is rolled once.\n\nWhat is the probability of getting '
                'a $target? (fraction in lowest terms)',
        answer: f.toString(),
        difficulty: c.difficulty,
        steps: even
            ? [
                'Even numbers on a die: 2, 4, 6 - that is 3 out of 6.',
                '3/6 simplifies to ${f.toString()}.',
              ]
            : [
                'There are 6 faces and only one shows $target.',
                'P = ${f.toString()}.',
              ],
      );
    }
    final red = c.int_(2, c.band(5, 9));
    final blue = c.int_(2, c.band(5, 9));
    final f = Fraction(red, red + blue);
    return Question(
      skillId: c.skillId,
      prompt: 'A bag holds $red red balls and $blue blue balls. One is taken '
          'without looking.\n\nWhat is the probability it is red? '
          '(fraction in lowest terms)',
      answer: f.toString(),
      difficulty: c.difficulty,
      steps: [
        'Total balls = $red + $blue = ${red + blue}.',
        'Red ones = $red, so P = $red/${red + blue} = ${f.toString()}.',
      ],
      hint: 'Wanted outcomes over total outcomes.',
    );
  });

  // ------------------------------------------------------------------- trig

  register('trig_ratios', (c) {
    const triples = [[3, 4, 5], [6, 8, 10], [5, 12, 13], [8, 15, 17], [7, 24, 25]];
    final t = c.pick(triples);
    final ratio = c.pick(['sin', 'cos', 'tan']);
    final f = switch (ratio) {
      'sin' => Fraction(t[0], t[2]),
      'cos' => Fraction(t[1], t[2]),
      _ => Fraction(t[0], t[1]),
    };
    return Question(
      skillId: c.skillId,
      prompt: 'In a right-angled triangle, the side opposite angle A is '
          '${t[0]}, the side adjacent to A is ${t[1]}, and the hypotenuse is '
          '${t[2]}.\n\nFind $ratio A. (fraction in lowest terms)',
      answer: f.toString(),
      difficulty: c.difficulty,
      steps: [
        'SOH CAH TOA: sin = opposite/hypotenuse, cos = adjacent/hypotenuse, '
            'tan = opposite/adjacent.',
        switch (ratio) {
          'sin' => '$ratio A = ${t[0]}/${t[2]} = ${f.toString()}.',
          'cos' => '$ratio A = ${t[1]}/${t[2]} = ${f.toString()}.',
          _ => '$ratio A = ${t[0]}/${t[1]} = ${f.toString()}.',
        },
      ],
      hint: 'Remember SOH CAH TOA.',
    );
  });

  register('trig_standard', (c) {
    // Only the exact values a student is expected to memorise.
    const table = {
      'sin 0': '0', 'sin 30': '1/2', 'sin 90': '1',
      'cos 0': '1', 'cos 60': '1/2', 'cos 90': '0',
      'tan 0': '0', 'tan 45': '1',
      'sin 45': '1/root2', 'cos 45': '1/root2',
    };
    final key = c.pick(table.keys.toList());
    final ans = table[key]!;
    return Question(
      skillId: c.skillId,
      prompt: 'What is the value of $key degrees?\n\n'
          '(write fractions like 1/2, and 1/root2 for one over root two)',
      answer: ans,
      difficulty: c.difficulty,
      choices: _withAnswer(
        const ['0', '1', '1/2', '1/root2'],
        ans,
        c,
      ),
      steps: ['From the standard angle table, $key = $ans.'],
      hint: 'These are the values worth memorising: 0, 30, 45, 60, 90.',
    );
  });

  register('heights_distances', (c) {
    // Only 45 degrees, where tan = 1, so the arithmetic stays exact.
    final d = c.int_(c.band(10, 30), c.band(40, 120));
    return Question(
      skillId: c.skillId,
      prompt: 'A pole stands upright. From a point $d m away on level ground, '
          'the angle of elevation to the top is 45 degrees.\n\n'
          'How tall is the pole, in metres?',
      answer: '$d',
      difficulty: c.difficulty,
      choices: c.choicesAround(d, distractors: [d * 2, d ~/ 2, d + 10]),
      steps: [
        'tan(angle) = height / distance.',
        'tan 45 = 1, so height / $d = 1.',
        'Height = $d m.',
      ],
      hint: 'What is tan 45?',
    );
  });
}

List<String> _withAnswer(List<String> pool, String answer, GenContext c) {
  final others = pool.where((e) => e != answer).toList()..shuffle(c.rng);
  return [answer, ...others.take(3)]..shuffle(c.rng);
}
