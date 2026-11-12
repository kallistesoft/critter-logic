import 'dart:math';

import 'package:flutter/material.dart';

import '../meadow.dart';
import '../palette.dart';

/// Pops its child in with a squash and stretch when it appears.
class SquashPop extends StatelessWidget {
  const SquashPop({super.key, required this.child, this.soft = false});

  final Widget child;

  /// Smaller, quicker pop (crosses).
  final bool soft;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: soft ? 260 : 520),
        builder: (_, t, child) {
          final base = soft ? Curves.easeOutBack.transform(t) : Curves.elasticOut.transform(t).clamp(0.0, 1.4);
          final wob = sin(t * pi * 2) * (1 - t) * (soft ? 0.12 : 0.28);
          return Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(max(0, base * (1 + wob)), max(0, base * (1 - wob)), 1),
            child: child,
          );
        },
        child: child,
      );
}

/// A short red wobble when a cell breaks a rule.
class Wobble extends StatelessWidget {
  const Wobble({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 520),
        builder: (_, t, child) => Transform.rotate(angle: sin(t * pi * 6) * 0.28 * (1 - t), child: child),
        child: child,
      );
}

/// A little green leaf: the Nests "not here" mark.
class LeafMark extends StatelessWidget {
  const LeafMark({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(dimension: size, child: const CustomPaint(painter: _LeafPainter()));
}

class _LeafPainter extends CustomPainter {
  const _LeafPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-0.6);
    final leaf = Path()
      ..moveTo(0, -h * 0.46)
      ..quadraticBezierTo(w * 0.42, -h * 0.1, 0, h * 0.42)
      ..quadraticBezierTo(-w * 0.42, -h * 0.1, 0, -h * 0.46)
      ..close();
    canvas.drawPath(leaf.shift(const Offset(0, 2)), Paint()..color = const Color(0x33000000));
    canvas.drawPath(leaf, Paint()..color = const Color(0xFF5DB043));
    canvas.drawPath(leaf, Paint()
      ..color = const Color(0xFF2F7A26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, w * 0.06));
    canvas.drawLine(Offset(0, -h * 0.34), Offset(0, h * 0.5), Paint()
      ..color = const Color(0xFF2F7A26)
      ..strokeWidth = max(1, w * 0.06)
      ..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(-w * 0.1, -h * 0.12), w * 0.06, Paint()..color = Colors.white.withValues(alpha: 0.5));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LeafPainter old) => false;
}

/// A pointing hand that taps at a spot (tutorial). Its fingertip is at the widget's top-left.
class PointingHand extends StatefulWidget {
  const PointingHand({super.key, required this.size});

  final double size;

  @override
  State<PointingHand> createState() => _PointingHandState();
}

class _PointingHandState extends State<PointingHand> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ambientMotion(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final t = _c.value;
        // Moves in, taps (press), lifts off.
        final press = t < 0.5 ? 0.0 : sin((t - 0.5) / 0.5 * pi);
        final dy = (1 - press) * s * 0.18;
        return SizedBox(
          width: s * 1.2,
          height: s * 1.4,
          child: Stack(clipBehavior: Clip.none, children: [
            if (press > 0.05)
              Positioned(
                left: -s * 0.35 * press,
                top: -s * 0.35 * press,
                child: Container(
                  width: s * 0.7 * press,
                  height: s * 0.7 * press,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 1 - press * 0.6), width: 3),
                  ),
                ),
              ),
            Positioned(
              left: -s * 0.18,
              top: dy - s * 0.02,
              child: Transform.rotate(
                angle: -0.35,
                alignment: Alignment.topLeft,
                child: Stack(children: [
                  Icon(Icons.pan_tool_alt_rounded, size: s, color: woodEdge),
                  Padding(
                    padding: EdgeInsets.all(s * 0.06),
                    child: Icon(Icons.pan_tool_alt_rounded, size: s * 0.88, color: Colors.white),
                  ),
                ]),
              ),
            ),
          ]),
        );
      },
    );
  }
}
