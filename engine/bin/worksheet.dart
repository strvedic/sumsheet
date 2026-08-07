import 'dart:io';

import 'package:maths_engine/maths_engine.dart';

/// Prints an A4 worksheet PDF, with its answer key, for one skill or chapter.
///
/// This is the teacher's tool. A tuition teacher writes these out by hand every
/// week; the engine can produce an unlimited supply, each one different, with
/// the marking already done.
const _usage = '''
Usage:
  worksheet --skill <id> [options]
  worksheet --class <n> --chapter <n> [--part <n>] [options]
  worksheet --list-classes
  worksheet --list-chapters <class>
  worksheet --list-skills [<class>]

Options:
  --count <n>      Questions on the sheet. Default 20.
  --difficulty <n> 1 (easiest) to 5 (hardest). Default 3.
  --centre <name>  Your name or your institution's, printed at the top.
  --lines <n>      Ruled working lines under each question. Default 2.
  --no-answers     Leave the answer key out.
  --seed <n>       Reproduces an exact sheet. Omit for a fresh one.
  --out <path>     Where to write. Default worksheet.pdf.

Examples:
  worksheet --class 6 --chapter 7 --count 20 --centre "Sri Vidya Tuition"
  worksheet --skill add-2digit-carry --count 24 --lines 3
''';

Future<int> main(List<String> argv) async {
  final args = _Args(argv);
  if (args.flag('help') || argv.isEmpty) {
    stdout.write(_usage);
    return 0;
  }

  final root = _findRoot();
  if (root == null) {
    stderr.writeln('Could not find skill-map.json. Run this from the repo.');
    return 1;
  }
  final map = SkillMap.fromJsonString(
      File('$root/skill-map.json').readAsStringSync());
  final curriculum = Curriculum.fromJsonString(
      File('$root/curriculum/ncert-nep.json').readAsStringSync());

  if (args.flag('list-classes')) {
    for (final c in curriculum.classes) {
      stdout.writeln('Class ${c.classNumber.padRight(3)} '
          '${c.book} (${c.chapters.length} chapters)');
    }
    return 0;
  }

  final listChapters = args.value('list-chapters');
  if (listChapters != null) {
    final cls = curriculum[listChapters];
    if (cls == null) {
      stderr.writeln('No class "$listChapters".');
      return 1;
    }
    stdout.writeln('Class ${cls.classNumber} - ${cls.book}\n');
    for (final ch in cls.chapters) {
      final part = ch.part == null ? '' : 'P${ch.part} ';
      final note = ch.skills.isEmpty ? '  [no skill yet: ${ch.gap}]' : '';
      stdout.writeln('  $part${ch.number.toString().padLeft(2)}. '
          '${ch.title.padRight(42)} ${ch.topic}$note');
    }
    return 0;
  }

  if (args.flag('list-skills')) {
    for (final s in map.all) {
      if (!hasGenerator(s)) continue;
      stdout.writeln('${s.id.padRight(26)} ${s.name}');
    }
    return 0;
  }

  // ------------------------------------------------- which skills to draw on
  final skills = <Skill>[];
  String? label;
  String? heading;

  final skillId = args.value('skill');
  final classId = args.value('class');
  if (skillId != null) {
    if (!map.skills.containsKey(skillId)) {
      stderr.writeln('No skill "$skillId". Try --list-skills.');
      return 1;
    }
    skills.add(map[skillId]);
  } else if (classId != null) {
    final chapterNo = int.tryParse(args.value('chapter') ?? '');
    if (chapterNo == null) {
      stderr.writeln('--class needs --chapter too.');
      return 1;
    }
    final cls = curriculum[classId];
    final ch = cls?.chapter(chapterNo, part: int.tryParse(args.value('part') ?? ''));
    if (ch == null) {
      stderr.writeln('No such chapter. Try --list-chapters $classId.');
      return 1;
    }
    if (ch.skills.isEmpty) {
      stderr.writeln('"${ch.title}" (${ch.topic}) has no skill behind it yet '
          '- gap: ${ch.gap}.\nNothing to print. See curriculum/GAPS.md.');
      return 1;
    }
    label = 'Class ${ch.classNumber}'
        '${ch.part == null ? '' : ' Part ${ch.part}'} - Chapter ${ch.number}';
    heading = ch.title;
    for (final id in ch.skills) {
      final s = map[id];
      if (hasGenerator(s)) skills.add(s);
    }
  } else {
    stderr.writeln('Give either --skill or --class with --chapter.\n');
    stdout.write(_usage);
    return 1;
  }

  // --------------------------------------------------------- build the sheet
  final count = int.tryParse(args.value('count') ?? '') ?? 20;
  final difficulty = int.tryParse(args.value('difficulty') ?? '') ?? 3;
  final seed = int.tryParse(args.value('seed') ?? '') ??
      DateTime.now().millisecondsSinceEpoch % 1000000;

  // Spread the requested count across the chapter's skills, so a chapter sheet
  // covers the chapter rather than hammering whichever skill came first.
  final questions = <Question>[];
  final perSkill = (count / skills.length).ceil();
  for (final s in skills) {
    questions.addAll(generatePractice(
      skill: s,
      count: perSkill,
      difficulty: difficulty,
      seed: seed + s.id.hashCode,
    ));
  }

  if (questions.isEmpty) {
    stderr.writeln('No questions could be generated.');
    return 1;
  }

  // Some skills genuinely cannot fill a sheet - there are only ten numbers to
  // count to. Say so, rather than handing over a short sheet without a word.
  if (questions.length < count) {
    stderr.writeln('Note: asked for $count questions, produced '
        '${questions.length}. ${skills.map((s) => s.id).join(', ')} '
        'cannot make more distinct questions than that at this difficulty.');
  }
  if (questions.length > count) questions.length = count;

  final pdf = await WorksheetBuilder(
    skill: skills.first,
    questions: questions,
    centreName: args.value('centre'),
    heading: heading,
    curriculumLabel: label,
    includeAnswerKey: !args.flag('no-answers'),
    workingLines: int.tryParse(args.value('lines') ?? '') ?? 2,
  ).build();

  final out = File(args.value('out') ?? 'worksheet.pdf');
  await out.writeAsBytes(pdf);
  stdout.writeln('${out.path}  -  ${questions.length} questions, '
      'seed $seed${label == null ? '' : '\n$label'}');
  return 0;
}

/// Walks up from the working directory looking for skill-map.json, so the
/// command works from the repo root or from inside engine/.
String? _findRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 4; i++) {
    if (File('${dir.path}/skill-map.json').existsSync()) return dir.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}

class _Args {
  _Args(List<String> argv) {
    for (var i = 0; i < argv.length; i++) {
      final a = argv[i];
      if (!a.startsWith('--')) continue;
      final name = a.substring(2);
      final next = i + 1 < argv.length ? argv[i + 1] : null;
      if (next != null && !next.startsWith('--')) {
        _values[name] = next;
        i++;
      } else {
        _flags.add(name);
      }
    }
  }

  final _values = <String, String>{};
  final _flags = <String>{};

  String? value(String name) => _values[name];
  bool flag(String name) => _flags.contains(name) || _values.containsKey(name);
}
