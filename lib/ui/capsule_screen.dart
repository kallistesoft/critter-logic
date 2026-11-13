import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../meta/album.dart';
import '../meta/collection.dart';
import '../meta/economy.dart';
import '../meta/game_flow.dart';
import '../meta/retention.dart';
import '../services/sound_service.dart';
import 'album_screen.dart';
import 'coin_fly.dart';
import 'critter_image.dart';
import 'meadow.dart';
import 'game/confetti.dart';
import 'navigation.dart';
import 'retention_ui.dart';
import 'palette.dart';
import 'services.dart';
import 'widgets.dart';
import 'worlds/level_mark.dart';

/// Opens capsules: tap to shake, tap to crack, tap to reveal the critter inside.
class CapsuleScreen extends StatefulWidget {
  const CapsuleScreen({super.key, this.random, this.fromAlbum = false});

  final Random? random;

  /// Opened from the album: "See album" goes back instead of opening it.
  final bool fromAlbum;

  @override
  State<CapsuleScreen> createState() => _CapsuleScreenState();
}

class _CapsuleScreenState extends State<CapsuleScreen> with TickerProviderStateMixin {
  static const _tapsToOpen = 3;
  int _taps = 0;
  CritterGrant? _result;
  bool _golden = false;
  late final _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final _spin = AnimationController(vsync: this, duration: const Duration(seconds: 14));
  late final _random = widget.random ?? Random();

  /// Coins paid for a duplicate or a finished set, still flying to the counter.
  int _coinsHeld = 0;
  final _coinTarget = GlobalKey();
  final _coinSource = GlobalKey();

  @override
  void dispose() {
    _shake.dispose();
    _burst.dispose();
    _spin.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    if (_result != null) return;
    final services = Services.of(context);
    final stats = services.stats;
    if (stats.capsules + stats.goldenCapsules == 0) return;
    _golden = stats.goldenCapsules > 0;
    _taps++;
    if (_taps < _tapsToOpen) {
      services.sound.play(Sfx.capsule);
      HapticFeedback.mediumImpact();
      setState(() {});
      _shake.forward(from: 0);
      return;
    }
    final retention = services.retention;
    final levels = retention.settings.critterLevels;
    final opened = openCapsule(stats.critterCopies, _random,
        forceGolden: _golden,
        levels: levels,
        odds: CapsuleOdds(
          rare: services.settings.value.capsuleRareOdds,
          golden: services.settings.value.capsuleGoldenOdds,
        ));
    await stats.takeCapsule(golden: _golden);
    final result =
        await grantCritter(stats, retention.progress, opened.critter.id, levels: levels, analytics: services.analytics);
    final update = await retention.recordEvent(const CapsuleOpened(), services.today());
    services.analytics.capsuleOpen(rarity: result.critter.rarity.name, duplicate: result.duplicate);
    services.sound.play(Sfx.reveal);
    HapticFeedback.heavyImpact();
    if (!mounted) return;
    final paid = result.coins;
    setState(() {
      _result = result;
      _coinsHeld = paid;
    });
    if (ambientMotion(context)) _spin.repeat();
    await _burst.forward(from: 0).orCancel.catchError((_) {});
    if (paid > 0 && mounted) {
      await flyCoins(context, from: _coinSource, to: _coinTarget, coins: 8, onArrive: (n) {
        if (mounted) setState(() => _coinsHeld = paid - (paid * n / 8).round());
      });
      if (mounted) setState(() => _coinsHeld = 0);
    }
    if (mounted) await showRetentionUpdate(context, update);
  }

  void _again() => setState(() {
        _taps = 0;
        _result = null;
        _coinsHeld = 0;
        _burst.reset();
        _spin.stop();
      });

  Future<void> _watchForCapsule() async {
    final services = Services.of(context);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final day = todayNumber(services.today());
    if (await services.ads.showRewarded()) {
      await services.stats.addCapsule();
      await services.stats.setAdCapsuleTaken(day);
      services.analytics.adReward('capsule');
      services.sound.play(Sfx.coin);
      _again();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noAdAvailable)));
    }
  }


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = Services.of(context);
    final stats = services.stats;
    final waiting = stats.capsules + stats.goldenCapsules;
    final adAvailable = !stats.adCapsuleTaken(todayNumber(services.today()));
    final result = _result;
    return MeadowScaffold(
      overlays: [Positioned.fill(child: Confetti(animation: _burst, seed: 11))],
      child: Column(children: [
        MeadowTopBar(
          title: l10n.capsules,
          backTooltip: l10n.back,
          trailing: [
            StatPill(key: const Key('capsuleCount'), icon: const CapsuleEgg(size: 26), text: '$waiting'),
            CoinCounter(value: stats.coins - _coinsHeld, iconKey: _coinTarget),
          ],
        ),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: result != null
                  ? _reveal(l10n, result)
                  : waiting > 0
                      ? _capsule(l10n)
                      : _empty(l10n, adAvailable),
            ),
          ),
        ),
        if (result != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: [
              if (waiting > 0)
                ChunkyButton(
                  key: const Key('openAnother'),
                  label: l10n.openAnother(waiting),
                  color: coral,
                  expand: true,
                  onPressed: _again,
                )
              else if (adAvailable)
                _adButton(l10n),
              const SizedBox(height: 10),
              ChunkyButton(
                key: const Key('seeAlbum'),
                label: l10n.seeAlbum,
                color: woodButton,
                expand: true,
                small: true,
                icon: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                onPressed: () => widget.fromAlbum
                    ? Navigator.pop(context)
                    : Navigator.pushReplacement(context, softRoute(const AlbumScreen())),
              ),
            ]),
          ),
      ]),
    );
  }

  Widget _capsule(AppLocalizations l10n) {
    final golden = _golden || _isGoldenNext();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (golden)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(l10n.goldenCapsule, style: outlinedText(24, color: const Color(0xFFFFE066), stroke: goldEdge)),
        ),
      GestureDetector(
        key: const Key('capsule'),
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: SizedBox(
          width: 260,
          height: 290,
          child: Stack(alignment: Alignment.bottomCenter, children: [
            if (golden)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _shake,
                  builder: (_, _) => CustomPaint(painter: RaysPainter(gold, 0.55 + 0.1 * _taps, 0)),
                ),
              ),
            const Positioned(bottom: 0, child: _Nest(width: 230)),
            Positioned(
              bottom: 30,
              child: AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  final t = _shake.value;
                  final amp = 0.12 + 0.08 * _taps;
                  final angle = sin(t * pi * 6) * amp * (1 - t);
                  final hop = sin(t * pi) * 14;
                  return Transform.translate(
                    offset: Offset(0, -hop),
                    child: Transform.rotate(angle: angle, alignment: Alignment.bottomCenter, child: child),
                  );
                },
                child: CapsuleEgg(size: 190, golden: golden, cracks: _taps),
              ),
            ),
            const Positioned(bottom: 0, child: _Nest(width: 230, front: true)),
          ]),
        ),
      ),
      const SizedBox(height: 16),
      _Bubble(text: _taps == 0 ? l10n.capsuleTap : (_taps == 1 ? l10n.capsuleTapAgain : l10n.capsuleAlmost)),
    ]);
  }

  bool _isGoldenNext() => Services.of(context).stats.goldenCapsules > 0;

  Widget _reveal(AppLocalizations l10n, CritterGrant r) {
    final c = r.critter;
    final (label, color) = switch (c.rarity) {
      Rarity.golden => (l10n.rarityGolden, gold),
      Rarity.rare => (l10n.rarityRare, rareBlue),
      Rarity.common => (l10n.rarityCommon, leaf),
    };
    final goldenEgg = c.rarity == Rarity.golden;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 290,
        height: 290,
        child: AnimatedBuilder(
          animation: Listenable.merge([_burst, _spin]),
          builder: (_, _) {
            final t = _burst.value;
            final rays = Curves.easeOut.transform((t / 0.5).clamp(0, 1));
            // Shell halves fly apart in the first half.
            final shell = (t / 0.45).clamp(0.0, 1.0);
            // The critter jumps out: up with a stretch, then lands with a squash.
            final j = ((t - 0.12) / 0.6).clamp(0.0, 1.0);
            final up = sin(j * pi) * 80;
            final land = ((t - 0.72) / 0.28).clamp(0.0, 1.0);
            final squash = sin(land * pi) * 0.18;
            final stretch = j < 1 ? sin(j * pi) * 0.14 : 0.0;
            return Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
              Positioned.fill(child: CustomPaint(painter: RaysPainter(color, rays, _spin.value * 2 * pi))),
              const Positioned(bottom: 0, child: _Nest(width: 230)),
              if (shell < 1) ...[
                Positioned(
                  bottom: 30 + shell * 110,
                  left: 66 - shell * 100,
                  child: Opacity(
                    opacity: 1 - shell,
                    child: Transform.rotate(angle: -shell * 2.4, child: CapsuleEgg(size: 190, golden: goldenEgg, half: 1)),
                  ),
                ),
                Positioned(
                  bottom: 30 - shell * 30,
                  left: 66 + shell * 90,
                  child: Opacity(
                    opacity: 1 - shell,
                    child: Transform.rotate(angle: shell * 1.2, child: CapsuleEgg(size: 190, golden: goldenEgg, half: 2)),
                  ),
                ),
              ],
              Positioned(
                bottom: 60,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [color.withValues(alpha: 0.6 * rays), color.withValues(alpha: 0)]),
                  ),
                ),
              ),
              if (t > 0.1)
                Positioned(
                  bottom: 34 + up,
                  child: Transform(
                    alignment: Alignment.bottomCenter,
                    transform: Matrix4.diagonal3Values(1 - stretch + squash, 1 + stretch - squash, 1),
                    child: Transform.scale(
                      scale: Curves.easeOutBack.transform(((t - 0.1) / 0.25).clamp(0, 1)),
                      child: goldenEgg && r.levelAfter < maxCritterLevel
                          ? Shimmer(child: CritterImage(c.id, size: 140, level: r.isNew ? 0 : r.levelAfter))
                          : CritterImage(c.id, size: 140, level: r.isNew ? 0 : r.levelAfter),
                    ),
                  ),
                ),
              if (t > 0.6 && t < 1)
                Positioned.fill(child: CustomPaint(painter: SparklePainter((t - 0.6) / 0.4, seed: 4, color: color, count: 14))),
              const Positioned(bottom: 0, child: _Nest(width: 230, front: true)),
            ]);
          },
        ),
      ),
      PopIn(
        delay: const Duration(milliseconds: 700),
        child: Column(children: [
          Text(critterName(l10n, c.id), key: const Key('revealName'), style: outlinedText(36, stroke: woodEdge, width: 2.6)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: edgeOf(color), width: 2.5),
            ),
            child: Text('$label · ${setName(l10n, c.set)}', style: outlinedText(15, stroke: edgeOf(color), width: 1.3)),
          ),
          const SizedBox(height: 12),
          SoftCard(
            key: _coinSource,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Column(children: [
              if (r.leveledUp) ...[
                _LevelStars(level: r.levelAfter),
                const SizedBox(height: 4),
              ],
              Text(
                critterGrantText(l10n, r, Services.of(context).retention.settings.critterLevels),
                key: const Key('revealText'),
                textAlign: TextAlign.center,
                style: chunky(17, color: r.isNew || r.leveledUp ? coralEdge : inkSoft),
              ),
              if (r.leveledUp)
                Text(l10n.rewardCoins(r.coins), style: chunky(15, color: goldEdge)),
              if (r.completedSet != null) ...[
                const SizedBox(height: 6),
                Text(l10n.capsuleSetComplete(setName(l10n, r.completedSet!), Economy.setComplete),
                    textAlign: TextAlign.center, style: chunky(17, color: goldEdge)),
              ],
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _empty(AppLocalizations l10n, bool adAvailable) => Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(
          width: 220,
          height: 80,
          child: Stack(alignment: Alignment.bottomCenter, children: [
            Positioned(bottom: 0, child: _Nest(width: 200)),
            Positioned(bottom: 0, child: _Nest(width: 200, front: true)),
          ]),
        ),
        const SizedBox(height: 12),
        SoftCard(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(children: [
            Text(l10n.noCapsules, style: chunky(22), textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(l10n.capsulesHowTo, textAlign: TextAlign.center, style: chunky(15, color: inkSoft, weight: FontWeight.w500)),
          ]),
        ),
        const SizedBox(height: 18),
        if (adAvailable) _adButton(l10n),
      ]);

  Widget _adButton(AppLocalizations l10n) => ChunkyButton(
        key: const Key('capsuleAd'),
        label: l10n.capsuleForVideo,
        color: leaf,
        expand: true,
        icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
        onPressed: _watchForCapsule,
      );
}

/// What a critter gave, in words: new, level up, max level (+coins) or one copy closer to the next level.
String critterGrantText(AppLocalizations l10n, CritterGrant g, CritterLevels levels) {
  if (g.isNew) return l10n.capsuleNew;
  if (g.leveledUp) return l10n.capsuleLevelUp(g.levelAfter);
  if (g.maxed) return l10n.capsuleMaxLevel(g.coins);
  final need = levels.nextAt(g.critter.rarity, g.levelAfter) ?? g.copies;
  return l10n.capsuleCopy(g.copies, need, g.levelAfter + 1);
}

/// The new level's stars popping in one by one on a level-up.
class _LevelStars extends StatelessWidget {
  const _LevelStars({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) => Row(key: const Key('levelStars'), mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < maxCritterLevel; i++)
          i < level
              ? PopIn(
                  delay: Duration(milliseconds: 900 + 120 * i),
                  child: LevelStarIcon(filled: true, size: 26, color: gold, edge: goldEdge),
                )
              : LevelStarIcon(filled: false, size: 26, empty: inkSoft.withValues(alpha: 0.25)),
      ]);
}

/// A speech-bubble hint under the capsule.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => PopIn(
        key: ValueKey(text),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: paperEdge, width: 2.5),
            boxShadow: [BoxShadow(color: paperEdge, offset: Offset(0, 4))],
          ),
          child: Text(text, style: chunky(20), textAlign: TextAlign.center),
        ),
      );
}

/// A twig nest; [front] draws only its front rim (over the egg).
class _Nest extends StatelessWidget {
  const _Nest({super.key, required this.width, this.front = false});

  final double width;
  final bool front;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: width, height: width * 0.36, child: CustomPaint(painter: _NestPainter(front)));
}

class _NestPainter extends CustomPainter {
  const _NestPainter(this.front);

  final bool front;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final r = Random(9);
    if (!front) {
      canvas.drawOval(Rect.fromLTWH(w * 0.02, h * 0.62, w * 0.96, h * 0.4), Paint()..color = const Color(0x33000000));
      canvas.drawOval(Rect.fromLTWH(w * 0.05, h * 0.05, w * 0.9, h * 0.62), Paint()..color = const Color(0xFF6B4423));
      canvas.drawOval(Rect.fromLTWH(w * 0.14, h * 0.12, w * 0.72, h * 0.4), Paint()..color = const Color(0xFF4A2E17));
      return;
    }
    // Front rim: a thick band of woven twigs.
    final band = Path()
      ..moveTo(w * 0.04, h * 0.32)
      ..quadraticBezierTo(w * 0.5, h * 0.62, w * 0.96, h * 0.32)
      ..lineTo(w * 0.94, h * 0.62)
      ..quadraticBezierTo(w * 0.5, h * 1.05, w * 0.06, h * 0.62)
      ..close();
    canvas.drawPath(band, Paint()..color = const Color(0xFFA06A3A));
    final twig = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.clipPath(band);
    for (var i = 0; i < 34; i++) {
      final x = w * (0.04 + r.nextDouble() * 0.92);
      final y = h * (0.42 + r.nextDouble() * 0.36) + sin(x / w * pi) * h * 0.16;
      final len = w * (0.08 + r.nextDouble() * 0.14);
      final a = (r.nextDouble() - 0.5) * 0.9;
      twig
        ..color = const [Color(0xFF7A4E28), Color(0xFFC89660), Color(0xFF8E5A2B)][i % 3]
        ..strokeWidth = 2.5 + r.nextDouble() * 2.5;
      canvas.drawLine(Offset(x - cos(a) * len / 2, y - sin(a) * len / 2), Offset(x + cos(a) * len / 2, y + sin(a) * len / 2), twig);
    }
    canvas.restore();
    canvas.drawPath(band, Paint()
      ..color = const Color(0xFF5A3A1C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
    // A few loose twigs sticking out.
    twig
      ..color = const Color(0xFF7A4E28)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(w * 0.02, h * 0.36), Offset(w * 0.12, h * 0.5), twig);
    canvas.drawLine(Offset(w * 0.98, h * 0.3), Offset(w * 0.86, h * 0.48), twig);
  }

  @override
  bool shouldRepaint(_NestPainter old) => old.front != front;
}

/// The egg-shaped capsule; [cracks] after each tap, [half] 1/2 draws only the top/bottom shell piece.
class CapsuleEgg extends StatelessWidget {
  const CapsuleEgg({super.key, required this.size, this.golden = false, this.cracks = 0, this.dim = false, this.half = 0});

  final double size;
  final bool golden;
  final int cracks;
  final bool dim;
  final int half;

  @override
  Widget build(BuildContext context) {
    final egg = SizedBox(
      width: size * 0.83,
      height: size,
      child: CustomPaint(painter: _CapsulePainter(golden: golden, cracks: cracks, half: half)),
    );
    return dim ? Opacity(opacity: 0.5, child: egg) : egg;
  }
}

/// An egg-like capsule: colored top with dots, cream bottom, a band, and cracks after each tap.
class _CapsulePainter extends CustomPainter {
  _CapsulePainter({required this.golden, required this.cracks, this.half = 0});

  final bool golden;
  final int cracks;
  final int half;

  static const _zig = [(0.06, 0.52), (0.18, 0.45), (0.3, 0.55), (0.42, 0.44), (0.54, 0.56), (0.66, 0.45), (0.78, 0.55), (0.9, 0.46), (0.98, 0.52)];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final egg = Path()
      ..moveTo(w * 0.5, h * 0.02)
      ..cubicTo(w * 0.86, h * 0.02, w * 0.98, h * 0.5, w * 0.95, h * 0.66)
      ..cubicTo(w * 0.9, h * 0.92, w * 0.7, h * 0.98, w * 0.5, h * 0.98)
      ..cubicTo(w * 0.3, h * 0.98, w * 0.1, h * 0.92, w * 0.05, h * 0.66)
      ..cubicTo(w * 0.02, h * 0.5, w * 0.14, h * 0.02, w * 0.5, h * 0.02)
      ..close();
    canvas.save();
    if (half != 0) {
      final cut = Path()..moveTo(0, h * 0.5);
      for (final (x, y) in _zig) {
        cut.lineTo(w * x, h * y);
      }
      if (half == 1) {
        cut
          ..lineTo(w, 0)
          ..lineTo(0, 0);
      } else {
        cut
          ..lineTo(w, h)
          ..lineTo(0, h);
      }
      canvas.clipPath(cut..close());
    } else {
      canvas.drawShadow(egg, ink, 6, false);
    }
    final top = golden ? gold : coral;
    final topLight = golden ? const Color(0xFFFFF0A0) : const Color(0xFFFFC2A6);
    canvas.save();
    canvas.clipPath(egg);
    canvas.drawRect(
        Rect.fromLTWH(0, h * 0.5, w, h * 0.5),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFBF3), Color(0xFFEFE2C8)])
              .createShader(Rect.fromLTWH(0, h * 0.5, w, h * 0.5)));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h * 0.55),
        Paint()
          ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [topLight, top])
              .createShader(Rect.fromLTWH(0, 0, w, h * 0.55)));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.52, w, h * 0.07), Paint()..color = Colors.white.withValues(alpha: 0.95));
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.4);
    for (final (x, y, r) in const [(0.3, 0.2, 0.06), (0.62, 0.14, 0.04), (0.72, 0.36, 0.07), (0.38, 0.4, 0.035)]) {
      canvas.drawCircle(Offset(w * x, h * y), w * r, dot);
    }
    final spot = Paint()..color = (golden ? goldEdge : coralEdge).withValues(alpha: 0.25);
    for (final (x, y, r) in const [(0.3, 0.75, 0.05), (0.62, 0.84, 0.04), (0.75, 0.68, 0.035)]) {
      canvas.drawCircle(Offset(w * x, h * y), w * r, spot);
    }
    canvas.drawOval(Rect.fromLTWH(w * 0.2, h * 0.1, w * 0.16, h * 0.2), Paint()..color = Colors.white.withValues(alpha: 0.5));
    canvas.restore();
    canvas.drawPath(egg, Paint()
      ..color = (golden ? goldEdge : coralEdge).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.5, w * 0.018));
    if (cracks > 0 && half == 0) {
      final crack = Paint()
        ..color = woodEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, w * 0.022)
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      final p = Path();
      final pts = cracks >= 2 ? _zig.sublist(1, 8) : _zig.sublist(2, 5);
      for (final (i, (x, y)) in pts.indexed) {
        i == 0 ? p.moveTo(w * x, h * y) : p.lineTo(w * x, h * y);
      }
      canvas.drawPath(p, crack);
      if (cracks >= 2) {
        canvas.drawPath(
            Path()
              ..moveTo(w * 0.54, h * 0.56)
              ..lineTo(w * 0.5, h * 0.64)
              ..lineTo(w * 0.56, h * 0.7),
            crack);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CapsulePainter old) => old.golden != golden || old.cracks != cracks || old.half != half;
}

/// Light rays spinning behind a reveal.
class RaysPainter extends CustomPainter {
  RaysPainter(this.color, this.t, this.angle);

  final Color color;
  final double t;
  final double angle;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.6);
    final r = size.width / 2 * (0.7 + 0.5 * t);
    final paint = Paint()..color = color.withValues(alpha: 0.3 * t);
    for (var k = 0; k < 14; k++) {
      final a = angle + k * pi / 7;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + cos(a - 0.1) * r, c.dy + sin(a - 0.1) * r)
        ..lineTo(c.dx + cos(a + 0.1) * r, c.dy + sin(a + 0.1) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.drawCircle(
        c,
        r * 0.5,
        Paint()
          ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.7 * t), Colors.white.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: c, radius: r * 0.5)));
  }

  @override
  bool shouldRepaint(RaysPainter old) => old.t != t || old.color != color || old.angle != angle;
}

/// The twig nest, for other screens (Lucky Nest); [front] draws only the front rim.
class TwigNest extends _Nest {
  const TwigNest({super.key, required super.width, super.front});
}
