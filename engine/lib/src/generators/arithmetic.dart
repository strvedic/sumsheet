import '../generator.dart';
import '../question.dart';

/// Counting, place value, addition, subtraction, tables and division.
/// This is the band ASER 2024 found broken in ~70% of Class 5 students,
/// so it is the band the whole app is really built to repair.
void registerArithmetic() {
  // ---------------------------------------------------------------- counting

  register('count_objects', (c) {
    final n = c.int_(1, c.band(5, 10));
    // A filled circle, not "*" or "+". A five-year-old counting plus signs is
    // being asked to count maths symbols, which is confusing at exactly the
    // age where it matters most. One shape, repeated, widely spaced.
    return Question(
      skillId: c.skillId,
      prompt: 'How many do you see?\n\n${List.filled(n, '●').join('  ')}',
      answer: '$n',
      difficulty: c.difficulty,
      choices: c.choicesAround(n, distractors: [n - 1, n + 1, n + 2]),
      steps: ['Point at each one and count.', 'There are $n.'],
    );
  });

  register('digit_recognise', (c) {
    final n = c.int_(0, 9);
    const words = [
      'zero', 'one', 'two', 'three', 'four',
      'five', 'six', 'seven', 'eight', 'nine',
    ];
    if (c.coin()) {
      return Question(
        skillId: c.skillId,
        prompt: 'Write the number for: ${words[n]}',
        answer: '$n',
        difficulty: c.difficulty,
        choices: c.choicesAround(n),
        steps: ['${words[n]} is written as $n.'],
      );
    }
    return Question(
      skillId: c.skillId,
      prompt: 'How do we say the number $n?',
      answer: words[n],
      difficulty: c.difficulty,
      choices: ([words[n], words[(n + 1) % 10], words[(n + 3) % 10], words[(n + 7) % 10]]
            ..shuffle(c.rng))
          .toSet()
          .toList(),
      steps: ['$n is said as "${words[n]}".'],
    );
  });

  register('count_sequence', (c) {
    // The skill decides the range, not the difficulty. "Count and write 1 to
    // 20" must never show a child numbers in the thirties.
    final maxN = switch (c.skillId) {
      'count-1-20' => 20,
      'count-1-100' => 100,
      _ => c.band(20, 100),
    };
    final start = c.int_(1, maxN - 4);
    final missingAt = c.int_(1, 3);
    final seq = List.generate(5, (i) => start + i);
    final answer = seq[missingAt];
    final shown = [...seq];
    shown[missingAt] = -1;
    return Question(
      skillId: c.skillId,
      prompt:
          'Fill in the missing number:\n\n${shown.map((e) => e == -1 ? '__' : '$e').join(', ')}',
      answer: '$answer',
      difficulty: c.difficulty,
      choices: c.choicesAround(answer, distractors: [answer - 1, answer + 1]),
      steps: [
        'The numbers go up by 1 each time.',
        'After ${seq[missingAt - 1]} comes $answer.',
      ],
    );
  });

  register('compare_quantity', (c) {
    final hi = c.band(10, 100);
    final a = c.int_(1, hi);
    final b = c.intExcept(1, hi, {a});
    final bigger = a > b ? a : b;
    return Question(
      skillId: c.skillId,
      prompt: 'Which number is greater: $a or $b?',
      answer: '$bigger',
      difficulty: c.difficulty,
      choices: ['$a', '$b'],
      steps: [
        'The bigger number is the one further along when you count.',
        '$bigger comes after ${a > b ? b : a}, so $bigger is greater.',
      ],
      hint: 'Which one would you say later if you counted up?',
    );
  });

  register('before_after', (c) {
    final hi = c.band(20, 100);
    final n = c.int_(2, hi - 1);
    final kind = c.pick(['before', 'after', 'between']);
    if (kind == 'between') {
      return Question(
        skillId: c.skillId,
        prompt: 'Which number comes between ${n - 1} and ${n + 1}?',
        answer: '$n',
        difficulty: c.difficulty,
        choices: c.choicesAround(n, distractors: [n - 1, n + 1, n + 2]),
        steps: ['Count: ${n - 1}, then $n, then ${n + 1}.'],
      );
    }
    final ans = kind == 'before' ? n - 1 : n + 1;
    return Question(
      skillId: c.skillId,
      prompt: 'Which number comes just $kind $n?',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [n, n + 1, n - 1]),
      steps: [
        kind == 'before'
            ? 'One less than $n is $ans.'
            : 'One more than $n is $ans.',
      ],
    );
  });

  register('skip_count', (c) {
    final step = c.pick([2, 5, 10, if (c.difficulty >= 3) 3, if (c.difficulty >= 4) 4]);
    final start = step * c.int_(1, 5);
    final seq = List.generate(5, (i) => start + i * step);
    final answer = seq[4];
    return Question(
      skillId: c.skillId,
      prompt:
          'Continue the pattern:\n\n${seq.take(4).join(', ')}, __',
      answer: '$answer',
      difficulty: c.difficulty,
      choices: c.choicesAround(answer, distractors: [answer + step, answer - step]),
      steps: [
        'The numbers go up by $step each time.',
        '${seq[3]} + $step = $answer.',
      ],
    );
  });

  // ------------------------------------------------------------- place value

  register('place_value', (c) {
    const places = ['ones', 'tens', 'hundreds', 'thousands'];
    // "Place value: tens and ones" must not ask about the hundreds column.
    final digits = switch (c.skillId) {
      'place-value-tens' => 2,
      'place-value-hundreds' => 3,
      _ => c.band(2, 4),
    };
    final low = _pow10(digits - 1);
    final n = c.int_(low, low * 10 - 1);
    final pos = c.int_(0, digits - 1);
    final digit = (n ~/ _pow10(pos)) % 10;
    if (c.coin()) {
      return Question(
        skillId: c.skillId,
        prompt: 'In the number $n, which digit is in the ${places[pos]} place?',
        answer: '$digit',
        difficulty: c.difficulty,
        choices: c.choicesAround(digit, distractors: List.generate(4, (i) => (n ~/ _pow10(i)) % 10)),
        steps: [
          'Read the places from the right: ones, tens, hundreds, thousands.',
          'The ${places[pos]} digit of $n is $digit.',
        ],
      );
    }
    final value = digit * _pow10(pos);
    return Question(
      skillId: c.skillId,
      prompt: 'In the number $n, what is the place value of the digit $digit '
          'in the ${places[pos]} place?',
      answer: '$value',
      difficulty: c.difficulty,
      choices: c.choicesAround(value, distractors: [digit, value * 10, value ~/ 10]),
      steps: [
        'The digit is $digit and it sits in the ${places[pos]} place.',
        'Place value = $digit x ${_pow10(pos)} = $value.',
      ],
    );
  });

  register('compare_order', (c) {
    final digits = c.band(2, 4);
    final low = _pow10(digits - 1);
    final nums = <int>{};
    while (nums.length < 3) {
      nums.add(c.int_(low, low * 10 - 1));
    }
    final asc = c.coin();
    final ascending = nums.toList()..sort();
    final target = asc ? ascending : ascending.reversed.toList();

    // The numbers must never be shown already in the order being asked for,
    // or the student just copies the line back. With three distinct values a
    // set's insertion order lands on the answer surprisingly often.
    var shown = nums.toList()..shuffle(c.rng);
    if (_sameOrder(shown, target)) shown = shown.reversed.toList();

    return Question(
      skillId: c.skillId,
      prompt: 'Arrange in ${asc ? 'ascending' : 'descending'} order:'
          '\n\n${shown.join(', ')}',
      answer: target.join(','),
      difficulty: c.difficulty,
      steps: [
        asc ? 'Ascending means smallest first.' : 'Descending means biggest first.',
        'Compare the leftmost digits first.',
        'Answer: ${target.join(', ')}',
      ],
    );
  });

  register('rounding', (c) {
    final toPlace = c.pick([10, 100, if (c.difficulty >= 3) 1000]);
    final n = c.int_(toPlace, toPlace * 100);
    final rounded = ((n / toPlace).round()) * toPlace;
    final name = toPlace == 10 ? 'ten' : (toPlace == 100 ? 'hundred' : 'thousand');
    return Question(
      skillId: c.skillId,
      prompt: 'Round $n to the nearest $name.',
      answer: '$rounded',
      difficulty: c.difficulty,
      choices: c.choicesAround(rounded,
          distractors: [rounded + toPlace, rounded - toPlace]),
      steps: [
        'Look at the digit just after the $name place.',
        'If it is 5 or more round up, otherwise round down.',
        '$n rounds to $rounded.',
      ],
    );
  });

  register('large_numbers', (c) {
    final digits = c.band(5, 8);
    final n = c.int_(_pow10(digits - 1), _pow10(digits - 1) * 10 - 1);
    final lakhs = n ~/ 100000;
    final rest = n % 100000;
    final thousands = rest ~/ 1000;
    return Question(
      skillId: c.skillId,
      prompt: 'How many thousands are there in $n? '
          '(Indian system: use the full thousands count)',
      answer: '${n ~/ 1000}',
      difficulty: c.difficulty,
      choices: c.choicesAround(n ~/ 1000, distractors: [thousands, lakhs, n ~/ 100]),
      steps: [
        'Thousands = the whole number divided by 1000, ignoring the remainder.',
        '$n / 1000 = ${n ~/ 1000} (remainder ${n % 1000}).',
      ],
    );
  });

  // ------------------------------------------------------ addition/subtraction

  register('add_small', (c) {
    final hi = c.band(5, 20);
    final a = c.int_(1, hi);
    final b = c.int_(1, hi);
    final ans = a + b;
    return Question(
      skillId: c.skillId,
      prompt: '$a + $b = ?',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [ans - 1, ans + 1, (a - b).abs()]),
      steps: ['Start at $a and count on $b more.', '$a + $b = $ans.'],
      hint: 'Try counting up from the bigger number.',
    );
  });

  register('sub_small', (c) {
    final hi = c.band(5, 20);
    final a = c.int_(2, hi);
    final b = c.int_(1, a);
    final ans = a - b;
    return Question(
      skillId: c.skillId,
      prompt: '$a - $b = ?',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [ans + 1, ans - 1, a + b]),
      steps: ['Start at $a and count back $b.', '$a - $b = $ans.'],
      hint: 'Count backwards from $a.',
    );
  });

  register('add_column', (c) {
    // Matched exactly, NOT with contains(): "add-2digit-nocarry" contains the
    // substring "carry", so a contains() check silently gave the no-carrying
    // skill nothing but carrying questions.
    final wantCarry = c.skillId == 'add-2digit-carry';
    late int a, b;
    var guard = 0;
    do {
      a = c.int_(10, 99);
      b = c.int_(10, 99);
      guard++;
    } while (guard < 100 && ((a % 10 + b % 10 >= 10) != wantCarry));
    final ans = a + b;
    return Question(
      skillId: c.skillId,
      prompt: '$a + $b = ?',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [ans - 10, ans + 10, ans - 1]),
      steps: [
        'Add the ones: ${a % 10} + ${b % 10} = ${a % 10 + b % 10}.',
        if (wantCarry)
          'That is 10 or more, so write ${(a % 10 + b % 10) % 10} and carry 1.',
        'Add the tens: ${a ~/ 10} + ${b ~/ 10}'
            '${wantCarry ? ' + 1 (carried)' : ''} = ${ans ~/ 10}.',
        '$a + $b = $ans.',
      ],
      hint: wantCarry ? 'The ones column goes past 10 - remember to carry.' : null,
    );
  });

  register('sub_column', (c) {
    // Same trap as add_column: "sub-2digit-noborrow" contains "borrow".
    final wantBorrow = c.skillId == 'sub-2digit-borrow';
    late int a, b;
    var guard = 0;
    do {
      a = c.int_(20, 99);
      b = c.int_(10, a - 1);
      guard++;
    } while (guard < 200 && ((a % 10 < b % 10) != wantBorrow));
    final ans = a - b;
    return Question(
      skillId: c.skillId,
      prompt: '$a - $b = ?',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [ans + 10, ans - 10, (a % 10 - b % 10).abs()]),
      steps: [
        if (wantBorrow) ...[
          'Ones: ${a % 10} is smaller than ${b % 10}, so borrow 1 ten.',
          'Now ${a % 10 + 10} - ${b % 10} = ${a % 10 + 10 - b % 10}.',
          'Tens: ${a ~/ 10 - 1} - ${b ~/ 10} = ${(a ~/ 10 - 1) - (b ~/ 10)}.',
        ] else ...[
          'Ones: ${a % 10} - ${b % 10} = ${a % 10 - b % 10}.',
          'Tens: ${a ~/ 10} - ${b ~/ 10} = ${a ~/ 10 - b ~/ 10}.',
        ],
        '$a - $b = $ans.',
      ],
      hint: wantBorrow ? 'The top ones digit is too small - borrow from the tens.' : null,
    );
  });

  register('add_sub_column', (c) {
    final a = c.int_(c.band(100, 1000), c.band(999, 9999));
    final b = c.int_(100, a - 1);
    final isAdd = c.coin();
    final ans = isAdd ? a + b : a - b;
    return Question(
      skillId: c.skillId,
      prompt: '$a ${isAdd ? '+' : '-'} $b = ?',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [ans + 100, ans - 100, ans + 10]),
      steps: [
        'Line up ones under ones, tens under tens, hundreds under hundreds.',
        'Work column by column from the right.',
        '$a ${isAdd ? '+' : '-'} $b = $ans.',
      ],
    );
  });

  register('word_addsub', (c) {
    final names = ['Ravi', 'Priya', 'Arun', 'Meena', 'Karthik', 'Divya'];
    final items = ['marbles', 'stickers', 'coins', 'pencils', 'mangoes'];
    final name = c.pick(names);
    final item = c.pick(items);
    final start = c.int_(c.band(20, 200), c.band(99, 900));
    final change = c.int_(5, start - 1);
    final gave = c.coin();
    final ans = gave ? start - change : start + change;
    return Question(
      skillId: c.skillId,
      prompt: gave
          ? '$name had $start $item and gave away $change. How many are left?'
          : '$name had $start $item and got $change more. How many now?',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [gave ? start + change : start - change, start]),
      steps: [
        gave
            ? 'Gave away means subtract.'
            : 'Got more means add.',
        '$start ${gave ? '-' : '+'} $change = $ans.',
      ],
      hint: gave ? 'Does the amount go up or down when you give things away?' : null,
    );
  });

  // ------------------------------------------------- multiplication/division

  register('mult_concept', (c) {
    final groups = c.int_(2, c.band(4, 8));
    final each = c.int_(2, c.band(5, 9));
    final ans = groups * each;
    return Question(
      skillId: c.skillId,
      prompt: '${List.filled(groups, '$each').join(' + ')} = ?\n\n'
          'That is $groups groups of $each. Write it as a multiplication and solve.',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [groups + each, ans - each, ans + each]),
      steps: [
        'Adding $each to itself $groups times is the same as $groups x $each.',
        '$groups x $each = $ans.',
      ],
      hint: 'Repeated addition is multiplication.',
    );
  });

  register('times_table', (c) {
    // Which tables to draw from depends on the skill, so a student stuck on
    // 7/8/9 is not quietly tested on the 2 times table.
    final tables = switch (c.skillId) {
      'tables-2-5-10' => [2, 5, 10],
      'tables-3-4-6' => [3, 4, 6],
      'tables-7-8-9' => [7, 8, 9],
      'tables-to-20' => [11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
      _ => [2, 3, 4, 5, 6, 7, 8, 9],
    };
    final t = c.pick(tables);
    final m = c.int_(2, c.band(10, 12));
    final ans = t * m;
    return Question(
      skillId: c.skillId,
      prompt: '$t x $m = ?',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [ans - t, ans + t, t + m]),
      steps: ['$t x $m means $m groups of $t.', '$t x $m = $ans.'],
      hint: 'If you are stuck, count up in ${t}s.',
    );
  });

  register('mult_column', (c) {
    final twoByTwo = c.skillId.contains('2by2');
    final a = c.int_(twoByTwo ? 11 : 12, twoByTwo ? 99 : 99);
    final b = twoByTwo ? c.int_(11, 99) : c.int_(2, 9);
    final ans = a * b;
    return Question(
      skillId: c.skillId,
      prompt: '$a x $b = ?',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [ans - a, ans + a, ans - b]),
      steps: twoByTwo
          ? [
              'Split $b into ${b ~/ 10} tens and ${b % 10} ones.',
              'First the ones: $a x ${b % 10} = ${a * (b % 10)}.',
              'Now the tens: $a x ${b ~/ 10} = ${a * (b ~/ 10)}.',
              'That row is really tens, so it becomes ${a * (b ~/ 10) * 10}.',
              'Add the two rows: ${a * (b % 10)} + ${a * (b ~/ 10) * 10} = $ans.',
            ]
          : [
              'Ones: ${a % 10} x $b = ${(a % 10) * b}.',
              'Tens: ${a ~/ 10} x $b = ${(a ~/ 10) * b}, that is ${(a ~/ 10) * b * 10}.',
              'Add: ${(a % 10) * b} + ${(a ~/ 10) * b * 10} = $ans.',
            ],
    );
  });

  register('div_concept', (c) {
    final each = c.int_(2, c.band(5, 9));
    final groups = c.int_(2, c.band(5, 9));
    final total = each * groups;
    return Question(
      skillId: c.skillId,
      prompt: '$total sweets are shared equally among $groups children. '
          'How many does each child get?',
      answer: '$each',
      difficulty: c.difficulty,
      choices: c.choicesAround(each, distractors: [groups, total - groups, each + 1]),
      steps: [
        'Sharing equally means divide.',
        '$total / $groups = $each.',
        'Check: $groups x $each = $total.',
      ],
      hint: 'Which number do you split up - the total, or the number of children?',
    );
  });

  register('div_fact', (c) {
    final d = c.int_(2, c.band(6, 12));
    final q = c.int_(2, c.band(6, 12));
    final total = d * q;
    return Question(
      skillId: c.skillId,
      prompt: '$total / $d = ?',
      answer: '$q',
      difficulty: c.difficulty,
      choices: c.choicesAround(q, distractors: [q + 1, q - 1, d]),
      steps: [
        'Ask: $d times what gives $total?',
        '$d x $q = $total, so $total / $d = $q.',
      ],
      hint: 'Division is the table you already know, read backwards.',
    );
  });

  register('div_remainder', (c) {
    final d = c.int_(2, c.band(6, 12));
    final q = c.int_(2, c.band(9, 20));
    final r = c.int_(1, d - 1);
    final total = d * q + r;
    return Question(
      skillId: c.skillId,
      // The format example must never be built from q and r - doing that
      // printed the answer inside the question and the whole sum could be
      // read straight off the screen.
      prompt: '$total / $d = ?\n\n'
          'Give the quotient and the remainder, like  ${_formatExample(q, r)}',
      answer: '$q R $r',
      difficulty: c.difficulty,
      steps: [
        'How many whole ${d}s fit into $total?',
        '$d x $q = ${d * q}, which is the closest without going over.',
        '$total - ${d * q} = $r left over.',
        'So the answer is $q remainder $r.',
      ],
      hint: 'Find the biggest multiple of $d that is not more than $total.',
    );
  });

  register('long_division', (c) {
    final d = c.int_(c.band(2, 11), c.band(9, 25));
    final q = c.int_(c.band(11, 100), c.band(99, 400));
    final exact = c.difficulty <= 2;
    final r = exact ? 0 : c.int_(0, d - 1);
    final total = d * q + r;
    return Question(
      skillId: c.skillId,
      prompt: r == 0
          ? '$total / $d = ?'
          : '$total / $d = ?\n\n'
              'Give the quotient and the remainder, like  '
              '${_formatExample(q, r)}',
      answer: r == 0 ? '$q' : '$q R $r',
      difficulty: c.difficulty,
      steps: [
        'Divide the leftmost digits of $total by $d, write the digit above.',
        'Multiply, subtract, bring down the next digit. Repeat.',
        '$d x $q = ${d * q}${r == 0 ? '' : ', and $total - ${d * q} = $r'}.',
        'Answer: ${r == 0 ? q : '$q remainder $r'}.',
      ],
    );
  });

  register('word_muldiv', (c) {
    final perBox = c.int_(c.band(6, 12), c.band(12, 40));
    final boxes = c.int_(c.band(3, 8), c.band(9, 30));
    final total = perBox * boxes;
    if (c.coin()) {
      return Question(
        skillId: c.skillId,
        prompt: 'A box holds $perBox pens. How many pens are in $boxes boxes?',
        answer: '$total',
        difficulty: c.difficulty,
        choices: c.choicesAround(total, distractors: [perBox + boxes, total - perBox]),
        steps: ['$boxes boxes of $perBox each means multiply.', '$boxes x $perBox = $total.'],
      );
    }
    return Question(
      skillId: c.skillId,
      prompt: '$total pens are packed equally into boxes of $perBox. '
          'How many boxes are needed?',
      answer: '$boxes',
      difficulty: c.difficulty,
      choices: c.choicesAround(boxes, distractors: [perBox, boxes + 1, boxes - 1]),
      steps: ['Splitting a total into equal groups means divide.', '$total / $perBox = $boxes.'],
    );
  });

  register('bodmas', (c) {
    final a = c.int_(2, 12);
    final b = c.int_(2, 9);
    final d = c.int_(2, 9);
    final e = c.int_(2, 6);
    final prod = b * d;
    if (c.difficulty <= 2) {
      final ans = a + prod;
      return Question(
        skillId: c.skillId,
        prompt: '$a + $b x $d = ?',
        answer: '$ans',
        difficulty: c.difficulty,
        choices: c.choicesAround(ans, distractors: [(a + b) * d, a + b + d]),
        steps: [
          'Multiplication comes before addition.',
          '$b x $d = $prod.',
          '$a + $prod = $ans.',
        ],
        hint: 'BODMAS - do the multiplication first, not left to right.',
      );
    }
    final divTotal = e * c.int_(2, 6);
    final ans = a + prod - (divTotal ~/ e);
    return Question(
      skillId: c.skillId,
      prompt: '$a + $b x $d - $divTotal / $e = ?',
      answer: '$ans',
      difficulty: c.difficulty,
      choices: c.choicesAround(ans, distractors: [(a + b) * d, ans + e]),
      steps: [
        'BODMAS: division and multiplication first, left to right.',
        '$b x $d = $prod, and $divTotal / $e = ${divTotal ~/ e}.',
        'Now $a + $prod - ${divTotal ~/ e} = $ans.',
      ],
      hint: 'Do x and / before + and -.',
    );
  });
}

bool _sameOrder(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// A "write it like this" sample for remainder answers.
///
/// Always a fixed pair, swapped for a different one on the rare occasion it
/// would coincide with the real answer. Showing the student's own answer back
/// to them as a formatting hint defeats the question entirely.
String _formatExample(int q, int r) =>
    (q == 7 && r == 3) ? '8 R 2' : '7 R 3';

int _pow10(int n) {
  var v = 1;
  for (var i = 0; i < n; i++) {
    v *= 10;
  }
  return v;
}
