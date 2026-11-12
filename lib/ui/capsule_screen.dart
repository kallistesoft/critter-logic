import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../meta/album.dart';
import '../meta/economy.dart';
import '../meta/game_flow.dart';
import '../services/sound_service.dart';
import 'album_screen.dart';
import 'critter_image.dart';
import 'game/confetti.dart';
import 'navigation.dart';
import 'palette.dart';
import 'services.dart';
import 'widgets.dart';

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
  CapsuleResult? _result;
  bool _golden = false;
  late final _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final _burst = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final _random = widget.random ?? Random();

  @override
  void dispose() {
    _shake.dispose();
    _burst.dispose();
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
    final result = openCapsule(stats.owned, _random, forceGolden: _golden);
    await stats.takeCapsule(golden: _golden);
    if (result.duplicate) {
      await stats.addCoins(Economy.duplicateCritter);
    } else {
      await stats.addCritter(result.critter.id);
    }
    if (result.completedSet != null) await stats.addCoins(Economy.setComplete);
    services.analytics.capsuleOpen(rarity: result.critter.rarity.name, duplicate: result.duplicate);
    services.sound.play(Sfx.reveal);
    HapticFeedback.heavyImpact();
    if (!mounted) return;
    setState(() => _result = result);
    _burst.forward(from: 0);
  }

  void _again() => setState(() {
        _taps = 0;
        _result = null;
        _burst.reset();
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
    return Scaffold(
      backgroundColor: background,
      body: Stack(children: [
        ScreenFrame(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(children: [
              Row(children: [
                RoundIconButton(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.maybePop(context), tooltip: l10n.back),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.capsules, style: chunky(26))),
                StatPill(emoji: '🥚', text: '$waiting', key: const Key('capsuleCount')),
                const SizedBox(width: 8),
                StatPill(emoji: '🪙', text: '${stats.coins}'),
              ]),
              Expanded(
                child: Center(
                  child: result != null
                      ? _reveal(l10n, result)
                      : waiting > 0
                          ? _capsule(l10n)
                          : _empty(l10n, adAvailable),
                ),
              ),
              if (result != null) ...[
                if (waiting > 0)
                  ChunkyButton(
                    key: const Key('openAnother'),
                    label: l10n.openAnother(waiting),
                    expand: true,
                    onPressed: _again,
                  )
                else if (adAvailable)
                  _adButton(l10n),
                const SizedBox(height: 10),
                ChunkyButton(
                  key: const Key('seeAlbum'),
                  label: l10n.seeAlbum,
                  color: surface,
                  textColor: ink,
                  expand: true,
                  onPressed: () => widget.fromAlbum
                      ? Navigator.pop(context)
                      : Navigator.pushReplacement(context, softRoute(const AlbumScreen())),
                ),
              ],
            ]),
          ),
        ),
        Positioned.fill(child: Confetti(animation: _burst, seed: 11)),
      ]),
    );
  }

  Widget _capsule(AppLocalizations l10n) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        key: const Key('capsule'),
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: AnimatedBuilder(
          animation: _shake,
          builder: (context, child) {
            final t = _shake.value;
            final amp = 0.12 + 0.08 * _taps;
            final angle = sin(t * pi * 6) * amp * (1 - t);
            return Transform.rotate(angle: angle, child: child);
          },
          child: SizedBox(
            width: 200,
            height: 240,
            child: CustomPaint(painter: _CapsulePainter(golden: _golden || _isGoldenNext(), cracks: _taps)),
          ),
        ),
      ),
      const SizedBox(height: 22),
      Text(
        _taps == 0 ? l10n.capsuleTap : (_taps == 1 ? l10n.capsuleTapAgain : l10n.capsuleAlmost),
        style: chunky(20),
        textAlign: TextAlign.center,
      ),
      if (_isGoldenNext()) ...[
        const SizedBox(height: 6),
        Text(l10n.goldenCapsule, style: chunky(15, color: const Color(0xFFB0820F), weight: FontWeight.w800)),
      ],
    ]);
  }

  bool _isGoldenNext() => Services.of(context).stats.goldenCapsules > 0;

  Widget _reveal(AppLocalizations l10n, CapsuleResult r) {
    final c = r.critter;
    final (label, color) = switch (c.rarity) {
      Rarity.golden => (l10n.rarityGolden, gold),
      Rarity.rare => (l10n.rarityRare, rareBlue),
      Rarity.common => (l10n.rarityCommon, good),
    };
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
        width: 260,
        height: 260,
        child: Stack(alignment: Alignment.center, children: [
          AnimatedBuilder(
            animation: _burst,
            builder: (_, _) => Transform.rotate(
              angle: _burst.value * 0.6,
              child: CustomPaint(size: const Size(260, 260), painter: _RaysPainter(color, Curves.easeOut.transform(_burst.value))),
            ),
          ),
          PopIn(
            delay: const Duration(milliseconds: 80),
            duration: const Duration(milliseconds: 700),
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: surface,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 5),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 30)],
              ),
              child: Center(child: CritterImage(c.id, size: 104)),
            ),
          ),
        ]),
      ),
      PopIn(
        delay: const Duration(milliseconds: 300),
        child: Column(children: [
          Text(critterName(l10n, c.id), key: const Key('revealName'), style: chunky(30)),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
            child: Text('$label · ${setName(l10n, c.set)}', style: chunky(14, color: Colors.white)),
          ),
          const SizedBox(height: 12),
          Text(
            r.duplicate ? l10n.capsuleDuplicate(Economy.duplicateCritter) : l10n.capsuleNew,
            textAlign: TextAlign.center,
            style: chunky(17, color: r.duplicate ? inkSoft : accent, weight: FontWeight.w800),
          ),
          if (r.completedSet != null) ...[
            const SizedBox(height: 8),
            Text(l10n.capsuleSetComplete(setName(l10n, r.completedSet!), Economy.setComplete),
                textAlign: TextAlign.center, style: chunky(17, color: const Color(0xFFB0820F))),
          ],
        ]),
      ),
    ]);
  }

  Widget _empty(AppLocalizations l10n, bool adAvailable) => Column(mainAxisSize: MainAxisSize.min, children: [
        Opacity(opacity: 0.45, child: SizedBox(width: 140, height: 170, child: CustomPaint(painter: _CapsulePainter(golden: false, cracks: 0)))),
        const SizedBox(height: 18),
        Text(l10n.noCapsules, style: chunky(22), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(l10n.capsulesHowTo, textAlign: TextAlign.center, style: chunky(15, color: inkSoft, weight: FontWeight.w700)),
        ),
        const SizedBox(height: 22),
        if (adAvailable) _adButton(l10n),
      ]);

  Widget _adButton(AppLocalizations l10n) => ChunkyButton(
        key: const Key('capsuleAd'),
        label: l10n.capsuleForVideo,
        color: good,
        expand: true,
        icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
        onPressed: _watchForCapsule,
      );
}

/// An egg-like capsule: colored top, cream bottom, a band, and cracks after each tap.
class _CapsulePainter extends CustomPainter {
  _CapsulePainter({required this.golden, required this.cracks});

  final bool golden;
  final int cracks;

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
    canvas.drawShadow(egg, ink, 8, false);
    final top = golden ? gold : accent;
    final topLight = golden ? const Color(0xFFFFE08A) : const Color(0xFFFFB896);
    canvas.save();
    canvas.clipPath(egg);
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFFBF3));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h * 0.55),
        Paint()
          ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [topLight, top])
              .createShader(Rect.fromLTWH(0, 0, w, h * 0.55)));
    // Band.
    canvas.drawRect(Rect.fromLTWH(0, h * 0.52, w, h * 0.07), Paint()..color = Colors.white.withValues(alpha: 0.9));
    // Polka dots.
    final dot = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (final (x, y, r) in const [(0.3, 0.2, 0.06), (0.62, 0.14, 0.04), (0.72, 0.36, 0.07), (0.38, 0.4, 0.035)]) {
      canvas.drawCircle(Offset(w * x, h * y), w * r, dot);
    }
    // Highlight.
    canvas.drawOval(Rect.fromLTWH(w * 0.2, h * 0.1, w * 0.16, h * 0.2), Paint()..color = Colors.white.withValues(alpha: 0.45));
    canvas.restore();
    canvas.drawPath(egg, Paint()
      ..color = ink.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    if (cracks > 0) {
      final crack = Paint()
        ..color = ink.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      final p = Path()..moveTo(w * 0.22, h * 0.5);
      final pts = cracks >= 2
          ? const [(0.3, 0.44), (0.38, 0.53), (0.47, 0.43), (0.55, 0.54), (0.64, 0.44), (0.72, 0.52), (0.8, 0.46)]
          : const [(0.3, 0.44), (0.38, 0.53), (0.46, 0.46)];
      for (final (x, y) in pts) {
        p.lineTo(w * x, h * y);
      }
      canvas.drawPath(p, crack);
    }
  }

  @override
  bool shouldRepaint(_CapsulePainter old) => old.golden != golden || old.cracks != cracks;
}

class _RaysPainter extends CustomPainter {
  _RaysPainter(this.color, this.t);

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 * (0.6 + 0.4 * t);
    final paint = Paint()..color = color.withValues(alpha: 0.22 * t);
    for (var k = 0; k < 12; k++) {
      final a = k * pi / 6;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + cos(a - 0.12) * r, c.dy + sin(a - 0.12) * r)
        ..lineTo(c.dx + cos(a + 0.12) * r, c.dy + sin(a + 0.12) * r)
        ..close();
      canvas.drawPath(path, paint);
    }
    canvas.drawCircle(c, r * 0.62, Paint()..color = color.withValues(alpha: 0.12 * t));
  }

  @override
  bool shouldRepaint(_RaysPainter old) => old.t != t || old.color != color;
}
