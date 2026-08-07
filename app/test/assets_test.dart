import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the bundled syllabus is the one in the repository', () {
    // Flutter can only bundle assets from inside the app directory, so these
    // two files are copies. Copies drift: a chapter fixed in curriculum/ and
    // not here would leave the site serving the old mapping, and nothing would
    // say so. This is what says so.
    const pairs = {
      'assets/skill-map.json': '../skill-map.json',
      'assets/ncert-nep.json': '../curriculum/ncert-nep.json',
    };
    for (final e in pairs.entries) {
      final bundled = File(e.key).readAsStringSync().replaceAll('\r\n', '\n');
      final master = File(e.value).readAsStringSync().replaceAll('\r\n', '\n');
      expect(bundled, master,
          reason: '${e.key} has drifted from ${e.value}. '
              'Run: dart run tool/sync_assets.dart');
    }
  });
}
