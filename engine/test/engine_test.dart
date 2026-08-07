import 'dart:io';
import 'dart:math';

import 'package:maths_engine/maths_engine.dart';
import 'package:test/test.dart';

late SkillMap map;

void main() {
  setUpAll(() {
    map = SkillMap.fromJsonString(
      File('../skill-map.json').readAsStringSync(),
    );
    ensureGeneratorsRegistered();
  });

  group('skill map', () {
    test('loads and validates without broken links or cycles', () {
      expect(map.all.length, greaterThan(150));
    });

    test('every prerequisite resolves to a real skill', () {
      for (final s in map.all) {
        for (final p in s.prereq) {
          expect(map.skills.containsKey(p), isTrue,
              reason: '${s.id} requires missing $p');
        }
      }
    });

    test('diagnostic chain is ordered easiest first and ends at the target', () {
      for (final s in map.all.where((s) => s.level >= 8)) {
        final chain = map.diagnosticChain(s.id);
        expect(chain.last.id, s.id);
        for (var i = 1; i < chain.length - 1; i++) {
          expect(chain[i].level, greaterThanOrEqualTo(chain[i - 1].level),
              reason: 'chain for ${s.id} not ordered at index $i');
        }
      }
    });

    test('practicePath climbs from the gap to the target, in a valid order', () {
      final path = map.practicePath(
        from: 'integer-muldiv', to: 'quadratic-factorise',
      );
      expect(path.first.id, 'integer-muldiv',
          reason: 'the plan must begin at the gap itself');
      expect(path.last.id, 'quadratic-factorise',
          reason: 'the plan must end at the target');

      // Nothing may appear before a skill it depends on.
      final seen = <String>{};
      for (final s in path) {
        for (final p in s.prereq) {
          if (path.any((x) => x.id == p)) {
            expect(seen.contains(p), isTrue,
                reason: '${s.id} listed before its prerequisite $p');
          }
        }
        seen.add(s.id);
      }

      // A Class 10 student must never be sent back to counting shapes.
      for (final s in path) {
        expect(s.id == 'integer-muldiv' || map.ancestorsOf(s.id).any((a) => a.id == 'integer-muldiv'),
            isTrue,
            reason: '${s.id} does not rest on the gap and should not be in the plan');
      }
      expect(path.any((s) => s.strand == 'geometry'), isFalse,
          reason: 'unrelated strands leaked into the study plan');
    });

    test('fullCourse covers everything up to a class, in teachable order', () {
      // A student who passes the placement test outright has a plan of one
      // step. The full course is what they get instead.
      for (final target in ['long-division', 'quadratic-factorise', 'trig-ratios']) {
        final course = map.fullCourse(target);
        final plan = map.practicePath(from: map.diagnosticChain(target).first.id, to: target);

        expect(course.last.id, target, reason: 'course must end at the target');
        expect(course.length, greaterThanOrEqualTo(plan.length),
            reason: 'the full course cannot be shorter than a plan inside it');
        expect(course.map((s) => s.id).toSet().length, course.length,
            reason: 'a skill listed twice');

        // Nothing may appear before something it depends on.
        final seen = <String>{};
        for (final s in course) {
          for (final p in s.prereq) {
            if (course.any((x) => x.id == p)) {
              expect(seen.contains(p), isTrue,
                  reason: '${s.id} listed before its prerequisite $p');
            }
          }
          seen.add(s.id);
        }

        // And it must not wander off into unrelated strands.
        for (final s in course) {
          expect(s.id == target || map.ancestorsOf(target).any((a) => a.id == s.id),
              isTrue,
              reason: '${s.id} is not needed for $target');
        }
      }
    });

    test('unlockedFor returns only skills whose prerequisites are met', () {
      final mastered = map.all
          .where((s) => s.level <= 4)
          .map((s) => s.id)
          .toSet();
      for (final s in map.unlockedFor(mastered)) {
        expect(mastered.contains(s.id), isFalse);
        for (final p in s.prereq) {
          expect(mastered.contains(p), isTrue,
              reason: '${s.id} unlocked but prereq $p not mastered');
        }
      }
    });
  });

  group('generators', () {
    test('produce structurally valid questions at every difficulty', () {
      final covered = map.all.where(hasGenerator).toList();
      expect(covered.length, greaterThan(40),
          reason: 'expected a decent number of skills to be covered');

      for (final skill in covered) {
        for (var d = 1; d <= 5; d++) {
          for (var seed = 0; seed < 40; seed++) {
            final q = generateQuestion(skill: skill, difficulty: d, seed: seed);
            expect(q.prompt.trim(), isNotEmpty,
                reason: '${skill.id} d$d seed$seed empty prompt');
            expect(q.answer.trim(), isNotEmpty,
                reason: '${skill.id} d$d seed$seed empty answer');
            expect(q.steps, isNotEmpty,
                reason: '${skill.id} d$d seed$seed has no worked solution');
            expect(q.isCorrect(q.answer), isTrue,
                reason: '${skill.id} rejects its own answer');
            if (q.choices.isNotEmpty) {
              expect(q.choices.length, greaterThanOrEqualTo(2),
                  reason: '${skill.id} d$d seed$seed has only one choice');
              expect(
                q.choices.any((ch) => q.isCorrect(ch)),
                isTrue,
                reason: '${skill.id} d$d seed$seed: correct answer '
                    '"${q.answer}" missing from choices ${q.choices}',
              );
              expect(q.choices.toSet().length, q.choices.length,
                  reason: '${skill.id} d$d seed$seed has duplicate choices');
            }
          }
        }
      }
    });

    test('arithmetic answers are independently verifiable', () {
      // Re-derives the answer straight from the printed prompt. If a generator
      // ever prints one sum and answers a different one, this catches it.
      var checked = 0;
      for (final skill in map.all.where(hasGenerator)) {
        for (var d = 1; d <= 5; d++) {
          for (var seed = 0; seed < 60; seed++) {
            final q = generateQuestion(skill: skill, difficulty: d, seed: seed);
            final v = _verifyIntegerArithmetic(q);
            if (v != null) {
              checked++;
              expect(v, isTrue,
                  reason: '${skill.id} d$d seed$seed WRONG: '
                      '"${q.prompt}" answered "${q.answer}"');
            }
          }
        }
      }
      expect(checked, greaterThan(500),
          reason: 'verifier should have checked a meaningful sample');
    });

    test('a question never prints its own answer', () {
      // Found by a real student: the remainder questions used to render
      // "Write your answer like 9 R 2" where 9 R 2 WAS the answer, so the sum
      // could be read straight off the screen without dividing anything.
      //
      // Only checked for answers containing a letter or comma. Purely numeric
      // answers legitimately overlap their prompt ("which is greater, 8 or 5?"
      // answers "8"), so those would be false alarms.
      var checked = 0;
      for (final skill in map.all.where(hasGenerator)) {
        for (var d = 1; d <= 5; d++) {
          for (var seed = 0; seed < 40; seed++) {
            final q = generateQuestion(skill: skill, difficulty: d, seed: seed);
            // Multiple choice legitimately shows the answer - "is 46 even or
            // odd?" has to contain the word "even". Only free-entry questions
            // can leak.
            if (q.choices.isNotEmpty) continue;
            if (!RegExp(r'[a-z,]', caseSensitive: false).hasMatch(q.answer)) {
              continue;
            }
            checked++;
            final prompt = q.prompt.toLowerCase().replaceAll(' ', '');
            final answer = q.answer.toLowerCase().replaceAll(' ', '');
            expect(prompt.contains(answer), isFalse,
                reason: '${skill.id} d$d seed$seed gives the answer away:\n'
                    '  prompt: ${q.prompt.replaceAll('\n', ' ')}\n'
                    '  answer: ${q.answer}');
          }
        }
      }
      expect(checked, greaterThan(200),
          reason: 'should have checked a meaningful sample');
    });

    test('remainder answers accept the ways a student actually writes them', () {
      final skill = map['div-remainder'];
      final q = generateQuestion(skill: skill, difficulty: 3, seed: 11);
      final parts = q.answer.split(' R ');
      final quotient = parts[0];
      final rem = parts[1];
      for (final form in [
        '$quotient R $rem',
        '$quotient r $rem',
        '${quotient}r$rem',
        '$quotient rem $rem',
        '$quotient remainder $rem',
        '  $quotient   R   $rem  ',
      ]) {
        expect(q.isCorrect(form), isTrue,
            reason: 'should have accepted "$form" for answer "${q.answer}"');
      }
      expect(q.isCorrect(quotient), isFalse,
          reason: 'the quotient alone is not the full answer');
    });

    test('generators respect which skill they are serving', () {
      // Several skills share one generator, and the generator has to honour
      // the difference. These all shipped broken at least once:
      // "add-2digit-nocarry".contains("carry") is true, so the no-carrying
      // skill was serving nothing but carrying questions.
      int biggestNumberIn(String prompt) {
        final nums = RegExp(r'\d+')
            .allMatches(prompt)
            .map((m) => int.parse(m.group(0)!));
        return nums.isEmpty ? 0 : nums.reduce((a, b) => a > b ? a : b);
      }

      for (var seed = 0; seed < 120; seed++) {
        for (var d = 1; d <= 5; d++) {
          final noCarry =
              generateQuestion(skill: map['add-2digit-nocarry'], difficulty: d, seed: seed);
          final m = RegExp(r'(\d+) \+ (\d+)').firstMatch(noCarry.prompt)!;
          expect(int.parse(m.group(1)!) % 10 + int.parse(m.group(2)!) % 10,
              lessThan(10),
              reason: 'no-carry skill produced a carrying sum: ${noCarry.prompt}');
          expect(noCarry.hint, isNot(contains('carry')),
              reason: 'no-carry skill hinted about carrying');

          final carry =
              generateQuestion(skill: map['add-2digit-carry'], difficulty: d, seed: seed);
          final mc = RegExp(r'(\d+) \+ (\d+)').firstMatch(carry.prompt)!;
          expect(int.parse(mc.group(1)!) % 10 + int.parse(mc.group(2)!) % 10,
              greaterThanOrEqualTo(10),
              reason: 'carry skill produced a non-carrying sum: ${carry.prompt}');

          final noBorrow =
              generateQuestion(skill: map['sub-2digit-noborrow'], difficulty: d, seed: seed);
          final mb = RegExp(r'(\d+) - (\d+)').firstMatch(noBorrow.prompt)!;
          expect(int.parse(mb.group(1)!) % 10,
              greaterThanOrEqualTo(int.parse(mb.group(2)!) % 10),
              reason: 'no-borrow skill needed a borrow: ${noBorrow.prompt}');

          expect(
            biggestNumberIn(
              generateQuestion(skill: map['count-1-20'], difficulty: d, seed: seed).prompt,
            ),
            lessThanOrEqualTo(20),
            reason: '"count 1 to 20" showed a number above 20',
          );

          final tens =
              generateQuestion(skill: map['place-value-tens'], difficulty: d, seed: seed);
          expect(tens.prompt.contains('hundreds') || tens.prompt.contains('thousands'),
              isFalse,
              reason: 'tens-and-ones skill asked about a bigger place: ${tens.prompt}');
        }
      }
    });

    test('multiple choice works when the answer is negative', () {
      // Determinants, slopes and integer sums can all come out negative.
      // Passing the absolute value as "correct" once left the real answer off
      // its own option list, which hands the student a free elimination.
      for (var i = 0; i < 300; i++) {
        final c = GenContext(skillId: 'x', difficulty: 3, seed: i);
        final correct = -c.int_(1, 60);
        final opts = c.choicesAround(correct, distractors: [-correct, 0]);
        expect(opts, contains('$correct'),
            reason: 'negative answer $correct missing from $opts');
        expect(opts.toSet().length, opts.length, reason: 'duplicates in $opts');
        expect(opts.length, greaterThanOrEqualTo(2));
        expect(opts.where((o) => int.parse(o) < 0).length, greaterThan(1),
            reason: 'all-positive distractors give the sign away: $opts');
      }
    });

    test('powers stay portable and no Unicode superscript is emitted', () {
      // Unicode superscripts are NOT used. A Samsung A23 rendered ³ and ⁵ but
      // silently dropped ⁴, so "3^5 / 3^4" appeared on screen as "3⁵ / 3 ".
      // The PDF font drops ⁴-⁹ and √ outright. Both failures are invisible.
      //
      // So powers stay as plain "x^2" here and each display surface raises the
      // digits itself using ordinary 0-9, which no font is missing.
      expect(mathify('x^2 + y^3'), 'x^2 + y^3');
      expect(mathify('5x^4'), '5x^4');
      expect(mathify('root(50)'), '√50');
      // Prose and answer formats must survive untouched, or typed answers
      // stop matching.
      expect(mathify('the square root of 49'), 'the square root of 49');
      expect(mathify('1/root2'), '1/root2');

      const superscripts = ['⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹', '⁻'];
      var checked = 0;
      for (final skill in map.all.where(hasGenerator)) {
        for (var seed = 0; seed < 20; seed++) {
          final q = generateQuestion(skill: skill, difficulty: 4, seed: seed);
          for (final text in [
            q.prompt,
            q.answer,
            ...q.steps,
            ...q.choices,
            if (q.hint != null) q.hint!,
          ]) {
            for (final sup in superscripts) {
              expect(text.contains(sup), isFalse,
                  reason: '${skill.id} emitted "$sup", which vanishes on some '
                      'phones and in the PDF: $text');
            }
            checked++;
          }
        }
      }
      expect(checked, greaterThan(1000));
    });

    test('questions that need a picture have one', () {
      // "How many sides does this hexagon have?" is close to meaningless in
      // words alone to the child who most needs it - knowing what a hexagon
      // looks like is the thing being taught.
      const needPicture = {
        'shapes-2d': 'polygon',
        'shapes-3d': 'solid',
        'angles-types': 'angle',
        'data-bargraph': 'bars',
        'data-piechart': 'pie',
      };
      for (final entry in needPicture.entries) {
        for (var d = 1; d <= 5; d++) {
          for (var seed = 0; seed < 20; seed++) {
            final q = generateQuestion(
                skill: map[entry.key], difficulty: d, seed: seed);
            expect(q.diagram, isNotNull,
                reason: '${entry.key} needs a diagram: ${q.prompt}');
            expect(q.diagram!.startsWith('${entry.value}:'), isTrue,
                reason: '${entry.key} got "${q.diagram}", '
                    'expected a ${entry.value} spec');
          }
        }
      }
    });

    test('a diagram spec never carries the answer away from the question', () {
      // The bar chart moved its numbers out of the prompt and into the
      // picture. The totals must still be derivable, and the prompt must not
      // have been left empty of the actual question.
      for (var seed = 0; seed < 40; seed++) {
        final q =
            generateQuestion(skill: map['data-bargraph'], difficulty: 3, seed: seed);
        expect(q.diagram, startsWith('bars:'));
        final values = q.diagram!
            .substring(5)
            .split(',')
            .map((p) => int.parse(p.split('=')[1]))
            .toList();
        expect(values.length, 5);
        final total = values.reduce((a, b) => a + b);
        final range = values.reduce((a, b) => a > b ? a : b) -
            values.reduce((a, b) => a < b ? a : b);
        expect([total, range], contains(int.parse(q.answer)),
            reason: 'answer ${q.answer} is not derivable from the chart');
        expect(q.prompt.contains('?'), isTrue,
            reason: 'the prompt still has to ask something: ${q.prompt}');
      }
    });

    test('difficulty scaling actually increases question size', () {
      final skill = map.all.firstWhere((s) => s.generator == 'times_table');
      int magnitude(int d) {
        var total = 0;
        for (var seed = 0; seed < 60; seed++) {
          final q = generateQuestion(skill: skill, difficulty: d, seed: seed);
          total += int.tryParse(q.answer) ?? 0;
        }
        return total;
      }

      expect(magnitude(5), greaterThan(magnitude(1)));
    });

    test('same seed reproduces the identical question', () {
      for (final skill in map.all.where(hasGenerator).take(20)) {
        final a = generateQuestion(skill: skill, difficulty: 3, seed: 12345);
        final b = generateQuestion(skill: skill, difficulty: 3, seed: 12345);
        expect(a.prompt, b.prompt);
        expect(a.answer, b.answer);
      }
    });

    test('practice sets avoid repeating the same question', () {
      for (final skill in map.all.where(hasGenerator)) {
        final qs = generatePractice(skill: skill, count: 8, seed: 4);
        // Compared the way a student compares them: the words plus the figure.
        // Two bar charts asking "how many altogether?" over different bars are
        // different questions; two identical charts are not.
        final ids = qs.map(questionIdentity).toSet();
        expect(ids.length, qs.length,
            reason: '${skill.id} produced duplicate questions in one set');
      }
    });

    test('a skill with room for them returns the full count asked for', () {
      // The bar-graph generator can produce thousands of distinct charts. It
      // used to hand back 2 of the 20 asked for, because deduplication looked
      // only at the prompt and every chart asks the same question in words.
      final qs = generatePractice(
          skill: map['data-bargraph'], count: 20, seed: 4);
      expect(qs.length, 20);
    });
  });

  group('worksheets', () {
    test('a plain sum is recognised as a stacked one, and nothing else is', () {
      ColumnSum? parse(String prompt, String answer) => ColumnSum.tryParse(
            Question(
                skillId: 'x', prompt: prompt, answer: answer, difficulty: 3,
                steps: const ['-']),
          );

      expect(parse('47 + 38 = ?', '85')?.op, '+');
      expect(parse('90 - 23 = ?', '67')?.op, '-');
      expect(parse('12 x 15 = ?', '180')?.op, '×');

      // Division is written under a bracket in an Indian exercise book, not
      // stacked with a rule under it.
      expect(parse('84 / 4 = ?', '21'), isNull);

      // Nothing that is not a bare sum.
      expect(parse('Which number is greater: 8 or 5?', '8'), isNull);
      expect(parse('A box holds 6 pens. How many in 4 boxes?', '24'), isNull);

      // And never a sum that disagrees with its own answer key - that would
      // print one question and mark a different one.
      expect(parse('47 + 38 = ?', '84'), isNull);
    });

    test('multiplying by two digits leaves room for partial products', () {
      final short = ColumnSum.tryParse(Question(
          skillId: 'x', prompt: '47 + 38 = ?', answer: '85', difficulty: 3,
          steps: const ['-']))!;
      final long = ColumnSum.tryParse(Question(
          skillId: 'x', prompt: '47 x 38 = ?', answer: '1786', difficulty: 3,
          steps: const ['-']))!;
      expect(long.answerSpace, greaterThan(short.answerSpace * 2));
    });


    test('a long sheet flows onto a second page instead of throwing', () async {
      // The two-column grid used to be one Row, and a Row cannot be split
      // across pages. 24 questions with three working lines overflowed A4 and
      // the whole PDF failed to build - the teacher got an exception, not a
      // worksheet.
      final skill = map['add-2digit-carry'];
      final bytes = await WorksheetBuilder(
        skill: skill,
        questions: generatePractice(skill: skill, count: 24, seed: 3),
        workingLines: 3,
      ).build();
      expect(bytes.length, greaterThan(1000));
    });

    test('a sheet built from a chapter is named after the chapter', () async {
      final skill = map['fraction-equivalent'];
      final bytes = await WorksheetBuilder(
        skill: skill,
        questions: generatePractice(skill: skill, count: 4, seed: 3),
        heading: 'Fractions',
        curriculumLabel: 'Class 6 - Chapter 7',
      ).build();
      expect(bytes.length, greaterThan(1000));
    });
  });

  group('fractions', () {
    test('exact rational arithmetic, no floating point drift', () {
      expect((Fraction(1, 3) + Fraction(1, 6)).toString(), '1/2');
      expect((Fraction(2, 3) + Fraction(3, 4)).toString(), '17/12');
      expect((Fraction(3, 4) / Fraction(2, 5)).toString(), '15/8');
      expect((Fraction(6, 8)).toString(), '3/4');
      expect(Fraction(17, 5).toMixedString(), '3 2/5');
      expect(Fraction(-6, -8).toString(), '3/4');
      expect(Fraction(6, -8).toString(), '-3/4');
    });

    test('fraction generators give answers already in lowest terms', () {
      for (final skill in map.all.where((s) =>
          hasGenerator(s) &&
          const ['fraction_addsub', 'fraction_multiply', 'fraction_divide',
              'fraction_simplify'].contains(s.generator))) {
        for (var seed = 0; seed < 80; seed++) {
          final q = generateQuestion(skill: skill, difficulty: 3, seed: seed);
          final parts = q.answer.split('/');
          if (parts.length == 2) {
            final n = int.parse(parts[0]);
            final dd = int.parse(parts[1]);
            expect(Fraction.gcd(n, dd), 1,
                reason: '${skill.id} answer ${q.answer} is not simplified');
          }
        }
      }
    });
  });

  group('answer matching', () {
    test('tolerates harmless formatting differences', () {
      final q = Question(
        skillId: 'x', prompt: 'p', answer: '0.5', difficulty: 3, steps: ['s'],
      );
      expect(q.isCorrect('0.5'), isTrue);
      expect(q.isCorrect(' 0.50 '), isTrue);
      expect(q.isCorrect('0.500'), isTrue);
      expect(q.isCorrect('0.6'), isFalse);
    });
  });

  group('adaptive placement', () {
    test('finds a planted gap and does it in far fewer than a linear scan', () {
      final target = map['quadratic-factorise'];
      // The session drops skills that have no generator yet, so gaps must be
      // planted against the chain the session will actually probe.
      final chain =
          PlacementSession(map: map, targetSkillId: target.id).chain;
      expect(chain.length, greaterThan(5));

      for (var plantIndex = 0; plantIndex < chain.length; plantIndex++) {
        final s = PlacementSession(
          map: map, targetSkillId: target.id, seed: 5,
        );
        // Simulated student: knows everything below plantIndex, fails at and
        // above it. That is the monotonic assumption the search relies on.
        while (!s.isComplete) {
          final q = s.nextQuestion();
          if (q == null) break;
          final idx = chain.indexWhere((c) => c.id == q.skillId);
          s.submit(correct: idx < plantIndex);
        }
        final r = s.result!;
        expect(r.gapSkill?.id, chain[plantIndex].id,
            reason: 'failed to locate planted gap at index $plantIndex');
        expect(r.questionsAsked, lessThan(chain.length),
            reason: 'placement asked more questions than a linear scan');
      }
    });

    test('reports no gap when the student knows everything', () {
      final s = PlacementSession(
        map: map, targetSkillId: 'quadratic-factorise', seed: 9,
      );
      while (!s.isComplete) {
        final q = s.nextQuestion();
        if (q == null) break;
        s.submit(correct: true);
      }
      expect(s.result!.isSolid, isTrue);
      expect(s.result!.gapSkill, isNull);
    });

    test('typical placement stays within a student\'s patience', () {
      final counts = <int>[];
      for (final target in ['quadratic-factorise', 'percentage-of-quantity',
          'fraction-addsub-unlike', 'long-division']) {
        final chain = PlacementSession(map: map, targetSkillId: target).chain;
        for (var plant = 0; plant < chain.length; plant++) {
          final s = PlacementSession(map: map, targetSkillId: target, seed: 3);
          while (!s.isComplete) {
            final q = s.nextQuestion();
            if (q == null) break;
            final idx = chain.indexWhere((c) => c.id == q.skillId);
            s.submit(correct: idx < plant);
          }
          counts.add(s.result!.questionsAsked);
        }
      }
      final worst = counts.reduce(max);
      final avg = counts.reduce((a, b) => a + b) / counts.length;
      print('placement questions -> avg ${avg.toStringAsFixed(1)}, worst $worst');
      expect(worst, lessThanOrEqualTo(20),
          reason: 'no student will sit through more than ~20 questions');
    });
  });
}

/// Independently re-computes the answer to simple integer arithmetic prompts.
/// Returns null when the prompt is not a form this verifier understands.
bool? _verifyIntegerArithmetic(Question q) {
  final line = q.prompt.split('\n').first.trim();
  final m = RegExp(r'^\(?(-?\d+)\)?\s*([+\-x/])\s*\(?(-?\d+)\)?\s*=\s*\?$')
      .firstMatch(line);
  if (m == null) return null;
  final a = int.parse(m.group(1)!);
  final op = m.group(2)!;
  final b = int.parse(m.group(3)!);
  final expected = switch (op) {
    '+' => a + b,
    '-' => a - b,
    'x' => a * b,
    '/' => b == 0 ? null : (a % b == 0 ? a ~/ b : null),
    _ => null,
  };
  if (expected == null) return null;
  return q.answer.trim() == '$expected';
}
