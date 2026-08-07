import 'dart:io';

/// Copies the master skill map and chapter mapping into the app's assets.
///
/// Flutter bundles only what lives under the app directory, so these are
/// copies. Run this after editing either master file; `flutter test` fails if
/// they have drifted.
void main() {
  const pairs = {
    '../skill-map.json': 'assets/skill-map.json',
    '../curriculum/ncert-nep.json': 'assets/ncert-nep.json',
  };
  pairs.forEach((from, to) {
    final source = File(from);
    if (!source.existsSync()) {
      stderr.writeln('Missing $from - run this from the app directory.');
      exitCode = 1;
      return;
    }
    source.copySync(to);
    stdout.writeln('$from -> $to');
  });
}
