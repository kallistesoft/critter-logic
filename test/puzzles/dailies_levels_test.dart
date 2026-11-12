import 'dart:convert';
import 'dart:io';

import 'package:critter_logic/puzzles/bundled_source.dart';
import 'package:critter_logic/puzzles/difficulty.dart';
import 'package:critter_logic/puzzles/levels.dart';
import 'package:critter_logic/puzzles/nests/generator.dart';
import 'package:critter_logic/puzzles/nests/nests.dart';
import 'package:critter_logic/puzzles/nests/solver.dart';
import 'package:critter_logic/puzzles/pairs/generator.dart';
import 'package:critter_logic/puzzles/pairs/pairs.dart';
import 'package:critter_logic/puzzles/pairs/solver.dart';
import 'package:flutter_test/flutter_test.dart';

List<Map<String, dynamic>> bundled(String game) {
  final json = jsonDecode(File('assets/dailies/$game.json').readAsStringSync()) as Map<String, dynamic>;
  expect(json['first'], 1);
  return (json['puzzles'] as List).cast<Map<String, dynamic>>();
}

void main() {
  test('bundled Nests dailies: 730, solved by deduction, matching their stored solution and weekday', () {
    final dailies = bundled('nests');
    expect(dailies.length, 730);
    final seen = <String>{};
    for (var i = 0; i < dailies.length; i++) {
      final p = NestsPuzzle.fromJson(dailies[i]);
      final solver = NestsSolver(p.size, p.regions);
      final result = solver.solve();
      expect(result.solved, isTrue, reason: 'daily ${i + 1}');
      expect(solver.solution, p.solution);
      final marks = [for (var c = 0; c < p.size * p.size; c++) p.isCritterInSolution(c) ? NestMark.critter : NestMark.empty];
      expect(NestsRules(p).isSolved(marks), isTrue);
      final spec = nestsDailySpec(i + 1);
      expect(p.size, spec.size);
      expect((nestsTierOf(result).index - spec.tier.index).abs(), lessThanOrEqualTo(1));
      seen.add(dailies[i]['r'] as String);
    }
    expect(seen.length, 730, reason: 'no repeated daily');
  });

  test('bundled Pairs dailies: 730, solved by deduction, matching their stored solution and weekday', () {
    final dailies = bundled('pairs');
    expect(dailies.length, 730);
    for (var i = 0; i < dailies.length; i++) {
      final p = PairsPuzzle.fromJson(dailies[i]);
      final solver = PairsSolver(p.size, p.givens, p.links);
      final result = solver.solve();
      expect(result.solved, isTrue, reason: 'daily ${i + 1}');
      expect(solver.solution, p.solution);
      expect(PairsRules(p).isSolved(p.solution), isTrue);
      final spec = pairsDailySpec(i + 1);
      expect(p.size, spec.size);
      expect((pairsTierOf(result).index - spec.tier.index).abs(), lessThanOrEqualTo(1));
    }
  });

  test('regenerating dailies gives the bundled puzzles', () {
    final nests = bundled('nests'), pairs = bundled('pairs');
    for (final n in [1, 2, 7, 100, 365, 730]) {
      expect(jsonEncode(generateNestsDaily(n).toJson()), jsonEncode(nests[n - 1]), reason: 'Nests daily $n');
      expect(jsonEncode(generatePairsDaily(n).toJson()), jsonEncode(pairs[n - 1]), reason: 'Pairs daily $n');
    }
  });

  test('daily difficulty follows the weekday', () {
    // Daily 1 is Tuesday 2026-12-01; daily 7 is Monday 2026-12-07.
    expect(nestsDailySpec(7), const PuzzleSpec(6, Tier.easy));
    expect(nestsDailySpec(6), const PuzzleSpec(8, Tier.hard));
    expect(pairsDailySpec(7), const PuzzleSpec(6, Tier.easy));
    expect(pairsDailySpec(6), const PuzzleSpec(8, Tier.hard));
  });

  test('level ramps: small and easy first, max size and hard by 60, breathers', () {
    for (final (spec, step) in [(nestsLevelSpec, 1), (pairsLevelSpec, 2)]) {
      for (var l = 1; l <= 3; l++) {
        expect(spec(l).tier, Tier.easy);
      }
      expect(spec(1).size, lessThanOrEqualTo(6));
      for (var l = 1; l <= 300; l++) {
        expect(spec(l).size, inInclusiveRange(5, 9));
      }
      // Never more than one size step (Pairs sizes are even) above any earlier non-breather level.
      for (var l = 2; l <= 300; l++) {
        final before = [for (var k = 1; k < l; k++) if (!isBreatherLevel(k)) spec(k).size];
        expect(spec(l).size, lessThanOrEqualTo(before.reduce((a, b) => a > b ? a : b) + step));
      }
      final late = [for (var l = 60; l < 120; l++) spec(l)];
      expect(late.where((s) => s.tier == Tier.hard).length, greaterThan(30));
      expect(spec(21).tier, Tier.easy, reason: 'breather');
    }
    expect(nestsLevelSpec(60).size, 9);
    expect(pairsLevelSpec(61).size, 8);
    expect([for (var l = 1; l <= 300; l++) pairsLevelSpec(l).size].every((s) => s == 6 || s == 8), isTrue);
  });

  test('levels are deterministic and stable across app versions', () {
    // Pinned so an accidental change to a generator (which would reshuffle every level) fails here.
    expect(generateNestsLevel(1).toJson(), golden['nests1']);
    expect(generatePairsLevel(1).toJson(), golden['pairs1']);
    for (final l in [5, 33, 60]) {
      expect(generateNestsLevel(l).toJson(), generateNestsLevel(l).toJson());
      expect(generatePairsLevel(l).toJson(), generatePairsLevel(l).toJson());
    }
  });

  test('BundledPuzzleSource: bundle first, generation past it', () async {
    final source = BundledPuzzleSource(load: (key) async => File(key).readAsStringSync(), useIsolate: false);
    final nests = bundled('nests'), pairs = bundled('pairs');
    expect((await source.dailyNests(1)).toJson(), nests[0]);
    expect((await source.dailyPairs(730)).toJson(), pairs[729]);
    expect((await source.dailyNests(731)).toJson(), generateNestsDaily(731).toJson());
    expect((await source.dailyPairs(0)).toJson(), generatePairsDaily(0).toJson());
    expect((await source.levelNests(3)).toJson(), generateNestsLevel(3).toJson());
    expect((await source.levelPairs(3)).toJson(), generatePairsLevel(3).toJson());

    final missing = BundledPuzzleSource(load: (key) async => throw StateError('no asset'), useIsolate: false);
    expect((await missing.dailyNests(5)).toJson(), generateNestsDaily(5).toJson());
  });
}

const golden = <String, Map<String, dynamic>>{
  'nests1': {'s': 5, 'r': '0033304443444421111211111', 'x': '30241'},
  'pairs1': {
    's': 6,
    'g': '..0.....0...........1.........0.....',
    'l': [
      [0, 1, 0], [1, 2, 0], [4, 5, 1], [7, 8, 0], [15, 16, 1], [15, 21, 1], [25, 26, 1], //
    ],
    'x': '010011110100101001011010100110001101',
  },
};
