import 'dart:math';

import '../worlds/world.dart';
import 'package:flutter/material.dart';

import '../../puzzles/pairs/pairs.dart';
import '../palette.dart';
import 'board_bits.dart';
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
    final pad = side * 0.035;
    final cell = (side - 2 * pad) / n;
    final gap = cell * 0.09;
    final t = celebrate?.value ?? 0;
    Offset topLeft(int i) => Offset(pad + (i % n) * cell, pad + (i ~/ n) * cell);
    return CustomPaint(
      painter: _LawnPainter(),
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
        if (targets.isNotEmpty)
          Positioned(
            left: topLeft(targets.first).dx + cell * 0.5,
            top: topLeft(targets.first).dy + cell * 0.55,
            child: IgnorePointer(child: PointingHand(size: cell * 0.62)),
          ),
      ]),
    );
  }

  Widget _linkMarker(PairsLink link, Offset Function(int) topLeft, double cell, int n) {
    final a = min(link.a, link.b), b = max(link.a, link.b);
    final horizontal = b == a + 1;
    final o = topLeft(a);
    final center = horizontal ? Offset(o.dx + cell, o.dy + cell / 2) : Offset(o.dx + cell / 2, o.dy + cell);
    final d = cell * 0.32;
    return Positioned(
      left: center.dx - d / 2,
      top: center.dy - d / 2,
      width: d,
      height: d,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: activeWorld.board.linkFill,
            shape: BoxShape.circle,
            border: Border.all(color: activeWorld.board.linkEdge, width: max(1.5, d * 0.09)),
            boxShadow: const [BoxShadow(color: Color(0x55000000), offset: Offset(0, 2))],
          ),
          alignment: Alignment.center,
          child: Text(link.same ? '=' : '×',
              style: TextStyle(fontFamily: displayFont, color: activeWorld.board.linkEdge, fontSize: d * 0.66, fontWeight: FontWeight.w700, height: 1)),
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
    final ring = conflict ? bad : (hint ? gold : (target ? coral : null));
    final depth = size * 0.08;
    Widget token = value == null
        ? const SizedBox.expand()
        : TweenAnimationBuilder<double>(
            key: ValueKey(value),
            tween: Tween(begin: given ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 420),
            builder: (_, v, child) {
              // A coin flip: turns edge-on to face, then settles with a little bounce.
              final turn = (1 - Curves.easeOut.transform(v)) * pi / 2;
              final bounce = 1 + sin(v * pi) * 0.12;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.002)
                  ..rotateY(turn)
                  ..scaleByDouble(bounce, bounce, 1, 1),
                child: child,
              );
            },
            child: Padding(padding: EdgeInsets.all(size * 0.15), child: SymbolIcon(value!, faded: given)),
          );
    if (conflict) token = Wobble(key: const ValueKey('wobble'), child: token);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Transform.translate(
        offset: Offset(0, -wave * size * 0.22),
        child: Transform.scale(
          scale: 1 + wave * 0.1,
          child: CustomPaint(
            painter: _StonePainter(given: given, conflict: conflict, ring: ring, depth: depth),
            child: Padding(padding: EdgeInsets.only(bottom: depth), child: token),
          ),
        ),
      ),
    );
  }
}

/// A grassy lawn under the stepping stones.
class _LawnPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final b = activeWorld.board;
    final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(size.width * 0.06));
    canvas.drawRRect(rr.shift(const Offset(0, 6)), Paint()..color = b.lawnEdge);
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [b.lawnTop, b.lawnBottom],
        ).createShader(Offset.zero & size),
    );
    final r = Random(3);
    final tuft = Paint()
      ..color = b.lawnTuft
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 40; i++) {
      final p = Offset(r.nextDouble() * size.width, r.nextDouble() * size.height);
      canvas.drawLine(p, p + const Offset(-3, -6), tuft);
      canvas.drawLine(p, p + const Offset(2, -7), tuft);
    }
    if (b.glow) paintGlow(canvas, Path()..addRRect(rr.deflate(1.5)), b.lawnEdge, 3);
    canvas.drawRRect(rr.deflate(1.5), Paint()
      ..color = b.lawnEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(_LawnPainter old) => false;
}

/// A rounded stepping stone with a thick bottom edge; givens are mossy and darker.
class _StonePainter extends CustomPainter {
  _StonePainter({required this.given, required this.conflict, required this.ring, required this.depth});

  final bool given;
  final bool conflict;
  final Color? ring;
  final double depth;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Radius.circular(size.width * 0.26);
    final outer = RRect.fromRectAndRadius(Offset.zero & size, r);
    final face = RRect.fromLTRBR(0, 0, size.width, size.height - depth, r);
    final b = activeWorld.board;
    final top = given ? b.givenTop : b.stoneTop;
    final low = given ? b.givenLow : b.stoneLow;
    final edge = given ? b.givenEdge : b.stoneEdge;
    canvas.drawRRect(outer, Paint()..color = edge);
    canvas.drawRRect(
      face,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, low])
            .createShader(face.outerRect),
    );
    if (given && b.moss != null) {
      final moss = Paint()..color = b.moss!;
      canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.2), size.width * 0.07, moss);
      canvas.drawCircle(Offset(size.width * 0.28, size.height * 0.13), size.width * 0.05, moss);
    } else if (!given) {
      canvas.drawOval(
        Rect.fromLTWH(size.width * 0.14, size.height * 0.08, size.width * 0.36, size.height * 0.14),
        Paint()..color = b.stoneShine,
      );
    }
    if (conflict) canvas.drawRRect(face, Paint()..color = bad.withValues(alpha: 0.28));
    if (ring != null) {
      canvas.drawRRect(face.deflate(size.width * 0.03), Paint()
        ..color = ring!
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(2.5, size.width * 0.07));
    }
  }

  @override
  bool shouldRepaint(_StonePainter old) =>
      old.given != given || old.conflict != conflict || old.ring != ring || old.depth != depth;
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
