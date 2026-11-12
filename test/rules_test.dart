import 'dart:math';

import 'package:critter_logic/meta/album.dart';
import 'package:critter_logic/meta/economy.dart';
import 'package:critter_logic/puzzles/nests/nests.dart';
import 'package:critter_logic/puzzles/pairs/pairs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 4×4 Nests, zones by row except two cells, solution columns 1,3,0,2.
  final nests = NestsPuzzle(
    size: 4,
    regions: [0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3],
    solution: [1, 3, 0, 2],
  );

  List<NestMark> marks(Iterable<int> critters) =>
      [for (var i = 0; i < 16; i++) critters.contains(i) ? NestMark.critter : NestMark.empty];

  test('Nests: solved, touching and same-line conflicts', () {
    const rules = NestsRules;
    expect(rules, isNotNull);
    final r = NestsRules(nests);
    expect(r.isSolved(marks([1, 7, 8, 14])), isTrue);
    expect(r.conflicts(marks([1, 6])), {1, 6}, reason: 'diagonal neighbours');
    expect(r.conflicts(marks([0, 12])), {0, 12}, reason: 'same column');
    expect(r.conflicts(marks([0, 2])), {0, 2}, reason: 'same row and zone');
    expect(r.isSolved(marks([1, 7, 8])), isFalse);
    expect(NestsPuzzle.fromJson(nests.toJson()).regions, nests.regions);
    expect(r.solutionCells(), [1, 7, 8, 14]);
  });

  test('Pairs: three in a row, too many of one symbol, links', () {
    final solution = [0, 1, 0, 1, 1, 0, 1, 0, 0, 0, 1, 1, 1, 1, 0, 0];
    final p = PairsPuzzle(
      size: 4,
      givens: List<int?>.filled(16, null),
      links: const [PairsLink(0, 1, same: false), PairsLink(8, 9, same: true)],
      solution: solution,
    );
    final r = PairsRules(p);
    expect(r.isSolved(solution), isTrue);
    final three = List<int?>.filled(16, null)..[0] = 0..[1] = 0..[2] = 0;
    expect(r.conflicts(three), containsAll([0, 1, 2]));
    final link = List<int?>.filled(16, null)..[8] = 0..[9] = 1;
    expect(r.conflicts(link), {8, 9});
    final overfull = List<int?>.filled(16, null)..[0] = 1..[4] = 1..[12] = 1;
    expect(r.conflicts(overfull), {0, 4, 12}, reason: '3 moons in a 4-cell column');
    expect(PairsPuzzle.fromJson(p.toJson()).links.length, 2);
  });

  test('capsules prefer missing critters and report a completed set', () {
    final farm = album.where((c) => c.set == 'farm').map((c) => c.id).toSet();
    final owned = {...farm}..remove('pig');
    // Only 'pig' is a missing farm common; force commons with zero rare/golden odds.
    final rnd = Random(1);
    final results = [
      for (var i = 0; i < 50; i++) openCapsule(owned, rnd, odds: const CapsuleOdds(rare: 0, golden: 0)),
    ];
    expect(results.every((r) => r.critter.rarity == Rarity.common && !owned.contains(r.critter.id)), isTrue);
    final pig = results.firstWhere((r) => r.critter.id == 'pig');
    expect(pig.completedSet, 'farm');
    final golden = openCapsule(album.map((c) => c.id).toSet(), rnd, forceGolden: true);
    expect(golden.critter.rarity, Rarity.golden);
    expect(golden.duplicate, isTrue);
  });

  test('streak chests', () {
    expect(chestForStreak(1), isNull);
    expect(chestForStreak(3)!.coins, 50);
    expect(chestForStreak(7)!.capsule, isTrue);
    expect(chestForStreak(14)!.capsule, isTrue);
    expect(chestForStreak(30)!.golden, isTrue);
    expect(album.length, 30);
    expect(album.map((c) => c.id).toSet().length, 30);
  });
}
