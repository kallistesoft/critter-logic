import 'dart:math';

import 'package:flutter/material.dart';

import '../critter_image.dart';
import 'world.dart';

/// Field journal inks (on parchment, whatever the World's own ink).
const journalInk = Color(0xFF2E2418);
const journalPencil = Color(0xFF6B5E4E);
const journalRed = Color(0xFFA8403A);
const journalGreen = Color(0xFF3E6B2A);
const journalBlue = Color(0xFF34557A);
const journalBrass = Color(0xFF8A6A22);

/// A field-journal page: warm parchment, faint ruled lines, a red margin, foxed corners and two strips of tape.
BoxDecoration journalPage({bool complete = false}) => BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEFE3C6), Color(0xFFE4D4AE), Color(0xFFDCC9A0)],
      ),
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: complete ? journalBrass : const Color(0xFFB59E72), width: complete ? 2.5 : 1),
      boxShadow: const [
        BoxShadow(color: Color(0x80000000), offset: Offset(0, 6), blurRadius: 10),
        BoxShadow(color: Color(0xFFC9B48A), offset: Offset(2, 2)),
      ],
    );

class JournalPagePainter extends CustomPainter {
  const JournalPagePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final line = Paint()
      ..color = const Color(0x2E34557A)
      ..strokeWidth = 1;
    for (var y = 44.0; y < h - 4; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(w, y), line);
    }
    final margin = Paint()
      ..color = journalRed.withValues(alpha: 0.4)
      ..strokeWidth = 1;
    canvas.drawLine(const Offset(18, 0), Offset(18, h), margin);
    canvas.drawLine(const Offset(21, 0), Offset(21, h), margin);
    // Foxing: soft brown stains toward the corners.
    for (final (c, r) in [(Offset(w, h), w * 0.45), (const Offset(0, 0), w * 0.3)]) {
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(colors: [const Color(0x30805A2A), const Color(0x00805A2A)])
              .createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(JournalPagePainter old) => false;
}

/// A strip of masking tape.
class JournalTape extends StatelessWidget {
  const JournalTape({super.key, this.angle = 0, this.width = 46});

  final double angle;
  final double width;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: angle,
        child: Container(
          width: width,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xB3E8DDB8),
            border: Border.all(color: const Color(0x33806A40)),
          ),
        ),
      );
}

/// A rubber stamp ("Complete") in red ink.
class JournalStamp extends StatelessWidget {
  const JournalStamp({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: -0.14,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: journalRed.withValues(alpha: 0.8), width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(text.toUpperCase(),
              style: activeWorld.text(12, color: journalRed.withValues(alpha: 0.85)).copyWith(letterSpacing: 1.5)),
        ),
      );
}

/// One sighting in the journal: the badge once collected, else a pencil sketch of the outline.
class JournalEntry extends StatelessWidget {
  const JournalEntry({super.key, required this.id, required this.owned, required this.name, this.golden = false, this.rare = false});

  final String id;
  final bool owned;
  final String name;
  final bool golden;
  final bool rare;

  @override
  Widget build(BuildContext context) {
    final size = 62.0;
    final Widget image = owned
        ? CritterImage(id, size: size)
        : SizedBox.square(
            dimension: size,
            child: CustomPaint(
              painter: const _SketchCircle(),
              child: Padding(
                padding: EdgeInsets.all(size * 0.2),
                child: Image(
                  image: ResizeImage(AssetImage('assets/silhouettes/$id.png'), width: 96, height: 96, policy: ResizeImagePolicy.fit),
                  color: const Color(0x2E2E2418),
                  colorBlendMode: BlendMode.srcIn,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          );
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(height: 74, child: Center(child: image)),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          owned ? name : '???',
          key: Key('critter-$id'),
          maxLines: 1,
          style: activeWorld.text(13, color: owned ? journalInk : journalPencil, weight: owned ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
      if (golden || rare)
        Row(mainAxisSize: MainAxisSize.min, children: [
          for (var i = 0; i < (golden ? 3 : 1); i++)
            Icon(Icons.star_rounded,
                size: 12, color: owned ? (golden ? journalBrass : journalBlue) : journalPencil.withValues(alpha: 0.45)),
        ]),
    ]);
  }
}

/// A loose pencil circle, drawn twice slightly off like a quick sketch.
class _SketchCircle extends CustomPainter {
  const _SketchCircle();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 * 0.9;
    final p = Paint()
      ..color = journalPencil.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -0.3, pi * 1.95, false, p);
    canvas.drawArc(Rect.fromCircle(center: c + const Offset(1.2, -0.8), radius: r * 0.97), 1.2, pi * 1.7, false,
        p..color = journalPencil.withValues(alpha: 0.3));
  }

  @override
  bool shouldRepaint(_SketchCircle old) => false;
}
