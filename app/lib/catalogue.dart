import 'package:flutter/services.dart' show rootBundle;
import 'package:maths_engine/maths_engine.dart';

/// Everything the app needs to offer a worksheet, loaded once at startup.
///
/// The skill map and the NCERT chapter list are bundled as assets rather than
/// fetched, so the page works the first time it opens and keeps working if the
/// connection does not.
class Catalogue {
  Catalogue._(this.skills, this.curriculum);

  static Future<Catalogue> load() async {
    ensureGeneratorsRegistered();
    final skills = SkillMap.fromJsonString(
      await rootBundle.loadString('assets/skill-map.json'),
    );
    final curriculum = Curriculum.fromJsonString(
      await rootBundle.loadString('assets/ncert-nep.json'),
    );
    return Catalogue._(skills, curriculum);
  }

  final SkillMap skills;
  final Curriculum curriculum;

  /// Chapters a worksheet can actually be made from.
  ///
  /// A chapter whose skills have no generator yet would produce an empty sheet,
  /// so it is not offered at all. Better to be short a chapter than to hand a
  /// teacher a blank page.
  List<Chapter> chaptersFor(String classNumber) {
    final cls = curriculum[classNumber];
    if (cls == null) return const [];
    return [
      for (final ch in cls.chapters)
        if (playableSkills(ch).isNotEmpty) ch,
    ];
  }

  List<Skill> playableSkills(Chapter ch) => [
        for (final id in ch.skills)
          if (skills.skills.containsKey(id) && hasGenerator(skills[id]))
            skills[id],
      ];

}
