import 'gen_context.dart';
import 'question.dart';

/// Produces one question for one skill at one difficulty.
typedef QuestionGenerator = Question Function(GenContext ctx);

/// Name -> generator. The `generator` field on each skill in skill-map.json
/// looks itself up here, so adding a skill is: add the JSON row, add the
/// function, register it. Nothing else changes.
final Map<String, QuestionGenerator> generatorRegistry = {};

void register(String name, QuestionGenerator fn) {
  if (generatorRegistry.containsKey(name)) {
    throw StateError('Generator "$name" registered twice');
  }
  generatorRegistry[name] = fn;
}
