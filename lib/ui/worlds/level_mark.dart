import 'dart:math';

import 'package:flutter/material.dart';

/// How a World draws a critter's level (⭐1–5) over its picture.
enum LevelMarkStyle {
  /// A row of chunky stars along the bottom edge (Meadow, Winter).
  stars,

  /// Small stars set along the lower rim of a round badge (Lodge).
  rim,

  /// Tiny round pips in a row (Clean Pro).
  pips,

  /// Stars that glow (Neon).
  glow,
}

/// The level stars, drawn over a critter picture of [size] (it fills a [size] square).
class LevelMark extends StatelessWidget {
  const LevelMark({
    super.key,
    required this.level,
    required this.size,
    this.style = LevelMarkStyle.stars,
    this.color = const Color(0xFFFFC93C),
    this.edge = const Color(0xFF9A6A0C),
  });

  final int level;
  final double size;
  final LevelMarkStyle style;
  final Color color;
  final Color edge;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: LevelMarkPainter(level: level, style: style, color: color, edge: edge)),
      );
}

class LevelMarkPainter extends CustomPainter {
  const LevelMarkPainter({required this.level, required this.style, required this.color, required this.edge});

  final int level;
  final LevelMarkStyle style;
  final Color color;
  final Color edge;

  @override
  void paint(Canvas canvas, Size size) {
    final n = level.clamp(0, 5);
    if (n == 0) return;
    final s = min(size.width, size.height);
    switch (style) {
      case LevelMarkStyle.stars:
      case LevelMarkStyle.glow:
        final r = (s * 0.1).clamp(4.0, 13.0);
        final gap = r * 1.75;
        final y = size.height - r * 0.85;
        for (var i = 0; i < n; i++) {
          final c = Offset(size.width / 2 + (i - (n - 1) / 2) * gap, y);
          if (style == LevelMarkStyle.glow) {
            canvas.drawPath(starPath(c, r * 1.25), Paint()
              ..color = color.withValues(alpha: 0.7)
              ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.6));
            _star(canvas, c, r, fill: Colors.white, stroke: color, width: max(1.0, r * 0.28));
          } else {
            _star(canvas, c, r, fill: color, stroke: edge, width: max(1.0, r * 0.3));
          }
        }
      case LevelMarkStyle.rim:
        final r = (s * 0.075).clamp(3.5, 11.0);
        final ring = s * 0.45;
        final center = Offset(size.width / 2, size.height / 2);
        for (var i = 0; i < n; i++) {
          final a = pi / 2 + (i - (n - 1) / 2) * 0.36;
          _star(canvas, center + Offset(cos(a), sin(a)) * ring, r, fill: color, stroke: edge, width: max(1.0, r * 0.32));
        }
      case LevelMarkStyle.pips:
        final r = (s * 0.045).clamp(2.2, 6.0);
        final gap = r * 2.8;
        final y = size.height - r * 1.4;
        for (var i = 0; i < n; i++) {
          final c = Offset(size.width / 2 + (i - (n - 1) / 2) * gap, y);
          canvas.drawCircle(c, r + 1, Paint()..color = edge);
          canvas.drawCircle(c, r, Paint()..color = color);
        }
    }
  }

  void _star(Canvas canvas, Offset c, double r, {required Color fill, required Color stroke, required double width}) {
    final path = starPath(c, r);
    canvas.drawPath(path.shift(Offset(0, r * 0.18)), Paint()..color = const Color(0x40000000));
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(path, Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round);
    canvas.drawCircle(c + Offset(-r * 0.2, -r * 0.25), r * 0.16, Paint()..color = Colors.white.withValues(alpha: 0.7));
  }

  @override
  bool shouldRepaint(LevelMarkPainter old) =>
      old.level != level || old.style != style || old.color != color || old.edge != edge;
}

/// A five-pointed star of outer radius [r] around [c].
Path starPath(Offset c, double r) {
  final path = Path();
  for (var k = 0; k < 10; k++) {
    final radius = k.isEven ? r : r * 0.48;
    final a = -pi / 2 + k * pi / 5;
    final p = c + Offset(cos(a), sin(a)) * radius;
    k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
  }
  return path..close();
}

/// One level star, lit ([filled]) or an empty slot, for the capsule reveal.
class LevelStarIcon extends StatelessWidget {
  const LevelStarIcon({super.key, required this.filled, this.size = 16, this.color = const Color(0xFFFFC93C),
      this.edge = const Color(0xFF9A6A0C), this.empty = const Color(0x33000000)});

  final bool filled;
  final double size;
  final Color color, edge, empty;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _OneStar(filled ? color : empty, filled ? edge : Colors.transparent)),
      );
}

class _OneStar extends CustomPainter {
  const _OneStar(this.fill, this.edge);

  final Color fill, edge;

  @override
  void paint(Canvas canvas, Size size) {
    final path = starPath(size.center(Offset.zero), size.width * 0.46);
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(path, Paint()
      ..color = edge
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, size.width * 0.08)
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_OneStar old) => old.fill != fill || old.edge != edge;
}
