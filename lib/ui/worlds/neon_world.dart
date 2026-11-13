import 'dart:math';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../critter_image.dart';
import 'world.dart';
import 'level_mark.dart';

const _cyan = Color(0xFF2EF2FF);
const _magenta = Color(0xFFFF3FD8);
const _lime = Color(0xFFB6FF3B);
const _yellow = Color(0xFFFFE53D);
const _violet = Color(0xFF9D7BFF);
const _night = Color(0xFF0B0820);
const _glass = Color(0xFF151231);

const neonPalette = WorldPalette(
  background: _night,
  surface: Color(0xFF1B1740),
  ink: Color(0xFFEAF6FF),
  inkSoft: Color(0xFFA9A3D6),
  accent: _magenta,
  good: Color(0xFF3DFF8E),
  bad: Color(0xFFFF3B6B),
  gold: _yellow,
  skyTop: Color(0xFF07051A),
  skyMid: Color(0xFF1C0C45),
  skyLow: Color(0xFF4A1066),
  hillFar: Color(0xFF241050),
  hillMid: Color(0xFF16093A),
  grass: Color(0xFF0E0A26),
  grassDark: _magenta,
  soil: Color(0xFF07051A),
  wood: _glass,
  woodLight: Color(0xFF221C4D),
  woodDark: _cyan,
  woodEdge: Color(0xFF05040F),
  paper: _glass,
  paperEdge: Color(0xFF3B3480),
  leaf: _lime,
  leafEdge: Color(0xFF6FB800),
  sky: _cyan,
  skyEdge: Color(0xFF0098B3),
  goldEdge: Color(0xFFD9A600),
  coral: _magenta,
  coralEdge: Color(0xFFB0198F),
  woodButton: _violet,
  sunColor: Color(0xFFFFB13D),
  moonColor: _cyan,
  accentSoft: Color(0xFF2E1240),
  goodSoft: Color(0xFF0F2C2A),
  goldSoft: Color(0xFF2B2614),
  rareBlue: Color(0xFF4FA8FF),
  rareSoft: Color(0xFF13234A),
  tileEmpty: Color(0xFF1A1638),
  tileGiven: Color(0xFF2A2456),
  shadow: Color(0x66000000),
  onWood: Color(0xFFEAF6FF),
  onWoodSoft: _cyan,
  barrier: Color(0xB3050412),
);

const neonBoard = BoardPalette(
  zones: [
    Color(0xFF3B1462),
    Color(0xFF0A3F52),
    Color(0xFF0E4630),
    Color(0xFF55123F),
    Color(0xFF1B2470),
    Color(0xFF5A1A22),
    Color(0xFF0B4A55),
    Color(0xFF34480E),
    Color(0xFF5A3208),
    Color(0xFF2E1F6E),
  ],
  bedShine: Color(0x00000000),
  speckles: false,
  cellLine: Color(0x332EF2FF),
  zoneEdge: Color(0xFF8BF8FF),
  zoneEdgeInner: _cyan,
  glow: true,
  ruledOut: Color(0x66A9A3D6),
  lawnTop: Color(0xFF120E2C),
  lawnBottom: Color(0xFF0B0820),
  lawnEdge: _magenta,
  lawnTuft: Color(0x00000000),
  stoneTop: Color(0xFF231D4F),
  stoneLow: Color(0xFF1A1540),
  stoneEdge: Color(0xFF4C3FA8),
  givenTop: Color(0xFF34295F),
  givenLow: Color(0xFF2A214F),
  givenEdge: _violet,
  stoneShine: Color(0x332EF2FF),
  linkFill: Color(0xFF0B0820),
  linkEdge: _yellow,
  grassLight: Color(0xFF120E2C),
  grassDark: Color(0xFF0E0B24),
  grassLine: Color(0x22FF3FD8),
  dirtEdge: _magenta,
  dirtFill: Color(0xFF3A0F4A),
  dirtGlow: Color(0xFFFF8BEA),
  dirtPrint: Color(0xFFFF8BEA),
  pebbleTop: Color(0xFF1E1946),
  pebbleLow: Color(0xFF151231),
  pebbleRim: _cyan,
  pebbleText: Color(0xFFEAF6FF),
  pebbleReachedTop: Color(0xFF3E3410),
  pebbleReachedLow: Color(0xFF2B2410),
  pebbleReachedRim: _yellow,
  pebbleReachedText: _yellow,
  cardNests: [Color(0xFF1A1440), Color(0xFF0E0B26)],
  cardPairs: [Color(0xFF101C40), Color(0xFF0B0E26)],
  cardTrail: [Color(0xFF2A1040), Color(0xFF140A26)],
  cardEdge: Color(0xFF3B3480),
);

const _critterGlow = [_cyan, _magenta, _lime, _yellow];

Color neonColorFor(String id) => _critterGlow[id.codeUnits.fold<int>(7, (a, c) => a * 31 + c) & 3];

/// A blurred glowing stroke followed by a crisp one.
void _neonStroke(Canvas canvas, Path path, Color color, double width, {double glow = 1}) {
  canvas.drawPath(path, Paint()
    ..color = color.withValues(alpha: 0.55 * glow)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width * 3
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 2.2));
  canvas.drawPath(path, Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round);
  canvas.drawPath(path, Paint()
    ..color = Color.lerp(color, Colors.white, 0.6)!
    ..style = PaintingStyle.stroke
    ..strokeWidth = max(0.6, width * 0.35)
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round);
}

List<Shadow> _glowShadows(Color c, double size) => [
      Shadow(color: c.withValues(alpha: 0.9), blurRadius: size * 0.25),
      Shadow(color: c.withValues(alpha: 0.6), blurRadius: size * 0.6),
    ];

/// Night Neon: a synthwave night, glowing grids and outlines, glowing critters.
class NeonWorld extends GameWorld {
  const NeonWorld();

  @override
  String get id => 'world.neon';

  @override
  String name(AppLocalizations l10n) => l10n.worldNeon;

  @override
  String blurb(AppLocalizations l10n) => l10n.worldNeonBlurb;

  @override
  WorldPalette get palette => neonPalette;

  @override
  BoardPalette get board => neonBoard;

  @override
  String get font => 'Exo2';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  double get radius => 14;

  @override
  List<Color> get celebration => const [_cyan, _magenta, _lime, _yellow, _violet, Colors.white];

  @override
  Color get bannerEdge => _magenta;

  @override
  List<Color> get mapGround => const [Color(0xFF1A0838), Color(0xFF120A30), Color(0xFF07051A)];

  @override
  bool get mapProps => false;

  @override
  Color get disabledButton => const Color(0xFF4A4670);

  @override
  Color edgeOf(Color c) => Color.lerp(c, _night, 0.45)!;

  @override
  TextStyle outlined(double size, {Color? color, Color? stroke, double? width}) {
    final c = color ?? Colors.white;
    // Light text glows in the accent behind it; colored text glows in its own color.
    final glow = c.computeLuminance() > 0.8 ? _magenta : c;
    return text(size, color: c).copyWith(shadows: [
      Shadow(color: _night.withValues(alpha: 0.9), offset: const Offset(0, 1.5), blurRadius: 2),
      ..._glowShadows(glow, size),
    ]);
  }

  @override
  BoxDecoration card({Color? fill, Color? border}) {
    final edge = border ?? _cyan.withValues(alpha: 0.75);
    final f = fill ?? _glass;
    return BoxDecoration(
      color: f.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: edge, width: border == null ? 1.6 : 2.2),
      boxShadow: [
        BoxShadow(color: edge.withValues(alpha: 0.45), blurRadius: 12),
        const BoxShadow(color: Color(0x88000000), blurRadius: 14, offset: Offset(0, 8)),
      ],
    );
  }

  @override
  BoxDecoration pill(Color fill, double height) => BoxDecoration(
        color: Color.lerp(fill, _night, 0.25)!.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: _cyan.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [BoxShadow(color: _cyan.withValues(alpha: 0.35), blurRadius: 8)],
      );

  @override
  Widget background(BuildContext context) => const NeonBackground();

  @override
  void paintPanel(Canvas canvas, Size size, {double radius = 18, bool nails = true, double plank = 34}) {
    final r = min(radius, 16.0);
    final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r));
    canvas.drawRRect(rr.shift(const Offset(0, 6)), Paint()
      ..color = const Color(0x99000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xF0241D52), Color(0xF0130F2E)],
        ).createShader(Offset.zero & size),
    );
    // Faint scanlines.
    canvas.save();
    canvas.clipRRect(rr);
    final scan = Paint()..color = const Color(0x0DFFFFFF);
    for (var y = 3.0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), scan);
    }
    canvas.restore();
    _neonStroke(canvas, Path()..addRRect(rr.deflate(1.2)), nails ? _magenta : _cyan, 1.8);
    if (nails && size.width > 60 && size.height > 40) {
      // Corner ticks instead of nails.
      final tick = Paint()
        ..color = _cyan
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (final (o, dx, dy) in [
        (const Offset(8, 8), 1.0, 1.0),
        (Offset(size.width - 8, 8), -1.0, 1.0),
        (Offset(8, size.height - 8), 1.0, -1.0),
        (Offset(size.width - 8, size.height - 8), -1.0, -1.0),
      ]) {
        canvas.drawLine(o, o + Offset(7 * dx, 0), tick);
        canvas.drawLine(o, o + Offset(0, 7 * dy), tick);
      }
    }
  }

  @override
  double buttonDepth(bool small) => small ? 2 : 3;

  @override
  void paintButton(Canvas canvas, Size size,
      {required Color face, required Color edge, double press = 0, double depth = 6, double radius = 20, bool circle = false}) {
    final r = circle ? size.height / 2 : min(radius, 12.0);
    final top = depth * press;
    final body = RRect.fromLTRBR(1.5, top + 1.5, size.width - 1.5, size.height - depth + top - 1.5, Radius.circular(r));
    canvas.drawRRect(body.shift(Offset(0, depth - top)), Paint()..color = edge.withValues(alpha: 0.5));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(_night, face, 0.32)!, Color.lerp(_night, face, 0.12)!],
        ).createShader(body.outerRect),
    );
    _neonStroke(canvas, Path()..addRRect(body), face, 2, glow: 1 - press * 0.4);
  }

  @override
  TextStyle buttonText(double size, {required Color textColor, required Color rim}) {
    // Buttons ask for white labels; glow them in the button's own color (the rim is darkened face).
    final face = Color.lerp(rim, Colors.white, 0.35)!;
    final c = textColor.computeLuminance() > 0.5 ? Colors.white : textColor;
    return text(size, color: c).copyWith(shadows: _glowShadows(face, size));
  }

  @override
  Color iconColor(Color face) => Color.lerp(face, Colors.white, 0.45)!;

  @override
  List<Shadow> iconShadows(Color face) => _glowShadows(face, 22);

  @override
  Widget sign(BuildContext context, {required String title, String? subtitle, double fontSize = 40}) => _NeonSign(
        world: this,
        title: title,
        subtitle: subtitle,
        fontSize: fontSize,
      );

  @override
  Widget label(BuildContext context, {required String text, String? subtitle, double fontSize = 22}) => Container(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
        decoration: BoxDecoration(
          color: const Color(0xE6130F2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _magenta, width: 1.6),
          boxShadow: [BoxShadow(color: _magenta.withValues(alpha: 0.5), blurRadius: 12)],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text.toUpperCase(),
                maxLines: 1,
                textAlign: TextAlign.center,
                style: this.text(fontSize * 0.92, color: Colors.white).copyWith(
                  letterSpacing: 1.2,
                  shadows: _glowShadows(_magenta, fontSize),
                )),
          ),
          if (subtitle != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(subtitle, maxLines: 1, style: this.text(14, color: _cyan, weight: FontWeight.w600)),
            ),
        ]),
      );

  @override
  Widget critter(BuildContext context, String id, double size, {CritterRole role = CritterRole.collectible}) =>
      NeonCritter(id: id, size: size, glow: role != CritterRole.piece || size > 30);

  @override
  Widget levelMark(BuildContext context, int level, double size) =>
      LevelMark(level: level, size: size, style: LevelMarkStyle.glow, color: _yellow);

  @override
  void paintStreak(Canvas canvas, Size size, {required bool lit, int streak = 0}) {
    final w = size.width, h = size.height, cx = w / 2;
    final flame = Path()
      ..moveTo(cx, h * 0.06)
      ..cubicTo(cx + w * 0.42, h * 0.38, cx + w * 0.4, h * 0.94, cx, h * 0.94)
      ..cubicTo(cx - w * 0.4, h * 0.94, cx - w * 0.42, h * 0.52, cx - w * 0.1, h * 0.42)
      ..cubicTo(cx - w * 0.04, h * 0.3, cx, h * 0.2, cx, h * 0.06)
      ..close();
    final inner = Path()
      ..moveTo(cx, h * 0.46)
      ..cubicTo(cx + w * 0.2, h * 0.62, cx + w * 0.18, h * 0.86, cx, h * 0.86)
      ..cubicTo(cx - w * 0.18, h * 0.86, cx - w * 0.18, h * 0.66, cx, h * 0.46)
      ..close();
    final c = lit ? _magenta : const Color(0xFF6A5F9E);
    if (lit) canvas.drawPath(flame, Paint()..color = _magenta.withValues(alpha: 0.18));
    _neonStroke(canvas, flame, c, max(1.2, w * 0.07), glow: lit ? 1 : 0.2);
    _neonStroke(canvas, inner, lit ? _yellow : const Color(0xFF6A5F9E), max(1, w * 0.06), glow: lit ? 1 : 0.2);
  }

  @override
  void paintCross(Canvas canvas, Size size) {
    final s = min(size.width, size.height);
    final c = size.center(Offset.zero);
    final d = s * 0.26;
    final x = Path()
      ..moveTo(c.dx - d, c.dy - d)
      ..lineTo(c.dx + d, c.dy + d)
      ..moveTo(c.dx + d, c.dy - d)
      ..lineTo(c.dx - d, c.dy + d);
    _neonStroke(canvas, x, _magenta, max(1.5, s * 0.1));
  }
}

class _NeonSign extends StatelessWidget {
  const _NeonSign({required this.world, required this.title, this.subtitle, this.fontSize = 40});

  final NeonWorld world;
  final String title;
  final String? subtitle;
  final double fontSize;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: const _SignFramePainter(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(26, 16, 26, subtitle == null ? 16 : 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title.toUpperCase(),
                textAlign: TextAlign.center,
                style: world.text(fontSize * 0.8, color: const Color(0xFFFFE9FB)).copyWith(
                  letterSpacing: 2,
                  fontStyle: FontStyle.italic,
                  shadows: [
                    const Shadow(color: _magenta, blurRadius: 2),
                    Shadow(color: _magenta, blurRadius: fontSize * 0.3),
                    Shadow(color: _magenta.withValues(alpha: 0.8), blurRadius: fontSize * 0.8),
                  ],
                )),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: world.text(13, color: const Color(0xFFDFFCFF), weight: FontWeight.w600).copyWith(
                    letterSpacing: 2.4,
                    shadows: _glowShadows(_cyan, 16),
                  )),
            ],
          ]),
        ),
      );
}

class _SignFramePainter extends CustomPainter {
  const _SignFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16));
    canvas.drawRRect(rr, Paint()..color = const Color(0xD90B0820));
    _neonStroke(canvas, Path()..addRRect(rr.deflate(2)), _cyan, 2.2);
    _neonStroke(canvas, Path()..addRRect(rr.deflate(7)), _magenta.withValues(alpha: 0.6), 1, glow: 0.4);
  }

  @override
  bool shouldRepaint(_SignFramePainter old) => false;
}

/// A Kenney critter as a glowing neon outline: a blurred glow, a thin bright rim, and the sprite darkened on top.
class NeonCritter extends StatelessWidget {
  const NeonCritter({super.key, required this.id, required this.size, this.glow = true});

  final String id;
  final double size;
  final bool glow;

  static const _dim = ColorFilter.matrix([
    0.55, 0.12, 0.12, 0, 4, //
    0.08, 0.5, 0.12, 0, 4,
    0.14, 0.14, 0.7, 0, 18,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final c = neonColorFor(id);
    final rim = max(1.0, size * 0.025);
    Widget tinted(Color color) =>
        ColorFiltered(colorFilter: ColorFilter.mode(color, BlendMode.srcIn), child: CritterSprite(id, size: size));
    return SizedBox.square(
      dimension: size,
      child: Stack(clipBehavior: Clip.none, children: [
        if (glow)
          Positioned.fill(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: size * 0.07, sigmaY: size * 0.07),
              child: tinted(c.withValues(alpha: 0.9)),
            ),
          ),
        for (var k = 0; k < 8; k++)
          Positioned.fill(
            child: Transform.translate(offset: Offset(cos(k * pi / 4) * rim, sin(k * pi / 4) * rim), child: tinted(c)),
          ),
        Positioned.fill(child: ColorFiltered(colorFilter: _dim, child: CritterSprite(id, size: size))),
      ]),
    );
  }
}

/// A synthwave night: stars, a striped sun on the horizon, a city line and a glowing grid floor rolling toward you.
class NeonBackground extends StatefulWidget {
  const NeonBackground({super.key});

  @override
  State<NeonBackground> createState() => _NeonBackgroundState();
}

class _NeonBackgroundState extends State<NeonBackground> with SingleTickerProviderStateMixin {
  late final _roll = AnimationController(vsync: this, duration: const Duration(seconds: 6));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ambientMotionOn(context)) {
      if (!_roll.isAnimating) _roll.repeat();
    } else {
      _roll.stop();
    }
  }

  @override
  void dispose() {
    _roll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        const Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _NeonSkyPainter()))),
        Positioned.fill(
          child: RepaintBoundary(child: CustomPaint(painter: _GridPainter(_roll))),
        ),
      ]);
}

double _horizon(Size s) => s.height * 0.64;

class _NeonSkyPainter extends CustomPainter {
  const _NeonSkyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final hz = _horizon(size);
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF05041A), Color(0xFF140A3C), Color(0xFF3A0C5A), Color(0xFF07051A)],
          stops: [0, 0.38, 0.64, 0.64],
        ).createShader(rect),
    );
    // Stars.
    final r = Random(11);
    for (var i = 0; i < 70; i++) {
      final p = Offset(r.nextDouble() * w, r.nextDouble() * hz * 0.85);
      final big = r.nextDouble() < 0.15;
      canvas.drawCircle(p, big ? 1.4 : 0.8,
          Paint()..color = (big ? _cyan : Colors.white).withValues(alpha: 0.35 + r.nextDouble() * 0.5));
    }
    // Striped sun sitting on the horizon.
    final sr = min(w, 600) * 0.3;
    final sc = Offset(w * 0.5, hz - sr * 0.28);
    canvas.drawCircle(sc, sr * 1.5, Paint()
      ..shader = RadialGradient(colors: [_magenta.withValues(alpha: 0.35), _magenta.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: sc, radius: sr * 1.5)));
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, w, hz));
    final sun = Path()..addOval(Rect.fromCircle(center: sc, radius: sr));
    for (var k = 0; k < 6; k++) {
      final y = sc.dy + sr * (0.1 + k * 0.16);
      sun.addRect(Rect.fromLTRB(sc.dx - sr, y, sc.dx + sr, y + sr * (0.03 + k * 0.018)));
    }
    sun.fillType = PathFillType.evenOdd;
    canvas.drawPath(
      sun,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE53D), Color(0xFFFF7A3D), Color(0xFFFF3FD8)],
        ).createShader(Rect.fromCircle(center: sc, radius: sr)),
    );
    canvas.restore();
    // City skyline silhouette with a few lit windows.
    final city = Path()..moveTo(0, hz);
    final cr = Random(5);
    var x = 0.0;
    while (x < w) {
      final bw = 14 + cr.nextDouble() * 30;
      final bh = 12 + cr.nextDouble() * (hz * 0.14);
      city
        ..lineTo(x, hz - bh)
        ..lineTo(x + bw, hz - bh);
      x += bw;
    }
    city
      ..lineTo(w, hz)
      ..close();
    canvas.drawPath(city, Paint()..color = const Color(0xFF0A0722));
    canvas.drawPath(city, Paint()
      ..color = _violet.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    final lit = Paint()..color = _yellow.withValues(alpha: 0.55);
    for (var i = 0; i < 40; i++) {
      canvas.drawRect(Rect.fromLTWH(cr.nextDouble() * w, hz - 4 - cr.nextDouble() * hz * 0.1, 2, 2), lit);
    }
    // Horizon line.
    canvas.drawLine(Offset(0, hz), Offset(w, hz), Paint()
      ..color = _magenta
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawLine(Offset(0, hz), Offset(w, hz), Paint()
      ..color = const Color(0xFFFFB8F2)
      ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(_NeonSkyPainter old) => false;
}

class _GridPainter extends CustomPainter {
  _GridPainter(this.roll) : super(repaint: roll);

  final Animation<double> roll;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final hz = _horizon(size);
    final depth = h - hz;
    final rect = Rect.fromLTRB(0, hz, w, h);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A0838), Color(0xFF07051A)],
        ).createShader(rect),
    );
    final line = Paint()
      ..color = _magenta.withValues(alpha: 0.75)
      ..strokeWidth = 1.3;
    final glow = Paint()
      ..color = _magenta.withValues(alpha: 0.35)
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    // Vertical lines fan out from the vanishing point.
    final vp = Offset(w / 2, hz - depth * 0.35);
    for (var k = -12; k <= 12; k++) {
      final bx = w / 2 + k * w * 0.16;
      final top = Offset.lerp(vp, Offset(bx, h), (hz - vp.dy) / (h - vp.dy))!;
      canvas.drawLine(top, Offset(bx, h), glow);
      canvas.drawLine(top, Offset(bx, h), line);
    }
    // Horizontal lines, spaced in perspective, rolling toward the viewer.
    final t = roll.value;
    for (var i = 0; i < 14; i++) {
      final z = (i + t) / 14; // 0 far .. 1 near
      final y = hz + depth * z * z;
      final a = (0.25 + 0.75 * z).clamp(0.0, 1.0);
      canvas.drawLine(Offset(0, y), Offset(w, y), glow..color = _cyan.withValues(alpha: 0.3 * a));
      canvas.drawLine(Offset(0, y), Offset(w, y), Paint()
        ..color = _cyan.withValues(alpha: 0.8 * a)
        ..strokeWidth = 1.2);
    }
    // Haze at the horizon.
    canvas.drawRect(
      Rect.fromLTRB(0, hz, w, hz + depth * 0.25),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_magenta.withValues(alpha: 0.35), _magenta.withValues(alpha: 0)],
        ).createShader(Rect.fromLTRB(0, hz, w, hz + depth * 0.25)),
    );
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
