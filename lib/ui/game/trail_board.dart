import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../critter_image.dart';
import '../palette.dart';
import '../widgets.dart';
import 'board_bits.dart';
import 'session.dart';

/// The Trail meadow: numbered pebbles on the grass, hedges on some cell edges, and the dirt trail the player draws
/// from pebble 1 with a critter walking at its head. Drag to extend, drag back to retract, tap the trail to cut it.
class TrailBoard extends StatefulWidget {
  const TrailBoard({
    super.key,
    required this.session,
    this.critter = 'chick',
    this.readOnly = false,
    this.celebrate,
    this.targets = const {},
    this.onMove,
    this.onStrokeEnd,
  });

  final TrailSession session;
  final String critter;
  final bool readOnly;

  /// 0→1 while celebrating a solve: the critter and the pebbles hop.
  final Animation<double>? celebrate;

  /// Cells to point at (tutorial): the hand points at the first.
  final Set<int> targets;

  /// After each step or tap: [MoveOutcome.ok] with a cell now on the trail (it grew) or off it (it shrank), or
  /// [MoveOutcome.mistake] with the refused cell.
  final void Function(MoveOutcome outcome, int cell)? onMove;

  /// When a drag ends (the undo history has its new step).
  final VoidCallback? onStrokeEnd;

  @override
  State<TrailBoard> createState() => _TrailBoardState();
}

class _TrailBoardState extends State<TrailBoard> {
  bool _dragging = false;

  /// After a refused step the drag pauses until the finger is back on the trail's end.
  bool _blocked = false;
  int? _lastCell;
  Offset? _lastPos;

  TrailSession get s => widget.session;

  int? _cellAt(Offset p, double side) {
    final n = s.size;
    if (p.dx < 0 || p.dy < 0 || p.dx >= side || p.dy >= side) return null;
    return (p.dy ~/ (side / n)) * n + (p.dx ~/ (side / n));
  }

  void _tap(int? cell) {
    if (cell == null) return;
    final before = s.path;
    final outcome = s.tap(cell);
    if (outcome == MoveOutcome.none) return;
    final after = s.path;
    // A cut reports the first cell it took off; anything else the tapped cell.
    widget.onMove?.call(outcome, after.length < before.length ? before[after.length] : cell);
    widget.onStrokeEnd?.call();
  }

  void _dragStart(Offset pos, double side) {
    final cell = _cellAt(pos, side);
    if (cell == null) return;
    final before = s.path;
    if (!s.startDrag(cell)) return;
    _dragging = true;
    _blocked = false;
    _lastCell = cell;
    _lastPos = pos;
    final after = s.path;
    if (after.length > before.length) {
      widget.onMove?.call(MoveOutcome.ok, after.last);
    } else if (after.length < before.length) {
      widget.onMove?.call(MoveOutcome.ok, before[after.length]);
    }
  }

  void _dragUpdate(Offset pos, double side) {
    if (!_dragging) return;
    final from = _lastPos ?? pos;
    _lastPos = pos;
    // Walk the finger's move in small steps, so a quick swipe still visits every cell on the way.
    final stepLen = side / s.size / 4;
    final steps = max(1, ((pos - from).distance / stepLen).ceil());
    for (var k = 1; k <= steps && _dragging; k++) {
      final cell = _cellAt(Offset.lerp(from, pos, k / steps)!, side);
      if (cell == null || cell == _lastCell) continue;
      _lastCell = cell;
      _step(cell);
    }
  }

  void _step(int cell) {
    if (_blocked) {
      if (cell == s.head) _blocked = false;
      return;
    }
    final head = s.head;
    switch (s.dragTo(cell)) {
      case TrailStep.extended:
        widget.onMove?.call(MoveOutcome.ok, cell);
        if (s.solved) _dragging = false;
      case TrailStep.retracted:
        widget.onMove?.call(MoveOutcome.ok, head!);
      case TrailStep.refused:
        _blocked = true;
        widget.onMove?.call(MoveOutcome.mistake, cell);
      case TrailStep.none:
        break;
    }
  }

  void _dragEnd() {
    _dragging = false;
    _lastPos = null;
    _lastCell = null;
    s.endStroke();
    widget.onStrokeEnd?.call();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final side = min(constraints.maxWidth, constraints.maxHeight);
      return Center(
        child: SizedBox.square(
          dimension: side,
          child: AnimatedBuilder(
            animation: Listenable.merge([s, ?widget.celebrate]),
            builder: (context, _) => _board(side),
          ),
        ),
      );
    },
  );

  Widget _board(double side) {
    final n = s.size;
    final frame = max(6.0, side * 0.03);
    final inner = side - 2 * frame;
    final c = inner / n;
    final t = widget.celebrate?.value ?? 0;
    final path = s.path;
    final head = path.isEmpty ? s.puzzle.stones.first : path.last;
    final numbers = s.puzzle.numbers;
    final last = s.puzzle.stones.length;
    Offset at(int i) => Offset((i % n) * c, (i ~/ n) * c);

    Widget ring(int i, Color color, Key key) => Positioned(
      key: key,
      left: at(i).dx + c * 0.06,
      top: at(i).dy + c * 0.06,
      width: c * 0.88,
      height: c * 0.88,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(c * 0.22),
            border: Border.all(color: color, width: max(2.5, c * 0.07)),
          ),
        ),
      ),
    );

    final hop = t > 0 && t < 1 ? sin(t * pi * 6).abs() * (1 - t) : 0.0;
    final grid = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(frame * 1.6),
            child: RepaintBoundary(child: CustomPaint(painter: _GrassPainter(n))),
          ),
        ),
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _DirtTrailPainter(path, n, glow: t)))),
        if (s.hintCell != null) ring(s.hintCell!, gold, const Key('trailHint')),
        for (final i in widget.targets) ring(i, coral, Key('target-$i')),
        if (s.refusedCell != null)
          Positioned(
            left: at(s.refusedCell!).dx,
            top: at(s.refusedCell!).dy,
            width: c,
            height: c,
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                key: ValueKey(s.refusals),
                tween: Tween(begin: 1, end: 0),
                duration: const Duration(milliseconds: 700),
                builder: (_, v, _) => Wobble(
                  child: Container(
                    margin: EdgeInsets.all(c * 0.08),
                    decoration: BoxDecoration(
                      color: bad.withValues(alpha: 0.35 * v),
                      borderRadius: BorderRadius.circular(c * 0.22),
                      border: Border.all(color: bad.withValues(alpha: v), width: max(2.0, c * 0.06)),
                    ),
                  ),
                ),
              ),
            ),
          ),
        for (final MapEntry(key: i, value: number) in numbers.entries)
          Positioned(
            left: at(i).dx,
            top: at(i).dy - _wave(t, i, n) * c * 0.25,
            width: c,
            height: c,
            child: IgnorePointer(
              child: Center(
                child: TrailPebble(
                  key: Key('stone-$number'),
                  number: number,
                  size: c * 0.68,
                  reached: s.onPath(i),
                  finish: number == last,
                ),
              ),
            ),
          ),
        Positioned.fill(child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: _HedgePainter(s.puzzle.walls, n))))),
        // The critter walks at the trail's head (waits on pebble 1 before the first move).
        AnimatedPositioned(
          key: const Key('trailCritter'),
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          left: at(head).dx + c * 0.02,
          top: at(head).dy - c * 0.36 - hop * c * 0.35,
          width: c * 0.96,
          height: c * 0.96,
          child: IgnorePointer(
            child: Opacity(
              opacity: path.isEmpty ? 0.75 : 1,
              child: s.refusals == 0
                  ? CritterImage(widget.critter, size: c * 0.96)
                  : Wobble(key: ValueKey('w${s.refusals}'), child: CritterImage(widget.critter, size: c * 0.96)),
            ),
          ),
        ),
        // Transparent cells on top, to find them by key (the board's detector handles the gestures).
        for (var i = 0; i < n * n; i++)
          Positioned(
            left: at(i).dx,
            top: at(i).dy,
            width: c,
            height: c,
            child: ColoredBox(key: Key('cell-$i'), color: Colors.transparent),
          ),
        if (widget.targets.isNotEmpty)
          Positioned(
            left: at(widget.targets.first).dx + c * 0.5,
            top: at(widget.targets.first).dy + c * 0.6,
            child: IgnorePointer(child: PointingHand(size: c * 0.66)),
          ),
      ],
    );
    final board = CustomPaint(
      painter: WoodPainter(radius: frame * 2.6, nails: false, plank: side),
      child: Padding(padding: EdgeInsets.all(frame), child: grid),
    );
    if (widget.readOnly) return board;
    Offset local(Offset p) => p - Offset(frame, frame);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onTapUp: (d) => _tap(_cellAt(local(d.localPosition), inner)),
      onPanStart: (d) => _dragStart(local(d.localPosition), inner),
      onPanUpdate: (d) => _dragUpdate(local(d.localPosition), inner),
      onPanEnd: (_) => _dragEnd(),
      onPanCancel: _dragEnd,
      child: board,
    );
  }

  /// Hop height (0..1) of the pebble in cell [i] at celebration time [t], in a wave across the board.
  static double _wave(double t, int i, int n) {
    if (t <= 0 || t >= 1) return 0;
    final delay = ((i ~/ n) + (i % n)) / (2 * n) * 0.5;
    final local = ((t - delay) / 0.5).clamp(0.0, 1.0);
    return sin(local * pi * 2).abs() * (1 - local);
  }
}

/// A round pebble with its number; warm and golden once the trail reaches it. The last one has a little flag.
class TrailPebble extends StatelessWidget {
  const TrailPebble({super.key, required this.number, required this.size, required this.reached, required this.finish});

  final int number;
  final double size;
  final bool reached;
  final bool finish;

  @override
  Widget build(BuildContext context) {
    final colors = reached
        ? const [Color(0xFFFFEDB8), Color(0xFFF5C95A)]
        : const [Color(0xFFF4EEE4), Color(0xFFCFC5B4)];
    final rim = reached ? goldEdge : const Color(0xFF9A8C76);
    return SizedBox.square(
      dimension: size,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
            border: Border.all(color: rim, width: max(1.5, size * 0.07)),
            boxShadow: [BoxShadow(color: const Color(0x55402A14), offset: Offset(0, size * 0.08))],
          ),
          alignment: Alignment.center,
          child: Text('$number', style: chunky(size * 0.52, color: reached ? woodEdge : ink, height: 1)),
        ),
        if (finish)
          Positioned(
            right: -size * 0.22,
            top: -size * 0.3,
            child: Icon(Icons.flag_rounded, size: size * 0.55, color: coral, shadows: const [Shadow(color: coralEdge, offset: Offset(0, 1.5))]),
          ),
      ]),
    );
  }
}

/// Soft checkered grass with a few tufts.
class _GrassPainter extends CustomPainter {
  _GrassPainter(this.n);

  final int n;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / n;
    final light = Paint()..color = const Color(0xFFC4EAA0);
    final dark = Paint()..color = const Color(0xFFB2E08B);
    final tuft = Paint()
      ..color = const Color(0xFF7CBF55)
      ..strokeWidth = max(1.2, c * 0.03)
      ..strokeCap = StrokeCap.round;
    final r = Random(n * 31 + 7);
    for (var i = 0; i < n * n; i++) {
      final rect = Rect.fromLTWH((i % n) * c, (i ~/ n) * c, c, c);
      canvas.drawRect(rect.inflate(0.5), ((i % n) + (i ~/ n)).isEven ? light : dark);
      canvas.drawCircle(rect.topLeft + Offset(c * 0.3, c * 0.3), c * 0.28, Paint()..color = Colors.white.withValues(alpha: 0.16));
      if (r.nextDouble() < 0.6) {
        final p = rect.topLeft + Offset(c * (0.15 + r.nextDouble() * 0.7), c * (0.55 + r.nextDouble() * 0.3));
        final h = c * 0.1;
        canvas.drawLine(p, p + Offset(-h * 0.5, -h), tuft);
        canvas.drawLine(p, p + Offset(0, -h * 1.25), tuft);
        canvas.drawLine(p, p + Offset(h * 0.5, -h), tuft);
      }
    }
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var k = 1; k < n; k++) {
      canvas.drawLine(Offset(k * c, 0), Offset(k * c, size.height), line);
      canvas.drawLine(Offset(0, k * c), Offset(size.width, k * c), line);
    }
  }

  @override
  bool shouldRepaint(_GrassPainter old) => old.n != n;
}

/// The drawn path: a soft dirt trail through the cell centers with little paw prints along it.
class _DirtTrailPainter extends CustomPainter {
  _DirtTrailPainter(this.path, this.n, {this.glow = 0});

  final List<int> path;
  final int n;

  /// 0→1 while celebrating: the trail brightens.
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;
    final c = size.width / n;
    Offset center(int i) => Offset((i % n + 0.5) * c, (i ~/ n + 0.5) * c);
    final edge = const Color(0xFFB8874F);
    final fill = Color.lerp(const Color(0xFFE9CB97), const Color(0xFFFFE9A8), sin(glow * pi).clamp(0.0, 1.0))!;
    if (path.length == 1) {
      canvas.drawCircle(center(path.first), c * 0.25, Paint()..color = edge);
      canvas.drawCircle(center(path.first), c * 0.19, Paint()..color = fill);
      return;
    }
    final line = Path()..moveTo(center(path.first).dx, center(path.first).dy);
    for (final i in path.skip(1)) {
      line.lineTo(center(i).dx, center(i).dy);
    }
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(line.shift(Offset(0, c * 0.04)), stroke(const Color(0x334A3426), c * 0.5));
    canvas.drawPath(line, stroke(edge, c * 0.5));
    canvas.drawPath(line, stroke(fill, c * 0.38));
    // Paw prints: alternating left and right along the trail.
    final print = Paint()..color = const Color(0xFFC79D66);
    var left = true;
    for (final m in line.computeMetrics()) {
      for (var d = c * 0.3; d < m.length - c * 0.1; d += c * 0.42) {
        final tan = m.getTangentForOffset(d);
        if (tan == null) continue;
        final side = Offset(-tan.vector.dy, tan.vector.dx) * (left ? 1 : -1) * c * 0.08;
        final p = tan.position + side;
        canvas.save();
        canvas.translate(p.dx, p.dy);
        canvas.rotate(atan2(tan.vector.dy, tan.vector.dx));
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: c * 0.09, height: c * 0.075), print);
        for (final k in const [-1.0, 0.0, 1.0]) {
          canvas.drawCircle(Offset(c * 0.065, k * c * 0.035), c * 0.017, print);
        }
        canvas.restore();
        left = !left;
      }
    }
  }

  @override
  bool shouldRepaint(_DirtTrailPainter old) => old.path.length != path.length || old.glow != glow || !_same(old.path);

  bool _same(List<int> other) {
    for (var i = 0; i < path.length; i++) {
      if (other[i] != path[i]) return false;
    }
    return true;
  }
}

/// Walls as short leafy hedges on the cell edges.
class _HedgePainter extends CustomPainter {
  _HedgePainter(this.walls, this.n);

  final List<(int, int)> walls;
  final int n;

  @override
  void paint(Canvas canvas, Size size) {
    if (walls.isEmpty) return;
    final c = size.width / n;
    final inset = c * 0.08;
    final hedges = Path();
    for (final (a, b) in walls) {
      final ra = a ~/ n, ca = a % n;
      if (b == a + 1) {
        final x = (ca + 1) * c;
        hedges
          ..moveTo(x, ra * c + inset)
          ..lineTo(x, (ra + 1) * c - inset);
      } else {
        final y = (ra + 1) * c;
        hedges
          ..moveTo(ca * c + inset, y)
          ..lineTo((ca + 1) * c - inset, y);
      }
    }
    final w = max(5.0, c * 0.17);
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(hedges.shift(Offset(0, w * 0.3)), stroke(const Color(0x444A3426), w));
    canvas.drawPath(hedges, stroke(const Color(0xFF2F7A26), w));
    canvas.drawPath(hedges, stroke(const Color(0xFF55AD3C), w * 0.55));
    final leafDot = Paint()..color = const Color(0xFF8BD468);
    for (final m in hedges.computeMetrics()) {
      for (var d = w * 0.4; d < m.length; d += w * 0.9) {
        final tan = m.getTangentForOffset(d);
        if (tan != null) canvas.drawCircle(tan.position, w * 0.2, leafDot);
      }
    }
  }

  @override
  bool shouldRepaint(_HedgePainter old) => old.walls != walls || old.n != n;
}
