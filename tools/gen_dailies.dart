// Writes the bundled dailies: dart run tools/gen_dailies.dart
//
// assets/dailies/{nests,pairs,trail}.json = {"first": 1, "puzzles": [compact puzzle JSON, ...]} for dailies 1..730.
// Rerunning gives the same files as long as the generators are unchanged.
import 'dart:convert';
import 'dart:io';

import 'package:critter_logic/puzzles/levels.dart';

const dailyCount = 730;

void main() {
  final sw = Stopwatch()..start();
  _write('assets/dailies/nests.json', [for (var n = 1; n <= dailyCount; n++) generateNestsDaily(n).toJson()]);
  _write('assets/dailies/pairs.json', [for (var n = 1; n <= dailyCount; n++) generatePairsDaily(n).toJson()]);
  _write('assets/dailies/trail.json', [for (var n = 1; n <= dailyCount; n++) generateTrailDaily(n).toJson()]);
  stdout.writeln('done in ${sw.elapsedMilliseconds} ms');
}

void _write(String path, List<Map<String, dynamic>> puzzles) {
  final file = File(path)..createSync(recursive: true);
  file.writeAsStringSync(jsonEncode({'first': 1, 'puzzles': puzzles}));
  stdout.writeln('$path: ${puzzles.length} puzzles, ${file.lengthSync()} bytes');
}
