import 'dart:math';

import 'package:flutter/material.dart';

import 'banner_slot.dart';
import 'palette.dart';
import 'services.dart';

/// False when the player asked the system for reduced motion (and in widget tests): ambient loops stay still.
bool ambientMotion(BuildContext context) => !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

/// The cozy world every screen sits in: sky, sun, drifting clouds, rolling hills and a flowery meadow.
/// One instance lives behind the navigator, so pages slide over the same landscape.
class MeadowWorld extends StatelessWidget {
  const MeadowWorld({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(children: [
        const Positioned.fill(child: MeadowBackground()),
        Positioned.fill(child: child),
      ]);
}

class MeadowBackground extends StatefulWidget {
  const MeadowBackground({super.key});

  @override
  State<MeadowBackground> createState() => _MeadowBackgroundState();
}

class _MeadowBackgroundState extends State<MeadowBackground> with SingleTickerProviderStateMixin {
  late final _drift = AnimationController(vsync: this, duration: const Duration(seconds: 120));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ambientMotion(context)) {
      if (!_drift.isAnimating) _drift.repeat();
    } else {
      _drift.stop();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final size = box.biggest;
      final bottomInset = MediaQuery.paddingOf(context).bottom;
      return Stack(clipBehavior: Clip.hardEdge, children: [
        Positioned.fill(
          child: RepaintBoundary(child: CustomPaint(painter: _SkyPainter(bottomInset))),
        ),
        // Sun, slowly turning.
        Positioned(
          left: size.width * 0.9 - _sunBox(size) / 2,
          top: size.height * 0.19 - _sunBox(size) / 2,
          width: _sunBox(size),
          height: _sunBox(size),
          child: AnimatedBuilder(
            animation: _drift,
            builder: (_, child) => Transform.rotate(angle: _drift.value * 2 * pi, child: child),
            child: const RepaintBoundary(child: CustomPaint(painter: _SunPainter())),
          ),
        ),
        for (final c in _clouds)
          AnimatedBuilder(
            animation: _drift,
            builder: (_, child) {
              final w = c.scale * 150;
              final span = size.width + w * 2;
              final x = ((c.start + _drift.value * c.speed) % 1.0) * span - w;
              return Positioned(left: x, top: size.height * c.y, width: w, height: w * 0.5, child: child!);
            },
            child: RepaintBoundary(child: CustomPaint(painter: _CloudPainter(c.alpha))),
          ),
        // The meadow in front of the clouds' paths.
        Positioned.fill(
          child: RepaintBoundary(child: CustomPaint(painter: _HillsPainter(bottomInset))),
        ),
      ]);
    });
  }

  static double _sunBox(Size s) => min(s.width, 700) * 0.42;

  static const _clouds = [
    _Cloud(y: 0.04, scale: 1.0, speed: 1, start: 0.1, alpha: 0.95),
    _Cloud(y: 0.17, scale: 0.7, speed: 2, start: 0.55, alpha: 0.85),
    _Cloud(y: 0.29, scale: 0.85, speed: 1, start: 0.8, alpha: 0.8),
    _Cloud(y: 0.42, scale: 0.55, speed: 3, start: 0.3, alpha: 0.7),
  ];
}

class _Cloud {
  const _Cloud({required this.y, required this.scale, required this.speed, required this.start, required this.alpha});
  final double y, scale, start, alpha;
  final int speed;
}

/// Height of the grassy foreground band at the bottom of the screen.
double meadowGround(double height, double bottomInset) => (height * 0.2).clamp(150.0, 300.0) + bottomInset;

class _SkyPainter extends CustomPainter {
  const _SkyPainter(this.inset);

  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [skyTop, skyMid, skyLow, skyLow],
          stops: [0, 0.38, 0.66, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_SkyPainter old) => old.inset != inset;
}

class _SunPainter extends CustomPainter {
  const _SunPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFFF3B0).withValues(alpha: 0.9),
          const Color(0xFFFFF3B0).withValues(alpha: 0),
        ]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    final ray = Paint()..color = const Color(0x55FFF8C8);
    for (var k = 0; k < 12; k++) {
      final a = k * pi / 6;
      final p = Path()
        ..moveTo(c.dx + cos(a - 0.09) * r * 0.36, c.dy + sin(a - 0.09) * r * 0.36)
        ..lineTo(c.dx + cos(a) * r * 0.95, c.dy + sin(a) * r * 0.95)
        ..lineTo(c.dx + cos(a + 0.09) * r * 0.36, c.dy + sin(a + 0.09) * r * 0.36)
        ..close();
      canvas.drawPath(p, ray);
    }
    canvas.drawCircle(c, r * 0.3, Paint()..color = const Color(0xFFFFE066));
    canvas.drawCircle(c, r * 0.24, Paint()..color = const Color(0xFFFFEE8A));
  }

  @override
  bool shouldRepaint(_SunPainter old) => false;
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter(this.alpha);

  final double alpha;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final shade = Paint()..color = const Color(0xFFD7ECFA).withValues(alpha: alpha);
    final fill = Paint()..color = Colors.white.withValues(alpha: alpha);
    void puff(Paint p, double dy) {
      canvas.drawCircle(Offset(w * 0.28, h * 0.62 + dy), h * 0.3, p);
      canvas.drawCircle(Offset(w * 0.47, h * 0.42 + dy), h * 0.4, p);
      canvas.drawCircle(Offset(w * 0.68, h * 0.55 + dy), h * 0.32, p);
      canvas.drawRRect(
          RRect.fromLTRBR(w * 0.12, h * 0.55 + dy, w * 0.88, h * 0.92 + dy, Radius.circular(h * 0.2)), p);
    }

    puff(shade, h * 0.06);
    puff(fill, 0);
  }

  @override
  bool shouldRepaint(_CloudPainter old) => old.alpha != alpha;
}

class _HillsPainter extends CustomPainter {
  const _HillsPainter(this.inset);

  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final ground = meadowGround(h, inset);
    final front = h - ground;

    // Far hills with a few round trees.
    final far = Path()..moveTo(0, front - ground * 0.55);
    for (var x = 0.0; x <= w; x += 8) {
      far.lineTo(x, front - ground * 0.55 - sin(x / w * pi * 2.2 + 0.6) * ground * 0.16 - ground * 0.08);
    }
    far
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(far, Paint()..color = hillFar);
    final rnd = Random(4);
    for (final tx in [0.08, 0.22, 0.63, 0.9]) {
      final x = w * tx;
      final y = front - ground * 0.55 - sin(x / w * pi * 2.2 + 0.6) * ground * 0.16 - ground * 0.08 + 6;
      final r = ground * (0.09 + rnd.nextDouble() * 0.04);
      canvas.drawRect(Rect.fromLTWH(x - r * 0.12, y - r * 1.2, r * 0.24, r * 1.2), Paint()..color = woodDark);
      final crown = Paint()..color = const Color(0xFF7DC45A);
      canvas.drawCircle(Offset(x, y - r * 1.6), r, crown);
      canvas.drawCircle(Offset(x - r * 0.6, y - r * 1.2), r * 0.7, crown);
      canvas.drawCircle(Offset(x + r * 0.6, y - r * 1.25), r * 0.72, crown);
      canvas.drawCircle(Offset(x - r * 0.3, y - r * 1.9), r * 0.35, Paint()..color = const Color(0x55FFFFFF));
    }

    // Middle hill.
    final mid = Path()..moveTo(0, front - ground * 0.25);
    for (var x = 0.0; x <= w; x += 8) {
      mid.lineTo(x, front - ground * 0.22 - sin(x / w * pi * 1.4 + 2.2) * ground * 0.14);
    }
    mid
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(mid, Paint()..color = hillMid);

    // Front meadow, with a lighter lip and flowers.
    final top = Path()..moveTo(0, front);
    for (var x = 0.0; x <= w; x += 8) {
      top.lineTo(x, front + sin(x / w * pi * 3 + 1) * ground * 0.05);
    }
    final fill = Path.from(top)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final rect = Rect.fromLTWH(0, front - 20, w, ground + 20);
    canvas.drawPath(
      fill,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [grass, Color(0xFF5BAF3E)],
        ).createShader(rect),
    );
    canvas.drawPath(
      top,
      Paint()
        ..color = const Color(0xFF9BE07A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // Tufts and flowers, deterministic.
    final r = Random(7);
    final tuft = Paint()
      ..color = grassDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final count = (w / 26).round();
    for (var i = 0; i < count; i++) {
      final x = r.nextDouble() * w;
      final y = front + 14 + r.nextDouble() * (ground - 30);
      if (r.nextDouble() < 0.55) {
        canvas.drawLine(Offset(x, y), Offset(x - 4, y - 9), tuft);
        canvas.drawLine(Offset(x, y), Offset(x + 1, y - 11), tuft);
        canvas.drawLine(Offset(x, y), Offset(x + 5, y - 8), tuft);
      } else {
        _flower(canvas, Offset(x, y), 4 + r.nextDouble() * 3, _petals[r.nextInt(_petals.length)]);
      }
    }
  }

  static const _petals = [Color(0xFFFFFFFF), Color(0xFFFFB3C7), Color(0xFFFFE066), Color(0xFFC9B6FF), Color(0xFFFF9E80)];

  static void _flower(Canvas canvas, Offset c, double s, Color petal) {
    canvas.drawLine(c + Offset(0, s * 1.2), c + Offset(0, s * 3), Paint()
      ..color = grassDark
      ..strokeWidth = 1.6);
    final p = Paint()..color = petal;
    for (var k = 0; k < 5; k++) {
      final a = k * 2 * pi / 5;
      canvas.drawCircle(c + Offset(cos(a), sin(a)) * s * 0.75, s * 0.6, p);
    }
    canvas.drawCircle(c, s * 0.45, Paint()..color = const Color(0xFFFFC23D));
  }

  @override
  bool shouldRepaint(_HillsPainter old) => old.inset != inset;
}

/// Lays a phone-sized layout out and scales it up on tablets, so cards, text and boards fill the screen.
class UiScale extends StatelessWidget {
  const UiScale({super.key, required this.child});

  final Widget child;

  static double factorFor(Size s) {
    if (s.width <= 520) return 1;
    final byWidth = min(s.width / 440, 1.75);
    final byHeight = max(1.0, s.height / 660);
    return min(byWidth, byHeight);
  }

  static double of(BuildContext context) => factorFor(MediaQuery.sizeOf(context));

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final s = factorFor(box.biggest);
        if (s <= 1.0001) return child;
        final inner = Size(box.maxWidth / s, box.maxHeight / s);
        return FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          child: SizedBox.fromSize(
            size: inner,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(size: inner, padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero),
              child: child,
            ),
          ),
        );
      });
}

/// A transparent screen over the meadow: safe area, tablet scaling, a centered column, and optionally the ad strip.
class MeadowScaffold extends StatelessWidget {
  const MeadowScaffold({super.key, required this.child, this.banner = false, this.overlays = const [], this.maxWidth = 480});

  final Widget child;
  final bool banner;
  final double maxWidth;

  /// Full-screen layers on top (confetti, win panel…), not scaled.
  final List<Widget> overlays;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Expanded(
          child: Stack(children: [
            Positioned.fill(
              child: SafeArea(
                bottom: !banner,
                child: UiScale(
                  child: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child)),
                ),
              ),
            ),
            ...overlays,
          ]),
        ),
        if (banner) const BannerStrip(),
      ]),
    );
  }
}

/// The banner ad in its own soil-colored strip, under the meadow.
class BannerStrip extends StatelessWidget {
  const BannerStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    return ListenableBuilder(
      listenable: services.premium,
      builder: (context, _) {
        final empty = services.premium.isPremium || services.banner == null;
        return Container(
          decoration: BoxDecoration(
            color: empty ? Colors.transparent : soil,
            border: empty ? null : const Border(top: BorderSide(color: grassDark, width: 4)),
          ),
          child: SafeArea(top: false, child: empty ? const SizedBox(width: double.infinity) : const BannerSlot()),
        );
      },
    );
  }
}
