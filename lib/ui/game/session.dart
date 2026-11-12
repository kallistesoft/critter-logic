import 'package:flutter/foundation.dart';

import '../../puzzles/nests/nests.dart';
import '../../puzzles/pairs/pairs.dart';
import '../../puzzles/puzzle.dart';
import '../../puzzles/source.dart';
import '../../puzzles/trail/solver.dart';
import '../../puzzles/trail/trail.dart';

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

/// What one step of a Trail drag did.
enum TrailStep {
  /// Nothing (the same cell, or a cell the drag can't reach from the path's end, like a diagonal).
  none,

  /// The path grew by the cell.
  extended,

  /// The path went back one cell (the drag moved back over it).
  retracted,

  /// A move that breaks a rule (wall, revisit, stone out of order, past the last stone): refused, a mistake.
  refused,
}

/// Trail: [cells] holds each cell's step on the drawn path (1 for the first cell, 0 when not on the path), so undo,
/// restart and saving work as in the other games. The path is always legal: wrong moves are refused (and counted
/// as mistakes) instead of drawn.
class TrailSession extends GameSession<int> {
  TrailSession(this.puzzle, {List<int> path = const []})
      : rules = TrailRules(puzzle),
        super(_cellsOf(puzzle.cellCount, path));

  final TrailPuzzle puzzle;
  final TrailRules rules;

  /// The cell of the last refused move, and how many moves were refused so far (to replay the wobble).
  int? refusedCell;
  int refusals = 0;

  static List<int> _cellsOf(int count, List<int> path) {
    final cells = List.filled(count, 0);
    for (var i = 0; i < path.length; i++) {
      cells[path[i]] = i + 1;
    }
    return cells;
  }

  /// The path in [cells], or null when the steps don't run 1, 2, … without a gap.
  static List<int>? _pathOf(List<int> cells) {
    final length = cells.where((v) => v > 0).length;
    final path = List.filled(length, -1);
    for (var i = 0; i < cells.length; i++) {
      final v = cells[i];
      if (v == 0) continue;
      if (v < 0 || v > length || path[v - 1] != -1) return null;
      path[v - 1] = i;
    }
    return path;
  }

  /// The drawn path, stone 1 first.
  List<int> get path => _pathOf(cells) ?? const [];

  /// The path's last cell (where the critter stands), or null before the first move.
  int? get head {
    final p = path;
    return p.isEmpty ? null : p.last;
  }

  bool onPath(int cell) => cells[cell] > 0;

  @override
  GameKind get kind => GameKind.trail;
  @override
  int get size => puzzle.size;

  @override
  int cycle(int value) => value;
  @override
  Set<int> findConflicts(List<int> cells) => rules.conflicts(_pathOf(cells) ?? const []);
  @override
  bool checkSolved(List<int> cells) {
    final p = _pathOf(cells);
    return p != null && rules.isSolved(p);
  }

  @override
  Hint<int>? findHint() => trailHint(puzzle, path);

  // One char per cell: '0' + the step (up to 8×8 = 64 steps, still plain ASCII).
  @override
  String encodeCell(int value) => String.fromCharCode(48 + value);
  @override
  int decodeCell(String char) => char.codeUnitAt(0) - 48;

  void _setPath(List<int> path) {
    final next = _cellsOf(cells.length, path);
    for (var i = 0; i < next.length; i++) {
      cells[i] = next[i];
    }
  }

  /// A one-step, undoable change outside a drag.
  MoveOutcome _apply(List<int> path) {
    _history.add(List.of(cells));
    _setPath(path);
    hintCell = null;
    return _commit(countMistake: false);
  }

  void _refuse(int cell) {
    mistakes++;
    refusedCell = cell;
    refusals++;
    notifyListeners();
  }

  /// One tap on [cell]: on the path, cuts it back to there; on stone 1 with no path yet, starts it; next to the
  /// path's end, extends it; a move that breaks a rule is refused (a mistake).
  @override
  MoveOutcome tap(int cell) {
    if (solved || isLocked(cell)) return MoveOutcome.none;
    final p = path;
    if (onPath(cell)) {
      final keep = cells[cell];
      return keep == p.length ? MoveOutcome.none : _apply(p.sublist(0, keep));
    }
    if (p.isEmpty) return cell == puzzle.stones.first ? _apply([cell]) : MoveOutcome.none;
    if (rules.canExtend(p, cell)) return _apply([...p, cell]);
    // A tap far from the trail's end is a stray touch, not a wrong move: ignore it. Only a step the trail could
    // reach (next to its end) but that breaks a rule (wall, revisit, stone order) counts as a mistake.
    final end = p.last, n = puzzle.size;
    final next = (end - cell).abs() == n || ((end - cell).abs() == 1 && end ~/ n == cell ~/ n);
    if (!next) return MoveOutcome.none;
    _refuse(cell);
    return MoveOutcome.mistake;
  }

  /// Where a drag starts: on the path (cut back to there), on stone 1, or next to the path's end. False when a drag
  /// can't start on [cell]. Call [endStroke] when the drag ends.
  bool startDrag(int cell) {
    if (solved || isLocked(cell)) return false;
    final p = path;
    final List<int> next;
    if (onPath(cell)) {
      next = p.sublist(0, cells[cell]);
    } else if (cell == puzzle.stones.first) {
      next = [cell];
    } else if (p.isNotEmpty && rules.canExtend(p, cell)) {
      next = [...p, cell];
    } else {
      return false;
    }
    beginStroke();
    if (!listEquals(next, p)) {
      _setPath(next);
      hintCell = null;
      notifyListeners();
    }
    return true;
  }

  /// The drag moved onto [cell]: back over the path retracts, a legal step extends, a rule break is refused. A step
  /// that solves the puzzle ends the stroke.
  TrailStep dragTo(int cell) {
    if (solved || _strokeStart == null) return TrailStep.none;
    final p = path;
    if (p.isEmpty || cell == p.last) return TrailStep.none;
    if (p.length >= 2 && cell == p[p.length - 2]) {
      if (isLocked(p.last)) return TrailStep.none;
      cells[p.last] = 0;
      hintCell = null;
      notifyListeners();
      return TrailStep.retracted;
    }
    if (isLocked(cell)) return TrailStep.none;
    final error = rules.firstError([...p, cell]);
    if (error == null) {
      cells[cell] = p.length + 1;
      hintCell = null;
      if (rules.isSolved([...p, cell])) {
        endStroke();
      } else {
        notifyListeners();
      }
      return TrailStep.extended;
    }
    if (error.$2 == TrailError.jump) return TrailStep.none;
    _refuse(cell);
    return TrailStep.refused;
  }

  @override
  int? applyHint() {
    if (solved) return null;
    final hint = findHint();
    if (hint == null) return null;
    final p = path;
    _history.add(List.of(cells));
    _setPath(hint.wrong ? p.sublist(0, hint.value) : [...p, hint.cell]);
    hints++;
    hintCell = hint.cell;
    _commit(countMistake: false);
    return hint.cell;
  }

  @override
  bool restore(Map<String, dynamic> json) {
    final raw = json['c'];
    if (raw is! String || raw.length != cells.length) return false;
    final p = _pathOf([for (final c in raw.split('')) decodeCell(c)]);
    if (p == null || !rules.isValid(p)) return false;
    return super.restore(json);
  }
}
