import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../puzzles/nests/nests.dart';
import '../cosmetics.dart';
import '../palette.dart';
import '../widgets.dart';
import 'board_bits.dart';
import 'session.dart';

/// The Nests grid: colored zones with thick borders between them. Tap cycles empty → cross → critter; dragging
/// paints crosses (or erases them when the drag starts on a cross).
class NestsBoard extends StatefulWidget {
  const NestsBoard({
    super.key,
    required this.session,
    this.critter = 'chick',
    this.autoCross = true,
    this.readOnly = false,
    this.celebrate,
    this.targets = const {},
    this.onMove,
  });

  final NestsSession session;
  final String critter;
  final bool autoCross;
  final bool readOnly;

  /// 0→1 while celebrating a solve: the critters hop.
  final Animation<double>? celebrate;

  /// Cells to point at (tutorial).
  final Set<int> targets;

  /// After each move, with the cell that changed last.
  final void Function(MoveOutcome outcome, int cell)? onMove;

  @override
  State<NestsBoard> createState() => _NestsBoardState();
}

class _NestsBoardState extends State<NestsBoard> {
  NestMark? _paint;
  int _lastCell = 0;

  NestsSession get s => widget.session;

  int? _cellAt(Offset p, double side) {
    final n = s.size;
    if (p.dx < 0 || p.dy < 0 || p.dx >= side || p.dy >= side) return null;
    return (p.dy ~/ (side / n)) * n + (p.dx ~/ (side / n));
  }

  void _tap(int cell) {
    final outcome = s.tap(cell);
    if (outcome != MoveOutcome.none) widget.onMove?.call(outcome, cell);
  }

  void _dragStart(int? cell) {
    if (cell == null) return;
    _paint = s.cells[cell] == NestMark.cross ? NestMark.empty : NestMark.cross;
    s.beginStroke();
    _dragTo(cell);
  }

  void _dragTo(int? cell) {
    if (cell == null || _paint == null) return;
    final from = _paint == NestMark.cross ? NestMark.empty : NestMark.cross;
    if (s.cells[cell] == from && s.paint(cell, _paint!)) {
      _lastCell = cell;
      HapticFeedback.selectionClick();
    }
  }

  void _dragEnd() {
    if (_paint == null) return;
    _paint = null;
    final outcome = s.endStroke();
    if (outcome != MoveOutcome.none) widget.onMove?.call(outcome, _lastCell);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = min(constraints.maxWidth, constraints.maxHeight);
        return Center(
          child: SizedBox.square(
            dimension: side,
            child: AnimatedBuilder(
              animation: Listenable.merge([s, if (widget.celebrate != null) widget.celebrate!]),
              builder: (context, _) => _board(side),
            ),
          ),
        );
      },
    );
  }

  Widget _board(double side) {
    final n = s.size;
    final frame = max(6.0, side * 0.03);
    final inner = side - 2 * frame;
    final cell = inner / n;
    final excluded = widget.autoCross ? s.excluded() : const <int>{};
    final t = widget.celebrate?.value ?? 0;
    final grid = Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(frame * 1.6),
            child: RepaintBoundary(child: CustomPaint(painter: _BedsPainter(s.puzzle.regions, n))),
          ),
        ),
        for (var i = 0; i < n * n; i++)
          Positioned(
            left: (i % n) * cell,
            top: (i ~/ n) * cell,
            width: cell,
            height: cell,
            child: _Cell(
              key: Key('cell-$i'),
              mark: s.cells[i],
              ruledOut: excluded.contains(i),
              conflict: s.conflicts.contains(i),
              hint: s.hintCell == i,
              target: widget.targets.contains(i),
              critter: widget.critter,
              size: cell,
              hop: _hop(t, i, n),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: _ZonePainter(s.puzzle.regions, n)))),
        ),
        if (widget.targets.isNotEmpty)
          Positioned(
            left: (widget.targets.first % n) * cell + cell * 0.45,
            top: (widget.targets.first ~/ n) * cell + cell * 0.5,
            child: IgnorePointer(child: PointingHand(size: cell * 0.7)),
          ),
      ],
    );
    // A wooden fence frame around the garden.
    final board = CustomPaint(
      painter: WoodPainter(radius: frame * 2.6, nails: false, plank: side),
      child: Padding(
        padding: EdgeInsets.all(frame),
        child: grid,
      ),
    );
    if (widget.readOnly) return board;
    Offset local(Offset p) => p - Offset(frame, frame);
    return GestureDetector(
      dragStartBehavior: DragStartBehavior.down,
      onTapUp: (d) {
        final c = _cellAt(local(d.localPosition), inner);
        if (c != null) _tap(c);
      },
      onPanStart: (d) => _dragStart(_cellAt(local(d.localPosition), inner)),
      onPanUpdate: (d) => _dragTo(_cellAt(local(d.localPosition), inner)),
      onPanEnd: (_) => _dragEnd(),
      onPanCancel: _dragEnd,
      child: board,
    );
  }

  /// Hop height (0..1) of the critter in cell [i] at celebration time [t], in a wave across the board.
  static double _hop(double t, int i, int n) {
    if (t <= 0 || t >= 1) return 0;
    final delay = ((i ~/ n) + (i % n)) / (2 * n) * 0.5;
    final local = ((t - delay) / 0.5).clamp(0.0, 1.0);
    return sin(local * pi * 2).abs() * (1 - local);
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    super.key,
    required this.mark,
    required this.ruledOut,
    required this.conflict,
    required this.hint,
    required this.target,
    required this.critter,
    required this.size,
    required this.hop,
  });

  final NestMark mark;
  final bool ruledOut;
  final bool conflict;
  final bool hint;
  final bool target;
  final String critter;
  final double size;
  final double hop;

  @override
  Widget build(BuildContext context) {
    Widget content = switch (mark) {
      NestMark.cross => SquashPop(key: const ValueKey('x'), soft: true, child: LeafMark(size: size * 0.5)),
      NestMark.critter => SquashPop(
        key: const ValueKey('c'),
        child: Transform.translate(
          offset: Offset(0, -hop * size * 0.32),
          child: HattedCritter(critter, size: size * 0.8),
        ),
      ),
      NestMark.empty =>
        ruledOut
            ? Container(
                key: const ValueKey('auto'),
                width: size * 0.16,
                height: size * 0.13,
                decoration: BoxDecoration(
                  color: const Color(0xFF8C7360).withValues(alpha: 0.28),
                  borderRadius: BorderRadius.all(Radius.elliptical(size * 0.08, size * 0.065)),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('e')),
    };
    if (conflict) content = Wobble(key: const ValueKey('wobble'), child: content);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: conflict ? bad.withValues(alpha: 0.38) : Colors.transparent,
        borderRadius: BorderRadius.circular(conflict || hint || target ? size * 0.16 : 0),
        border: conflict || hint || target
            ? Border.all(color: conflict ? bad : (hint ? gold : coral), width: max(2.5, size * 0.07))
            : null,
      ),
      child: Center(child: content),
    );
  }
}

/// Soft pastel flower beds: each zone's color, with little speckles of soil and petals.
class _BedsPainter extends CustomPainter {
  _BedsPainter(this.regions, this.n);

  final List<int> regions;
  final int n;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / n;
    final r = Random(n * 977 + regions.length);
    for (var i = 0; i < n * n; i++) {
      final rect = Rect.fromLTWH((i % n) * c, (i ~/ n) * c, c, c);
      final base = zoneColors[regions[i] % zoneColors.length];
      canvas.drawRect(rect.inflate(0.5), Paint()..color = base);
      // A lighter top-left glow per cell, and two speckles.
      canvas.drawCircle(rect.topLeft + Offset(c * 0.3, c * 0.3), c * 0.32, Paint()..color = Colors.white.withValues(alpha: 0.22));
      final dark = Paint()..color = Color.lerp(base, woodDark, 0.25)!.withValues(alpha: 0.45);
      for (var k = 0; k < 2; k++) {
        canvas.drawCircle(rect.topLeft + Offset(c * (0.15 + r.nextDouble() * 0.7), c * (0.15 + r.nextDouble() * 0.7)), c * 0.025, dark);
      }
    }
  }

  @override
  bool shouldRepaint(_BedsPainter old) => old.regions != regions || old.n != n;
}

/// Thin soft lines between cells, leafy hedges between zones.
class _ZonePainter extends CustomPainter {
  _ZonePainter(this.regions, this.n);

  final List<int> regions;
  final int n;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / n;
    final thin = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.2;
    final hedges = Path();
    for (var r = 0; r < n; r++) {
      for (var col = 0; col < n; col++) {
        final i = r * n + col;
        if (col < n - 1) {
          final p1 = Offset((col + 1) * c, r * c), p2 = Offset((col + 1) * c, (r + 1) * c);
          if (regions[i] != regions[i + 1]) {
            hedges
              ..moveTo(p1.dx, p1.dy)
              ..lineTo(p2.dx, p2.dy);
          } else {
            canvas.drawLine(p1, p2, thin);
          }
        }
        if (r < n - 1) {
          final p1 = Offset(col * c, (r + 1) * c), p2 = Offset((col + 1) * c, (r + 1) * c);
          if (regions[i] != regions[i + n]) {
            hedges
              ..moveTo(p1.dx, p1.dy)
              ..lineTo(p2.dx, p2.dy);
          } else {
            canvas.drawLine(p1, p2, thin);
          }
        }
      }
    }
    final w = max(4.0, c * 0.12);
    canvas.drawPath(hedges, Paint()
      ..color = const Color(0xFF2F7A26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round);
    canvas.drawPath(hedges, Paint()
      ..color = const Color(0xFF55AD3C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.5
      ..strokeCap = StrokeCap.round);
    // Leafy bumps along the hedges.
    final leafDot = Paint()..color = const Color(0xFF7FCB5E);
    for (final m in hedges.computeMetrics()) {
      for (var d = w; d < m.length; d += w * 1.6) {
        final t = m.getTangentForOffset(d);
        if (t != null) canvas.drawCircle(t.position, w * 0.2, leafDot);
      }
    }
  }

  @override
  bool shouldRepaint(_ZonePainter old) => old.regions != regions || old.n != n;
}
