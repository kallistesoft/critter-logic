import 'dart:math';

import 'worlds/world.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../meta/set_rewards.dart';
import 'critter_image.dart';
import 'services.dart';

// ---- Hats ----

/// A critter wearing [hat] (null = bare head). The hat sits on top of the round head of the sprites.
class Hatted extends StatelessWidget {
  const Hatted({super.key, required this.hat, required this.size, required this.child});

  /// Hats only go on Worlds whose critters have heads to wear them (not the Lodge's badges).

  final String? hat;
  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final h = hat;
    if (h == null || !hatIds.contains(h) || !worldOf(context).hats) return child;
    final w = size * 0.6;
    final hh = w * 0.8;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: child),
          Positioned(
            left: (size - w) / 2,
            top: size * 0.34 - hh,
            width: w,
            height: hh,
            child: IgnorePointer(child: CustomPaint(painter: HatPainter(h))),
          ),
        ],
      ),
    );
  }
}

/// A critter image with the equipped hat (a shortcut for the home, board and win screens).
class HattedCritter extends StatelessWidget {
  const HattedCritter(this.id, {super.key, required this.size, this.hat, this.role = CritterRole.collectible});

  final String id;
  final double size;
  final CritterRole role;

  /// Overrides the equipped hat (shop previews).
  final String? hat;

  @override
  Widget build(BuildContext context) => Hatted(
    hat: hat ?? Services.of(context).retention.shop.equippedHat,
    size: size,
    child: CritterImage(id, size: size, role: role),
  );
}

const hatIds = ['hat.flowers', 'hat.party', 'hat.beanie', 'hat.crown'];

/// Draws a hat in its box: the brim / band sits on the box's bottom edge (the top of the head).
class HatPainter extends CustomPainter {
  const HatPainter(this.hat);

  final String hat;

  @override
  void paint(Canvas canvas, Size size) {
    switch (hat) {
      case 'hat.flowers':
        _flowers(canvas, size);
      case 'hat.party':
        _party(canvas, size);
      case 'hat.beanie':
        _beanie(canvas, size);
      case 'hat.crown':
        _crown(canvas, size);
    }
  }

  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void _flowers(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    // A leafy vine band lying on the head.
    final band = Rect.fromLTWH(w * 0.04, h * 0.66, w * 0.92, h * 0.3);
    canvas.drawArc(band, pi * 1.05, pi * 0.9, false, _stroke(const Color(0xFF3F9322), max(2, w * 0.07)));
    canvas.drawArc(
      band.shift(Offset(0, h * 0.02)),
      pi * 0.05,
      pi * 0.9,
      false,
      _stroke(const Color(0xFF3F9322), max(2, w * 0.07)),
    );
    final leaf = Paint()..color = const Color(0xFF6CCB3C);
    for (final (x, y, a) in const [(0.12, 0.74, -0.6), (0.88, 0.74, 0.6), (0.36, 0.95, 0.3), (0.64, 0.95, -0.3)]) {
      canvas.save();
      canvas.translate(w * x, h * y);
      canvas.rotate(a);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.16, height: w * 0.08), leaf);
      canvas.restore();
    }
    // Five flowers along the front.
    const flowers = [
      (0.14, 0.7, Color(0xFFFF8FB1), 0.11),
      (0.33, 0.82, Color(0xFFFFFFFF), 0.12),
      (0.52, 0.86, Color(0xFFFFC23D), 0.14),
      (0.71, 0.82, Color(0xFF8FC8FF), 0.12),
      (0.88, 0.7, Color(0xFFFF8FB1), 0.11),
    ];
    for (final (x, y, color, r) in flowers) {
      final c = Offset(w * x, h * y);
      final pr = w * r * 0.5;
      final petal = Paint()..color = color;
      final edge = _stroke(Color.lerp(color, const Color(0xFF7A3A50), 0.45)!, max(0.8, w * 0.012));
      for (var k = 0; k < 5; k++) {
        final a = k * 2 * pi / 5 - pi / 2;
        final pc = c + Offset(cos(a), sin(a)) * pr * 0.9;
        canvas.drawCircle(pc, pr * 0.62, petal);
        canvas.drawCircle(pc, pr * 0.62, edge);
      }
      canvas.drawCircle(
        c,
        pr * 0.5,
        Paint()..color = color == const Color(0xFFFFC23D) ? const Color(0xFFFF8A5B) : const Color(0xFFFFD84A),
      );
    }
  }

  void _party(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    canvas.save();
    canvas.translate(w / 2, h);
    canvas.rotate(0.14);
    final cone = Path()
      ..moveTo(-w * 0.27, -h * 0.04)
      ..lineTo(0, -h * 0.86)
      ..lineTo(w * 0.27, -h * 0.04)
      ..quadraticBezierTo(0, h * 0.06, -w * 0.27, -h * 0.04)
      ..close();
    canvas.drawPath(cone.shift(Offset(0, h * 0.03)), Paint()..color = const Color(0x33000000));
    canvas.drawPath(cone, Paint()..color = const Color(0xFF4FB3EE));
    canvas.save();
    canvas.clipPath(cone);
    // Diagonal candy stripes and dots.
    final stripe = Paint()..color = const Color(0xFFFF7BA9);
    for (var k = -3; k < 6; k++) {
      final y = -h * 0.12 * k;
      canvas.drawPath(
        Path()
          ..moveTo(-w * 0.4, y)
          ..lineTo(w * 0.4, y - h * 0.18)
          ..lineTo(w * 0.4, y - h * 0.24)
          ..lineTo(-w * 0.4, y - h * 0.06)
          ..close(),
        stripe,
      );
    }
    final dot = Paint()..color = const Color(0xFFFFE066);
    for (final (x, y) in const [(-0.1, -0.25), (0.08, -0.45), (-0.02, -0.62), (0.13, -0.16)]) {
      canvas.drawCircle(Offset(w * x, h * y), w * 0.03, dot);
    }
    canvas.drawPath(
      Path()
        ..moveTo(-w * 0.05, -h * 0.8)
        ..lineTo(-w * 0.2, -h * 0.1),
      _stroke(Colors.white.withValues(alpha: 0.45), w * 0.04),
    );
    canvas.restore();
    canvas.drawPath(cone, _stroke(const Color(0xFF2479B8), max(1.5, w * 0.03)));
    // Pom-pom on top.
    final top = Offset(0, -h * 0.86);
    for (var k = 0; k < 7; k++) {
      final a = k * 2 * pi / 7;
      canvas.drawCircle(top + Offset(cos(a), sin(a)) * w * 0.05, w * 0.05, Paint()..color = const Color(0xFFFFC23D));
    }
    canvas.drawCircle(top, w * 0.06, Paint()..color = const Color(0xFFFFE066));
    canvas.restore();
  }

  void _beanie(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    const knit = Color(0xFFE5484D);
    const knitDark = Color(0xFFB02E33);
    const rib = Color(0xFFFFF4E0);
    final dome = Path()
      ..moveTo(w * 0.06, h * 0.78)
      ..cubicTo(w * 0.06, h * 0.12, w * 0.94, h * 0.12, w * 0.94, h * 0.78)
      ..close();
    canvas.drawPath(dome.shift(Offset(0, h * 0.03)), Paint()..color = const Color(0x33000000));
    canvas.drawPath(dome, Paint()..color = knit);
    canvas.save();
    canvas.clipPath(dome);
    // Knit columns.
    final col = _stroke(knitDark.withValues(alpha: 0.35), max(1, w * 0.02));
    for (var k = 1; k < 6; k++) {
      final x = w * (0.06 + 0.88 * k / 6);
      canvas.drawLine(Offset(x, h * 0.2), Offset(x, h * 0.8), col);
    }
    canvas.drawOval(
      Rect.fromLTWH(w * 0.22, h * 0.3, w * 0.2, h * 0.1),
      Paint()..color = Colors.white.withValues(alpha: 0.3),
    );
    canvas.restore();
    canvas.drawPath(dome, _stroke(knitDark, max(1.5, w * 0.03)));
    // Folded cuff.
    final cuff = RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.66, w, h * 0.3), Radius.circular(h * 0.12));
    canvas.drawRRect(cuff, Paint()..color = rib);
    final ribLine = _stroke(const Color(0xFFD9C7A8), max(1, w * 0.02));
    for (var k = 1; k < 9; k++) {
      final x = w * k / 9;
      canvas.drawLine(Offset(x, h * 0.7), Offset(x, h * 0.92), ribLine);
    }
    canvas.drawRRect(cuff, _stroke(const Color(0xFFB59B74), max(1.5, w * 0.025)));
    // Pom-pom.
    final top = Offset(w * 0.5, h * 0.2);
    canvas.drawCircle(top, w * 0.13, Paint()..color = rib);
    for (var k = 0; k < 8; k++) {
      final a = k * pi / 4;
      canvas.drawCircle(top + Offset(cos(a), sin(a)) * w * 0.1, w * 0.04, Paint()..color = const Color(0xFFFFFFFF));
    }
    canvas.drawCircle(top, w * 0.13, _stroke(const Color(0xFFD9C7A8), max(1, w * 0.02)));
  }

  void _crown(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final crown = Path()
      ..moveTo(w * 0.1, h * 0.92)
      ..lineTo(w * 0.04, h * 0.32)
      ..lineTo(w * 0.3, h * 0.58)
      ..lineTo(w * 0.5, h * 0.18)
      ..lineTo(w * 0.7, h * 0.58)
      ..lineTo(w * 0.96, h * 0.32)
      ..lineTo(w * 0.9, h * 0.92)
      ..close();
    canvas.drawPath(crown.shift(Offset(0, h * 0.04)), Paint()..color = const Color(0x40000000));
    canvas.drawPath(
      crown,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE47A), Color(0xFFFFC23D), Color(0xFFE59E1A)],
        ).createShader(Offset.zero & s),
    );
    // Band and gems.
    canvas.drawRect(Rect.fromLTWH(w * 0.09, h * 0.74, w * 0.82, h * 0.06), Paint()..color = const Color(0xFFD38A12));
    canvas.drawCircle(Offset(w * 0.5, h * 0.62), w * 0.07, Paint()..color = const Color(0xFFE5484D));
    canvas.drawCircle(Offset(w * 0.28, h * 0.72), w * 0.045, Paint()..color = const Color(0xFF4F95F0));
    canvas.drawCircle(Offset(w * 0.72, h * 0.72), w * 0.045, Paint()..color = const Color(0xFF5CBF3A));
    canvas.drawCircle(Offset(w * 0.48, h * 0.6), w * 0.02, Paint()..color = Colors.white.withValues(alpha: 0.8));
    for (final x in const [0.04, 0.5, 0.96]) {
      canvas.drawCircle(
        Offset(w * x, h * (x == 0.5 ? 0.18 : 0.32)),
        w * 0.05,
        Paint()..color = const Color(0xFFFFF0A0),
      );
    }
    canvas.drawPath(crown, _stroke(const Color(0xFFB7700A), max(1.5, w * 0.03)));
    canvas.drawLine(
      Offset(w * 0.2, h * 0.5),
      Offset(w * 0.17, h * 0.8),
      _stroke(Colors.white.withValues(alpha: 0.5), w * 0.03),
    );
  }

  @override
  bool shouldRepaint(HatPainter old) => old.hat != hat;
}

// ---- Names ----

String cosmeticName(AppLocalizations l10n, String id) => switch (id) {
  'hat.flowers' => l10n.hatFlowers,
  'hat.party' => l10n.hatParty,
  'hat.beanie' => l10n.hatBeanie,
  'hat.crown' => l10n.hatCrown,
  'frame.album_gold' => l10n.frameAlbumGold,
  _ when id.startsWith('world.') => worldById(id).name(l10n),
  _ => id,
};

/// Cosmetics announced as unlocks: hats and the gold album frame (Worlds are bought in the shop).
bool shownCosmetic(String id) => id.startsWith('hat.') || id == 'frame.album_gold';

/// The set whose completion gives [cosmetic] for free ('all' for the full album), if any.
String? unlockSetOf(String cosmetic) {
  for (final e in setUnlocks.entries) {
    if (e.value == cosmetic) return e.key;
  }
  return fullAlbumUnlocks.contains(cosmetic) ? 'all' : null;
}
