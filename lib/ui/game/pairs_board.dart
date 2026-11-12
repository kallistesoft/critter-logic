import 'dart:math';

import 'package:flutter/material.dart';

import '../../puzzles/pairs/pairs.dart';
import '../palette.dart';
import 'session.dart';

/// The Pairs grid: tap cycles empty → sun → moon. Givens are locked and darker; =/× links sit on the edges.
class PairsBoard extends StatelessWidget {
  const PairsBoard({super.key, required this.session, this.readOnly = false, this.celebrate, this.targets = const {}, this.onMove});

  final PairsSession session;
  final bool readOnly;
  final Animation<double>? celebrate;
  final Set<int> targets;
  final void Function(MoveOutcome outcome, int cell)? onMove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final side = min(constraints.maxWidth, constraints.maxHeight);
      return Center(
        child: SizedBox.square(
          dimension: side,
          child: AnimatedBuilder(
            animation: Listenable.merge([session, ?celebrate]),
            builder: (context, _) => _board(side),
          ),
        ),
      );
    });
  }

  Widget _board(double side) {
    final s = session;
    final n = s.size;
    final pad = side * 0.025;
    final cell = (side - 2 * pad) / n;
    final gap = cell * 0.07;
    final t = celebrate?.value ?? 0;
    Offset topLeft(int i) => Offset(pad + (i % n) * cell, pad + (i ~/ n) * cell);
    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: shadow, blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        for (var i = 0; i < n * n; i++)
          Positioned(
            left: topLeft(i).dx + gap / 2,
            top: topLeft(i).dy + gap / 2,
            width: cell - gap,
            height: cell - gap,
            child: _Tile(
              key: Key('cell-$i'),
              value: s.cells[i],
              given: s.puzzle.givens[i] != null,
              conflict: s.conflicts.contains(i),
              hint: s.hintCell == i,
              target: targets.contains(i),
              size: cell - gap,
              wave: _wave(t, i, n),
              onTap: readOnly
                  ? null
                  : () {
                      final outcome = s.tap(i);
                      if (outcome != MoveOutcome.none) onMove?.call(outcome, i);
                    },
            ),
          ),
        for (final link in s.puzzle.links) _linkMarker(link, topLeft, cell, n),
      ]),
    );
  }

  Widget _linkMarker(PairsLink link, Offset Function(int) topLeft, double cell, int n) {
    final a = min(link.a, link.b), b = max(link.a, link.b);
    final horizontal = b == a + 1;
    final o = topLeft(a);
    final center = horizontal ? Offset(o.dx + cell, o.dy + cell / 2) : Offset(o.dx + cell / 2, o.dy + cell);
    final d = cell * 0.3;
    return Positioned(
      left: center.dx - d / 2,
      top: center.dy - d / 2,
      width: d,
      height: d,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            shape: BoxShape.circle,
            border: Border.all(color: ink.withValues(alpha: 0.18), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(link.same ? '=' : '×', style: TextStyle(color: ink, fontSize: d * 0.62, fontWeight: FontWeight.w900, height: 1)),
        ),
      ),
    );
  }

  static double _wave(double t, int i, int n) {
    if (t <= 0 || t >= 1) return 0;
    final delay = ((i ~/ n) + (i % n)) / (2 * n) * 0.5;
    final local = ((t - delay) / 0.5).clamp(0.0, 1.0);
    return sin(local * pi);
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    super.key,
    required this.value,
    required this.given,
    required this.conflict,
    required this.hint,
    required this.target,
    required this.size,
    required this.wave,
    this.onTap,
  });

  final int? value;
  final bool given;
  final bool conflict;
  final bool hint;
  final bool target;
  final double size;
  final double wave;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final base = given ? tileGiven : tileEmpty;
    final ring = conflict ? bad : (hint ? gold : (target ? accent : null));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Transform.scale(
        scale: 1 + wave * 0.14,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: conflict ? Color.alphaBlend(bad.withValues(alpha: 0.22), base) : base,
            borderRadius: BorderRadius.circular(size * 0.22),
            border: ring == null ? null : Border.all(color: ring, width: max(2.5, size * 0.06)),
          ),
          child: value == null
              ? null
              : TweenAnimationBuilder<double>(
                  key: ValueKey(value),
                  tween: Tween(begin: given ? 1 : 0.3, end: 1),
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.elasticOut,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Padding(
                    padding: EdgeInsets.all(size * 0.16),
                    child: SymbolIcon(value!, faded: given),
                  ),
                ),
        ),
      ),
    );
  }
}

/// A painted sun or moon.
class SymbolIcon extends StatelessWidget {
  const SymbolIcon(this.symbol, {super.key, this.faded = false});

  final int symbol;

  /// Givens: a touch darker so the player's own symbols stand out from them.
  final bool faded;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _SymbolPainter(symbol, faded), size: Size.infinite);
}

class _SymbolPainter extends CustomPainter {
  _SymbolPainter(this.symbol, this.faded);

  final int symbol;
  final bool faded;

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width, size.height);
    final c = size.center(Offset.zero);
    if (symbol == sun) {
      final color = faded ? Color.lerp(sunColor, const Color(0xFFB07A1A), 0.35)! : sunColor;
      final ray = Paint()
        ..color = color
        ..strokeWidth = s * 0.09
        ..strokeCap = StrokeCap.round;
      for (var k = 0; k < 8; k++) {
        final a = k * pi / 4;
        final dir = Offset(cos(a), sin(a));
        canvas.drawLine(c + dir * s * 0.36, c + dir * s * 0.48, ray);
      }
      canvas.drawCircle(c, s * 0.27, Paint()..color = color);
      canvas.drawCircle(c - Offset(s * 0.08, s * 0.08), s * 0.07, Paint()..color = Colors.white.withValues(alpha: 0.45));
    } else {
      final color = faded ? Color.lerp(moonColor, const Color(0xFF2E3570), 0.35)! : moonColor;
      final outer = Path()..addOval(Rect.fromCircle(center: c, radius: s * 0.42));
      final bite = Path()..addOval(Rect.fromCircle(center: c + Offset(s * 0.2, -s * 0.12), radius: s * 0.34));
      canvas.drawPath(Path.combine(PathOperation.difference, outer, bite), Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_SymbolPainter old) => old.symbol != symbol || old.faded != faded;
}
