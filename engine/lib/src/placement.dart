import 'engine_api.dart';
import 'question.dart';
import 'skill_map.dart';

/// What the placement test concluded.
class PlacementResult {
  PlacementResult({
    required this.gapSkill,
    required this.masteredUpTo,
    required this.questionsAsked,
    required this.chain,
  });

  /// The first broken skill found, or null if the student is solid all the way
  /// up and the target skill itself was fine.
  final Skill? gapSkill;

  /// The last skill they demonstrably knew.
  final Skill? masteredUpTo;

  final int questionsAsked;
  final List<Skill> chain;

  bool get isSolid => gapSkill == null;

  String get summary {
    if (isSolid) {
      return 'No gap found - the foundation is solid up to '
          '${chain.last.name}.';
    }
    return 'Real gap: ${gapSkill!.name} (usually taught in class '
        '${gapSkill!.typicalClass}). Start practice here, not at the top.';
  }
}

/// Finds the deepest broken skill under a target, in about 15 questions.
///
/// A student who fails quadratics has 25 ancestor skills. Asking all 25 in
/// order would take an hour and the student would quit - which is exactly the
/// behaviour this app exists to prevent. Instead this binary searches the
/// chain: test the middle skill, and each answer eliminates half the
/// remaining possibilities. 25 skills collapses to about 5 probes.
///
/// The search assumes the chain is monotonic: if you can do a skill, you can
/// do everything below it. That is not perfectly true of real students, so
/// each probe asks 2 questions (3 on a split) before deciding, and the result
/// is treated as a starting point for practice rather than a verdict.
class PlacementSession {
  PlacementSession({
    required this.map,
    required this.targetSkillId,
    this.seed = 1,
  }) : chain = map
            .diagnosticChain(targetSkillId)
            .where(hasGenerator)
            .toList(growable: false) {
    // A skill with no generator yet cannot be probed, so it is dropped rather
    // than crashed on. Coverage grows as generators are written; the placement
    // test must keep working in the meantime.
    if (chain.isEmpty) {
      throw StateError(
        'Cannot place on "$targetSkillId": no skill in its chain has a '
        'generator yet.',
      );
    }
    _lo = 0;
    _hi = chain.length - 1;
    _firstFail = chain.length;
  }

  final SkillMap map;
  final String targetSkillId;
  final List<Skill> chain;
  final int seed;

  late int _lo;
  late int _hi;
  late int _firstFail;

  int _asked = 0;
  int _probeCorrect = 0;
  int _probeAsked = 0;
  int? _currentProbe;
  PlacementResult? _result;

  static const _maxPerProbe = 3;

  PlacementResult? get result => _result;
  bool get isComplete => _result != null;
  int get questionsAsked => _asked;

  /// The skill currently being probed, for showing progress in the UI.
  Skill? get currentSkill =>
      _currentProbe == null ? null : chain[_currentProbe!];

  /// Next question, or null once the search has converged.
  Question? nextQuestion() {
    if (_result != null) return null;
    if (_currentProbe == null) {
      if (_lo > _hi) {
        _finish();
        return null;
      }
      _currentProbe = (_lo + _hi) ~/ 2;
      _probeCorrect = 0;
      _probeAsked = 0;
    }
    final skill = chain[_currentProbe!];
    final q = generateQuestion(
      skill: skill,
      // Probe at middling difficulty: too easy passes students who are shaky,
      // too hard fails students who are basically fine.
      difficulty: 3,
      seed: seed * 7919 + _asked * 31 + _currentProbe! * 17,
    );
    _asked++;
    _probeAsked++;
    return q;
  }

  /// Record the student's outcome for the question just issued.
  void submit({required bool correct}) {
    if (_result != null) return;
    if (_currentProbe == null) {
      throw StateError('submit() called before nextQuestion()');
    }
    if (correct) _probeCorrect++;

    final decided = _probeDecision();
    if (decided == null) return; // ask another question at this probe

    if (decided) {
      _lo = _currentProbe! + 1;
    } else {
      _firstFail = _currentProbe!;
      _hi = _currentProbe! - 1;
    }
    _currentProbe = null;
    if (_lo > _hi) _finish();
  }

  /// true = passed, false = failed, null = need another question.
  bool? _probeDecision() {
    final wrong = _probeAsked - _probeCorrect;
    if (_probeCorrect >= 2) return true;
    if (wrong >= 2) return false;
    if (_probeAsked >= _maxPerProbe) return _probeCorrect > wrong;
    return null;
  }

  void _finish() {
    _result = PlacementResult(
      gapSkill: _firstFail < chain.length ? chain[_firstFail] : null,
      masteredUpTo: _firstFail > 0 ? chain[_firstFail - 1] : null,
      questionsAsked: _asked,
      chain: chain,
    );
  }
}
