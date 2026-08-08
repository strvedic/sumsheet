import '../generator.dart';
import '../question.dart';

/// Units, time, money, perimeter, area, surface area and volume.
///
/// Circle work uses pi = 22/7 with radii that are multiples of 7, so answers
/// come out whole. A student practising area should be practising area, not
/// wrestling with 153.93804.
void registerMensuration() {
  register('units', (c) {
    const conv = [
      ['km', 'm', 1000], ['m', 'cm', 100], ['cm', 'mm', 10],
      ['kg', 'g', 1000], ['L', 'mL', 1000],
    ];
    final row = c.pick(conv);
    final from = row[0] as String;
    final to = row[1] as String;
    final factor = row[2] as int;
    final n = c.int_(2, c.band(9, 40));
    return Question(
      skillId: c.skillId,
      prompt: '$n $from = ? $to',
      answer: '${n * factor}',
      difficulty: c.difficulty,
      choices: c.choicesAround(n * factor,
          distractors: [n * factor ~/ 10, n * factor * 10, n + factor]),
      steps: ['1 $from = $factor $to.', '$n x $factor = ${n * factor}.'],
      hint: 'Bigger unit to smaller unit means multiply.',
    );
  });

  register('money', (c) {
    final bill = c.int_(c.band(40, 200), c.band(199, 900));
    final paid = ((bill ~/ 100) + 1) * 100 + (c.coin() ? 0 : 100);
    return Question(
      skillId: c.skillId,
      prompt: 'A bill comes to Rs $bill. You pay with Rs $paid.\n\n'
          'How much change do you get?',
      answer: '${paid - bill}',
      difficulty: c.difficulty,
      choices: c.choicesAround(paid - bill, distractors: [bill, paid, paid + bill]),
      steps: ['Change = what you paid minus the bill.', '$paid - $bill = ${paid - bill}.'],
    );
  });

  register('clock', (c) {
    final hour = c.int_(1, 12);
    const mins = {
      'quarter past': 15, 'half past': 30, 'quarter to': 45, "o'clock": 0,
    };
    // O'clock is read straight off the hour hand. Half past and quarter past
    // still name the hour they belong to. Quarter to names the *next* hour,
    // which is the one children get wrong, so it comes last.
    final phrase =
        c.pickByLevel(const ["o'clock", 'half past', 'quarter past', 'quarter to']);
    final m = mins[phrase]!;
    final displayHour = phrase == 'quarter to' ? (hour % 12) + 1 : hour;
    final shown = phrase == 'quarter to'
        ? '$hour:45'
        : '$hour:${m.toString().padLeft(2, '0')}';
    return Question(
      skillId: c.skillId,
      prompt: phrase == 'quarter to'
          ? 'Write $shown in words, using "quarter to".\n\n'
              'Which hour comes after "quarter to"?'
          : 'What is the time $phrase $hour, written in numbers? '
              '(like 7:30)',
      answer: phrase == 'quarter to' ? '$displayHour' : shown,
      difficulty: c.difficulty,
      steps: phrase == 'quarter to'
          ? [
              '$shown is 15 minutes before the next hour.',
              'The next hour after $hour is $displayHour.',
            ]
          : ['$phrase $hour means $m minutes after $hour.', 'So it is $shown.'],
    );
  });

  register('time_calc', (c) {
    final startH = c.int_(1, 20);
    final startM = c.pick([0, 10, 15, 20, 30, 40, 45, 50]);
    final durH = c.int_(1, c.band(2, 5));
    final durM = c.pick([0, 10, 15, 20, 30, 40, 45]);
    final totalMin = startH * 60 + startM + durH * 60 + durM;
    final endH = (totalMin ~/ 60) % 24;
    final endM = totalMin % 60;
    String fmt(int h, int m) => '$h:${m.toString().padLeft(2, '0')}';
    return Question(
      skillId: c.skillId,
      prompt: 'A train leaves at ${fmt(startH, startM)} and the journey takes '
          '${durH}h ${durM}m.\n\nWhat time does it arrive? (like 7:30)',
      answer: fmt(endH, endM),
      difficulty: c.difficulty,
      steps: [
        'Add the hours: $startH + $durH = ${startH + durH}.',
        'Add the minutes: $startM + $durM = ${startM + durM}'
            '${startM + durM >= 60 ? ', which is over 60 so carry an hour' : ''}.',
        'Arrival: ${fmt(endH, endM)}.',
      ],
      hint: '60 minutes make an hour - watch for the carry.',
    );
  });

  register('perimeter', (c) {
    final l = c.int_(c.band(4, 12), c.band(15, 40));
    final w = c.int_(c.band(3, 8), c.band(12, 30));
    return Question(
      skillId: c.skillId,
      prompt: 'Find the perimeter of a rectangle $l cm long and $w cm wide.',
      answer: '${2 * (l + w)}',
      difficulty: c.difficulty,
      choices: c.choicesAround(2 * (l + w), distractors: [l * w, l + w, 2 * l * w]),
      steps: [
        'Perimeter = distance all the way round = 2 x (length + width).',
        '2 x ($l + $w) = 2 x ${l + w} = ${2 * (l + w)}.',
      ],
      hint: 'Add all four sides.',
    );
  });

  register('area_rect', (c) {
    final square = c.coin();
    final l = c.int_(c.band(4, 12), c.band(15, 40));
    final w = square ? l : c.int_(c.band(3, 8), c.band(12, 30));
    return Question(
      skillId: c.skillId,
      prompt: square
          ? 'Find the area of a square of side $l cm.'
          : 'Find the area of a rectangle $l cm by $w cm.',
      answer: '${l * w}',
      difficulty: c.difficulty,
      choices: c.choicesAround(l * w, distractors: [2 * (l + w), l + w, l * w * 2]),
      steps: [
        square ? 'Area of a square = side x side.' : 'Area = length x width.',
        '$l x $w = ${l * w}.',
      ],
      hint: 'Area is multiply, perimeter is add.',
    );
  });

  register('area_triangle', (c) {
    // Base is even so half the product stays a whole number.
    final base = c.int_(c.band(3, 10), c.band(10, 24)) * 2;
    final height = c.int_(c.band(4, 9), c.band(10, 25));
    if (c.coin()) {
      return Question(
        skillId: c.skillId,
        prompt: 'Find the area of a triangle with base $base cm and height '
            '$height cm.',
        answer: '${base * height ~/ 2}',
        difficulty: c.difficulty,
        choices: c.choicesAround(base * height ~/ 2,
            distractors: [base * height, base + height]),
        steps: [
          'Area of a triangle = half x base x height.',
          '$base x $height = ${base * height}.',
          'Half of ${base * height} is ${base * height ~/ 2}.',
        ],
        hint: 'Do not forget the half.',
      );
    }
    return Question(
      skillId: c.skillId,
      prompt: 'Find the area of a parallelogram with base $base cm and height '
          '$height cm.',
      answer: '${base * height}',
      difficulty: c.difficulty,
      choices: c.choicesAround(base * height,
          distractors: [base * height ~/ 2, base + height]),
      steps: [
        'Area of a parallelogram = base x height (no half).',
        '$base x $height = ${base * height}.',
      ],
      hint: 'A parallelogram has no half - that is the triangle.',
    );
  });

  register('circle_area', (c) {
    // A multiple of 7 keeps both answers whole once pi is taken as 22/7, which
    // is the whole point of that approximation. Any multiple works, so there is
    // no reason to pick from a list of five.
    final r = 7 * c.int_(1, c.band(6, 20));
    final wantArea = c.coin();
    final circ = 2 * 22 * r ~/ 7;
    final area = 22 * r * r ~/ 7;
    return Question(
      skillId: c.skillId,
      prompt: wantArea
          ? 'Find the area of a circle of radius $r cm. (Take pi = 22/7)'
          : 'Find the circumference of a circle of radius $r cm. '
              '(Take pi = 22/7)',
      answer: '${wantArea ? area : circ}',
      difficulty: c.difficulty,
      choices: c.choicesAround(wantArea ? area : circ,
          distractors: [wantArea ? circ : area, r * 2]),
      steps: wantArea
          ? [
              'Area = pi x r x r.',
              '22/7 x $r x $r = $area.',
            ]
          : [
              'Circumference = 2 x pi x r.',
              '2 x 22/7 x $r = $circ.',
            ],
      hint: wantArea ? 'Area uses r squared.' : 'Circumference uses r, not r squared.',
    );
  });

  register('surface_area', (c) {
    final cube = c.coin();
    final l = c.int_(c.band(3, 7), c.band(8, 15));
    final b = cube ? l : c.int_(c.band(2, 6), c.band(7, 12));
    final h = cube ? l : c.int_(c.band(2, 5), c.band(6, 10));
    final sa = 2 * (l * b + b * h + h * l);
    return Question(
      skillId: c.skillId,
      prompt: cube
          ? 'Find the total surface area of a cube of side $l cm.'
          : 'Find the total surface area of a cuboid $l cm by $b cm by $h cm.',
      answer: '$sa',
      difficulty: c.difficulty,
      choices: c.choicesAround(sa, distractors: [l * b * h, sa ~/ 2]),
      steps: cube
          ? ['Surface area of a cube = 6 x side x side.', '6 x $l x $l = $sa.']
          : [
              'Surface area = 2 x (lb + bh + hl).',
              'lb = ${l * b}, bh = ${b * h}, hl = ${h * l}.',
              '2 x ${l * b + b * h + h * l} = $sa.',
            ],
    );
  });

  register('volume', (c) {
    final cube = c.coin();
    final l = c.int_(c.band(3, 7), c.band(8, 15));
    final b = cube ? l : c.int_(c.band(2, 6), c.band(7, 12));
    final h = cube ? l : c.int_(c.band(2, 5), c.band(6, 10));
    return Question(
      skillId: c.skillId,
      prompt: cube
          ? 'Find the volume of a cube of side $l cm.'
          : 'Find the volume of a cuboid $l cm by $b cm by $h cm.',
      answer: '${l * b * h}',
      difficulty: c.difficulty,
      choices: c.choicesAround(l * b * h,
          distractors: [2 * (l * b + b * h + h * l), l + b + h]),
      steps: [
        cube ? 'Volume of a cube = side x side x side.' : 'Volume = l x b x h.',
        '$l x $b x $h = ${l * b * h}.',
      ],
      hint: 'Volume multiplies all three, surface area does not.',
    );
  });

  register('solids', (c) {
    final r = c.pick([7, 14, 21]);
    final h = c.int_(c.band(5, 10), c.band(12, 25));
    final vol = 22 * r * r * h ~/ 7;
    return Question(
      skillId: c.skillId,
      prompt: 'Find the volume of a cylinder with radius $r cm and height '
          '$h cm. (Take pi = 22/7)',
      answer: '$vol',
      difficulty: c.difficulty,
      choices: c.choicesAround(vol, distractors: [vol ~/ 3, 22 * r * r ~/ 7]),
      steps: [
        'Volume of a cylinder = pi x r x r x h.',
        '22/7 x $r x $r x $h = $vol.',
      ],
      hint: 'It is the circle area, multiplied by the height.',
    );
  });
}
