import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'levels.dart';
import 'nests/nests.dart';
import 'pairs/pairs.dart';
import 'source.dart';
import 'trail/trail.dart';

/// Dailies from assets/dailies/*.json (made by tools/gen_dailies.dart), generated on the device past the end of
/// the bundle; levels generated on demand. Nests 7×7 and up can take tens of ms on a slow phone, so they are
/// generated in a background isolate; Pairs and Trail take a few ms and run inline.
class BundledPuzzleSource implements PuzzleSource {
  BundledPuzzleSource({Future<String> Function(String key)? load, this.useIsolate = true})
      : _load = load ?? rootBundle.loadString;

  final Future<String> Function(String key) _load;

  /// Whether big Nests are generated in a background isolate.
  final bool useIsolate;

  Future<_Bundle>? _nests, _pairs, _trail;

  Future<_Bundle> _bundle(String name) async {
    try {
      final json = jsonDecode(await _load('assets/dailies/$name.json')) as Map<String, dynamic>;
      return _Bundle(json['first'] as int, (json['puzzles'] as List).cast<Map<String, dynamic>>());
    } catch (_) {
      return const _Bundle(1, []); // Missing or broken asset: generate everything instead.
    }
  }

  Future<T> _run<T>(T Function(int) generate, int n, {required bool heavy}) =>
      useIsolate && heavy ? compute(generate, n) : Future.value(generate(n));

  @override
  Future<NestsPuzzle> dailyNests(int number) async {
    final json = (await (_nests ??= _bundle('nests'))).at(number);
    return json != null ? NestsPuzzle.fromJson(json) : _run(generateNestsDaily, number, heavy: nestsDailySpec(number).size >= 7);
  }

  @override
  Future<PairsPuzzle> dailyPairs(int number) async {
    final json = (await (_pairs ??= _bundle('pairs'))).at(number);
    return json != null ? PairsPuzzle.fromJson(json) : _run(generatePairsDaily, number, heavy: false);
  }

  @override
  Future<TrailPuzzle> dailyTrail(int number) async {
    final json = (await (_trail ??= _bundle('trail'))).at(number);
    return json != null ? TrailPuzzle.fromJson(json) : _run(generateTrailDaily, number, heavy: false);
  }

  @override
  Future<NestsPuzzle> levelNests(int level) => _run(generateNestsLevel, level, heavy: nestsLevelSpec(level).size >= 7);

  @override
  Future<PairsPuzzle> levelPairs(int level) => _run(generatePairsLevel, level, heavy: false);

  @override
  Future<TrailPuzzle> levelTrail(int level) => _run(generateTrailLevel, level, heavy: false);
}

class _Bundle {
  const _Bundle(this.first, this.puzzles);

  final int first;
  final List<Map<String, dynamic>> puzzles;

  Map<String, dynamic>? at(int number) {
    final i = number - first;
    return i >= 0 && i < puzzles.length ? puzzles[i] : null;
  }
}
