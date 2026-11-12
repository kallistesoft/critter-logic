import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../critter_image.dart';
import 'world.dart';

const _gold = Color(0xFFD4AF37);
const _goldDeep = Color(0xFFA88A26);
const _slate = Color(0xFF2A313B);
const _slateLine = Color(0xFF3A4350);
const _night = Color(0xFF1B2027);

const proPalette = WorldPalette(
  background: Color(0xFF1E242C),
  surface: Color(0xFF262D36),
  ink: Color(0xFFEEF1F5),
  inkSoft: Color(0xFF9AA5B4),
  accent: _gold,
  good: Color(0xFF4CB782),
  bad: Color(0xFFE5575B),
  gold: _gold,
  skyTop: Color(0xFF1B2027),
  skyMid: Color(0xFF20262E),
  skyLow: Color(0xFF242B34),
  hillFar: Color(0xFF2C343E),
  hillMid: Color(0xFF323B46),
  grass: Color(0xFF323B46),
  grassDark: Color(0xFF2A313B),
  soil: Color(0xFF15191E),
  wood: Color(0xFF2E3640),
  woodLight: Color(0xFF353E4A),
  woodDark: Color(0xFFB9C2CE),
  woodEdge: Color(0xFF12161B),
  paper: _slate,
  paperEdge: _slateLine,
  leaf: _gold,
  leafEdge: _goldDeep,
  sky: Color(0xFF4A5566),
  skyEdge: Color(0xFF343D4A),
  goldEdge: _goldDeep,
  coral: Color(0xFFE07A5F),
  coralEdge: Color(0xFFB3593F),
  woodButton: Color(0xFF4A5566),
  sunColor: Color(0xFFE8B54A),
  moonColor: Color(0xFF93A7CC),
  accentSoft: Color(0xFF3A302B),
  goodSoft: Color(0xFF22362E),
  goldSoft: Color(0xFF39331F),
  rareBlue: Color(0xFF6B9BF2),
  rareSoft: Color(0xFF233250),
  tileEmpty: Color(0xFF2F3742),
  tileGiven: Color(0xFF3B4451),
  shadow: Color(0x66000000),
  onWood: Color(0xFFF2F4F7),
  onWoodSoft: Color(0xFFB9C2CE),
  barrier: Color(0xAA0B0E12),
);

const proBoard = BoardPalette(
  zones: [
    Color(0xFF3C4C63),
    Color(0xFF465843),
    Color(0xFF5E4A39),
    Color(0xFF4D3F60),
    Color(0xFF3B5855),
    Color(0xFF5C4452),
    Color(0xFF54523A),
    Color(0xFF34505F),
    Color(0xFF5A4136),
    Color(0xFF475266),
  ],
  bedShine: Color(0x00000000),
  speckles: false,
  cellLine: Color(0x1FFFFFFF),
  zoneEdge: Color(0xFF12161B),
  zoneEdgeInner: Color(0xFFC9A646),
  ruledOut: Color(0x55B9C2CE),
  lawnTop: Color(0xFF262D36),
  lawnBottom: Color(0xFF222830),
  lawnEdge: Color(0xFF12161B),
  lawnTuft: Color(0x00000000),
  stoneTop: Color(0xFF3B4451),
  stoneLow: Color(0xFF353D49),
  stoneEdge: Color(0xFF242A33),
  givenTop: Color(0xFF2B323C),
  givenLow: Color(0xFF282E37),
  givenEdge: Color(0xFF1A1F26),
  stoneShine: Color(0x12FFFFFF),
  linkFill: _slate,
  linkEdge: _gold,
  grassLight: Color(0xFF29303A),
  grassDark: Color(0xFF252B34),
  grassLine: Color(0x00000000),
  dirtEdge: _goldDeep,
  dirtFill: _gold,
  dirtGlow: Color(0xFFF2D77F),
  dirtPrint: _gold,
  pebbleTop: Color(0xFF3B4451),
  pebbleLow: Color(0xFF303844),
  pebbleRim: Color(0xFF5E6979),
  pebbleText: Color(0xFFEEF1F5),
  pebbleReachedTop: Color(0xFFE8C860),
  pebbleReachedLow: Color(0xFFC9A13A),
  pebbleReachedRim: _goldDeep,
  pebbleReachedText: _night,
  cardNests: [Color(0xFF303844), Color(0xFF2A313B)],
  cardPairs: [Color(0xFF303844), Color(0xFF2A313B)],
  cardTrail: [Color(0xFF303844), Color(0xFF2A313B)],
  cardEdge: _slateLine,
);

/// Clean Pro: minimal slate and gold, a clean sans, flat cards, no decorations. Critters only show up, small, in
/// the album and the rewards; on the boards they're plain gold tokens.
class ProWorld extends GameWorld {
  const ProWorld();

  @override
  String get id => 'world.pro';

  @override
  String name(AppLocalizations l10n) => l10n.worldPro;

  @override
  String blurb(AppLocalizations l10n) => l10n.worldProBlurb;

  @override
  WorldPalette get palette => proPalette;

  @override
  BoardPalette get board => proBoard;

  @override
  String get font => 'Inter';

  @override
  Brightness get brightness => Brightness.dark;

  @override
  bool get decorations => false;

  @override
  bool get hats => false;

  @override
  double get radius => 12;

  @override
  List<Color> get mapGround => const [Color(0xFF232A33), Color(0xFF262D37), Color(0xFF20262E)];

  @override
  List<Color> get celebration => const [_gold, Color(0xFFF2D77F), Color(0xFFEEF1F5), Color(0xFF93A7CC), Color(0xFF9AA5B4)];

  @override
  TextStyle text(double size, {Color? color, FontWeight weight = FontWeight.w700, double? height, String? family}) =>
      super.text(size * 0.94, color: color, weight: weight, height: height, family: family).copyWith(
            letterSpacing: -0.1,
            fontFeatures: const [FontFeature.tabularFigures()],
          );

  @override
  TextStyle outlined(double size, {Color? color, Color? stroke, double? width}) =>
      text(size, color: color == null || color == Colors.white ? palette.ink : color);

  @override
  Widget background(BuildContext context) => const RepaintBoundary(child: CustomPaint(painter: _ProBackdrop()));

  @override
  Color get bannerStrip => const Color(0xFF15191E);

  @override
  Color get bannerEdge => _slateLine;

  @override
  void paintPanel(Canvas canvas, Size size, {double radius = 18, bool nails = true, double plank = 34}) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(min(radius, 12)));
    canvas.drawRRect(rr.shift(const Offset(0, 3)), Paint()
      ..color = const Color(0x55000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawRRect(rr, Paint()..color = palette.wood);
    canvas.drawRRect(rr.deflate(0.5), Paint()
      ..color = _slateLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
  }

  @override
  BoxDecoration card({Color? fill, Color? border}) => BoxDecoration(
        color: fill ?? palette.paper,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: border ?? palette.paperEdge, width: border == null ? 1 : 1.5),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 3))],
      );

  @override
  BoxDecoration pill(Color fill, double height) => BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: _slateLine, width: 1),
      );

  @override
  Color edgeOf(Color c) => Color.lerp(c, Colors.black, 0.25)!;

  @override
  double buttonDepth(bool small) => 0;

  @override
  void paintButton(Canvas canvas, Size size,
      {required Color face, required Color edge, double press = 0, double depth = 6, double radius = 20, bool circle = false}) {
    final r = circle ? size.height / 2 : min(radius, 10.0);
    final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r));
    canvas.drawRRect(rr, Paint()..color = Color.lerp(face, Colors.black, 0.12 * press)!);
    canvas.drawRRect(rr.deflate(0.5), Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
  }

  bool _lightFace(Color rim) => rim.computeLuminance() > 0.2;

  @override
  TextStyle buttonText(double size, {required Color textColor, required Color rim}) =>
      text(size * 0.92, color: textColor == Colors.white && _lightFace(rim) ? _night : textColor, weight: FontWeight.w600);

  @override
  Color iconColor(Color face) => face.computeLuminance() > 0.35 ? _night : Colors.white;

  @override
  List<Shadow> iconShadows(Color face) => const [];

  @override
  Color get disabledButton => const Color(0xFF3A4350);

  @override
  Widget sign(BuildContext context, {required String title, String? subtitle, double fontSize = 40}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title,
              textAlign: TextAlign.center,
              style: text(fontSize * 0.86, color: palette.ink).copyWith(letterSpacing: -0.8)),
          const SizedBox(height: 6),
          Container(width: 42, height: 3, decoration: BoxDecoration(color: _gold, borderRadius: BorderRadius.circular(2))),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle.toUpperCase(),
                textAlign: TextAlign.center,
                style: text(12, color: palette.inkSoft, weight: FontWeight.w600).copyWith(letterSpacing: 1.6)),
          ],
        ]),
      );

  @override
  Widget label(BuildContext context, {required String text, String? subtitle, double fontSize = 22}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(text, maxLines: 1, style: this.text(fontSize, color: palette.ink).copyWith(letterSpacing: -0.4)),
          ),
          if (subtitle != null)
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(subtitle,
                  maxLines: 1, style: this.text(13, color: _gold, weight: FontWeight.w600).copyWith(letterSpacing: 0.4)),
            ),
        ]),
      );

  @override
  Widget critter(BuildContext context, String id, double size, {CritterRole role = CritterRole.collectible}) =>
      switch (role) {
        CritterRole.decoration => SizedBox.square(dimension: size),
        CritterRole.piece => SizedBox.square(dimension: size, child: const CustomPaint(painter: _TokenPainter())),
        CritterRole.collectible => SizedBox.square(
            dimension: size,
            child: Center(child: CritterSprite(id, size: size * 0.82)),
          ),
      };

  @override
  void paintStreak(Canvas canvas, Size size, {required bool lit, int streak = 0}) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    final flame = Path()
      ..moveTo(cx, h * 0.1)
      ..cubicTo(cx + w * 0.36, h * 0.38, cx + w * 0.34, h * 0.9, cx, h * 0.9)
      ..cubicTo(cx - w * 0.34, h * 0.9, cx - w * 0.36, h * 0.52, cx - w * 0.08, h * 0.4)
      ..cubicTo(cx - w * 0.04, h * 0.3, cx, h * 0.2, cx, h * 0.1)
      ..close();
    if (lit) canvas.drawPath(flame, Paint()..color = _gold.withValues(alpha: 0.22));
    canvas.drawPath(flame, Paint()
      ..color = lit ? _gold : const Color(0xFF6B7584)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.4, w * 0.08)
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  void paintCross(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0xFF7C8796)
      ..strokeWidth = max(1.5, size.width * 0.1)
      ..strokeCap = StrokeCap.round;
    final a = size.width * 0.3, b = size.width * 0.7;
    canvas.drawLine(Offset(a, a), Offset(b, b), p);
    canvas.drawLine(Offset(b, a), Offset(a, b), p);
  }
}

/// A plain slate gradient with a soft vignette and one gold hairline.
class _ProBackdrop extends CustomPainter {
  const _ProBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1F26), Color(0xFF212831), Color(0xFF1B2027)],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.6),
          radius: 1.1,
          colors: [Colors.white.withValues(alpha: 0.035), Colors.transparent],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ProBackdrop old) => false;
}

/// A board piece: a gold disc with a darker ring.
class _TokenPainter extends CustomPainter {
  const _TokenPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = min(size.width, size.height) * 0.34;
    canvas.drawCircle(c + Offset(0, r * 0.08), r, Paint()..color = const Color(0x55000000));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(center: Alignment(-0.3, -0.4), colors: [Color(0xFFF2D77F), _gold, _goldDeep])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(c, r * 0.55, Paint()
      ..color = _night.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, r * 0.1));
  }

  @override
  bool shouldRepaint(_TokenPainter old) => false;
}
