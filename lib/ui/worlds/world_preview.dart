import 'dart:math';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../critter_image.dart';
import '../widgets.dart';
import 'world.dart';

/// A miniature home screen drawn in [world] (whatever World is equipped): its landscape, title, a daily card with a
/// tiny Nests board, a level panel and its critters. Live: the landscape moves when motion is on.
class WorldMiniPreview extends StatelessWidget {
  const WorldMiniPreview({super.key, required this.world, this.borderRadius = 16});

  final GameWorld world;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: IgnorePointer(
      child: ExcludeSemantics(
        child: WorldScope(
          world: world,
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 380,
              height: 600,
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: const Size(380, 600),
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                  textScaler: TextScaler.noScaling,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(child: world.background(context)),
                    const Positioned.fill(child: WorldPreviewHome()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The sample home inside a preview: everything drawn with the scope's World, never the equipped one.
class WorldPreviewHome extends StatelessWidget {
  const WorldPreviewHome({super.key, this.compact = true});

  /// Mini (shop cards, welcome) or full screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final world = worldOf(context);
    final p = world.palette;
    final l10n = AppLocalizations.of(context);
    final critters = const ['dog', 'bear', 'owl'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              StatPill(icon: const FlameIcon(lit: true, streak: 6), text: '6', color: p.goldSoft),
              const SizedBox(width: 8),
              const StatPill(icon: CoinIcon(), text: '1250'),
              const Spacer(),
              RoundIconButton(icon: Icons.settings_rounded, onPressed: () {}, size: 42, color: p.woodButton),
            ],
          ),
          const SizedBox(height: 16),
          world.sign(context, title: 'Critter Logic', subtitle: l10n.tagline, fontSize: 34),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PreviewDaily(world: world, critter: critters[0]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    CustomPaint(
                      painter: WoodPainter(world: world, radius: 18),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                l10n.levels,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: world.text(18, color: p.onWood),
                              ),
                            ),
                            Text('24', style: world.text(18, color: p.onWoodSoft)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SoftCard(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          CritterImage(critters[1], size: 40),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              world.albumTitle(l10n),
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: world.text(16, color: p.ink),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          if (world.decorations)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, id) in critters.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: CritterImage(id, size: i == 1 ? 78 : 62, role: CritterRole.decoration),
                  ),
              ],
            ),
          SizedBox(height: compact ? 24 : 60),
        ],
      ),
    );
  }
}

class _PreviewDaily extends StatelessWidget {
  const _PreviewDaily({required this.world, required this.critter});

  final GameWorld world;
  final String critter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final b = world.board;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 92,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: b.cardNests),
              borderRadius: BorderRadius.circular(min(14, world.radius)),
              border: Border.all(color: b.cardEdge, width: 2),
            ),
            padding: const EdgeInsets.all(8),
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: _MiniNests(world: world, critter: critter),
              ),
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(l10n.previewDaily, maxLines: 1, style: world.text(20, color: world.palette.ink)),
          ),
          const SizedBox(height: 6),
          ChunkyButton(label: l10n.play, small: true, expand: true, onPressed: () {}),
        ],
      ),
    );
  }
}

/// A 4×4 Nests board in the World's board colors with one critter piece.
class _MiniNests extends StatelessWidget {
  const _MiniNests({required this.world, required this.critter});

  final GameWorld world;
  final String critter;

  static const _zones = [0, 0, 1, 1, 0, 2, 2, 1, 3, 2, 1, 1, 3, 3, 3, 1];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final side = box.maxWidth;
      final frame = max(3.0, side * 0.05);
      final cell = (side - frame * 2) / 4;
      return CustomPaint(
        painter: WoodPainter(world: world, radius: frame * 2.4, nails: false, plank: side),
        child: Padding(
          padding: EdgeInsets.all(frame),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _MiniBedsPainter(world.board))),
              Positioned(
                left: cell,
                top: cell * 2,
                width: cell,
                height: cell,
                child: Center(
                  child: CritterImage(critter, size: cell * 0.86, role: CritterRole.piece),
                ),
              ),
              Positioned(
                left: cell * 3,
                top: 0,
                width: cell,
                height: cell,
                child: Center(
                  child: SizedBox.square(
                    dimension: cell * 0.5,
                    child: CustomPaint(painter: _MiniCross(world)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _MiniBedsPainter extends CustomPainter {
  const _MiniBedsPainter(this.b);

  final BoardPalette b;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.width / 4;
    for (var i = 0; i < 16; i++) {
      canvas.drawRect(
        Rect.fromLTWH((i % 4) * c, (i ~/ 4) * c, c, c).inflate(0.5),
        Paint()..color = b.zones[_MiniNests._zones[i] % b.zones.length],
      );
    }
    final edge = Path();
    final thin = Paint()
      ..color = b.cellLine
      ..strokeWidth = 1;
    for (var r = 0; r < 4; r++) {
      for (var col = 0; col < 4; col++) {
        final i = r * 4 + col;
        if (col < 3) {
          final a = Offset((col + 1) * c, r * c), z = Offset((col + 1) * c, (r + 1) * c);
          _MiniNests._zones[i] != _MiniNests._zones[i + 1]
              ? (edge
                  ..moveTo(a.dx, a.dy)
                  ..lineTo(z.dx, z.dy))
              : canvas.drawLine(a, z, thin);
        }
        if (r < 3) {
          final a = Offset(col * c, (r + 1) * c), z = Offset((col + 1) * c, (r + 1) * c);
          _MiniNests._zones[i] != _MiniNests._zones[i + 4]
              ? (edge
                  ..moveTo(a.dx, a.dy)
                  ..lineTo(z.dx, z.dy))
              : canvas.drawLine(a, z, thin);
        }
      }
    }
    final w = max(2.5, c * 0.12);
    if (b.glow) {
      canvas.drawPath(
        edge,
        Paint()
          ..color = b.zoneEdgeInner.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 1.6
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.9),
      );
    }
    canvas.drawPath(
      edge,
      Paint()
        ..color = b.zoneEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      edge,
      Paint()
        ..color = b.zoneEdgeInner
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_MiniBedsPainter old) => old.b != b;
}

class _MiniCross extends CustomPainter {
  const _MiniCross(this.world);

  final GameWorld world;

  @override
  void paint(Canvas canvas, Size size) => world.paintCross(canvas, size);

  @override
  bool shouldRepaint(_MiniCross old) => old.world.id != world.id;
}

/// Shows [world] full screen; any tap closes it.
Future<void> showWorldPreview(BuildContext context, GameWorld world) => Navigator.of(context).push(
  PageRouteBuilder<void>(
    opaque: true,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, _, _) => WorldFullPreview(world: world),
    transitionsBuilder: (context, a, _, child) => FadeTransition(opacity: a, child: child),
  ),
);

class WorldFullPreview extends StatelessWidget {
  const WorldFullPreview({super.key, required this.world});

  final GameWorld world;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      key: const Key('worldPreview'),
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).pop(),
      child: WorldScope(
        world: world,
        child: Material(
          color: Colors.black,
          child: Stack(
            children: [
              Positioned.fill(child: world.background(context)),
              Positioned.fill(
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: const IgnorePointer(child: WorldPreviewHome(compact: false)),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xB3000000),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${world.name(l10n)} · ${l10n.worldPreviewNote}',
                          style: world.text(15, color: Colors.white, weight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
