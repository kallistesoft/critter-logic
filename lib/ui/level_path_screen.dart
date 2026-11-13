import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../meta/game_flow.dart';
import '../puzzles/puzzle.dart';
import 'critter_actor.dart';
import 'game/game_screen.dart';
import 'meadow.dart';
import 'navigation.dart';
import 'palette.dart';
import 'services.dart';
import 'widgets.dart';
import 'worlds/world.dart';

/// A game's levels as a winding trail through the meadow: finished levels with their stars, the current one with
/// the player's critter on it (tap to play), the next ones locked.
class LevelPathScreen extends StatefulWidget {
  const LevelPathScreen({super.key, required this.kind});

  final GameKind kind;

  @override
  State<LevelPathScreen> createState() => _LevelPathScreenState();
}

class _LevelPathScreenState extends State<LevelPathScreen> {
  static const _spacing = 104.0;
  // A window of the endless track: the road ahead is long enough to feel like a journey, with a sign every 10 levels.
  static const _behind = 14, _ahead = 30;
  ScrollController? _scroll;

  Future<void> _play() async {
    await openGame(context, widget.kind, PlayMode.level);
    if (mounted) setState(() {});
  }

  /// A finished level: watch a rewarded video to play it again (coins only for beating its stars).
  Future<void> _replay(int level) async {
    final services = Services.of(context);
    final l10n = AppLocalizations.of(context);
    final nav = Navigator.of(context);
    final best = services.stats.levelStars(widget.kind, level);
    final go = await showSoftDialog<bool>(
      context,
      title: l10n.levelReplayTitle(level),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        StarRow(stars: best, size: 40),
        const SizedBox(height: 10),
        Text(l10n.levelReplayBody, textAlign: TextAlign.center, style: chunky(16, color: inkSoft, weight: FontWeight.w500)),
      ]),
      actions: [
        ChunkyButton(
          key: const Key('replayLevel'),
          label: l10n.levelReplayButton,
          expand: true,
          color: sky,
          icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
    if (go != true || !mounted) return;
    if (!await services.ads.showRewarded()) {
      _say(l10n.noAdAvailable);
      return;
    }
    services.analytics.adReward('replay');
    await nav.push(softRoute(GameScreen(kind: widget.kind, mode: PlayMode.level, number: level, replay: true)));
    if (mounted) setState(() {});
  }

  void _say(String text) {
    final m = ScaffoldMessenger.of(context);
    m.hideCurrentSnackBar();
    m.showSnackBar(SnackBar(content: Text(text), duration: const Duration(milliseconds: 1600)));
  }

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ModalRoute.of(context);
    final l10n = AppLocalizations.of(context);
    final stats = Services.of(context).stats;
    final current = stats.level(widget.kind);
    final first = max(1, current - _behind);
    final last = current + _ahead;
    final critter = buddyCritters(stats, 1, seed: current).first;
    _scroll ??= ScrollController(initialScrollOffset: max(0.0, (current - first) * _spacing - 40));

    return MeadowScaffold(
      child: Column(children: [
        MeadowTopBar(
          title: l10n.levelPathTitle(gameName(l10n, widget.kind)),
          backTooltip: l10n.back,
          trailing: [CoinCounter(value: stats.coins)],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: woodEdge, width: 4),
                boxShadow: [BoxShadow(color: woodEdge, offset: Offset(0, 6)), BoxShadow(color: shadow, blurRadius: 16, offset: Offset(0, 10))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: LayoutBuilder(builder: (context, box) {
                  final width = box.maxWidth;
                  final count = last - first + 1;
                  final height = max(box.maxHeight, count * _spacing + 140);
                  Offset pos(int level) {
                    final i = level - first;
                    return Offset(width / 2 + sin(i * 0.95 + first * 0.95) * width * 0.27, height - 90 - i * _spacing);
                  }

                  return SingleChildScrollView(
                    controller: _scroll,
                    reverse: true,
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Stack(clipBehavior: Clip.none, children: [
                        Positioned.fill(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: _TrailPainter(
                                points: [for (var l = first; l <= last; l++) pos(l)],
                                firstLevel: first,
                                doneUpTo: current - first,
                              ),
                            ),
                          ),
                        ),
                        for (var l = first; l <= last; l++)
                          if (l < current)
                            _at(pos(l), 64, _DoneNode(
                              key: Key('doneLevel-$l'),
                              level: l,
                              stars: stats.levelStars(widget.kind, l),
                              onTap: () => _replay(l),
                            ))
                          else if (l > current)
                            _at(pos(l), 56, _LockedNode(level: l, onTap: () => _say(l10n.levelLocked(current))))
                          else
                            _at(pos(l), 84, _CurrentNode(key: const Key('playLevel'), level: l, critter: critter, onTap: _play)),
                        for (var l = first; l <= last; l++)
                          if (l % 10 == 0)
                            Positioned(
                              // On the side of the road with more room.
                              left: pos(l).dx > width / 2 ? pos(l).dx - 170 : pos(l).dx + 50,
                              top: pos(l).dy - 22,
                              width: 120,
                              child: IgnorePointer(child: WoodLabel(text: '🏁 $l', fontSize: 18)),
                            ),
                      ]),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _at(Offset c, double size, Widget child) =>
      Positioned(left: c.dx - size / 2, top: c.dy - size / 2, width: size, height: size, child: child);
}

class _DoneNode extends StatelessWidget {
  const _DoneNode({super.key, required this.level, required this.stars, required this.onTap});

  final int level;
  final int stars;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Bouncy(
        onTap: onTap,
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
          Positioned.fill(
            child: CustomPaint(painter: CandyPainter(face: woodButton, edge: woodEdge, depth: 6, circle: true)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('$level', style: outlinedText(24, color: onWood)),
          ),
          Positioned(
            bottom: -16,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.only(bottom: i == 1 ? 5 : 0),
                  child: StarIcon(size: i == 1 ? 24 : 20, filled: i < stars),
                ),
            ]),
          ),
        ]),
      );
}

class _LockedNode extends StatelessWidget {
  const _LockedNode({required this.level, required this.onTap});

  final int level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Bouncy(
        onTap: onTap,
        sound: false,
        child: Stack(alignment: Alignment.center, children: [
          Positioned.fill(
            child: CustomPaint(
              painter: CandyPainter(
                face: activeWorld.disabledButton,
                edge: activeWorld.edgeOf(activeWorld.disabledButton),
                depth: activeWorld.buttonDepth(true) == 0 ? 0 : 5,
                circle: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.lock_rounded, color: inkSoft, size: 18),
              Text('$level', style: chunky(15, color: inkSoft, height: 1)),
            ]),
          ),
        ]),
      );
}

/// The level to play: a big bouncing green stone with the player's critter standing on it.
class _CurrentNode extends StatefulWidget {
  const _CurrentNode({super.key, required this.level, required this.critter, required this.onTap});

  final int level;
  final String critter;
  final VoidCallback onTap;

  @override
  State<_CurrentNode> createState() => _CurrentNodeState();
}

class _CurrentNodeState extends State<_CurrentNode> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ambientMotion(context)) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Bouncy(
      onTap: widget.onTap,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) {
            final t = Curves.easeInOut.transform(_pulse.value);
            return Transform.scale(scale: 1 + 0.06 * t, child: child);
          },
          child: Stack(alignment: Alignment.center, children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFFFFF59D).withValues(alpha: 0.9), blurRadius: 22, spreadRadius: 4)],
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: CandyPainter(face: leaf, edge: leafEdge, depth: 7, circle: true))),
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Text('${widget.level}', style: outlinedText(30, stroke: leafEdge)),
            ),
          ]),
        ),
        Positioned(
          bottom: 66,
          child: IgnorePointer(child: CritterBuddy(widget.critter, size: 58, tappable: false, cheer: true, seed: 2)),
        ),
        Positioned(
          bottom: -34,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: woodEdge, width: 2),
              ),
              child: Text(l10n.tapToPlay, maxLines: 1, style: chunky(14, color: woodDark)),
            ),
          ),
        ),
      ]),
    );
  }
}

/// The meadow map: grass, a dirt trail between the level stones, and bushes, flowers and rocks along it.
class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.points, required this.firstLevel, required this.doneUpTo});

  final List<Offset> points;
  final int firstLevel;
  final int doneUpTo;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: activeWorld.mapGround,
          stops: [0, 0.5, 1],
        ).createShader(rect),
    );
    // Soft lighter patches.
    final r = Random(firstLevel);
    for (var i = 0; i < size.height / 120; i++) {
      final c = Offset(r.nextDouble() * size.width, r.nextDouble() * size.height);
      canvas.drawOval(Rect.fromCenter(center: c, width: 160 + r.nextDouble() * 120, height: 70 + r.nextDouble() * 40),
          Paint()..color = Colors.white.withValues(alpha: 0.07));
    }
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy + 60);
    path.lineTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final mid = (a.dy + b.dy) / 2;
      path.cubicTo(a.dx, mid, b.dx, mid, b.dx, b.dy);
    }
    canvas.drawPath(path, Paint()
      ..color = activeWorld.board.dirtEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34
      ..strokeCap = StrokeCap.round);
    canvas.drawPath(path, Paint()
      ..color = activeWorld.board.dirtFill
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..strokeCap = StrokeCap.round);
    // Pebbles along the trail.
    final pebble = Paint()..color = activeWorld.board.dirtPrint;
    for (final m in path.computeMetrics()) {
      for (var d = 20.0; d < m.length; d += 26) {
        final t = m.getTangentForOffset(d);
        if (t == null) continue;
        final n = Offset(-t.vector.dy, t.vector.dx);
        canvas.drawCircle(t.position + n * ((d ~/ 26).isEven ? 6 : -6), 2.6, pebble);
      }
    }
    // Decorations beside each stone, on the side away from the trail's swing.
    if (!activeWorld.mapProps) return;
    for (var i = 0; i < points.length; i++) {
      final rr = Random((firstLevel + i) * 131);
      final p = points[i];
      final side = p.dx < size.width / 2 ? 1 : -1;
      final x = (p.dx + side * (70 + rr.nextDouble() * 40)).clamp(24.0, size.width - 24);
      final o = Offset(x, p.dy + 10 + rr.nextDouble() * 30);
      switch (rr.nextInt(5)) {
        case 0:
          _bush(canvas, o, 20 + rr.nextDouble() * 8);
        case 1:
          _tree(canvas, o, 24 + rr.nextDouble() * 6);
        case 2:
          _flowers(canvas, o, rr);
        case 3:
          _rock(canvas, o, 14 + rr.nextDouble() * 6);
        default:
          _mushroom(canvas, o, 12 + rr.nextDouble() * 4);
      }
    }
  }

  static void _bush(Canvas canvas, Offset o, double s) {
    final dark = Paint()..color = const Color(0xFF3F8F2E);
    final light = Paint()..color = const Color(0xFF5DB043);
    canvas.drawOval(Rect.fromCenter(center: o + Offset(0, s * 0.55), width: s * 2.4, height: s * 0.5), Paint()..color = const Color(0x22000000));
    for (final (dx, dy, k) in const [(-0.7, 0.1, 0.7), (0.7, 0.1, 0.7), (0.0, -0.3, 0.9)]) {
      canvas.drawCircle(o + Offset(dx * s, dy * s), s * k, dark);
    }
    for (final (dx, dy, k) in const [(-0.7, 0.0, 0.55), (0.7, 0.0, 0.55), (0.0, -0.4, 0.72)]) {
      canvas.drawCircle(o + Offset(dx * s, dy * s), s * k, light);
    }
    canvas.drawCircle(o + Offset(-s * 0.2, -s * 0.7), s * 0.2, Paint()..color = Colors.white.withValues(alpha: 0.3));
    canvas.drawCircle(o + Offset(s * 0.4, -s * 0.1), s * 0.12, Paint()..color = const Color(0xFFFF6B6B));
  }

  static void _tree(Canvas canvas, Offset o, double s) {
    canvas.drawOval(Rect.fromCenter(center: o + Offset(0, s * 0.9), width: s * 1.8, height: s * 0.4), Paint()..color = const Color(0x22000000));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx - s * 0.15, o.dy - s * 0.2, s * 0.3, s * 1.1), const Radius.circular(4)),
        Paint()..color = woodDark);
    canvas.drawCircle(o + Offset(0, -s * 0.8), s * 0.95, Paint()..color = const Color(0xFF3F8F2E));
    canvas.drawCircle(o + Offset(-s * 0.1, -s * 0.9), s * 0.8, Paint()..color = const Color(0xFF66BB47));
    canvas.drawCircle(o + Offset(-s * 0.35, -s * 1.25), s * 0.22, Paint()..color = Colors.white.withValues(alpha: 0.3));
  }

  static void _flowers(Canvas canvas, Offset o, Random r) {
    const petals = [Color(0xFFFFFFFF), Color(0xFFFFB3C7), Color(0xFFFFE066), Color(0xFFC9B6FF)];
    for (var k = 0; k < 4; k++) {
      final c = o + Offset((r.nextDouble() - 0.5) * 40, (r.nextDouble() - 0.5) * 24);
      final p = Paint()..color = petals[r.nextInt(petals.length)];
      for (var j = 0; j < 5; j++) {
        final a = j * 2 * pi / 5;
        canvas.drawCircle(c + Offset(cos(a), sin(a)) * 4.5, 3.6, p);
      }
      canvas.drawCircle(c, 2.8, Paint()..color = const Color(0xFFFFB627));
    }
  }

  static void _rock(Canvas canvas, Offset o, double s) {
    canvas.drawOval(Rect.fromCenter(center: o + Offset(0, s * 0.4), width: s * 2.2, height: s * 0.6), Paint()..color = const Color(0x22000000));
    canvas.drawOval(Rect.fromCenter(center: o, width: s * 2, height: s * 1.3), Paint()..color = const Color(0xFF9C978D));
    canvas.drawOval(Rect.fromCenter(center: o - Offset(s * 0.15, s * 0.15), width: s * 1.5, height: s * 0.9), Paint()..color = const Color(0xFFBDB8AD));
  }

  static void _mushroom(Canvas canvas, Offset o, double s) {
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx - s * 0.3, o.dy - s * 0.2, s * 0.6, s * 0.9), Radius.circular(s * 0.2)),
        Paint()..color = const Color(0xFFFFF4E0));
    final cap = Path()
      ..addArc(Rect.fromCenter(center: o - Offset(0, s * 0.2), width: s * 1.8, height: s * 1.5), pi, pi)
      ..close();
    canvas.drawPath(cap, Paint()..color = const Color(0xFFE5484D));
    for (final (dx, dy) in const [(-0.4, -0.55), (0.3, -0.7), (0.5, -0.35)]) {
      canvas.drawCircle(o + Offset(dx * s, dy * s), s * 0.13, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.firstLevel != firstLevel || old.doneUpTo != doneUpTo || old.points.length != points.length || old.points.first != points.first;
}
