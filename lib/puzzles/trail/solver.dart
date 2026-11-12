import 'dart:typed_data';

import '../source.dart';
import 'trail.dart';

/// Rule levels of the Trail solver's deductions, simplest first (the solver works on the links between
/// side-by-side cells, as players do when they sketch the path in pieces):
/// 1. 'fill': a cell with just enough open links left uses all of them (a corner, a cell boxed in by walls or by
///    the path); 'full': a cell whose path is complete (two links, one for the first and last stones) closes the
///    rest.
/// 2. 'loop': a link that would close a piece of path into a loop, or join the first and last stones before every
///    cell is on the path, is closed.
///    'order': a link that would put stones out of order on one piece of path (say 3 next to 5) is closed.
/// 3. 'guess': none of the above applies; the search tries a link both ways. A puzzle that needs no guess can be
///    solved by deduction alone.
const trailRuleLevels = {'fill': 1, 'full': 1, 'loop': 2, 'order': 2, 'guess': 3};

/// What the exact solver found.
class TrailSolveResult {
  const TrailSolveResult({
    required this.solutions,
    required this.guesses,
    required this.rules,
    this.path,
    this.capped = false,
  });

  /// Solutions found, capped at the solver's limit (2 by default): 1 means unique.
  final int solutions;

  /// Branches the search opened when deduction got stuck, until it had proved uniqueness (0 = deduction alone).
  final int guesses;

  /// How many links each rule decided before the first guess (the deduction a player can do straight away).
  final Map<String, int> rules;

  /// The first solution found, in path order.
  final List<int>? path;

  /// The search hit its node cap; [solutions] is then reported as the limit (treated as not unique).
  final bool capped;

  bool get unique => solutions == 1;

  /// Solved by deduction alone, with no guess.
  bool get deduced => unique && guesses == 0;

  int uses(String rule) => rules[rule] ?? 0;

  @override
  String toString() => 'TrailSolveResult(solutions: $solutions, guesses: $guesses, rules: $rules)';
}

/// Exact Trail solver: deduction on the links between cells, plus search when deduction gets stuck, counting
/// solutions up to [limit].
///
/// Every cell takes two path links (stones 1 and K one). The deduction rules ([trailRuleLevels]) decide links; a
/// board that breaks a cell's link count, splits the open cells in two, or puts stones out of order is a dead end.
/// When stuck, the search picks the most constrained cell and tries one of its links on, then off. A puzzle with
/// exactly one solution is unique; [TrailSolveResult.guesses] measures how much trial and error it took.
class TrailSolver {
  TrailSolver(this.size, this.stones, {this.walls = const [], this.limit = 2, this.maxGuesses = 0});

  TrailSolver.of(TrailPuzzle p, {int limit = 2, int maxGuesses = 0})
    : this(p.size, p.stones, walls: p.walls, limit: limit, maxGuesses: maxGuesses);

  final int size;
  final List<int> stones;
  final int limit;

  /// Gives up after this many guesses (0 = never); the result is then [TrailSolveResult.capped].
  final int maxGuesses;

  /// Walls between side-by-side cells, as cell pairs.
  final List<(int, int)> walls;

  late final int _cells = size * size;
  late final int _edgeCount = 2 * size * (size - 1);

  /// The two cells of each link: horizontal links first, then vertical.
  late final Int16List _ends = () {
    final n = size, h = n * (n - 1);
    final out = Int16List(2 * _edgeCount);
    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n - 1; c++) {
        final e = r * (n - 1) + c;
        out[2 * e] = r * n + c;
        out[2 * e + 1] = r * n + c + 1;
      }
    }
    for (var r = 0; r < n - 1; r++) {
      for (var c = 0; c < n; c++) {
        final e = h + r * n + c;
        out[2 * e] = r * n + c;
        out[2 * e + 1] = (r + 1) * n + c;
      }
    }
    return out;
  }();

  /// The links of each cell.
  late final List<Int16List> _cellEdges = () {
    final lists = List.generate(_cells, (_) => <int>[]);
    for (var e = 0; e < _edgeCount; e++) {
      lists[_ends[2 * e]].add(e);
      lists[_ends[2 * e + 1]].add(e);
    }
    return [for (final l in lists) Int16List.fromList(l)];
  }();

  late final Int8List _number = () {
    final out = Int8List(_cells);
    for (var i = 0; i < stones.length; i++) {
      out[stones[i]] = i + 1;
    }
    return out;
  }();

  late final Int8List _target = () {
    final out = Int8List(_cells)..fillRange(0, _cells, 2);
    out[stones.first] = 1;
    out[stones.last] = 1;
    return out;
  }();

  int _guesses = 0, _found = 0;
  bool _capped = false;
  List<int>? _first;
  Map<String, int>? _rootRules;

  int _edgeIndex(int a, int b) {
    final n = size;
    if (a > b) return _edgeIndex(b, a);
    return b == a + 1 ? (a ~/ n) * (n - 1) + a % n : n * (n - 1) + a;
  }

  TrailSolveResult solve() {
    TrailSolveResult result([int? found]) => TrailSolveResult(
      solutions: found ?? (_capped ? limit : _found),
      guesses: _guesses,
      rules: _rootRules ?? const {},
      path: _first,
      capped: _capped,
    );
    final n = size;
    final start = stones.first, end = stones.last;
    if (stones.length < 2 || start == end || stones.toSet().length != stones.length) return result(0);
    int color(int c) => (c ~/ n + c % n) & 1;
    // Parity: the path alternates colors, so the ends' colors are fixed by the cell count.
    if (_cells.isEven ? color(start) == color(end) : color(start) != 0 || color(end) != 0) return result(0);
    final state = _State(_cells, _edgeCount);
    for (var c = 0; c < _cells; c++) {
      state.unknown[c] = _cellEdges[c].length;
      state.partner[c] = c;
      state.near[c] = _number[c];
      state.count[c] = _number[c] == 0 ? 0 : 1;
      state.len[c] = 1;
    }
    for (final (a, b) in walls) {
      if (!_adjacent(a, b)) continue;
      final e = _edgeIndex(a, b);
      if (state.edge[e] == 0) _close(state, e);
    }
    final rules = <String, int>{};
    final ok = _deduce(state, rules);
    _rootRules = rules;
    if (ok) _search(state);
    return result();
  }

  bool _adjacent(int a, int b) {
    final n = size;
    return (a ~/ n == b ~/ n && (a - b).abs() == 1) || (a - b).abs() == n;
  }

  void _search(_State s) {
    if (_found >= limit || _capped) return;
    // Most constrained open cell: fewest open links for the links it still needs.
    var best = -1, bestSlack = 99;
    for (var c = 0; c < _cells; c++) {
      final need = _target[c] - s.on[c];
      if (need <= 0) continue;
      final slack = s.unknown[c] - need;
      if (slack < bestSlack) {
        bestSlack = slack;
        best = c;
        if (slack == 1) break;
      }
    }
    if (best < 0) {
      _found++;
      _first ??= _walk(s);
      return;
    }
    var edge = -1;
    for (final e in _cellEdges[best]) {
      if (s.edge[e] == 0) {
        edge = e;
        break;
      }
    }
    _guesses++;
    if (maxGuesses > 0 && _guesses > maxGuesses) {
      _capped = true;
      return;
    }
    // The link on, then off.
    final withLink = s.copy();
    if (_open(withLink, edge) && _deduce(withLink, null)) _search(withLink);
    if (_found >= limit || _capped) return;
    _close(s, edge);
    if (_deduce(s, null)) _search(s);
  }

  /// The path of a finished board, from stone 1.
  List<int> _walk(_State s) {
    final path = [stones.first];
    var prev = -1;
    while (path.length < _cells) {
      final c = path.last;
      var next = -1;
      for (final e in _cellEdges[c]) {
        if (s.edge[e] != 1) continue;
        final o = _ends[2 * e] == c ? _ends[2 * e + 1] : _ends[2 * e];
        if (o != prev) {
          next = o;
          break;
        }
      }
      prev = c;
      path.add(next);
    }
    return path;
  }

  /// Turns link [e] on, joining two pieces of path; false when that breaks a rule.
  bool _open(_State s, int e) {
    final a = _ends[2 * e], b = _ends[2 * e + 1];
    if (_joinError(s, a, b) != null) return false;
    s.edge[e] = 1;
    s.on[a]++;
    s.on[b]++;
    s.unknown[a]--;
    s.unknown[b]--;
    final pa = s.partner[a], pb = s.partner[b];
    final cA = s.count[a], cB = s.count[b];
    final nearPa = s.near[pa], nearA = s.near[a], nearB = s.near[b], nearPb = s.near[pb];
    final total = cA + cB;
    final d = total < 2
        ? 0
        : cA >= 2
        ? s.dir[pa]
        : cA == 1
        ? nearB - nearA
        : s.dir[b];
    final len = s.len[a] + s.len[b];
    s.partner[pa] = pb;
    s.partner[pb] = pa;
    s.near[pa] = cA > 0 ? nearPa : nearB;
    s.near[pb] = cB > 0 ? nearPb : nearA;
    s.dir[pa] = d;
    s.dir[pb] = -d;
    s.count[pa] = s.count[pb] = total;
    s.len[pa] = s.len[pb] = len;
    return s.on[a] <= _target[a] && s.on[b] <= _target[b];
  }

  /// Turns link [e] off; the link counts are checked by [_deduce].
  void _close(_State s, int e) {
    s.edge[e] = -1;
    s.unknown[_ends[2 * e]]--;
    s.unknown[_ends[2 * e + 1]]--;
  }

  /// Why joining the path ends [a] and [b] is wrong ('loop' or 'order'), or null when it is fine.
  String? _joinError(_State s, int a, int b) {
    if (s.on[a] >= _target[a] || s.on[b] >= _target[b]) return 'full';
    final pa = s.partner[a], pb = s.partner[b];
    if (pa == b) return 'loop';
    final start = stones.first, end = stones.last;
    if (((pa == start && pb == end) || (pa == end && pb == start)) && s.len[a] + s.len[b] != _cells) return 'loop';
    final x = s.near[a], y = s.near[b];
    if (x != 0 && y != 0) {
      final d = y - x;
      if (d != 1 && d != -1) return 'order';
      if (s.count[a] >= 2 && d != -s.dir[a]) return 'order';
      if (s.count[b] >= 2 && d != s.dir[b]) return 'order';
    }
    return null;
  }

  /// Applies the deduction rules until none applies; false on a contradiction. Counts rule uses into [rules].
  bool _deduce(_State s, Map<String, int>? rules) {
    void count(String rule) {
      if (rules != null) rules[rule] = (rules[rule] ?? 0) + 1;
    }

    for (;;) {
      var changed = false;
      for (var c = 0; c < _cells; c++) {
        final on = s.on[c], open = s.unknown[c], target = _target[c];
        if (on > target || on + open < target) return false;
        if (open == 0) continue;
        if (on == target) {
          for (final e in _cellEdges[c]) {
            if (s.edge[e] == 0) {
              _close(s, e);
              count('full');
            }
          }
          changed = true;
        } else if (on + open == target) {
          for (final e in _cellEdges[c]) {
            if (s.edge[e] == 0) {
              if (!_open(s, e)) return false;
              count('fill');
            }
          }
          changed = true;
        }
      }
      if (changed) continue;
      for (var e = 0; e < _edgeCount; e++) {
        if (s.edge[e] != 0) continue;
        final why = _joinError(s, _ends[2 * e], _ends[2 * e + 1]);
        if (why == null) continue;
        _close(s, e);
        count(why == 'full' ? 'full' : why);
        changed = true;
      }
      if (!changed) return _connected(s);
    }
  }

  /// All cells still reachable from stone 1 through links that are not closed.
  bool _connected(_State s) {
    final seen = Uint8List(_cells);
    final queue = Int16List(_cells);
    var qh = 0, qt = 0;
    queue[qt++] = stones.first;
    seen[stones.first] = 1;
    while (qh < qt) {
      final c = queue[qh++];
      for (final e in _cellEdges[c]) {
        if (s.edge[e] == -1) continue;
        final o = _ends[2 * e] == c ? _ends[2 * e + 1] : _ends[2 * e];
        if (seen[o] == 0) {
          seen[o] = 1;
          queue[qt++] = o;
        }
      }
    }
    return qt == _cells;
  }
}

/// The solver's board: each link on (1), off (-1) or open (0), and for each end of a piece of path, the other end,
/// the stone nearest to it, which way the stone numbers run from there, the stones on the piece and its length.
class _State {
  _State(int cells, int edges)
    : edge = Int8List(edges),
      on = Int8List(cells),
      unknown = Int8List(cells),
      partner = Int16List(cells),
      near = Int8List(cells),
      dir = Int8List(cells),
      count = Int8List(cells),
      len = Int16List(cells);

  _State._(this.edge, this.on, this.unknown, this.partner, this.near, this.dir, this.count, this.len);

  final Int8List edge, on, unknown, near, dir, count;
  final Int16List partner, len;

  _State copy() => _State._(
    Int8List.fromList(edge),
    Int8List.fromList(on),
    Int8List.fromList(unknown),
    Int16List.fromList(partner),
    Int8List.fromList(near),
    Int8List.fromList(dir),
    Int8List.fromList(count),
    Int16List.fromList(len),
  );
}

/// The next step for the player from their drawn [path]: when it follows the solution, the next cell to draw
/// (rule 'next', [Hint.value] = its index in the path); when it has left the solution, where to undo back to (rule
/// 'undo', [Hint.wrong], [Hint.cell] = the last right cell or stone 1 and [Hint.value] = how many cells to keep).
/// Null once solved. The solution is unique, so a path that leaves it can never be finished.
Hint<int>? trailHint(TrailPuzzle puzzle, List<int> path) {
  final sol = puzzle.solution;
  var k = 0;
  while (k < path.length && k < sol.length && path[k] == sol[k]) {
    k++;
  }
  if (k < path.length) return Hint(k > 0 ? sol[k - 1] : sol[0], k, wrong: true, rule: 'undo');
  if (k == sol.length) return null;
  return Hint(sol[k], k, rule: 'next');
}
