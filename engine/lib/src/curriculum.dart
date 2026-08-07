import 'dart:convert';

/// The NCERT chapter listing, as an overlay on the skill map.
///
/// This exists so a teacher can ask for "Class 6, Chapter 7" instead of
/// "fraction-equivalent". It never defines a skill and never overrides an
/// ability level - it only says which skills a chapter touches.
class Curriculum {
  Curriculum._(this.board, this.edition, this.classes);

  factory Curriculum.fromJsonString(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    return Curriculum._(
      j['board'] as String,
      j['edition'] as String,
      [
        for (final c in (j['classes'] as List))
          CurriculumClass._fromJson(c as Map<String, dynamic>),
      ],
    );
  }

  final String board;
  final String edition;
  final List<CurriculumClass> classes;

  CurriculumClass? operator [](String classNumber) {
    for (final c in classes) {
      if (c.classNumber == classNumber) return c;
    }
    return null;
  }
}

class CurriculumClass {
  CurriculumClass._(this.classNumber, this.book, this.chapters);

  factory CurriculumClass._fromJson(Map<String, dynamic> j) =>
      CurriculumClass._(
        j['class'] as String,
        j['book'] as String,
        [
          for (final c in (j['chapters'] as List))
            Chapter._fromJson(c as Map<String, dynamic>, j['class'] as String),
        ],
      );

  final String classNumber;
  final String book;
  final List<Chapter> chapters;

  /// Chapters are numbered per part in two-part books, so Class 7 has two
  /// chapter 1s. [part] disambiguates; omit it for single-part books.
  Chapter? chapter(int number, {int? part}) {
    for (final c in chapters) {
      if (c.number == number && (part == null || c.part == part)) return c;
    }
    return null;
  }
}

class Chapter {
  Chapter._({
    required this.classNumber,
    required this.number,
    required this.part,
    required this.title,
    required this.topic,
    required this.skills,
    required this.gap,
  });

  factory Chapter._fromJson(Map<String, dynamic> j, String classNumber) =>
      Chapter._(
        classNumber: classNumber,
        number: j['no'] as int,
        part: j['part'] as int?,
        title: j['title'] as String,
        topic: j['topic'] as String,
        skills: [for (final s in (j['skills'] as List)) s as String],
        gap: j['gap'] as String?,
      );

  final String classNumber;
  final int number;

  /// Which part of a two-part book, or null for a single-volume class.
  final int? part;

  final String title;

  /// What the chapter actually teaches. For Classes 3 to 5 the title is a
  /// story name - "Coconut Farm" is division - so this is the useful field.
  final String topic;

  final List<String> skills;

  /// Set when the chapter teaches something no skill covers yet. Such a
  /// chapter can still be listed, but cannot produce a worksheet.
  final String? gap;

  /// The line printed across the top of a worksheet.
  String get label => part == null
      ? 'Class $classNumber - Chapter $number: $title'
      : 'Class $classNumber Part $part - Chapter $number: $title';
}
