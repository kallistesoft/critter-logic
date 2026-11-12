import 'package:critter_logic/puzzles/nests/nests.dart';
import 'package:critter_logic/ui/game/session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  test('a conflict fixed on the same cell, or undone, is not a mistake', () {
    final s = PairsSession(fakePairs);
    expect(s.tap(1), MoveOutcome.mistake, reason: 'sun next to two suns: three in a row');
    expect(s.hasPendingMistake, isTrue);
    s.tap(1); // → moon: fixed
    expect(s.mistakes, 0);
    expect(s.hasPendingMistake, isFalse);

    s.tap(3); // sun: row 0 now has 3 suns
    s.undo();
    expect(s.mistakes, 0);

    s.tap(3);
    s.tap(5); // moves on with the conflict left: it counts
    expect(s.mistakes, 1);
  });

  test('Nests: undo, restart, hint and save round trip', () {
    final s = NestsSession(fakeNests);
    s.tap(0);
    expect(s.cells[0], NestMark.cross);
    s.beginStroke();
    s.paint(2, NestMark.cross);
    s.paint(3, NestMark.cross);
    s.endStroke();
    expect(s.cells.where((m) => m == NestMark.cross), hasLength(3));
    s.undo();
    expect(s.cells.where((m) => m == NestMark.cross), hasLength(1), reason: 'a drag is one undo step');
    s.restart();
    expect(s.isPristine, isTrue);
    expect(s.applyHint(), 1);
    expect(s.hints, 1);
    final copy = NestsSession(fakeNests)..restore(s.toJson());
    expect(copy.cells, s.cells);
    expect(copy.hints, 1);
    expect(s.excluded(), containsAll([0, 2, 3, 4, 5, 6]));
  });
}
