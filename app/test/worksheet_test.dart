import 'package:flutter_test/flutter_test.dart';
import 'package:sumsheet/catalogue.dart';
import 'package:sumsheet/worksheet_request.dart';

void main() {
  late Catalogue catalogue;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    catalogue = await Catalogue.load();
  });

  test('every chapter the form offers can actually produce a worksheet',
      () async {
    // A chapter in the dropdown that builds an empty sheet is worse than a
    // chapter that is missing: the teacher only finds out after downloading.
    var checked = 0;
    for (final cls in catalogue.curriculum.classes) {
      for (final ch in catalogue.chaptersFor(cls.classNumber)) {
        final skills = catalogue.playableSkills(ch);
        expect(skills, isNotEmpty, reason: '${ch.label} offered with no skills');
        final built = await buildWorksheet(
          WorksheetRequest(
            skills: skills,
            heading: ch.title,
            curriculumLabel: 'Class ${ch.classNumber}',
            count: 8,
            difficulty: 3,
            centreName: 'Test Centre',
            includeAnswerKey: true,
            // On here on purpose. This is the only test that walks every
            // chapter the form offers, so it is the one place the worked
            // solutions of every reachable skill get put on paper - and the
            // PDF library complains about a character it cannot draw while
            // building the sheet quite happily, which is how the counting
            // objects vanished twice before.
            includeSolutions: true,
            workingLines: 2,
          ),
          seed: 7,
        );
        expect(built.questionCount, greaterThan(0),
            reason: '${ch.label} built an empty sheet');
        expect(built.bytes.length, greaterThan(1000));
        expect(built.filename, endsWith('.pdf'));
        checked++;
      }
    }
    expect(checked, greaterThan(100),
        reason: 'expected most of the 155 chapters to be playable');
  });

  test('the offered question limit is one the chapter can really meet',
      () async {
    // Class 1 chapter 3 is digit recognition and counting to ten, which is a
    // small pool. The form must not offer more than the pool holds.
    final ch = catalogue.chaptersFor('1').firstWhere((c) => c.number == 3);
    final skills = catalogue.playableSkills(ch);
    final limit =
        maxQuestionsFor(skills: skills, difficulty: 3, ceiling: 40);

    final built = await buildWorksheet(
      WorksheetRequest(
        skills: skills,
        heading: ch.title,
        curriculumLabel: 'Class 1',
        count: limit,
        difficulty: 3,
        centreName: null,
        includeAnswerKey: true,
        includeSolutions: false,
        workingLines: 2,
      ),
      seed: 7,
    );
    expect(built.questionCount, limit,
        reason: 'the form offered $limit but only ${built.questionCount} came '
            'out, which is the promise the slider makes being broken');
  });
}
