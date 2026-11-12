import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../meta/lucky_nest.dart';
import '../meta/progress_store.dart';
import '../services/sound_service.dart';
import 'capsule_screen.dart';
import 'coin_fly.dart';
import 'meadow.dart';
import 'navigation.dart';
import 'palette.dart';
import 'services.dart';
import 'widgets.dart';

/// Shell colors of the three nest eggs.
const _eggColors = [Color(0xFFBFE3F7), Color(0xFFFFD6E0), Color(0xFFDFF2C4)];

/// The Lucky Nest on the home meadow: a twig nest with three eggs, "Free!" when today's free egg is waiting.
class LuckyNestProp extends StatelessWidget {
  const LuckyNestProp({super.key, required this.free, required this.onTap, this.size = 92});

  final bool free;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Bouncy(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: l10n.luckyNest,
        child: SizedBox(
          width: size,
          height: size * 0.8,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned(bottom: 0, child: TwigNest(width: size)),
              for (final (i, dx) in const [-0.22, 0.22, 0.0].indexed)
                Positioned(
                  bottom: size * (i == 2 ? 0.12 : 0.16),
                  left: size * (0.5 + dx) - size * 0.14,
                  child: NestEgg(size: size * (i == 2 ? 0.36 : 0.3), color: _eggColors[i]),
                ),
              Positioned(bottom: 0, child: TwigNest(width: size, front: true)),
              if (free)
                Positioned(
                  top: -size * 0.12,
                  right: -size * 0.1,
                  child: Container(
                    key: const Key('luckyFreeBadge'),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: leaf,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: const [BoxShadow(color: shadow, offset: Offset(0, 2))],
                    ),
                    child: Text(l10n.luckyFree, style: outlinedText(13, stroke: leafEdge, width: 1.2)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A speckled bird egg; [cracks] 1–2 after taps, [half] 1/2 draws only the top/bottom shell piece.
class NestEgg extends StatelessWidget {
  const NestEgg({super.key, required this.size, required this.color, this.cracks = 0, this.half = 0});

  final double size;
  final Color color;
  final int cracks;
  final int half;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 0.8,
    height: size,
    child: CustomPaint(painter: _EggPainter(color, cracks, half)),
  );
}

class _EggPainter extends CustomPainter {
  const _EggPainter(this.color, this.cracks, this.half);

  final Color color;
  final int cracks;
  final int half;

  static const _zig = [
    (0.0, 0.5),
    (0.14, 0.43),
    (0.28, 0.54),
    (0.42, 0.42),
    (0.56, 0.55),
    (0.7, 0.43),
    (0.84, 0.53),
    (1.0, 0.46),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final egg = Path()
      ..moveTo(w * 0.5, 0)
      ..cubicTo(w * 0.86, 0, w, h * 0.5, w * 0.98, h * 0.66)
      ..cubicTo(w * 0.95, h * 0.92, w * 0.72, h, w * 0.5, h)
      ..cubicTo(w * 0.28, h, w * 0.05, h * 0.92, w * 0.02, h * 0.66)
      ..cubicTo(0, h * 0.5, w * 0.14, 0, w * 0.5, 0)
      ..close();
    canvas.save();
    if (half != 0) {
      final cut = Path()..moveTo(-1, h * 0.5);
      for (final (x, y) in _zig) {
        cut.lineTo(w * x, h * y);
      }
      if (half == 1) {
        cut
          ..lineTo(w + 1, -1)
          ..lineTo(-1, -1);
      } else {
        cut
          ..lineTo(w + 1, h + 1)
          ..lineTo(-1, h + 1);
      }
      canvas.clipPath(cut..close());
    }
    canvas.drawPath(
      egg,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.6)!, color, Color.lerp(color, const Color(0xFF8C7360), 0.18)!],
        ).createShader(Offset.zero & size),
    );
    canvas.save();
    canvas.clipPath(egg);
    final speck = Paint()..color = Color.lerp(color, const Color(0xFF6B4A2E), 0.45)!.withValues(alpha: 0.55);
    final r = Random(color.toARGB32());
    for (var i = 0; i < 9; i++) {
      canvas.drawCircle(
        Offset(w * (0.15 + r.nextDouble() * 0.7), h * (0.2 + r.nextDouble() * 0.7)),
        w * (0.025 + r.nextDouble() * 0.03),
        speck,
      );
    }
    canvas.drawOval(
      Rect.fromLTWH(w * 0.2, h * 0.12, w * 0.2, h * 0.16),
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
    canvas.restore();
    canvas.drawPath(
      egg,
      Paint()
        ..color = Color.lerp(color, const Color(0xFF4A3426), 0.5)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.2, w * 0.03),
    );
    if (cracks > 0 && half == 0) {
      final crack = Paint()
        ..color = woodEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.2, w * 0.035)
        ..strokeJoin = StrokeJoin.round;
      final pts = cracks >= 2 ? _zig.sublist(0, 8) : _zig.sublist(2, 5);
      final p = Path();
      for (final (i, (x, y)) in pts.indexed) {
        i == 0 ? p.moveTo(w * x, h * y) : p.lineTo(w * x, h * y);
      }
      canvas.drawPath(p, crack);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EggPainter old) => old.color != color || old.cracks != cracks || old.half != half;
}

/// Pick an egg: it wobbles, cracks and a prize pops out. One free egg a day, then eggs for coins; odds always shown.
class LuckyNestScreen extends StatefulWidget {
  const LuckyNestScreen({super.key});

  @override
  State<LuckyNestScreen> createState() => _LuckyNestScreenState();
}

class _LuckyNestScreenState extends State<LuckyNestScreen> with TickerProviderStateMixin {
  late final _open = AnimationController(vsync: this, duration: const Duration(milliseconds: 1900));
  late final _float = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  late final _spin = AnimationController(vsync: this, duration: const Duration(seconds: 14));
  final _coinTarget = GlobalKey();
  final _prizeKey = GlobalKey();
  int? _picked;
  LuckyDraw? _draw;
  int _coinsHeld = 0;
  bool _busy = false;

  @override
  void dispose() {
    _open.dispose();
    _float.dispose();
    _spin.dispose();
    super.dispose();
  }

  int get _today => localDay(Services.of(context).today());

  Future<void> _pick(int egg) async {
    if (_busy) return;
    final services = Services.of(context);
    final l10n = AppLocalizations.of(context);
    final nest = services.retention.luckyNest;
    final state = nest.state(_today);
    if (!state.freeAvailable && (state.paidLeft ?? 1) <= 0) return;
    if (!state.freeAvailable && services.stats.coins < state.price) {
      await showSoftDialog<void>(
        context,
        emoji: '🪙',
        title: l10n.hintNoCoinsTitle,
        body: l10n.shopNotEnough(state.price - services.stats.coins),
        actions: [
          ChunkyButton(label: l10n.close, expand: true, color: woodButton, onPressed: () => Navigator.pop(context)),
        ],
      );
      return;
    }
    _busy = true;
    final draw = await nest.draw(_today);
    if (!mounted) return;
    if (draw == null) {
      _busy = false;
      setState(() {});
      return;
    }
    setState(() {
      _picked = egg;
      _draw = draw;
      _coinsHeld = draw.coins;
    });
    services.sound.play(Sfx.capsule);
    HapticFeedback.mediumImpact();
    final motion = ambientMotion(context);
    if (motion) {
      await _open.forward(from: 0).orCancel.catchError((_) {});
    } else {
      _open.value = 1;
    }
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    services.sound.play(switch (draw.prize) {
      LuckyPrize.goldenCapsule || LuckyPrize.capsule => Sfx.reveal,
      LuckyPrize.feather => Sfx.erase,
      _ => Sfx.chest,
    });
    if (draw.prize == LuckyPrize.goldenCapsule && motion) _spin.repeat();
    if (draw.prize == LuckyPrize.feather) {
      motion ? _float.forward(from: 0) : _float.value = 1;
    }
    if (draw.prize == LuckyPrize.coins) {
      await Future<void>.delayed(Duration(milliseconds: motion ? 500 : 0));
      if (!mounted) return;
      final total = draw.coins;
      await flyCoins(
        context,
        from: _prizeKey,
        to: _coinTarget,
        coins: 10,
        onArrive: (n) {
          if (mounted) setState(() => _coinsHeld = total - (total * n / 10).round());
        },
      );
    }
    if (!mounted) return;
    setState(() {
      _coinsHeld = 0;
      _busy = false;
    });
  }

  void _again() {
    _open.reset();
    _float.reset();
    _spin.stop();
    setState(() {
      _picked = null;
      _draw = null;
    });
  }

  void _showOdds() {
    final l10n = AppLocalizations.of(context);
    final s = Services.of(context).retention.settings.lucky;
    String pct(double v) => '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1)} %'.replaceAll(' %', '%');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SoftCard(
            key: const Key('oddsSheet'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.luckyOddsTitle, style: chunky(22)),
                const SizedBox(height: 10),
                for (final e in s.odds.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Center(child: _PrizeIcon(prize: e.key, size: 30)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_prizeName(l10n, e.key, s), style: chunky(17))),
                        Text(
                          pct(e.value),
                          key: Key('odds-${e.key.name}'),
                          style: chunky(17, color: woodDark),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  l10n.luckyOddsNote,
                  textAlign: TextAlign.center,
                  style: chunky(14, color: inkSoft, weight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = Services.of(context);
    final nest = services.retention.luckyNest;
    final state = nest.state(_today);
    final paidOff = state.paidLeft == 0;
    final canDraw = state.freeAvailable || !paidOff;
    final eggs = paidOff ? 1 : 3;
    final draw = _draw;
    return MeadowScaffold(
      child: Column(
        children: [
          MeadowTopBar(
            title: l10n.luckyNest,
            backTooltip: l10n.back,
            trailing: [CoinCounter(value: services.stats.coins - _coinsHeld, iconKey: _coinTarget)],
          ),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 64,
                    child: Center(
                      child: draw == null
                          ? (canDraw ? _Bubble(text: l10n.luckyTapEgg) : _Bubble(text: l10n.luckyTomorrow))
                          : null,
                    ),
                  ),
                  SizedBox(
                    width: 340,
                    height: 330,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_open, _float, _spin]),
                      builder: (context, _) => _stage(eggs, canDraw),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 340,
                    height: 130,
                    child: draw == null
                        ? (canDraw
                              ? Center(
                                  child: ChunkyButton(
                                    key: const Key('luckyDraw'),
                                    label: state.freeAvailable ? l10n.luckyFreeEgg : '${state.price}',
                                    color: state.freeAvailable ? leaf : gold,
                                    textColor: state.freeAvailable ? Colors.white : ink,
                                    icon: state.freeAvailable
                                        ? const Icon(Icons.egg_rounded, color: Colors.white)
                                        : const CoinIcon(size: 26),
                                    onPressed: () => _pick(eggs == 1 ? 0 : 1),
                                  ),
                                )
                              : null)
                        : (_busy ? null : _result(l10n, draw, state)),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: TextButton.icon(
              key: const Key('luckyOdds'),
              onPressed: _showOdds,
              icon: const Icon(
                Icons.info_outline_rounded,
                color: Colors.white,
                shadows: [Shadow(color: woodEdge, offset: Offset(0, 2))],
              ),
              label: Text(
                l10n.luckyOdds,
                style: outlinedText(
                  17,
                  stroke: woodEdge,
                  width: 1.5,
                ).copyWith(decoration: TextDecoration.underline, decorationColor: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stage(int eggs, bool canDraw) {
    final t = _open.value;
    final draw = _draw;
    final wobble = (t / 0.4).clamp(0.0, 1.0);
    final burst = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
    final cracks = t < 0.25 ? 0 : (t < 0.45 ? 1 : 2);
    final positions = eggs == 1 ? const [0.5] : const [0.22, 0.5, 0.78];
    final children = <Widget>[const Positioned(bottom: 0, left: 20, child: TwigNest(width: 300))];
    if (draw != null && burst > 0) {
      children.add(Positioned.fill(child: _prizeGlow(draw.prize, burst)));
    }
    for (final (i, x) in positions.indexed) {
      final picked = _picked == i;
      final size = eggs == 1 ? 130.0 : (i == 1 ? 112.0 : 100.0);
      final left = 340 * x - size * 0.4;
      if (picked && burst > 0) {
        // The shell splits: top half flies up and away, bottom half stays in the nest.
        children.add(
          Positioned(
            bottom: 52,
            left: left,
            child: Opacity(
              opacity: 1 - burst * 0.4,
              child: NestEgg(size: size, color: _eggColors[i % 3], half: 2),
            ),
          ),
        );
        children.add(
          Positioned(
            bottom: 52 + burst * 90,
            left: left - burst * 50,
            child: Opacity(
              opacity: (1 - burst).clamp(0.0, 1.0),
              child: Transform.rotate(
                angle: -burst * 1.4,
                child: NestEgg(size: size, color: _eggColors[i % 3], half: 1),
              ),
            ),
          ),
        );
        continue;
      }
      final angle = picked ? sin(wobble * pi * 7) * 0.18 * (1 - wobble * 0.3) : 0.0;
      final hop = picked ? -sin(wobble * pi * 3).abs() * 8 : 0.0;
      final faded = _picked != null && !picked;
      children.add(
        Positioned(
          bottom: 52 + hop,
          left: left,
          child: GestureDetector(
            key: Key('egg-$i'),
            behavior: HitTestBehavior.opaque,
            onTap: canDraw && _draw == null ? () => _pick(i) : null,
            child: Opacity(
              opacity: faded ? 0.55 : (canDraw || _draw != null ? 1 : 0.6),
              child: Transform.rotate(
                alignment: Alignment.bottomCenter,
                angle: angle,
                child: NestEgg(size: size, color: _eggColors[i % 3], cracks: picked ? cracks : 0),
              ),
            ),
          ),
        ),
      );
    }
    children.add(const Positioned(bottom: 0, left: 20, child: IgnorePointer(child: TwigNest(width: 300, front: true))));
    if (draw != null && burst > 0) children.add(_prize(draw, burst));
    return Stack(clipBehavior: Clip.none, children: children);
  }

  Widget _prizeGlow(LuckyPrize prize, double burst) {
    if (prize == LuckyPrize.feather) return const SizedBox.shrink();
    final color = prize == LuckyPrize.goldenCapsule
        ? gold
        : (prize == LuckyPrize.hint ? const Color(0xFFFFF09A) : Colors.white);
    return CustomPaint(
      painter: RaysPainter(color, burst * (prize == LuckyPrize.goldenCapsule ? 1 : 0.6), _spin.value * 2 * pi),
    );
  }

  Widget _prize(LuckyDraw draw, double burst) {
    final rise = Curves.easeOutBack.transform(burst);
    const x = 170.0;
    if (draw.prize == LuckyPrize.feather) {
      // The feather drifts down gently, swaying.
      final f = _float.value;
      final y = 30 + f * 170;
      final sway = sin(f * pi * 3) * 40;
      return Positioned(
        top: y,
        left: x - 30 + sway,
        child: Transform.rotate(
          angle: sin(f * pi * 3 + 1) * 0.5,
          child: const _PrizeIcon(prize: LuckyPrize.feather, size: 60),
        ),
      );
    }
    final size = draw.prize == LuckyPrize.goldenCapsule ? 110.0 : 90.0;
    return Positioned(
      bottom: 90 + rise * 110,
      left: x - size / 2,
      child: Transform.scale(
        scale: 0.3 + 0.7 * rise,
        child: SizedBox(
          key: _prizeKey,
          width: size,
          height: size,
          child: Center(
            child: _PrizeIcon(prize: draw.prize, size: size),
          ),
        ),
      ),
    );
  }

  Widget _result(AppLocalizations l10n, LuckyDraw draw, LuckyState state) {
    final s = Services.of(context).retention.settings.lucky;
    final text = switch (draw.prize) {
      LuckyPrize.goldenCapsule => l10n.rewardGoldenCapsule,
      LuckyPrize.capsule => l10n.rewardCapsule,
      LuckyPrize.coins => l10n.rewardCoins(draw.coins),
      LuckyPrize.hint => l10n.luckyWonHint,
      LuckyPrize.feather => l10n.luckySoClose,
    };
    final canMore = state.freeAvailable || (state.paidLeft ?? 1) > 0;
    final capsule = draw.prize == LuckyPrize.goldenCapsule || draw.prize == LuckyPrize.capsule;
    return PopIn(
      child: Column(
        children: [
          Text(
            text,
            key: const Key('luckyResult'),
            style: outlinedText(
              28,
              color: draw.prize == LuckyPrize.feather ? Colors.white : const Color(0xFFFFE066),
              stroke: woodEdge,
              width: 2.2,
            ),
          ),
          if (draw.prize == LuckyPrize.coins)
            Text(
              _prizeName(l10n, LuckyPrize.coins, s),
              style: chunky(14, color: Colors.white).copyWith(shadows: outline(woodEdge, 1.2)),
            ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (capsule) ...[
                ChunkyButton(
                  key: const Key('luckyOpen'),
                  label: l10n.luckyOpenCapsule,
                  small: true,
                  color: coral,
                  onPressed: () async {
                    await Navigator.of(context).push(softRoute(const CapsuleScreen()));
                    if (mounted) _again();
                  },
                ),
                const SizedBox(width: 10),
              ],
              if (canMore)
                ChunkyButton(
                  key: const Key('luckyAgain'),
                  label: state.freeAvailable ? l10n.luckyFreeEgg : '${state.price}',
                  small: true,
                  color: leaf,
                  icon: state.freeAvailable ? null : const CoinIcon(size: 22),
                  onPressed: _again,
                )
              else
                Flexible(
                  child: Text(l10n.luckyTomorrow, textAlign: TextAlign.center, style: outlinedText(16, stroke: woodEdge)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _prizeName(AppLocalizations l10n, LuckyPrize p, LuckySettings s) => switch (p) {
  LuckyPrize.goldenCapsule => l10n.luckyPrizeGolden,
  LuckyPrize.capsule => l10n.luckyPrizeCapsule,
  LuckyPrize.coins => l10n.luckyPrizeCoins(s.minCoins, s.maxCoins),
  LuckyPrize.hint => l10n.luckyPrizeHint,
  LuckyPrize.feather => l10n.luckyPrizeFeather,
};

class _PrizeIcon extends StatelessWidget {
  const _PrizeIcon({required this.prize, required this.size});

  final LuckyPrize prize;
  final double size;

  @override
  Widget build(BuildContext context) => switch (prize) {
    LuckyPrize.goldenCapsule => CapsuleEgg(size: size, golden: true),
    LuckyPrize.capsule => CapsuleEgg(size: size),
    LuckyPrize.coins => SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            bottom: size * 0.05,
            child: CoinIcon(size: size * 0.55),
          ),
          Positioned(
            right: 0,
            bottom: size * 0.1,
            child: CoinIcon(size: size * 0.55),
          ),
          Positioned(
            left: size * 0.22,
            top: size * 0.08,
            child: CoinIcon(size: size * 0.6),
          ),
        ],
      ),
    ),
    LuckyPrize.hint => Icon(
      Icons.lightbulb_rounded,
      size: size,
      color: gold,
      shadows: const [Shadow(color: goldEdge, offset: Offset(0, 3))],
    ),
    LuckyPrize.feather => SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _FeatherPainter()),
    ),
  };
}

class _FeatherPainter extends CustomPainter {
  const _FeatherPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.save();
    canvas.translate(s / 2, s / 2);
    canvas.rotate(-0.6);
    final vane = Path()
      ..moveTo(0, -s * 0.46)
      ..cubicTo(s * 0.26, -s * 0.3, s * 0.2, s * 0.2, 0, s * 0.32)
      ..cubicTo(-s * 0.2, s * 0.2, -s * 0.26, -s * 0.3, 0, -s * 0.46)
      ..close();
    canvas.drawPath(
      vane,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFDCEBFA)])
            .createShader(Rect.fromLTWH(-s / 2, -s / 2, s, s)),
    );
    final barb = Paint()
      ..color = const Color(0xFFB8CBE0)
      ..strokeWidth = max(1, s * 0.02);
    for (var k = 0; k < 6; k++) {
      final y = -s * 0.32 + k * s * 0.1;
      canvas.drawLine(Offset(0, y), Offset(s * 0.16, y - s * 0.06), barb);
      canvas.drawLine(Offset(0, y), Offset(-s * 0.16, y - s * 0.06), barb);
    }
    canvas.drawPath(
      vane,
      Paint()
        ..color = const Color(0xFF9CB3CC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1, s * 0.025),
    );
    canvas.drawLine(
      Offset(0, -s * 0.44),
      Offset(0, s * 0.48),
      Paint()
        ..color = const Color(0xFF8C7360)
        ..strokeWidth = max(1.5, s * 0.035)
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FeatherPainter old) => false;
}

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
        boxShadow: const [BoxShadow(color: paperEdge, offset: Offset(0, 4))],
      ),
      child: Text(text, style: chunky(20), textAlign: TextAlign.center),
    ),
  );
}
