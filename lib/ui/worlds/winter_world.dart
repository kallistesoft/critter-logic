import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../critter_image.dart';
import 'meadow_world.dart';
import 'world.dart';

const _snow = Color(0xFFF4F8FD);
const _iceShadow = Color(0xFF9FB4D2);
const _cranberry = Color(0xFFD2414E);
const _pine = Color(0xFF2E8A57);
const _ice = Color(0xFF5AB0E0);
const _mustard = Color(0xFFE9A93A);

const winterPalette = WorldPalette(
  background: Color(0xFFF3EEE6),
  surface: Color(0xFFFFFDF9),
  ink: Color(0xFF2E2A3A),
  inkSoft: Color(0xFF756B84),
  accent: _cranberry,
  good: Color(0xFF3E9A5A),
  bad: Color(0xFFD9364A),
  gold: Color(0xFFF2B53A),
  skyTop: Color(0xFF0A1230),
  skyMid: Color(0xFF1C2E5C),
  skyLow: Color(0xFF3E5D8E),
  hillFar: Color(0xFFDDE8F5),
  hillMid: Color(0xFFC6D6EC),
  grass: _snow,
  grassDark: _iceShadow,
  soil: Color(0xFF243052),
  wood: Color(0xFF9A5B33),
  woodLight: Color(0xFFB9784A),
  woodDark: Color(0xFF6E3E22),
  woodEdge: Color(0xFF4A2814),
  paper: Color(0xFFFFF8EE),
  paperEdge: Color(0xFFE0D2BF),
  leaf: _pine,
  leafEdge: Color(0xFF1D5E3B),
  sky: _ice,
  skyEdge: Color(0xFF2C78A8),
  goldEdge: Color(0xFFC4861A),
  coral: _cranberry,
  coralEdge: Color(0xFF98222F),
  woodButton: Color(0xFFB9784A),
  sunColor: Color(0xFFF5A623),
  moonColor: Color(0xFF5E73D6),
  accentSoft: Color(0xFFFBE1E2),
  goodSoft: Color(0xFFDDF1E3),
  goldSoft: Color(0xFFFCEFD0),
  rareBlue: Color(0xFF4F8FE0),
  rareSoft: Color(0xFFDEEAFB),
  tileEmpty: Color(0xFFEEF2F8),
  tileGiven: Color(0xFFD6DFEC),
  shadow: Color(0x33202840),
  onWood: Color(0xFFFFF4E2),
  onWoodSoft: Color(0xFFFFE2C0),
  barrier: Color(0x880A1230),
);

const winterBoard = BoardPalette(
  zones: [
    Color(0xFFDDEEFF),
    Color(0xFFFDDDE3),
    Color(0xFFDDF3E6),
    Color(0xFFEAE0FF),
    Color(0xFFFFEDCF),
    Color(0xFFD3EFF4),
    Color(0xFFF7DCF0),
    Color(0xFFE4EAF6),
    Color(0xFFEFF5D4),
    Color(0xFFFFE1CF),
  ],
  bedShine: Color(0x66FFFFFF),
  speckles: false,
  cellLine: Color(0xB3FFFFFF),
  zoneEdge: Color(0xFF8DA6C8),
  zoneEdgeInner: Color(0xFFFFFFFF),
  zoneDots: Color(0xFFE3EEFA),
  ruledOut: Color(0x667A8AA8),
  lawnTop: Color(0xFFF8FBFF),
  lawnBottom: Color(0xFFDCE7F4),
  lawnEdge: Color(0xFF8FA9CB),
  lawnTuft: Color(0x00000000),
  stoneTop: Color(0xFFEAF7FF),
  stoneLow: Color(0xFFC9E4F5),
  stoneEdge: Color(0xFF8DB7D6),
  givenTop: Color(0xFFD3DEEB),
  givenLow: Color(0xFFB7C8DA),
  givenEdge: Color(0xFF7F93AD),
  moss: Color(0xFFFFFFFF),
  stoneShine: Color(0xCCFFFFFF),
  linkFill: Color(0xFFFFF8EE),
  linkEdge: Color(0xFF6E3E22),
  grassLight: Color(0xFFF7FAFE),
  grassDark: Color(0xFFEAF0F8),
  grassLine: Color(0x00000000),
  dirtEdge: Color(0xFFA6B9D3),
  dirtFill: Color(0xFFD3DFEE),
  dirtGlow: Color(0xFFFFF1CF),
  dirtPrint: Color(0xFF8AA0BF),
  pebbleTop: Color(0xFFFFFFFF),
  pebbleLow: Color(0xFFD8E4F0),
  pebbleRim: Color(0xFF8DA4C2),
  pebbleText: Color(0xFF2E2A3A),
  pebbleReachedTop: Color(0xFFFCE6B4),
  pebbleReachedLow: Color(0xFFF2B53A),
  pebbleReachedRim: Color(0xFFC4861A),
  pebbleReachedText: Color(0xFF4A2814),
  cardNests: [Color(0xFFE8F3FF), Color(0xFFCFE3F8)],
  cardPairs: [Color(0xFFEFF0FF), Color(0xFFD7DDF6)],
  cardTrail: [Color(0xFFFFF1E0), Color(0xFFF4DCBB)],
  cardEdge: Color(0xFFE0D2BF),
);

const _scarves = [
  (_cranberry, Color(0xFFFFF3E6)),
  (_pine, Color(0xFFFFF3E6)),
  (_ice, Color(0xFFFFFFFF)),
  (_mustard, _cranberry),
];

/// Winter Cabin: a snowy pine forest at night under the northern lights; cozy wood, wool and scarves.
class WinterWorld extends GameWorld {
  const WinterWorld();

  @override
  String get id => 'world.winter';

  @override
  String name(AppLocalizations l10n) => l10n.worldWinter;

  @override
  String blurb(AppLocalizations l10n) => l10n.worldWinterBlurb;

  @override
  WorldPalette get palette => winterPalette;

  @override
  BoardPalette get board => winterBoard;

  @override
  String get font => 'Fredoka';

  @override
  List<Color> get celebration => const [Colors.white, Color(0xFFBFE3FA), _cranberry, Color(0xFFF2B53A), _pine, _ice];

  @override
  Color get bannerEdge => const Color(0xFFDCE7F4);

  @override
  List<Color> get mapGround => const [Color(0xFFF4F8FD), Color(0xFFE2EBF6), Color(0xFFC9D8EC)];

  @override
  bool get mapProps => false;

  @override
  TextStyle outlined(double size, {Color? color, Color? stroke, double? width}) => text(size, color: color ?? Colors.white)
      .copyWith(shadows: cartoonOutline(stroke ?? const Color(0xFF1B2547), width ?? max(1.5, size * 0.07)));

  @override
  BoxDecoration card({Color? fill, Color? border}) {
    final f = fill ?? winterPalette.paper;
    return BoxDecoration(
      color: f,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.lerp(f, Colors.white, 0.5)!, f],
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border ?? const Color(0xFFD9C8B0), width: border == null ? 2.5 : 3.5),
      boxShadow: [
        BoxShadow(color: border ?? const Color(0xFFB9A58A), offset: const Offset(0, 4)),
        const BoxShadow(color: Color(0x55091230), blurRadius: 16, offset: Offset(0, 9)),
      ],
    );
  }

  @override
  Widget background(BuildContext context) => const WinterBackground();

  @override
  void paintPanel(Canvas canvas, Size size, {double radius = 18, bool nails = true, double plank = 34}) {
    paintWoodPlanks(canvas, size, winterPalette, radius: radius, nails: nails, plank: plank);
    paintSnowCap(canvas, size, radius: radius);
  }

  @override
  void paintButton(Canvas canvas, Size size,
      {required Color face, required Color edge, double press = 0, double depth = 6, double radius = 20, bool circle = false}) {
    paintCandy(canvas, size,
        face: face, edge: edge, press: press, depth: depth, radius: radius, circle: circle, shadow: winterPalette.shadow, gloss: 0.18);
    // A stitched seam inside the face.
    final r = circle ? size.height / 2 : radius;
    final top = depth * press;
    final face0 = RRect.fromLTRBR(0, top, size.width, size.height - depth + top, Radius.circular(r));
    final inset = circle ? size.height * 0.14 : 4.5;
    _dashed(canvas, Path()..addRRect(face0.deflate(inset)), Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round, dash: 4, gap: 3.5);
  }

  @override
  Widget sign(BuildContext context, {required String title, String? subtitle, double fontSize = 40}) => CustomPaint(
        painter: const _SnowySignPainter(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(30, 30, 30, subtitle == null ? 26 : 22),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title,
                textAlign: TextAlign.center,
                style: text(fontSize, color: winterPalette.onWood)
                    .copyWith(shadows: cartoonOutline(winterPalette.woodEdge, 2.6))),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle,
                  textAlign: TextAlign.center, style: text(15, color: winterPalette.onWoodSoft, weight: FontWeight.w600)),
            ],
          ]),
        ),
      );

  @override
  Widget label(BuildContext context, {required String text, String? subtitle, double fontSize = 22}) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: PanelLabel(world: this, text: text, subtitle: subtitle, fontSize: fontSize),
      );

  @override
  Widget critter(BuildContext context, String id, double size, {CritterRole role = CritterRole.collectible}) =>
      ScarfCritter(id: id, size: size);

  @override
  void paintStreak(Canvas canvas, Size size, {required bool lit, int streak = 0}) {
    final w = size.width, h = size.height;
    if (lit) {
      final c = Offset(w / 2, h * 0.62);
      canvas.drawCircle(c, w * 0.5, Paint()
        ..shader = RadialGradient(colors: [const Color(0x88FFB347), const Color(0x00FFB347)])
            .createShader(Rect.fromCircle(center: c, radius: w * 0.5)));
    }
    paintFlame(canvas, size,
        lit: lit,
        outer: lit ? const Color(0xFFFF7A1F) : const Color(0xFFE8C6B0),
        inner: lit ? const Color(0xFFFFE08A) : const Color(0xFFF6E6D8),
        line: lit ? const Color(0xFFB8420E) : const Color(0xFFC9A28A));
  }

  @override
  void paintCross(Canvas canvas, Size size) {
    final s = min(size.width, size.height);
    final c = size.center(Offset.zero);
    final arm = s * 0.4;
    final shadow = Paint()
      ..color = const Color(0xFF5F87B8)
      ..strokeWidth = max(1.6, s * 0.11)
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = max(1, s * 0.06)
      ..strokeCap = StrokeCap.round;
    for (final p in [shadow, line]) {
      for (var k = 0; k < 6; k++) {
        final a = k * pi / 3 - pi / 2;
        final d = Offset(cos(a), sin(a));
        final n = Offset(-d.dy, d.dx);
        final end = c + d * arm;
        canvas.drawLine(c, end, p);
        final b = c + d * arm * 0.58;
        canvas.drawLine(b, b + (d - n) * arm * 0.25, p);
        canvas.drawLine(b, b + (d + n) * arm * 0.25, p);
      }
    }
  }
}

/// A snow lip along the top edge of a panel, with a few drips.
void paintSnowCap(Canvas canvas, Size size, {double radius = 18}) {
  final w = size.width;
  final t = min(14.0, max(6.0, size.height * 0.18));
  final r = Random(w.round() * 7 + size.height.round());
  final cap = Path()..moveTo(-2, t * 0.2 + radius * 0.25);
  cap.quadraticBezierTo(-1, -t * 0.25, radius * 0.6, -t * 0.3);
  cap.lineTo(w - radius * 0.6, -t * 0.3);
  cap.quadraticBezierTo(w + 1, -t * 0.25, w + 2, t * 0.2 + radius * 0.25);
  // Wavy underside with drips, right to left.
  var x = w + 2;
  while (x > -2) {
    final step = 10 + r.nextDouble() * 14;
    final nx = max(-2.0, x - step);
    final drip = r.nextDouble() < 0.25;
    final y = t * (0.55 + r.nextDouble() * 0.35) + (drip ? t * 0.55 : 0);
    cap.quadraticBezierTo((x + nx) / 2, y, nx, t * (0.5 + r.nextDouble() * 0.25));
    x = nx;
  }
  cap.close();
  canvas.drawPath(cap.shift(const Offset(0, 2.5)), Paint()..color = const Color(0x557F9CC4));
  canvas.drawPath(
    cap,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.white, Color(0xFFE6EFFA)],
      ).createShader(Rect.fromLTWH(0, -t, w, t * 2.2)),
  );
  canvas.drawPath(cap, Paint()
    ..color = const Color(0xFFB7C9E2)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1);
  final sparkle = Paint()..color = Colors.white;
  for (var i = 0; i < w / 40; i++) {
    canvas.drawCircle(Offset(r.nextDouble() * w, t * 0.15 + r.nextDouble() * t * 0.2), 1.1, sparkle);
  }
}

void _dashed(Canvas canvas, Path path, Paint paint, {double dash = 5, double gap = 4}) {
  for (final m in path.computeMetrics()) {
    for (var d = 0.0; d < m.length; d += dash + gap) {
      canvas.drawPath(m.extractPath(d, min(d + dash, m.length)), paint);
    }
  }
}

class _SnowySignPainter extends CustomPainter {
  const _SnowySignPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const top = 12.0;
    final board = Rect.fromLTWH(0, top, size.width, size.height - top - 10);
    canvas.save();
    canvas.translate(board.left, board.top);
    paintWoodPlanks(canvas, board.size, winterPalette, radius: 22, plank: 30);
    // Icicles under the board.
    final r = Random(3);
    final ice = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFFFFF), Color(0xCCBFE3FA)],
      ).createShader(Rect.fromLTWH(0, board.height - 4, board.width, 18));
    for (var x = 24.0; x < board.width - 20; x += 14 + r.nextDouble() * 18) {
      final len = 6 + r.nextDouble() * 12;
      canvas.drawPath(
        Path()
          ..moveTo(x - 4, board.height - 3)
          ..lineTo(x + 4, board.height - 3)
          ..lineTo(x + 0.5, board.height - 3 + len)
          ..close(),
        ice,
      );
    }
    paintSnowCap(canvas, Size(board.width, board.height), radius: 22);
    // A second, thicker drift on the top.
    final drift = Path()
      ..moveTo(board.width * 0.08, 0)
      ..cubicTo(board.width * 0.2, -14, board.width * 0.36, -10, board.width * 0.5, -12)
      ..cubicTo(board.width * 0.66, -16, board.width * 0.8, -8, board.width * 0.92, 0)
      ..close();
    canvas.drawPath(drift, Paint()..color = Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SnowySignPainter old) => false;
}

/// A Kenney critter wrapped in a little knitted scarf.
class ScarfCritter extends StatelessWidget {
  const ScarfCritter({super.key, required this.id, required this.size});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = _scarves[id.codeUnits.fold<int>(3, (a, c) => a * 31 + c) % _scarves.length];
    return SizedBox.square(
      dimension: size,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: CritterSprite(id, size: size)),
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _ScarfPainter(colors.$1, colors.$2)))),
      ]),
    );
  }
}

class _ScarfPainter extends CustomPainter {
  const _ScarfPainter(this.wool, this.stripe);

  final Color wool;
  final Color stripe;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final dark = Color.lerp(wool, Colors.black, 0.3)!;
    final outline = Paint()
      ..color = dark
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(0.8, w * 0.018)
      ..strokeJoin = StrokeJoin.round;
    // Hanging tail on the right.
    final tail = Path()
      ..moveTo(w * 0.6, h * 0.84)
      ..lineTo(w * 0.74, h * 0.84)
      ..lineTo(w * 0.76, h * 1.04)
      ..lineTo(w * 0.62, h * 1.06)
      ..close();
    canvas.drawPath(tail, Paint()..color = wool);
    canvas.save();
    canvas.clipPath(tail);
    for (final y in [0.92, 0.98]) {
      canvas.drawRect(Rect.fromLTWH(w * 0.55, h * y, w * 0.3, h * 0.025), Paint()..color = stripe);
    }
    canvas.restore();
    canvas.drawPath(tail, outline);
    final fringe = Paint()
      ..color = dark
      ..strokeWidth = max(0.7, w * 0.014)
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 4; k++) {
      final x = w * (0.635 + k * 0.035);
      final y = h * (1.06 - k * 0.005);
      canvas.drawLine(Offset(x, y), Offset(x + w * 0.004, y + h * 0.04), fringe);
    }
    // The wrap around the neck.
    final band = Path()
      ..moveTo(w * 0.2, h * 0.76)
      ..quadraticBezierTo(w * 0.5, h * 0.86, w * 0.8, h * 0.76)
      ..lineTo(w * 0.82, h * 0.86)
      ..quadraticBezierTo(w * 0.5, h * 0.97, w * 0.18, h * 0.86)
      ..close();
    canvas.drawPath(band, Paint()..color = wool);
    canvas.save();
    canvas.clipPath(band);
    final rib = Paint()
      ..color = dark.withValues(alpha: 0.35)
      ..strokeWidth = max(0.6, w * 0.012);
    for (var k = 0; k < 9; k++) {
      final x = w * (0.22 + k * 0.07);
      canvas.drawLine(Offset(x, h * 0.74), Offset(x - w * 0.02, h * 0.98), rib);
    }
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.2, h * 0.81)
        ..quadraticBezierTo(w * 0.5, h * 0.915, w * 0.8, h * 0.81),
      Paint()
        ..color = stripe
        ..style = PaintingStyle.stroke
        ..strokeWidth = h * 0.025,
    );
    canvas.restore();
    canvas.drawPath(band, outline);
  }

  @override
  bool shouldRepaint(_ScarfPainter old) => old.wool != wool || old.stripe != stripe;
}

// ---- The landscape ----

/// Night sky with drifting northern lights, a moon and stars, snowy hills and pines, a cabin with warm windows,
/// and snow falling gently.
class WinterBackground extends StatefulWidget {
  const WinterBackground({super.key});

  @override
  State<WinterBackground> createState() => _WinterBackgroundState();
}

class _WinterBackgroundState extends State<WinterBackground> with TickerProviderStateMixin {
  late final _aurora = AnimationController(vsync: this, duration: const Duration(seconds: 90));
  late final _snowfall = AnimationController(vsync: this, duration: const Duration(seconds: 40));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ambientMotionOn(context)) {
      if (!_aurora.isAnimating) _aurora.repeat();
      if (!_snowfall.isAnimating) _snowfall.repeat();
    } else {
      _aurora.stop();
      _snowfall.stop();
    }
  }

  @override
  void dispose() {
    _aurora.dispose();
    _snowfall.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final size = box.biggest;
        final inset = MediaQuery.paddingOf(context).bottom;
        return Stack(clipBehavior: Clip.hardEdge, children: [
          const Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _NightSkyPainter()))),
          // The aurora is painted once, two screens wide, and slides: no repaint per frame.
          AnimatedBuilder(
            animation: _aurora,
            builder: (_, child) =>
                Positioned(left: -_aurora.value * size.width, top: 0, width: size.width * 2, height: size.height * 0.5, child: child!),
            child: RepaintBoundary(child: CustomPaint(painter: _AuroraPainter(size.width))),
          ),
          Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _SnowyLandPainter(inset)))),
          Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _SnowfallPainter(_snowfall)))),
        ]);
      });
}

class _NightSkyPainter extends CustomPainter {
  const _NightSkyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    const p = winterPalette;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.skyTop, p.skyMid, p.skyLow, const Color(0xFF6E85B0)],
          stops: const [0, 0.35, 0.62, 0.8],
        ).createShader(rect),
    );
    final r = Random(21);
    for (var i = 0; i < 90; i++) {
      final s = Offset(r.nextDouble() * w, r.nextDouble() * h * 0.55);
      canvas.drawCircle(s, r.nextDouble() < 0.12 ? 1.5 : 0.8, Paint()..color = Colors.white.withValues(alpha: 0.3 + r.nextDouble() * 0.6));
    }
    // Moon with a soft halo.
    final mc = Offset(w * 0.84, h * 0.14);
    final mr = min(w, 600) * 0.07;
    canvas.drawCircle(mc, mr * 3, Paint()
      ..shader = RadialGradient(colors: [const Color(0x55DDE8FF), const Color(0x00DDE8FF)])
          .createShader(Rect.fromCircle(center: mc, radius: mr * 3)));
    canvas.drawCircle(mc, mr, Paint()..color = const Color(0xFFF7F3E4));
    canvas.drawCircle(mc + Offset(-mr * 0.3, mr * 0.2), mr * 0.18, Paint()..color = const Color(0x22000000));
    canvas.drawCircle(mc + Offset(mr * 0.35, -mr * 0.25), mr * 0.12, Paint()..color = const Color(0x1A000000));
  }

  @override
  bool shouldRepaint(_NightSkyPainter old) => false;
}

class _AuroraPainter extends CustomPainter {
  const _AuroraPainter(this.period);

  /// One screen width: the ribbons repeat after it, so sliding by it loops seamlessly.
  final double period;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    const ribbons = [
      (0.32, 0.09, 1, Color(0xFF5CFFB0), 0.0),
      (0.44, 0.07, 2, Color(0xFF39D8E0), 1.7),
      (0.26, 0.06, 1, Color(0xFFA77BFF), 3.1),
    ];
    for (final (y0, amp, waves, color, phase) in ribbons) {
      final top = Path();
      final bottomPts = <Offset>[];
      for (var x = 0.0; x <= size.width; x += 6) {
        final a = x / period * 2 * pi * waves + phase;
        final y = h * (y0 + amp * sin(a));
        x == 0 ? top.moveTo(x, y) : top.lineTo(x, y);
        bottomPts.add(Offset(x, y + h * (0.16 + 0.06 * sin(a * 1.5 + 1))));
      }
      for (final p in bottomPts.reversed) {
        top.lineTo(p.dx, p.dy);
      }
      top.close();
      canvas.drawPath(
        top,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0), color.withValues(alpha: 0.32), color.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(0, h * (y0 - amp), size.width, h * 0.4))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  @override
  bool shouldRepaint(_AuroraPainter old) => old.period != period;
}

class _SnowyLandPainter extends CustomPainter {
  const _SnowyLandPainter(this.inset);

  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final ground = meadowGround(h, inset);
    final front = h - ground;

    Path hill(double base, double amp, double freq, double phase) {
      final p = Path()..moveTo(0, base);
      for (var x = 0.0; x <= w; x += 8) {
        p.lineTo(x, base - sin(x / w * pi * freq + phase) * amp);
      }
      return p
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
    }

    // Far hills, pale blue under the night.
    canvas.drawPath(hill(front - ground * 0.6, ground * 0.14, 2.2, 0.6), Paint()..color = const Color(0xFF8EA4C8));
    _pines(canvas, w, front - ground * 0.6, ground * 0.14, 2.2, 0.6, ground * 0.22, const Color(0xFF2E4466), 11, 6);
    canvas.drawPath(hill(front - ground * 0.3, ground * 0.12, 1.4, 2.2), Paint()..color = const Color(0xFFB3C5E0));
    _pines(canvas, w, front - ground * 0.3, ground * 0.12, 1.4, 2.2, ground * 0.32, const Color(0xFF1F3552), 7, 9);
    _cabin(canvas, Offset(w * 0.2, front - ground * 0.14), ground * 0.5);
    // Front snow.
    final rect = Rect.fromLTWH(0, front - 20, w, ground + 20);
    canvas.drawPath(
      hill(front, ground * 0.05, 3, 1),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF4F8FD), Color(0xFFD5E2F2)],
        ).createShader(rect),
    );
    final r = Random(9);
    final glint = Paint()..color = Colors.white;
    final blue = Paint()..color = const Color(0x339FB4D2);
    for (var i = 0; i < w / 18; i++) {
      final x = r.nextDouble() * w, y = front + 16 + r.nextDouble() * (ground - 30);
      canvas.drawOval(Rect.fromCenter(center: Offset(x, y + 3), width: 22 + r.nextDouble() * 20, height: 5), blue);
      canvas.drawCircle(Offset(x, y), 1.2, glint);
    }
    // Two front pines at the edges.
    _pine(canvas, Offset(w * 0.04, front + ground * 0.12), ground * 0.62, const Color(0xFF1A3049));
    _pine(canvas, Offset(w * 0.97, front + ground * 0.08), ground * 0.7, const Color(0xFF1A3049));
  }

  void _pines(Canvas canvas, double w, double base, double amp, double freq, double phase, double height, Color color,
      int count, int seed) {
    final r = Random(seed);
    for (var i = 0; i < count; i++) {
      final x = (i + 0.2 + r.nextDouble() * 0.6) / count * w;
      final y = base - sin(x / w * pi * freq + phase) * amp + 4;
      _pine(canvas, Offset(x, y), height * (0.7 + r.nextDouble() * 0.5), color);
    }
  }

  /// A pine with snow on its tiers; [foot] is the bottom of the trunk.
  void _pine(Canvas canvas, Offset foot, double height, Color color) {
    final wd = height * 0.46;
    canvas.drawRect(Rect.fromLTWH(foot.dx - wd * 0.06, foot.dy - height * 0.14, wd * 0.12, height * 0.14), Paint()..color = const Color(0xFF3A2A22));
    final fill = Paint()..color = color;
    final snow = Paint()..color = const Color(0xFFEAF2FC);
    for (var t = 0; t < 3; t++) {
      final top = foot.dy - height * (0.38 + t * 0.24) - height * 0.24;
      final bottom = foot.dy - height * (0.1 + t * 0.24);
      final half = wd * (0.5 - t * 0.12);
      final tier = Path()
        ..moveTo(foot.dx, top)
        ..lineTo(foot.dx + half, bottom)
        ..lineTo(foot.dx - half, bottom)
        ..close();
      canvas.drawPath(tier, fill);
      final cap = Path()
        ..moveTo(foot.dx, top)
        ..lineTo(foot.dx + half * 0.55, top + (bottom - top) * 0.55)
        ..quadraticBezierTo(foot.dx + half * 0.2, top + (bottom - top) * 0.45, foot.dx, top + (bottom - top) * 0.6)
        ..quadraticBezierTo(foot.dx - half * 0.25, top + (bottom - top) * 0.48, foot.dx - half * 0.55, top + (bottom - top) * 0.55)
        ..close();
      canvas.drawPath(cap, snow);
    }
  }

  void _cabin(Canvas canvas, Offset foot, double s) {
    final w = s * 0.9, wallH = s * 0.42;
    final left = foot.dx - w / 2, base = foot.dy;
    // Window glow on the snow.
    canvas.drawCircle(Offset(foot.dx, base - wallH * 0.4), s * 0.75, Paint()
      ..shader = RadialGradient(colors: [const Color(0x55FFB54A), const Color(0x00FFB54A)])
          .createShader(Rect.fromCircle(center: Offset(foot.dx, base - wallH * 0.4), radius: s * 0.75)));
    // Chimney and smoke.
    canvas.drawRect(Rect.fromLTWH(left + w * 0.68, base - wallH - s * 0.38, w * 0.1, s * 0.3), Paint()..color = const Color(0xFF5B3A2E));
    final smoke = Paint()..color = const Color(0x44DDE6F5);
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(Offset(left + w * (0.74 + i * 0.05), base - wallH - s * (0.46 + i * 0.13)), s * (0.05 + i * 0.025), smoke);
    }
    // Log walls.
    final walls = Rect.fromLTWH(left, base - wallH, w, wallH);
    canvas.drawRect(walls, Paint()..color = const Color(0xFF6B4029));
    final log = Paint()
      ..color = const Color(0xFF4E2D1C)
      ..strokeWidth = 1.2;
    for (var y = walls.top + wallH / 6; y < walls.bottom; y += wallH / 6) {
      canvas.drawLine(Offset(walls.left, y), Offset(walls.right, y), log);
    }
    // Roof with a thick snow layer.
    final roof = Path()
      ..moveTo(left - w * 0.1, base - wallH)
      ..lineTo(foot.dx, base - wallH - s * 0.36)
      ..lineTo(left + w * 1.1, base - wallH)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF3E2418));
    final snowRoof = Path()
      ..moveTo(left - w * 0.13, base - wallH + 2)
      ..lineTo(foot.dx, base - wallH - s * 0.42)
      ..lineTo(left + w * 1.13, base - wallH + 2)
      ..quadraticBezierTo(left + w * 0.8, base - wallH - s * 0.06, foot.dx, base - wallH - s * 0.26)
      ..quadraticBezierTo(left + w * 0.2, base - wallH - s * 0.06, left - w * 0.13, base - wallH + 2)
      ..close();
    canvas.drawPath(snowRoof, Paint()..color = const Color(0xFFF2F7FD));
    // Warm windows and a door.
    final warm = Paint()
      ..shader = const RadialGradient(colors: [Color(0xFFFFE6A0), Color(0xFFFFA43A)])
          .createShader(Rect.fromLTWH(left, base - wallH, w, wallH));
    for (final x in [0.14, 0.62]) {
      final win = Rect.fromLTWH(left + w * x, base - wallH * 0.72, w * 0.22, wallH * 0.36);
      canvas.drawRect(win, warm);
      final bar = Paint()
        ..color = const Color(0xFF4E2D1C)
        ..strokeWidth = 1.4;
      canvas.drawLine(win.topCenter, win.bottomCenter, bar);
      canvas.drawLine(win.centerLeft, win.centerRight, bar);
      canvas.drawRect(win, bar..style = PaintingStyle.stroke);
    }
    canvas.drawRect(Rect.fromLTWH(left + w * 0.42, base - wallH * 0.62, w * 0.14, wallH * 0.62), Paint()..color = const Color(0xFF3E2418));
    // Snow bank at the foot.
    canvas.drawOval(Rect.fromCenter(center: Offset(foot.dx, base + 1), width: w * 1.3, height: s * 0.12), Paint()..color = const Color(0xFFEAF2FC));
  }

  @override
  bool shouldRepaint(_SnowyLandPainter old) => old.inset != inset;
}

class _SnowfallPainter extends CustomPainter {
  _SnowfallPainter(this.fall) : super(repaint: fall);

  final Animation<double> fall;

  static final _flakes = List.generate(70, (i) {
    final r = Random(i * 13 + 5);
    return (r.nextDouble(), r.nextDouble(), 0.8 + r.nextDouble() * 2.2, 1 + r.nextInt(3), r.nextDouble() * 2 * pi);
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = fall.value;
    for (final (x0, y0, radius, speed, phase) in _flakes) {
      final y = ((y0 + t * speed) % 1.0) * (size.height + 20) - 10;
      final x = (x0 * size.width + sin(t * 2 * pi * speed + phase) * 14) % size.width;
      canvas.drawCircle(Offset(x, y), radius, Paint()..color = Colors.white.withValues(alpha: 0.4 + radius * 0.15));
    }
  }

  @override
  bool shouldRepaint(_SnowfallPainter old) => false;
}
