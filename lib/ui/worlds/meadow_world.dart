import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../critter_image.dart';
import 'world.dart';

/// The Meadow palette (the original Critter Logic look).
const meadowPalette = WorldPalette(
  background: Color(0xFFFFF4DC),
  surface: Color(0xFFFFFBF0),
  ink: Color(0xFF4A3426),
  inkSoft: Color(0xFF8C7360),
  accent: Color(0xFFFF8A5B),
  good: Color(0xFF5CBF3A),
  bad: Color(0xFFE5484D),
  gold: Color(0xFFFFC23D),
  skyTop: Color(0xFF7CC8F7),
  skyMid: Color(0xFFB9E4FB),
  skyLow: Color(0xFFFFF1D6),
  hillFar: Color(0xFFB5E08A),
  hillMid: Color(0xFF8DD067),
  grass: Color(0xFF6CC04A),
  grassDark: Color(0xFF479A35),
  soil: Color(0xFF7A5235),
  wood: Color(0xFFC98A4B),
  woodLight: Color(0xFFE3AD6C),
  woodDark: Color(0xFF8E5A2B),
  woodEdge: Color(0xFF6B4220),
  paper: Color(0xFFFFF8E7),
  paperEdge: Color(0xFFE6D2AC),
  leaf: Color(0xFF6CCB3C),
  leafEdge: Color(0xFF3F9322),
  sky: Color(0xFF4FB3EE),
  skyEdge: Color(0xFF2479B8),
  goldEdge: Color(0xFFD38A12),
  coral: Color(0xFFFF8A5B),
  coralEdge: Color(0xFFD25A31),
  woodButton: Color(0xFFD99A5A),
  sunColor: Color(0xFFFFB627),
  moonColor: Color(0xFF6C7BD9),
  accentSoft: Color(0xFFFFE3D6),
  goodSoft: Color(0xFFDFF5D2),
  goldSoft: Color(0xFFFFF0C4),
  rareBlue: Color(0xFF4F95F0),
  rareSoft: Color(0xFFDDEBFF),
  tileEmpty: Color(0xFFF3E6CE),
  tileGiven: Color(0xFFE3D0AE),
  shadow: Color(0x334A3426),
  onWood: Color(0xFFFFF4D6),
  onWoodSoft: Color(0xFFFFE6BC),
  barrier: Color(0x664A3426),
);

const meadowBoard = BoardPalette(
  zones: [
    Color(0xFFFFD9A8),
    Color(0xFFCFF2B6),
    Color(0xFFB3E8F5),
    Color(0xFFD6CCFF),
    Color(0xFFFFC2C2),
    Color(0xFFFFF2AE),
    Color(0xFFB8D4FF),
    Color(0xFFFFCDEE),
    Color(0xFFD3F1DF),
    Color(0xFFEAD3F7),
  ],
  bedShine: Color(0x38FFFFFF),
  speckles: true,
  cellLine: Color(0x8CFFFFFF),
  zoneEdge: Color(0xFF2F7A26),
  zoneEdgeInner: Color(0xFF55AD3C),
  zoneDots: Color(0xFF7FCB5E),
  ruledOut: Color(0x478C7360),
  lawnTop: Color(0xFF8ED46B),
  lawnBottom: Color(0xFF6CC04A),
  lawnEdge: Color(0xFF2F7A26),
  lawnTuft: Color(0xFF4FA238),
  stoneTop: Color(0xFFF7F0E2),
  stoneLow: Color(0xFFE4D8C2),
  stoneEdge: Color(0xFFB3A285),
  givenTop: Color(0xFFD9CCB2),
  givenLow: Color(0xFFC2B292),
  givenEdge: Color(0xFF94836A),
  moss: Color(0xCC8DBF5A),
  stoneShine: Color(0x99FFFFFF),
  linkFill: Color(0xFFE3AD6C),
  linkEdge: Color(0xFF6B4220),
  grassLight: Color(0xFFC4EAA0),
  grassDark: Color(0xFFB2E08B),
  grassLine: Color(0xFF7CBF55),
  dirtEdge: Color(0xFFB8874F),
  dirtFill: Color(0xFFE9CB97),
  dirtGlow: Color(0xFFFFE9A8),
  dirtPrint: Color(0xFFC79D66),
  pebbleTop: Color(0xFFF4EEE4),
  pebbleLow: Color(0xFFCFC5B4),
  pebbleRim: Color(0xFF9A8C76),
  pebbleText: Color(0xFF4A3426),
  pebbleReachedTop: Color(0xFFFFEDB8),
  pebbleReachedLow: Color(0xFFF5C95A),
  pebbleReachedRim: Color(0xFFD38A12),
  pebbleReachedText: Color(0xFF6B4220),
  cardNests: [Color(0xFFDDF5C6), Color(0xFFB9E596)],
  cardPairs: [Color(0xFFD6ECFF), Color(0xFFB4D8F7)],
  cardTrail: [Color(0xFFFFEBC9), Color(0xFFF6D49C)],
  cardEdge: Color(0xFFE6D2AC),
);

/// The cozy Meadow: sky, sun, drifting clouds, rolling hills, wooden signs, candy buttons and Kenney critters.
class MeadowWorld extends GameWorld {
  const MeadowWorld();

  @override
  String get id => 'world.meadow';

  @override
  String name(AppLocalizations l10n) => l10n.worldMeadow;

  @override
  String blurb(AppLocalizations l10n) => l10n.worldMeadowBlurb;

  @override
  WorldPalette get palette => meadowPalette;

  @override
  BoardPalette get board => meadowBoard;

  @override
  String get font => 'Fredoka';

  @override
  List<Color> get celebration => const [
        Color(0xFFFF8A5B),
        Color(0xFFFFC23D),
        Color(0xFF6CCB3C),
        Color(0xFF4FB3EE),
        Color(0xFFC9B6FF),
        Color(0xFFFF8FB1),
      ];

  @override
  Widget background(BuildContext context) => const MeadowBackground();

  @override
  void paintPanel(Canvas canvas, Size size, {double radius = 18, bool nails = true, double plank = 34}) =>
      paintWoodPlanks(canvas, size, meadowPalette, radius: radius, nails: nails, plank: plank);

  @override
  void paintButton(Canvas canvas, Size size,
          {required Color face, required Color edge, double press = 0, double depth = 6, double radius = 20, bool circle = false}) =>
      paintCandy(canvas, size, face: face, edge: edge, press: press, depth: depth, radius: radius, circle: circle, shadow: meadowPalette.shadow);

  @override
  Widget sign(BuildContext context, {required String title, String? subtitle, double fontSize = 40}) =>
      HangingSign(world: this, title: title, subtitle: subtitle, fontSize: fontSize, subtitleColor: const Color(0xFFFFE9C2));

  @override
  Widget label(BuildContext context, {required String text, String? subtitle, double fontSize = 22}) =>
      PanelLabel(world: this, text: text, subtitle: subtitle, fontSize: fontSize);

  @override
  Widget critter(BuildContext context, String id, double size, {CritterRole role = CritterRole.collectible}) =>
      CritterSprite(id, size: size);

  @override
  void paintStreak(Canvas canvas, Size size, {required bool lit, int streak = 0}) => paintFlame(canvas, size, lit: lit);

  @override
  void paintCross(Canvas canvas, Size size) => paintLeaf(canvas, size);
}

// ---- Shared painters (other Worlds reuse them with their own colors) ----

/// Wood planks with seams, grain and nails.
void paintWoodPlanks(Canvas canvas, Size size, WorldPalette p,
    {double radius = 18, bool nails = true, double plank = 34, double grainAlpha = 0.18, double shineAlpha = 0.22}) {
  final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
  canvas.drawRRect(rr.shift(const Offset(0, 9)), Paint()
    ..color = p.shadow
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
  canvas.drawRRect(rr.shift(const Offset(0, 5)), Paint()..color = p.woodEdge);
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [p.woodLight, p.wood],
      ).createShader(Offset.zero & size),
  );
  canvas.save();
  canvas.clipRRect(rr);
  final seam = Paint()
    ..color = p.woodDark.withValues(alpha: 0.55)
    ..strokeWidth = 2;
  final grain = Paint()
    ..color = p.woodDark.withValues(alpha: grainAlpha)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;
  final rows = max(1, (size.height / plank).round());
  final ph = size.height / rows;
  final r = Random(size.width.round() * 31 + size.height.round());
  for (var i = 0; i < rows; i++) {
    final y = i * ph;
    if (i > 0) canvas.drawLine(Offset(0, y), Offset(size.width, y), seam);
    canvas.drawLine(Offset(0, y + 1.5), Offset(size.width, y + 1.5), Paint()
      ..color = Colors.white.withValues(alpha: 0.18 * shineAlpha / 0.22)
      ..strokeWidth = 1.5);
    for (var g = 0; g < 2; g++) {
      final gy = y + ph * (0.3 + 0.4 * r.nextDouble());
      final x0 = r.nextDouble() * size.width * 0.5;
      final path = Path()
        ..moveTo(x0, gy)
        ..quadraticBezierTo(x0 + size.width * 0.2, gy - 3, x0 + size.width * 0.45, gy + 1);
      canvas.drawPath(path, grain);
    }
  }
  canvas.restore();
  canvas.drawRRect(rr.deflate(1.5), Paint()
    ..color = p.woodEdge
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3);
  canvas.drawRRect(rr.deflate(4.5), Paint()
    ..color = Colors.white.withValues(alpha: shineAlpha)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5);
  if (nails && size.width > 60 && size.height > 40) {
    for (final o in [
      const Offset(11, 11),
      Offset(size.width - 11, 11),
      Offset(11, size.height - 11),
      Offset(size.width - 11, size.height - 11),
    ]) {
      canvas.drawCircle(o, 3.2, Paint()..color = p.woodEdge);
      canvas.drawCircle(o - const Offset(0.8, 0.8), 1.3, Paint()..color = Colors.white.withValues(alpha: 0.5));
    }
  }
}

/// A candy button: dark outline, thick bottom edge, gradient face and a glossy highlight.
void paintCandy(Canvas canvas, Size size,
    {required Color face,
    required Color edge,
    double press = 0,
    double depth = 6,
    double radius = 20,
    bool circle = false,
    required Color shadow,
    double gloss = 0.28}) {
  final r = circle ? size.height / 2 : radius;
  final outer = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r));
  final top = depth * press;
  final faceRect = RRect.fromLTRBR(0, top, size.width, size.height - depth + top, Radius.circular(r));
  canvas.drawRRect(outer.shift(const Offset(0, 3)), Paint()
    ..color = shadow
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  canvas.drawRRect(outer, Paint()..color = edge);
  canvas.drawRRect(
    faceRect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.lerp(face, Colors.white, 0.28)!, face],
      ).createShader(faceRect.outerRect),
  );
  final g = faceRect.outerRect;
  final glossRect = RRect.fromLTRBR(g.left + r * 0.45, g.top + 3, g.right - r * 0.45, g.top + g.height * 0.45, Radius.circular(r));
  canvas.drawRRect(glossRect, Paint()..color = Colors.white.withValues(alpha: gloss));
  canvas.drawRRect(outer.deflate(1), Paint()
    ..color = Color.lerp(edge, Colors.black, 0.25)!
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2);
}

/// The streak flame.
void paintFlame(Canvas canvas, Size size, {required bool lit, Color? outer, Color? inner, Color? line}) {
  Path flame(double k) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    return Path()
      ..moveTo(cx, h * (0.04 + (1 - k) * 0.4))
      ..cubicTo(cx + w * 0.42 * k, h * 0.35, cx + w * 0.44 * k, h * 0.95, cx, h * 0.96)
      ..cubicTo(cx - w * 0.44 * k, h * 0.95, cx - w * 0.42 * k, h * 0.5, cx - w * 0.1 * k, h * 0.42)
      ..cubicTo(cx - w * 0.05, h * 0.3, cx, h * 0.2, cx, h * (0.04 + (1 - k) * 0.4))
      ..close();
  }

  final o = outer ?? (lit ? const Color(0xFFFF6B2C) : const Color(0xFFFFB892));
  final i = inner ?? (lit ? const Color(0xFFFFC93C) : const Color(0xFFFFE6C8));
  canvas.drawPath(flame(1), Paint()..color = o);
  canvas.save();
  canvas.translate(0, size.height * 0.12);
  canvas.drawPath(flame(0.6), Paint()..color = i);
  canvas.restore();
  canvas.drawPath(flame(1), Paint()
    ..color = line ?? (lit ? const Color(0xFFC2410C) : const Color(0xFFD9895F))
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(1, size.width * 0.06));
}

/// A little green leaf: the Meadow's Nests "not here" mark.
void paintLeaf(Canvas canvas, Size size) {
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

/// Paints with a World's panel (wood planks in the Meadow).
class WorldPanelPainter extends CustomPainter {
  const WorldPanelPainter(this.world, {this.radius = 18, this.nails = true, this.plank = 34});

  final GameWorld world;
  final double radius;
  final bool nails;
  final double plank;

  @override
  void paint(Canvas canvas, Size size) => world.paintPanel(canvas, size, radius: radius, nails: nails, plank: plank);

  @override
  bool shouldRepaint(WorldPanelPainter old) =>
      old.world.id != world.id || old.radius != radius || old.nails != nails || old.plank != plank;
}

/// The Meadow title: a wooden sign hanging from two ropes.
class HangingSign extends StatelessWidget {
  const HangingSign({super.key, required this.world, required this.title, this.subtitle, this.fontSize = 40, this.subtitleColor});

  final GameWorld world;
  final Color? subtitleColor;
  final String title;
  final String? subtitle;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final p = world.palette;
    return CustomPaint(
      painter: _RopeSignPainter(world),
      child: Padding(
        padding: EdgeInsets.fromLTRB(30, 34, 30, subtitle == null ? 18 : 14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title,
              textAlign: TextAlign.center,
              style: world.outlined(fontSize, color: p.onWood, stroke: p.woodEdge, width: 2.6)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!,
                textAlign: TextAlign.center,
                style: world.text(15, color: subtitleColor ?? p.onWoodSoft, weight: FontWeight.w600)),
          ],
        ]),
      ),
    );
  }
}

class _RopeSignPainter extends CustomPainter {
  const _RopeSignPainter(this.world);

  final GameWorld world;

  @override
  void paint(Canvas canvas, Size size) {
    const top = 22.0;
    final board = Rect.fromLTWH(0, top, size.width, size.height - top - 4);
    final rope = Paint()
      ..color = const Color(0xFFB88A55)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final x in [size.width * 0.18, size.width * 0.82]) {
      canvas.drawLine(Offset(x, 0), Offset(x, top + 10), rope);
      canvas.drawLine(Offset(x, 0), Offset(x, top + 10), Paint()
        ..color = const Color(0xFF8A6238)
        ..strokeWidth = 1.2);
      canvas.drawCircle(Offset(x, 2), 4, Paint()..color = world.palette.woodEdge);
    }
    canvas.save();
    canvas.translate(board.left, board.top);
    world.paintPanel(canvas, board.size, radius: 22, plank: 30);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RopeSignPainter old) => old.world.id != world.id;
}

/// A plaque with a title, for screen headers (a wooden one in the Meadow).
class PanelLabel extends StatelessWidget {
  const PanelLabel({super.key, required this.world, required this.text, this.subtitle, this.fontSize = 22, this.titleStyle});

  final GameWorld world;
  final String text;
  final String? subtitle;
  final double fontSize;

  /// Overrides the title style (Worlds with their own engraving).
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final p = world.palette;
    return CustomPaint(
      painter: WorldPanelPainter(world, radius: 16, nails: false, plank: 60),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(text,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: titleStyle ?? world.outlined(fontSize, color: p.onWood, stroke: p.woodEdge, width: 2)),
          ),
          if (subtitle != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(subtitle!, maxLines: 1, style: world.text(14, color: p.onWoodSoft, weight: FontWeight.w600)),
            ),
        ]),
      ),
    );
  }
}

// ---- The Meadow landscape ----

/// Sky, sun, drifting clouds, rolling hills and a flowery meadow. One instance lives behind the navigator, so pages
/// slide over the same landscape.
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
    if (ambientMotionOn(context)) {
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
    // None in the top bar: a cloud behind the round buttons looked like a white pad stuck to them.
    _Cloud(y: 0.14, scale: 1.0, speed: 1, start: 0.1, alpha: 0.95),
    _Cloud(y: 0.22, scale: 0.7, speed: 2, start: 0.55, alpha: 0.85),
    _Cloud(y: 0.29, scale: 0.85, speed: 1, start: 0.8, alpha: 0.8),
    _Cloud(y: 0.42, scale: 0.55, speed: 3, start: 0.3, alpha: 0.7),
  ];
}

class _Cloud {
  const _Cloud({required this.y, required this.scale, required this.speed, required this.start, required this.alpha});
  final double y, scale, start, alpha;
  final int speed;
}

/// Height of the foreground band at the bottom of the screen (grass in the Meadow).
double meadowGround(double height, double bottomInset) => (height * 0.2).clamp(150.0, 300.0) + bottomInset;

class _SkyPainter extends CustomPainter {
  const _SkyPainter(this.inset);

  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const p = meadowPalette;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.skyTop, p.skyMid, p.skyLow, p.skyLow],
          stops: const [0, 0.38, 0.66, 1],
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
      canvas.drawRRect(RRect.fromLTRBR(w * 0.12, h * 0.55 + dy, w * 0.88, h * 0.92 + dy, Radius.circular(h * 0.2)), p);
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
    const p = meadowPalette;
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
    canvas.drawPath(far, Paint()..color = p.hillFar);
    final rnd = Random(4);
    for (final tx in [0.08, 0.22, 0.63, 0.9]) {
      final x = w * tx;
      final y = front - ground * 0.55 - sin(x / w * pi * 2.2 + 0.6) * ground * 0.16 - ground * 0.08 + 6;
      final r = ground * (0.09 + rnd.nextDouble() * 0.04);
      canvas.drawRect(Rect.fromLTWH(x - r * 0.12, y - r * 1.2, r * 0.24, r * 1.2), Paint()..color = p.woodDark);
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
    canvas.drawPath(mid, Paint()..color = p.hillMid);

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
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.grass, const Color(0xFF5BAF3E)],
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
      ..color = p.grassDark
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
      ..color = meadowPalette.grassDark
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
