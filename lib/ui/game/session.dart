import 'package:flutter/foundation.dart';

import '../../puzzles/nests/nests.dart';
import '../../puzzles/pairs/pairs.dart';
import '../../puzzles/puzzle.dart';
import '../../puzzles/source.dart';

/// What a move did.
enum MoveOutcome { none, ok, mistake }

/// A puzzle being played: the cells, undo history, conflicts, mistakes and hints.
abstract class GameSession<T> extends ChangeNotifier {
  GameSession(List<T> initial)
      : _initial = List.unmodifiable(initial),
        cells = List.of(initial);

  final List<T> _initial;
  List<T> cells;
  final _history = <List<T>>[];
  Set<int> conflicts = const {};
  int mistakes = 0;
  int hints = 0;
  bool solved = false;

  /// The cell the last hint filled, to highlight it.
  int? hintCell;

  GameKind get kind;
  int get size;

  /// The next value when a cell is tapped.
  T cycle(T value);
  /// When set, only these cells can change (tutorial steps).
  Set<int>? editable;

  bool isLocked(int cell) => editable != null && !editable!.contains(cell);
  Set<int> findConflicts(List<T> cells);
  bool checkSolved(List<T> cells);
  Hint<T>? findHint();

  String encodeCell(T value);
  T decodeCell(String char);

  bool get canUndo => _history.isNotEmpty;
  bool get isPristine => listEquals(cells, _initial);

  /// One tap on [cell]: cycles its value.
  MoveOutcome tap(int cell) {
    if (solved || isLocked(cell)) return MoveOutcome.none;
    _history.add(List.of(cells));
    cells[cell] = cycle(cells[cell]);
    return _commit(cell: cell);
  }

  /// A drag paints several cells as one undo step: [beginStroke], [paint]…, [endStroke].
  List<T>? _strokeStart;

  void beginStroke() => _strokeStart = List.of(cells);

  bool paint(int cell, T value) {
    if (solved || _strokeStart == null || isLocked(cell) || cells[cell] == value) return false;
    cells[cell] = value;
    notifyListeners();
    return true;
  }

  MoveOutcome endStroke() {
    final start = _strokeStart;
    _strokeStart = null;
    if (start == null || listEquals(start, cells)) return MoveOutcome.none;
    _history.add(start);
    return _commit();
  }

  void undo() {
    if (_history.isEmpty || solved) return;
    cells = _history.removeLast();
    hintCell = null;
    _commit(countMistake: false, forgiving: true);
  }

  /// Back to the start (undoable).
  void restart() {
    if (solved || isPristine) return;
    _history.add(List.of(cells));
    cells = List.of(_initial);
    hintCell = null;
    _commit(countMistake: false, forgiving: true);
  }

  /// Applies the next hint; null when there is nothing to hint (solved).
  int? applyHint() {
    if (solved) return null;
    final hint = findHint();
    if (hint == null) return null;
    _history.add(List.of(cells));
    cells[hint.cell] = hint.value;
    hints++;
    hintCell = hint.cell;
    _commit(countMistake: false);
    return hint.cell;
  }

  // A conflict created by a tap is a pending mistake: fixing it right away on the same cell (cycling past a wrong
  // symbol, or taking a misplaced critter back) or with undo is free; any other move first makes it count.
  int? _pendingCell;
  Set<int>? _beforePending;

  bool get hasPendingMistake => _pendingCell != null;

  MoveOutcome _commit({int? cell, bool countMistake = true, bool forgiving = false}) {
    final before = conflicts;
    conflicts = findConflicts(cells);
    if (_pendingCell != null) {
      final resolved = _beforePending!.containsAll(conflicts);
      if ((cell == _pendingCell || forgiving) && resolved) {
        _pendingCell = _beforePending = null;
      } else if (cell != _pendingCell) {
        mistakes++;
        _pendingCell = _beforePending = null;
      }
    }
    final mistake = countMistake && conflicts.difference(before).isNotEmpty;
    if (mistake && _pendingCell == null) {
      if (cell == null) {
        mistakes++;
      } else {
        _pendingCell = cell;
        _beforePending = before;
      }
    }
    solved = checkSolved(cells);
    notifyListeners();
    return mistake ? MoveOutcome.mistake : MoveOutcome.ok;
  }

  Map<String, dynamic> toJson() => {'c': cells.map(encodeCell).join(), 'mi': mistakes, 'h': hints};

  /// Restores a saved game; false if it doesn't fit this puzzle.
  bool restore(Map<String, dynamic> json) {
    final raw = json['c'];
    if (raw is! String || raw.length != _initial.length) return false;
    final restored = [for (final c in raw.split('')) decodeCell(c)];
    for (var i = 0; i < restored.length; i++) {
      if (isLocked(i) && restored[i] != _initial[i]) return false;
    }
    cells = restored;
    mistakes = json['mi'] as int? ?? 0;
    hints = json['h'] as int? ?? 0;
    conflicts = findConflicts(cells);
    solved = checkSolved(cells);
    notifyListeners();
    return true;
  }
}

class NestsSession extends GameSession<NestMark> {
  NestsSession(this.puzzle, {List<NestMark>? initial})
      : rules = NestsRules(puzzle),
        super(initial ?? List.filled(puzzle.size * puzzle.size, NestMark.empty));

  final NestsPuzzle puzzle;
  final NestsRules rules;

  @override
  GameKind get kind => GameKind.nests;
  @override
  int get size => puzzle.size;

  @override
  NestMark cycle(NestMark value) => NestMark.values[(value.index + 1) % NestMark.values.length];
  @override
  Set<int> findConflicts(List<NestMark> cells) => rules.conflicts(cells);
  @override
  bool checkSolved(List<NestMark> cells) => rules.isSolved(cells);
  @override
  Hint<NestMark>? findHint() => nestsHint(puzzle, cells);
  @override
  String encodeCell(NestMark value) => '${value.index}';
  @override
  NestMark decodeCell(String char) => NestMark.values[int.parse(char)];

  /// Cells a placed critter rules out (same row, column or zone, or touching it), for the auto-cross assist.
  Set<int> excluded() {
    final n = size;
    final out = <int>{};
    for (var i = 0; i < cells.length; i++) {
      if (cells[i] != NestMark.critter) continue;
      final r = i ~/ n, c = i % n;
      for (var j = 0; j < cells.length; j++) {
        if (j == i) continue;
        final rj = j ~/ n, cj = j % n;
        if (rj == r || cj == c || puzzle.regions[j] == puzzle.regions[i] || ((rj - r).abs() <= 1 && (cj - c).abs() <= 1)) {
          out.add(j);
        }
      }
    }
    return out;
  }
}

class PairsSession extends GameSession<int?> {
  PairsSession(this.puzzle, {List<int?>? initial})
      : rules = PairsRules(puzzle),
        super(initial ?? List.of(puzzle.givens));

  final PairsPuzzle puzzle;
  final PairsRules rules;

  @override
  GameKind get kind => GameKind.pairs;
  @override
  int get size => puzzle.size;

  @override
  bool isLocked(int cell) => super.isLocked(cell) || puzzle.givens[cell] != null;
  @override
  int? cycle(int? value) => switch (value) { null => sun, sun => moon, _ => null };
  @override
  Set<int> findConflicts(List<int?> cells) => rules.conflicts(cells);
  @override
  bool checkSolved(List<int?> cells) => rules.isSolved(cells);
  @override
  Hint<int?>? findHint() => pairsHint(puzzle, cells);
  @override
  String encodeCell(int? value) => value == null ? '.' : '$value';
  @override
  int? decodeCell(String char) => char == '.' ? null : int.parse(char);
}
