import 'dart:convert';

/// One node in the maths skill ladder.
class Skill {
  Skill({
    required this.id,
    required this.name,
    required this.strand,
    required this.level,
    required this.prereq,
    required this.typicalClass,
    required this.generator,
    required this.critical,
    required this.sample,
  });

  factory Skill.fromJson(Map<String, dynamic> j) => Skill(
        id: j['id'] as String,
        name: j['name'] as String,
        strand: j['strand'] as String,
        level: j['level'] as int,
        prereq: (j['prereq'] as List).cast<String>(),
        typicalClass: j['typical_class'] as String? ?? '',
        generator: j['generator'] as String? ?? '',
        critical: j['critical'] as bool? ?? false,
        sample: j['sample'] as String? ?? '',
      );

  final String id;
  final String name;
  final String strand;
  final int level;
  final List<String> prereq;
  final String typicalClass;
  final String generator;

  /// Gateway skill. If this is broken, everything above it collapses.
  final bool critical;
  final String sample;
}

/// The skill graph, plus the queries the app needs to run against it.
class SkillMap {
  SkillMap._(this.skills, this.levels, this.strands);

  factory SkillMap.fromJsonString(String source) {
    final j = jsonDecode(source) as Map<String, dynamic>;
    final skills = <String, Skill>{};
    for (final raw in (j['skills'] as List)) {
      final s = Skill.fromJson(raw as Map<String, dynamic>);
      skills[s.id] = s;
    }
    final levels = (j['levels'] as Map).map(
      (k, v) => MapEntry(int.parse(k as String), v as String),
    );
    final strands = (j['strands'] as Map).cast<String, dynamic>().map(
          (k, v) => MapEntry(k, v as String),
        );
    final map = SkillMap._(skills, levels, strands);
    map._validate();
    return map;
  }

  final Map<String, Skill> skills;
  final Map<int, String> levels;
  final Map<String, String> strands;

  Skill operator [](String id) {
    final s = skills[id];
    if (s == null) throw ArgumentError('Unknown skill: $id');
    return s;
  }

  Iterable<Skill> get all => skills.values;

  /// Fails loudly at load time rather than producing a broken placement test
  /// in front of a real student.
  void _validate() {
    for (final s in skills.values) {
      for (final p in s.prereq) {
        if (!skills.containsKey(p)) {
          throw StateError('Skill "${s.id}" requires unknown skill "$p"');
        }
      }
    }
    for (final s in skills.values) {
      _detectCycle(s.id, <String>{}, <String>[]);
    }
  }

  void _detectCycle(String id, Set<String> onPath, List<String> trail) {
    if (onPath.contains(id)) {
      throw StateError('Circular prerequisite: ${[...trail, id].join(" -> ")}');
    }
    onPath.add(id);
    trail.add(id);
    for (final p in skills[id]!.prereq) {
      _detectCycle(p, onPath, trail);
    }
    onPath.remove(id);
    trail.removeLast();
  }

  /// Every skill [id] transitively depends on, nearest first.
  List<Skill> ancestorsOf(String id) {
    final seen = <String>{};
    final out = <Skill>[];
    void walk(String cur) {
      for (final p in skills[cur]!.prereq) {
        if (seen.add(p)) {
          out.add(skills[p]!);
          walk(p);
        }
      }
    }

    walk(id);
    return out;
  }

  /// Skills that directly list [id] as a prerequisite.
  List<Skill> dependentsOf(String id) =>
      all.where((s) => s.prereq.contains(id)).toList();

  /// The foundation chain to search when a student fails [id].
  ///
  /// Ordered easiest-first and restricted to gateway skills, because those are
  /// the ones actually worth testing. Searching all 25 ancestors linearly would
  /// exhaust the student; this list is what the binary search runs over.
  List<Skill> diagnosticChain(String id) {
    final chain = ancestorsOf(id).where((s) => s.critical).toList()
      ..sort((a, b) {
        final byLevel = a.level.compareTo(b.level);
        return byLevel != 0 ? byLevel : a.id.compareTo(b.id);
      });
    chain.add(skills[id]!);
    return chain;
  }

  /// All skills a student is ready for: every prerequisite already mastered,
  /// and this one not yet mastered.
  List<Skill> unlockedFor(Set<String> mastered) => all
      .where((s) =>
          !mastered.contains(s.id) && s.prereq.every(mastered.contains))
      .toList()
    ..sort((a, b) => a.level.compareTo(b.level));

  /// The ordered climb from a student's gap back up to where they are meant
  /// to be.
  ///
  /// This is the actual study plan. It deliberately contains only skills that
  /// lie between the gap and the target - a Class 10 student with a sign-rules
  /// gap gets sign rules, then the algebra that depends on it. They do not get
  /// sent back to counting shapes, which would be both useless and humiliating.
  List<Skill> practicePath({required String from, required String to}) {
    final upTo = <String>{to, ...ancestorsOf(to).map((s) => s.id)};

    bool restsOn(String id) =>
        id == from || ancestorsOf(id).any((a) => a.id == from);

    return _teachingOrder(upTo.where(restsOn).toSet());
  }

  /// Everything needed to reach [targetId], including it, in teaching order.
  ///
  /// This is the whole course up to a student's class, as opposed to
  /// [practicePath] which is only the stretch above their gap. Needed because
  /// a student who passes the placement test outright has almost no plan -
  /// and "you have no gaps" should open up the full course, not leave them
  /// with nothing to do.
  List<Skill> fullCourse(String targetId) =>
      _teachingOrder({targetId, ...ancestorsOf(targetId).map((s) => s.id)});

  /// Kahn's algorithm over the induced subgraph, so a skill never appears
  /// before something it depends on.
  List<Skill> _teachingOrder(Set<String> nodes) {
    final indegree = {
      for (final id in nodes)
        id: skills[id]!.prereq.where(nodes.contains).length,
    };
    final ready = nodes.where((id) => indegree[id] == 0).toList()
      ..sort(_byLevelThenId);

    final out = <Skill>[];
    while (ready.isNotEmpty) {
      final id = ready.removeAt(0);
      out.add(skills[id]!);
      for (final dep in dependentsOf(id)) {
        if (!nodes.contains(dep.id)) continue;
        indegree[dep.id] = indegree[dep.id]! - 1;
        if (indegree[dep.id] == 0) {
          ready
            ..add(dep.id)
            ..sort(_byLevelThenId);
        }
      }
    }
    return out;
  }

  int _byLevelThenId(String a, String b) {
    final byLevel = skills[a]!.level.compareTo(skills[b]!.level);
    return byLevel != 0 ? byLevel : a.compareTo(b);
  }
}
