import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'meadow_world.dart';
import 'world.dart';

/// Wild Lodge palette: dusk sky, dark weathered wood, charcoal-green panels, parchment text, forest green and brass.
/// Text-ish accents ([woodDark], [goldEdge], [leafEdge], [coralEdge]) are light enough to read on the dark cards.
const lodgePalette = WorldPalette(
  background: Color(0xFF221A15),
  surface: Color(0xFF2E3329),
  ink: Color(0xFFF1E6CF),
  inkSoft: Color(0xFFBFAE8C),
  accent: Color(0xFFD9822B),
  good: Color(0xFF7FA65A),
  bad: Color(0xFFC8553D),
  gold: Color(0xFFC9A04E),
  skyTop: Color(0xFF191329),
  skyMid: Color(0xFF6A2C4A),
  skyLow: Color(0xFFF08A3C),
  hillFar: Color(0xFF6B3D5A),
  hillMid: Color(0xFF3F2A44),
  grass: Color(0xFF1E2A1F),
  grassDark: Color(0xFF3A2A1C),
  soil: Color(0xFF120D09),
  wood: Color(0xFF4A3323),
  woodLight: Color(0xFF5E4330),
  woodDark: Color(0xFFCDA772),
  woodEdge: Color(0xFF140C07),
  paper: Color(0xFF283025),
  paperEdge: Color(0xFF5E5640),
  leaf: Color(0xFF4E7A3A),
  leafEdge: Color(0xFFA3C77F),
  sky: Color(0xFF4F6272),
  skyEdge: Color(0xFFA9BCCB),
  goldEdge: Color(0xFFD9B25E),
  coral: Color(0xFFA9502E),
  coralEdge: Color(0xFFE39066),
  woodButton: Color(0xFF7A5A3A),
  sunColor: Color(0xFFD9761E),
  moonColor: Color(0xFF2F4B69),
  accentSoft: Color(0xFF4A3024),
  goodSoft: Color(0xFF2E3F27),
  goldSoft: Color(0xFF43381F),
  rareBlue: Color(0xFF7FA0C4),
  rareSoft: Color(0xFF2B3542),
  tileEmpty: Color(0xFF3A3A30),
  tileGiven: Color(0xFF4C4A3C),
  shadow: Color(0x73000000),
  onWood: Color(0xFFF3E3C3),
  onWoodSoft: Color(0xFFCDB48C),
  barrier: Color(0x9E0C0805),
);

const lodgeBoard = BoardPalette(
  zones: [
    Color(0xFF7E8F55), // moss
    Color(0xFFC49A4A), // ochre
    Color(0xFFA9603F), // rust
    Color(0xFF6A7F96), // slate blue
    Color(0xFFCDB98C), // sand
    Color(0xFF9AAE8C), // sage
    Color(0xFF8A6278), // plum
    Color(0xFFB07A5E), // clay
    Color(0xFF5E8C86), // teal
    Color(0xFFA8A272), // khaki
  ],
  bedShine: Color(0x00000000),
  speckles: false,
  cellLine: Color(0x2E000000),
  zoneEdge: Color(0xFF24170E),
  zoneEdgeInner: Color(0xFF5A3D26),
  zoneDots: Color(0xFFC9A04E),
  ruledOut: Color(0x47000000),
  lawnTop: Color(0xFF3E4A2E),
  lawnBottom: Color(0xFF2A3420),
  lawnEdge: Color(0xFF151B10),
  lawnTuft: Color(0xFF5B6A40),
  stoneTop: Color(0xFFCFCBBE),
  stoneLow: Color(0xFFAAA699),
  stoneEdge: Color(0xFF66635A),
  givenTop: Color(0xFF9C978A),
  givenLow: Color(0xFF858073),
  givenEdge: Color(0xFF4F4C44),
  moss: Color(0xCC6E8A4A),
  stoneShine: Color(0x55FFFFFF),
  linkFill: Color(0xFFC9A04E),
  linkEdge: Color(0xFF3A2614),
  grassLight: Color(0xFF4A5634),
  grassDark: Color(0xFF414C2D),
  grassLine: Color(0xFF2C351E),
  dirtEdge: Color(0xFF5C3F24),
  dirtFill: Color(0xFFA88158),
  dirtGlow: Color(0xFFE6B66E),
  dirtPrint: Color(0xFF6E4E30),
  pebbleTop: Color(0xFFD3CFC2),
  pebbleLow: Color(0xFF9E9A8C),
  pebbleRim: Color(0xFF55524A),
  pebbleText: Color(0xFF1E1A14),
  pebbleReachedTop: Color(0xFFEBCB80),
  pebbleReachedLow: Color(0xFFC9A04E),
  pebbleReachedRim: Color(0xFF6E5020),
  pebbleReachedText: Color(0xFF2A1A0A),
  cardNests: [Color(0xFF34412B), Color(0xFF242E1D)],
  cardPairs: [Color(0xFF2D3A44), Color(0xFF1F2930)],
  cardTrail: [Color(0xFF45362A), Color(0xFF30251C)],
  cardEdge: Color(0xFF5E5640),
);

const _brass = Color(0xFFC9A04E);
const _brassLight = Color(0xFFEBD08A);
const _brassDark = Color(0xFF7A5A22);
const _parchment = Color(0xFFF1E3BF);
const _cream = Color(0xFFF2DFAE);

/// Wild Lodge: dusk in the pines, a campfire glow, dark wood and brass, slab type; critters as wildlife badges.
class LodgeWorld extends GameWorld {
  const LodgeWorld();

  @override
  String get id => 'world.lodge';

  @override
  String name(AppLocalizations l10n) => l10n.worldLodge;

  @override
  String blurb(AppLocalizations l10n) => l10n.worldLodgeBlurb;

  @override
  WorldPalette get palette => lodgePalette;

  @override
  BoardPalette get board => lodgeBoard;

  @override
  String get font => 'ZillaSlab';

  @override
  String get titleFont => 'Bevan';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  bool get hats => false;

  @override
  bool get cartoonProps => false;

  @override
  bool get journal => true;

  @override
  String albumTitle(AppLocalizations l10n) => l10n.fieldJournal;

  @override
  double get radius => 10;

  @override
  List<Color> get mapGround => const [Color(0xFF2C3522), Color(0xFF1F271A), Color(0xFF151B12)];

  @override
  bool get mapProps => false;

  @override
  List<Color> get celebration => const [
        Color(0xFFE8A33C),
        Color(0xFFFF7A1C),
        _brass,
        Color(0xFF7FA65A),
        Color(0xFFD96B3B),
        _parchment,
      ];

  @override
  Color get bannerStrip => const Color(0xFF0E0A07);

  @override
  Color get bannerEdge => const Color(0xFF3A2A1C);

  // ---- Text ----

  @override
  TextStyle outlined(double size, {Color? color, Color? stroke, double? width}) =>
      text(size, color: color ?? lodgePalette.onWood).copyWith(shadows: [
        Shadow(color: const Color(0xE6000000), offset: Offset(0, max(1.0, size * 0.06)), blurRadius: size * 0.1),
        Shadow(color: const Color(0x80000000), blurRadius: size * 0.35),
      ]);

  @override
  TextStyle buttonText(double size, {required Color textColor, required Color rim}) => text(size, color: textColor)
      .copyWith(letterSpacing: 0.5, shadows: [Shadow(color: const Color(0xB3000000), offset: const Offset(0, 1.5), blurRadius: 1.5)]);

  /// Cream letters routed into a dark plank, like a park trail sign.
  TextStyle carved(double size) => TextStyle(
        fontFamily: titleFont,
        fontWeight: FontWeight.w700,
        fontSize: size,
        height: 1.1,
        letterSpacing: 0.6,
        color: _cream,
        shadows: [
          const Shadow(color: Color(0xCC000000), offset: Offset(0, -1)),
          Shadow(color: const Color(0x33FFE6B0), offset: Offset(0, max(1.0, size * 0.05))),
          Shadow(color: const Color(0x99000000), blurRadius: size * 0.15, offset: Offset(0, size * 0.06)),
        ],
      );

  // ---- Background ----

  @override
  Widget background(BuildContext context) => const LodgeBackground();

  // ---- Panels and buttons ----

  @override
  void paintPanel(Canvas canvas, Size size, {double radius = 18, bool nails = true, double plank = 34}) =>
      paintDarkPlanks(canvas, size, radius: radius, nails: nails, plank: plank);

  @override
  BoxDecoration card({Color? fill, Color? border}) {
    final f = fill ?? lodgePalette.paper;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color.lerp(f, Colors.white, 0.05)!, Color.lerp(f, Colors.black, 0.12)!],
      ),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: border ?? lodgePalette.paperEdge, width: border == null ? 1.5 : 2.5),
      boxShadow: const [
        BoxShadow(color: Color(0x8C000000), offset: Offset(0, 4)),
        BoxShadow(color: Color(0x59000000), blurRadius: 14, offset: Offset(0, 8)),
      ],
    );
  }

  @override
  BoxDecoration pill(Color fill, double height) => BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: _brass.withValues(alpha: 0.7), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x80000000), offset: Offset(0, 3), blurRadius: 4)],
      );

  @override
  Color edgeOf(Color c) => Color.lerp(c, const Color(0xFF0B0805), 0.5)!;

  @override
  double buttonDepth(bool small) => small ? 3 : 4;

  @override
  Color iconColor(Color face) => lodgePalette.onWood;

  @override
  List<Shadow> iconShadows(Color face) => const [Shadow(color: Color(0xB3000000), offset: Offset(0, 1.5), blurRadius: 1.5)];

  @override
  Color get disabledButton => const Color(0xFF45443C);

  @override
  void paintButton(Canvas canvas, Size size,
      {required Color face, required Color edge, double press = 0, double depth = 6, double radius = 20, bool circle = false}) {
    final r = circle ? size.height / 2 : min(radius, 10.0);
    final outer = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r));
    final top = depth * press;
    final faceRect = RRect.fromLTRBR(0, top, size.width, size.height - depth + top, Radius.circular(r));
    canvas.drawRRect(outer.shift(const Offset(0, 3)), Paint()
      ..color = const Color(0x80000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    canvas.drawRRect(outer, Paint()..color = edge);
    canvas.drawRRect(
      faceRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(face, Colors.white, 0.14)!, Color.lerp(face, Colors.black, 0.12)!],
        ).createShader(faceRect.outerRect),
    );
    // Bevel: a light top edge, a brass hairline inside.
    final f = faceRect.outerRect;
    canvas.save();
    canvas.clipRRect(faceRect);
    canvas.drawLine(Offset(f.left, f.top + 1.2), Offset(f.right, f.top + 1.2), Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1.6);
    canvas.restore();
    canvas.drawRRect(faceRect.deflate(3), Paint()
      ..color = _brass.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    canvas.drawRRect(outer.deflate(1), Paint()
      ..color = const Color(0xFF0E0906)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  // ---- Sign and plaque ----

  @override
  Widget sign(BuildContext context, {required String title, String? subtitle, double fontSize = 40}) =>
      _TrailSign(world: this, title: title, subtitle: subtitle, fontSize: fontSize);

  @override
  Widget label(BuildContext context, {required String text, String? subtitle, double fontSize = 22}) =>
      PanelLabel(world: this, text: text, subtitle: subtitle, fontSize: fontSize, titleStyle: carved(fontSize * 0.8));

  // ---- Critters ----

  @override
  Widget critter(BuildContext context, String id, double size, {CritterRole role = CritterRole.collectible}) =>
      WildlifeBadge(id, size: size, role: role);

  // ---- Icons ----

  @override
  void paintStreak(Canvas canvas, Size size, {required bool lit, int streak = 0}) =>
      paintCampfire(canvas, size, lit: lit, streak: streak);

  @override
  void paintCross(Canvas canvas, Size size) {
    // A burned X, charred in the middle.
    final w = size.width, h = size.height;
    final a = Offset(w * 0.2, h * 0.2), b = Offset(w * 0.8, h * 0.8);
    final c = Offset(w * 0.8, h * 0.2), d = Offset(w * 0.2, h * 0.8);
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(a, b, stroke(const Color(0x33000000), w * 0.24));
    canvas.drawLine(c, d, stroke(const Color(0x33000000), w * 0.24));
    canvas.drawLine(a, b, stroke(const Color(0xE62A1A10), w * 0.15));
    canvas.drawLine(c, d, stroke(const Color(0xE62A1A10), w * 0.15));
    canvas.drawLine(a + Offset(w * 0.04, 0), b - Offset(w * 0.04, 0), stroke(const Color(0x8C7A4A26), w * 0.04));
    canvas.drawCircle(size.center(Offset.zero), w * 0.06, Paint()..color = const Color(0x99D9761E));
  }
}

// ---- Panels ----

/// Dark weathered planks with seams, grain, knots and brass rivets.
void paintDarkPlanks(Canvas canvas, Size size, {double radius = 18, bool nails = true, double plank = 34}) {
  final r = min(radius * 0.55, 12.0);
  final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r));
  canvas.drawRRect(rr.shift(const Offset(0, 7)), Paint()
    ..color = const Color(0x8C000000)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  canvas.drawRRect(rr.shift(const Offset(0, 4)), Paint()..color = const Color(0xFF120B07));
  canvas.drawRRect(
    rr,
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5A3E2A), Color(0xFF3B281B)],
      ).createShader(Offset.zero & size),
  );
  canvas.save();
  canvas.clipRRect(rr);
  final rows = max(1, (size.height / plank).round());
  final ph = size.height / rows;
  final rnd = Random(size.width.round() * 17 + size.height.round() * 3);
  final seam = Paint()
    ..color = const Color(0xD91A110B)
    ..strokeWidth = 2;
  final grain = Paint()
    ..color = const Color(0x24000000)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  final light = Paint()
    ..color = const Color(0x12FFE6C0)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  for (var i = 0; i < rows; i++) {
    final y = i * ph;
    // Each plank a slightly different tone.
    canvas.drawRect(Rect.fromLTWH(0, y, size.width, ph),
        Paint()..color = (rnd.nextBool() ? Colors.black : const Color(0xFF8A5A30)).withValues(alpha: 0.06 + rnd.nextDouble() * 0.06));
    if (i > 0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), seam);
      canvas.drawLine(Offset(0, y + 1.5), Offset(size.width, y + 1.5), Paint()
        ..color = const Color(0x14FFFFFF)
        ..strokeWidth = 1);
    }
    for (var g = 0; g < 3; g++) {
      final gy = y + ph * (0.2 + 0.6 * rnd.nextDouble());
      final x0 = rnd.nextDouble() * size.width * 0.4 - size.width * 0.1;
      final len = size.width * (0.4 + rnd.nextDouble() * 0.5);
      final path = Path()
        ..moveTo(x0, gy)
        ..cubicTo(x0 + len * 0.3, gy - 2.5, x0 + len * 0.6, gy + 2.5, x0 + len, gy - 0.5);
      canvas.drawPath(path, g == 0 ? light : grain);
    }
    if (size.width > 90 && rnd.nextDouble() < 0.35) {
      final k = Offset(size.width * (0.15 + rnd.nextDouble() * 0.7), y + ph * (0.35 + rnd.nextDouble() * 0.3));
      final kr = min(ph * 0.16, 6.0);
      canvas.drawOval(Rect.fromCenter(center: k, width: kr * 2.6, height: kr * 1.4), Paint()..color = const Color(0x40000000));
      canvas.drawOval(Rect.fromCenter(center: k, width: kr * 4.2, height: kr * 2.2), grain);
    }
  }
  canvas.restore();
  canvas.drawRRect(rr.deflate(1.25), Paint()
    ..color = const Color(0xFF140C07)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.5);
  canvas.drawRRect(rr.deflate(3.5), Paint()
    ..color = const Color(0x14FFE6C0)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1);
  if (nails && size.width > 60 && size.height > 40) {
    for (final o in [
      const Offset(10, 10),
      Offset(size.width - 10, 10),
      Offset(10, size.height - 10),
      Offset(size.width - 10, size.height - 10),
    ]) {
      paintRivet(canvas, o, 3.4);
    }
  }
}

/// A brass rivet.
void paintRivet(Canvas canvas, Offset o, double r) {
  canvas.drawCircle(o + const Offset(0, 1), r, Paint()..color = const Color(0x99000000));
  canvas.drawCircle(
    o,
    r,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.4, -0.4),
        colors: [_brassLight, _brass, _brassDark],
        stops: [0, 0.5, 1],
      ).createShader(Rect.fromCircle(center: o, radius: r)),
  );
}

// ---- The title sign ----

class _TrailSign extends StatelessWidget {
  const _TrailSign({required this.world, required this.title, this.subtitle, this.fontSize = 40});

  final LodgeWorld world;
  final String title;
  final String? subtitle;
  final double fontSize;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: const _TrailSignPainter(),
        child: Padding(
          padding: EdgeInsets.fromLTRB(30, 42, 30, subtitle == null ? 22 : 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(title, maxLines: 1, textAlign: TextAlign.center, style: world.carved(fontSize * 0.86)),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!.toUpperCase(),
                textAlign: TextAlign.center,
                style: world.text(13, color: lodgePalette.onWoodSoft, weight: FontWeight.w600).copyWith(
                  letterSpacing: 2.2,
                  shadows: const [Shadow(color: Color(0xB3000000), offset: Offset(0, 1))],
                ),
              ),
            ],
          ]),
        ),
      );
}

class _TrailSignPainter extends CustomPainter {
  const _TrailSignPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const top = 26.0;
    final board = Rect.fromLTWH(0, top, size.width, size.height - top - 4);
    // Iron chains up to the top edge.
    for (final x in [size.width * 0.16, size.width * 0.84]) {
      canvas.drawCircle(Offset(x, 3), 4, Paint()
        ..color = const Color(0xFF3C3A36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4);
      var y = 6.0;
      var k = 0;
      while (y < top + 6) {
        final link = k.isEven
            ? Rect.fromCenter(center: Offset(x, y + 3.5), width: 6, height: 9)
            : Rect.fromCenter(center: Offset(x, y + 3.5), width: 2.4, height: 9);
        canvas.drawOval(link, Paint()
          ..color = const Color(0xFF15120F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2);
        canvas.drawOval(link, Paint()
          ..color = k.isEven ? const Color(0xFF8E8A82) : const Color(0xFF5E5A54)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);
        y += 6.5;
        k++;
      }
    }
    canvas.save();
    canvas.translate(board.left, board.top);
    paintDarkPlanks(canvas, board.size, radius: 12, plank: board.height / 2, nails: true);
    // A routed groove inside the edge, park-sign style.
    final groove = RRect.fromRectAndRadius((Offset.zero & board.size).deflate(9), const Radius.circular(4));
    canvas.drawRRect(groove.shift(const Offset(0, 1)), Paint()
      ..color = const Color(0x33FFE6B0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
    canvas.drawRRect(groove, Paint()
      ..color = _cream.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_TrailSignPainter old) => false;
}

// ---- Streak campfire ----

/// Logs and a fire that grows with the streak: embers at 0, small at 1–2, bigger from 3, 7 and 30 days.
void paintCampfire(Canvas canvas, Size size, {required bool lit, int streak = 0}) {
  final w = size.width, h = size.height;
  final level = !lit || streak <= 0
      ? 0.0
      : streak < 3
          ? 0.55
          : streak < 7
              ? 0.7
              : streak < 30
                  ? 0.85
                  : 1.0;
  final base = Offset(w / 2, h * 0.84);
  if (level > 0) {
    canvas.drawCircle(
      base,
      w * 0.55 * level,
      Paint()
        ..shader = RadialGradient(colors: [const Color(0xFFFF8A2A).withValues(alpha: 0.5), const Color(0x00FF8A2A)])
            .createShader(Rect.fromCircle(center: base, radius: w * 0.55 * level)),
    );
  }
  // Two crossed logs.
  for (final a in const [0.38, -0.38]) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(a);
    final log = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w * 0.82, height: h * 0.15), Radius.circular(h * 0.07));
    canvas.drawRRect(log, Paint()..color = const Color(0xFF5E3B21));
    canvas.drawRRect(log, Paint()
      ..color = const Color(0xFF2A190D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, w * 0.04));
    final end = Offset(w * 0.41 * (a > 0 ? 1 : -1) * (a > 0 ? 1 : -1), 0);
    canvas.drawCircle(end, h * 0.06, Paint()..color = const Color(0xFFB98A58));
    canvas.restore();
  }
  if (level == 0) {
    final ember = Paint()..color = const Color(0xFFC2451F);
    for (final (x, y, r) in const [(0.42, 0.78, 0.05), (0.56, 0.76, 0.045), (0.5, 0.82, 0.04)]) {
      canvas.drawCircle(Offset(w * x, h * y), w * r, ember);
    }
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.7)
        ..cubicTo(w * 0.4, h * 0.55, w * 0.62, h * 0.45, w * 0.5, h * 0.25),
      Paint()
        ..color = const Color(0x66B8B0A4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1, w * 0.05)
        ..strokeCap = StrokeCap.round,
    );
    return;
  }
  final fh = h * 0.8 * level;
  final fw = w * 0.72 * (0.65 + 0.35 * level);
  canvas.save();
  canvas.translate(base.dx - fw / 2, base.dy + h * 0.02 - fh);
  paintFlame(canvas, Size(fw, fh), lit: true, outer: const Color(0xFFFF7A1C), inner: const Color(0xFFFFD15C), line: const Color(0xFFA9380B));
  canvas.restore();
  if (streak >= 30) {
    final spark = Paint()..color = const Color(0xFFFFC04A);
    for (final (x, y) in const [(0.22, 0.2), (0.8, 0.12), (0.7, 0.32)]) {
      canvas.drawCircle(Offset(w * x, h * y), max(0.8, w * 0.035), spark);
    }
  }
}

// ---- Wildlife badges ----

/// A critter as a wildlife badge: the animal's silhouette in a carved brass medallion.
class WildlifeBadge extends StatelessWidget {
  const WildlifeBadge(this.id, {super.key, required this.size, this.role = CritterRole.collectible});

  final String id;
  final double size;
  final CritterRole role;

  static int _bucket(double px) {
    for (final b in const [48, 96, 160, 256]) {
      if (px <= b) return b;
    }
    return 384;
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2;
    final inset = switch (role) {
      CritterRole.piece => 0.19,
      CritterRole.decoration => 0.2,
      CritterRole.collectible => 0.22,
    };
    final px = _bucket(size * (1 - inset * 2) * dpr);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BadgePainter(role),
        child: Padding(
          padding: EdgeInsets.all(size * inset),
          child: Image(
            image: ResizeImage(AssetImage('assets/silhouettes/$id.png'), width: px, height: px, policy: ResizeImagePolicy.fit),
            color: role == CritterRole.collectible ? const Color(0xFFEBD9AE) : _parchment,
            colorBlendMode: BlendMode.srcIn,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => Icon(Icons.pets_rounded, color: _parchment, size: size * 0.5),
          ),
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  const _BadgePainter(this.role);

  final CritterRole role;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = min(size.width, size.height) / 2 * 0.97;
    final rim = switch (role) {
      CritterRole.piece => 0.1,
      CritterRole.decoration => 0.12,
      CritterRole.collectible => 0.13,
    };
    if (role != CritterRole.piece) {
      canvas.drawCircle(c + Offset(0, r * 0.08), r, Paint()
        ..color = const Color(0x8C000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.08));
    }
    final outer = Rect.fromCircle(center: c, radius: r);
    // Brass rim, lit from the top left.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_brassLight, _brass, _brassDark, _brass],
          stops: [0, 0.35, 0.75, 1],
        ).createShader(outer),
    );
    final faceR = r * (1 - rim);
    final face = Rect.fromCircle(center: c, radius: faceR);
    canvas.drawCircle(
      c,
      faceR,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.2, -0.3),
          colors: [Color(0xFF35523A), Color(0xFF1F3323), Color(0xFF132017)],
          stops: [0, 0.65, 1],
        ).createShader(face),
    );
    // Inner shadow under the rim, and a fine inner ring.
    canvas.drawCircle(c, faceR - 0.6, Paint()
      ..color = const Color(0x8C000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, r * 0.05));
    if (role != CritterRole.piece) {
      canvas.drawCircle(c, faceR * 0.9, Paint()
        ..color = _brass.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(0.8, r * 0.02));
    }
    canvas.drawCircle(c, r - 0.5, Paint()
      ..color = const Color(0xFF2A1C08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, r * 0.035));
    // A glint on the rim.
    canvas.drawArc(Rect.fromCircle(center: c, radius: r * (1 - rim / 2)), pi * 1.1, pi * 0.35, false, Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(0.8, r * rim * 0.35)
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_BadgePainter old) => old.role != role;
}

// ---- The landscape ----

/// Dusk over the mountains, pine forest, and a campfire glowing below with a few rising embers.
class LodgeBackground extends StatefulWidget {
  const LodgeBackground({super.key});

  @override
  State<LodgeBackground> createState() => _LodgeBackgroundState();
}

class _LodgeBackgroundState extends State<LodgeBackground> with SingleTickerProviderStateMixin {
  late final _fire = AnimationController(vsync: this, duration: const Duration(seconds: 8));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ambientMotionOn(context)) {
      if (!_fire.isAnimating) _fire.repeat();
    } else {
      _fire.stop();
    }
  }

  @override
  void dispose() {
    _fire.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return Stack(children: [
      Positioned.fill(child: RepaintBoundary(child: CustomPaint(painter: _DuskPainter(inset)))),
      Positioned.fill(
        child: RepaintBoundary(
          child: CustomPaint(painter: _FirePainter(_fire, inset)),
        ),
      ),
    ]);
  }
}

class _DuskPainter extends CustomPainter {
  const _DuskPainter(this.inset);

  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final ground = meadowGround(h, inset);
    final front = h - ground * 0.62;
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF15102A), Color(0xFF2C1C42), Color(0xFF6A2C4A), Color(0xFFB9483E), Color(0xFFEE8A3C), Color(0xFFF4A65A)],
          stops: [0, 0.2, 0.38, 0.5, 0.6, 0.7],
        ).createShader(rect),
    );
    // The sun just gone behind the ridge.
    final sun = Offset(w * 0.32, h * 0.66);
    canvas.drawCircle(
      sun,
      w * 0.6,
      Paint()
        ..shader = RadialGradient(colors: [const Color(0xFFFFC27A).withValues(alpha: 0.55), const Color(0x00FF9A4A)])
            .createShader(Rect.fromCircle(center: sun, radius: w * 0.6)),
    );
    // Early stars in the purple.
    final r = Random(11);
    for (var i = 0; i < 70; i++) {
      final y = r.nextDouble() * h * 0.42;
      final x = r.nextDouble() * w;
      final fade = 1 - y / (h * 0.42);
      final s = 0.5 + r.nextDouble() * 1.1;
      canvas.drawCircle(Offset(x, y), s, Paint()..color = Colors.white.withValues(alpha: (0.25 + r.nextDouble() * 0.6) * fade));
    }
    final venus = Offset(w * 0.78, h * 0.2);
    canvas.drawCircle(venus, 6, Paint()
      ..color = const Color(0x55FFF2D0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(venus, 1.8, Paint()..color = const Color(0xFFFFF6E0));

    // Mountain ranges, far to near.
    _range(canvas, size, min(h * 0.72, front - ground * 0.5), h * 0.12, 8, 3, const Color(0xFF5A2F4E), rim: const Color(0xB3FFB07A));
    _range(canvas, size, min(h * 0.79, front - ground * 0.25), h * 0.1, 6, 5, const Color(0xFF3A2440), rim: const Color(0x40F0A070));
    _range(canvas, size, front - ground * 0.1, ground * 0.45, 10, 8, const Color(0xFF2E2236));

    // A hazy band of pines along the far ridge, then the forest floor.
    final back = Paint()..color = const Color(0xFF1E1A26);
    final rb = Random(5);
    for (var x = -10.0; x < w + 20; x += 9 + rb.nextDouble() * 9) {
      final ph = ground * (0.28 + rb.nextDouble() * 0.3);
      _pine(canvas, x, front + 4, ph, ph * 0.36, back);
    }
    canvas.drawRect(Rect.fromLTWH(0, front, w, h - front), Paint()..color = const Color(0xFF0D100E));
    final mid = Paint()..color = const Color(0xFF121614);
    final rm = Random(9);
    for (var x = -10.0; x < w + 20; x += 16 + rm.nextDouble() * 22) {
      final ph = ground * (0.45 + rm.nextDouble() * 0.35);
      _pine(canvas, x, front + ground * 0.18, ph, ph * 0.34, mid);
    }
    canvas.drawRect(Rect.fromLTWH(0, front + ground * 0.17, w, h), Paint()..color = const Color(0xFF0A0C0B));
    // Tall pines framing the sides.
    final near = Paint()..color = const Color(0xFF070908);
    final rn = Random(3);
    for (final (x, k) in [(w * 0.03, 2.3), (w * 0.12, 1.7), (-w * 0.04, 1.4), (w * 0.9, 2.1), (w * 1.0, 2.6), (w * 0.8, 1.35)]) {
      final ph = ground * k * (0.9 + rn.nextDouble() * 0.2);
      _pine(canvas, x, h - ground * 0.25, ph, ph * 0.3, near);
    }
  }

  static void _range(Canvas canvas, Size size, double baseY, double height, int peaks, int seed, Color color, {Color? rim}) {
    final w = size.width;
    final r = Random(seed);
    final pts = <Offset>[Offset(0, baseY - height * 0.3)];
    final step = w / peaks;
    for (var i = 0; i <= peaks; i++) {
      final x = i * step + (r.nextDouble() - 0.5) * step * 0.4;
      pts.add(Offset(x - step * 0.5, baseY - height * (0.2 + r.nextDouble() * 0.2)));
      pts.add(Offset(x, baseY - height * (0.55 + r.nextDouble() * 0.45)));
    }
    pts.add(Offset(w, baseY - height * 0.3));
    final ridge = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      ridge.lineTo(p.dx, p.dy);
    }
    final fill = Path.from(ridge)
      ..lineTo(w, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = color);
    if (rim != null) {
      canvas.drawPath(ridge, Paint()
        ..color = rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeJoin = StrokeJoin.round);
    }
  }

  static void _pine(Canvas canvas, double x, double baseY, double height, double halfW, Paint paint) {
    const tiers = 6;
    final path = Path()..moveTo(x, baseY - height);
    final tierH = height * 0.86 / tiers;
    for (var i = 1; i <= tiers; i++) {
      final y = baseY - height + tierH * i + height * 0.02;
      final hw = halfW * i / tiers;
      path
        ..lineTo(x + hw, y)
        ..lineTo(x + hw * 0.45, y - tierH * 0.3);
    }
    path.lineTo(x + halfW * 0.08, baseY);
    path.lineTo(x - halfW * 0.08, baseY);
    for (var i = tiers; i >= 1; i--) {
      final y = baseY - height + tierH * i + height * 0.02;
      final hw = halfW * i / tiers;
      path
        ..lineTo(x - hw * 0.45, y - tierH * 0.3)
        ..lineTo(x - hw, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DuskPainter old) => old.inset != inset;
}

class _FirePainter extends CustomPainter {
  _FirePainter(this.t, this.inset) : super(repaint: t);

  final Animation<double> t;
  final double inset;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final ground = meadowGround(h, inset);
    final v = t.value;
    final flicker = 0.82 + 0.1 * sin(v * pi * 2 * 13) + 0.08 * sin(v * pi * 2 * 29 + 1.3);
    final c = Offset(w * 0.5, h + ground * 0.15);
    final radius = max(w, ground * 2.4) * 0.85;
    canvas.drawCircle(
      c,
      radius,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xFFFF7A2A).withValues(alpha: 0.42 * flicker),
          const Color(0xFFD9541E).withValues(alpha: 0.16 * flicker),
          const Color(0x00D9541E),
        ], stops: const [0, 0.45, 1])
            .createShader(Rect.fromCircle(center: c, radius: radius)),
    );
    // Embers drifting up.
    final r = Random(21);
    final ember = Paint();
    for (var i = 0; i < 14; i++) {
      final speed = 1 + r.nextInt(3);
      final phase = (v * speed + r.nextDouble()) % 1.0;
      final x0 = w * (0.25 + r.nextDouble() * 0.5);
      final x = x0 + sin(phase * pi * 4 + i) * 14;
      final y = h - ground * 0.15 - phase * ground * 2.2;
      final a = (1 - phase) * (phase < 0.1 ? phase * 10 : 1);
      ember.color = Color.lerp(const Color(0xFFFFD27A), const Color(0xFFFF5A1C), phase)!.withValues(alpha: 0.85 * a);
      canvas.drawCircle(Offset(x, y), 1.1 + r.nextDouble() * 1.3, ember);
    }
  }

  @override
  bool shouldRepaint(_FirePainter old) => old.inset != inset || old.t != t;
}
