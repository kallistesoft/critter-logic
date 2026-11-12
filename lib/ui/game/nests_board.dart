import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../puzzles/nests/nests.dart';
import '../critter_image.dart';
import '../palette.dart';
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
    if (s.cells[cell] == from && s.paint(cell, _paint!)) _lastCell = cell;
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
    final cell = side / n;
    final excluded = widget.autoCross ? s.excluded() : const <int>{};
    final t = widget.celebrate?.value ?? 0;
    final grid = Stack(
      children: [
        for (var i = 0; i < n * n; i++)
          Positioned(
            left: (i % n) * cell,
            top: (i ~/ n) * cell,
            width: cell,
            height: cell,
            child: _Cell(
              key: Key('cell-$i'),
              color: zoneColors[s.puzzle.regions[i] % zoneColors.length],
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
          child: IgnorePointer(child: CustomPaint(painter: _ZonePainter(s.puzzle.regions, n))),
        ),
      ],
    );
    final board = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: shadow, blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: grid),
    );
    if (widget.readOnly) return board;
    return GestureDetector(
      dragStartBehavior: DragStartBehavior.down,
      onTapUp: (d) {
        final c = _cellAt(d.localPosition, side);
        if (c != null) _tap(c);
      },
      onPanStart: (d) => _dragStart(_cellAt(d.localPosition, side)),
      onPanUpdate: (d) => _dragTo(_cellAt(d.localPosition, side)),
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
    required this.color,
    required this.mark,
    required this.ruledOut,
    required this.conflict,
    required this.hint,
    required this.target,
    required this.critter,
    required this.size,
    required this.hop,
  });

  final Color color;
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
      NestMark.cross => _Pop(
        key: const ValueKey('x'),
        child: Icon(Icons.close_rounded, size: size * 0.42, color: ink.withValues(alpha: 0.42)),
      ),
      NestMark.critter => _Pop(
        key: const ValueKey('c'),
        elastic: true,
        child: Transform.translate(
          offset: Offset(0, -hop * size * 0.28),
          child: CritterImage(critter, size: size * 0.78),
        ),
      ),
      NestMark.empty =>
        ruledOut
            ? Icon(
                Icons.close_rounded,
                key: const ValueKey('auto'),
                size: size * 0.26,
                color: ink.withValues(alpha: 0.16),
              )
            : const SizedBox.shrink(key: ValueKey('e')),
    };
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        color: conflict ? Color.alphaBlend(bad.withValues(alpha: 0.42), color) : color,
        border: conflict || hint || target
            ? Border.all(color: conflict ? bad : (hint ? gold : accent), width: max(2.5, size * 0.07))
            : null,
      ),
      child: Center(child: content),
    );
  }
}

/// Scales its child in when it appears.
class _Pop extends StatelessWidget {
  const _Pop({super.key, required this.child, this.elastic = false});

  final Widget child;
  final bool elastic;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0.3, end: 1),
    duration: Duration(milliseconds: elastic ? 380 : 160),
    curve: elastic ? Curves.elasticOut : Curves.easeOutBack,
    builder: (_, v, child) => Transform.scale(scale: v, child: child),
    child: child,
  );
}

/// Thin white grid lines, thick ink lines between zones.
class _ZonePainter extends CustomPainter {
  _ZonePainter(this.regions, this.n);

  final List<int> regions;
  final int n;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / n;
    final thin = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 1.5;
    final thick = Paint()
      ..color = ink.withValues(alpha: 0.78)
      ..strokeWidth = max(2.5, c * 0.06)
      ..strokeCap = StrokeCap.square;
    for (var r = 0; r < n; r++) {
      for (var col = 0; col < n; col++) {
        final i = r * n + col;
        if (col < n - 1) {
          final p1 = Offset((col + 1) * c, r * c), p2 = Offset((col + 1) * c, (r + 1) * c);
          canvas.drawLine(p1, p2, regions[i] != regions[i + 1] ? thick : thin);
        }
        if (r < n - 1) {
          final p1 = Offset(col * c, (r + 1) * c), p2 = Offset((col + 1) * c, (r + 1) * c);
          canvas.drawLine(p1, p2, regions[i] != regions[i + n] ? thick : thin);
        }
      }
    }
    final rect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)).deflate(thick.strokeWidth / 2);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = thick.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = thick.strokeWidth * 1.4,
    );
  }

  @override
  bool shouldRepaint(_ZonePainter old) => old.regions != regions || old.n != n;
}
