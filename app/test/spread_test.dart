import 'package:flutter_test/flutter_test.dart';
import 'package:sumsheet/catalogue.dart';
import 'package:sumsheet/worksheet_request.dart';

void main() {
  test('the count the slider offers is the count any download delivers',
      () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final catalogue = await Catalogue.load();

    // Small pools are where the promise breaks. Class 1 is full of them.
    for (final ch in catalogue.chaptersFor('1')) {
      final skills = catalogue.playableSkills(ch);
      final limit =
          maxQuestionsFor(skills: skills, difficulty: 3, ceiling: 40);
      for (final seed in [1, 7, 12345, 999999]) {
        final got = spreadQuestions(
          skills: skills,
          count: limit,
          difficulty: 3,
          seed: seed,
        ).length;
        expect(got, limit,
            reason: '${ch.label} offers $limit but seed $seed gives $got');
      }
    }
  });
}
