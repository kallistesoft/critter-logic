import 'dart:math';

import 'package:flutter/material.dart';

import '../worlds/world.dart';

/// A burst of soft confetti driven by [animation] (0→1).
class Confetti extends StatelessWidget {
  const Confetti({super.key, required this.animation, this.count = 70, this.seed = 7});

  final Animation<double> animation;
  final int count;
  final int seed;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, _) => CustomPaint(painter: _ConfettiPainter(animation.value, count, seed), size: Size.infinite),
        ),
      );
}

class _Piece {
  _Piece(Random r)
      : x = r.nextDouble(),
        vx = (r.nextDouble() - 0.5) * 0.9,
        vy = -0.9 - r.nextDouble() * 0.9,
        spin = (r.nextDouble() - 0.5) * 14,
        size = 6 + r.nextDouble() * 7,
        round = r.nextBool(),
        color = r.nextInt(1 << 20);

  final double x, vx, vy, spin, size;
  final bool round;
  /// Picks a color of the World's celebration set.
  final int color;

}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t, int count, int seed) : pieces = _cache.putIfAbsent((count, seed), () {
          final r = Random(seed);
          return List.generate(count, (_) => _Piece(r));
        });

  static final _cache = <(int, int), List<_Piece>>{};
  final double t;
  final List<_Piece> pieces;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = activeWorld.celebration;
    if (t <= 0 || t >= 1) return;
    final fade = t < 0.75 ? 1.0 : (1 - t) / 0.25;
    for (final p in pieces) {
      // Thrown up from the bottom middle, then falling with gravity.
      final x = size.width * (0.5 + (p.x - 0.5) * 0.3 + p.vx * t);
      final y = size.height * (0.85 + p.vy * t + 1.6 * t * t);
      final paint = Paint()..color = colors[p.color % colors.length].withValues(alpha: fade);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.55),
                const Radius.circular(2)),
            paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
