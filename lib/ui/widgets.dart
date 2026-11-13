import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sound_service.dart';
import 'meadow.dart';
import 'palette.dart';
import 'services.dart';
import 'worlds/world.dart';

/// Chunky, friendly type in the equipped World's display font.
TextStyle chunky(double size, {Color? color, FontWeight weight = FontWeight.w700, double? height}) =>
    activeWorld.text(size, color: color, weight: weight, height: height);

/// A cartoon outline around text, made of shadows (so it stays a single [Text]).
List<Shadow> outline(Color color, double width, {double drop = 1.8}) => cartoonOutline(color, width, drop: drop);

/// Light text that stands out over the World's background (a dark cartoon outline in the Meadow).
TextStyle outlinedText(double size, {Color? color, Color? stroke, double? width}) =>
    activeWorld.outlined(size, color: color, stroke: stroke, width: width);

/// Centers screen content at phone width (scaled up on tablets by [MeadowScaffold]).
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({super.key, required this.child, this.maxWidth = 480});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}

/// Squashes under the finger and springs back, plays a tap and a light haptic.
class Bouncy extends StatefulWidget {
  const Bouncy({super.key, required this.child, this.onTap, this.sound = true, this.builder});

  final Widget child;
  final VoidCallback? onTap;
  final bool sound;

  /// Custom press look: gets the press amount (0 rest, 1 pressed, overshoots while springing back).
  final Widget Function(BuildContext context, double press, Widget child)? builder;

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> with SingleTickerProviderStateMixin {
  late final _press = AnimationController(vsync: this, lowerBound: -1, upperBound: 1, value: 0);

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _down() => _press.animateTo(1, duration: const Duration(milliseconds: 70), curve: Curves.easeOut);

  void _up() => _press.animateTo(0, duration: const Duration(milliseconds: 420), curve: Curves.elasticOut);

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _down() : null,
      onTapCancel: enabled ? _up : null,
      onTapUp: enabled ? (_) => _up() : null,
      onTap: enabled
          ? () {
              if (widget.sound) Services.of(context).sound.play(Sfx.tap);
              HapticFeedback.selectionClick();
              widget.onTap!();
            }
          : null,
      child: AnimatedBuilder(
        animation: _press,
        child: widget.child,
        builder: (context, child) {
          final p = _press.value;
          if (widget.builder != null) return widget.builder!(context, p, child!);
          return Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(1 + 0.03 * p, 1 - 0.07 * p, 1),
            child: child,
          );
        },
      ),
    );
  }
}

enum PanelStyle { paper, wood }

/// A cozy panel: cream paper (default) or warm wood planks, with a solid drop edge and a soft shadow.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.border,
    this.style = PanelStyle.paper,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? border;
  final PanelStyle style;

  @override
  Widget build(BuildContext context) {
    final world = worldOf(context);
    final Widget card;
    if (style == PanelStyle.wood) {
      card = CustomPaint(painter: WoodPainter(world: world), child: Padding(padding: padding, child: child));
    } else {
      card = Container(padding: padding, decoration: world.card(fill: color, border: border), child: child);
    }
    return onTap == null ? card : Bouncy(onTap: onTap, child: card);
  }
}

/// The World's panel (wood planks with seams, grain and nails in the Meadow).
class WoodPainter extends CustomPainter {
  const WoodPainter({this.radius = 18, this.nails = true, this.plank = 34, this.world});

  final double radius;
  final bool nails;
  final double plank;

  /// Paints this World's panel instead of the equipped one (previews).
  final GameWorld? world;

  @override
  void paint(Canvas canvas, Size size) =>
      (world ?? activeWorld).paintPanel(canvas, size, radius: radius, nails: nails, plank: plank);

  @override
  bool shouldRepaint(WoodPainter old) =>
      old.radius != radius || old.nails != nails || old.plank != plank || old.world?.id != world?.id;
}

/// The darker rim of a button for a base color, in the equipped World.
Color edgeOf(Color c) => activeWorld.edgeOf(c);

/// Chunky 3D "candy" button: thick darker edge, glossy top, squashes when pressed and springs back.
class ChunkyButton extends StatelessWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.edge,
    this.textColor = Colors.white,
    this.expand = false,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;

  /// Face color; the World's main button color ([WorldPalette.leaf]) by default.
  final Color? color;
  final Color? edge;
  final Color textColor;
  final bool expand;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final world = worldOf(context);
    final base = color ?? world.palette.leaf;
    final enabled = onPressed != null;
    final face = enabled ? base : Color.lerp(base, world.disabledButton, 0.65)!;
    final rim = enabled ? (edge ?? world.edgeOf(base)) : world.edgeOf(face);
    final fontSize = small ? 16.0 : 20.0;
    final depth = world.buttonDepth(small);
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, SizedBox(width: small ? 6 : 8)],
        // Shrink a long label (narrow cards, big system font) instead of cutting it to "Pl…".
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: world.buttonText(fontSize, textColor: textColor, rim: rim)),
          ),
        ),
      ],
    );
    return Bouncy(
      onTap: onPressed,
      builder: (context, p, child) {
        final pressed = p.clamp(0.0, 1.0);
        return CustomPaint(
          painter: CandyPainter(face: face, edge: rim, press: pressed, depth: depth, radius: small ? 16 : 20, world: world),
          child: Padding(
            padding: EdgeInsets.only(top: depth * pressed, bottom: depth * (1 - pressed)),
            child: Transform.scale(scaleX: 1 + 0.04 * p, scaleY: 1 - 0.04 * p, child: child),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: small ? 16 : 22, vertical: small ? 9 : 13),
        child: content,
      ),
    );
  }
}

/// Paints a button the World's way (a candy button in the Meadow).
class CandyPainter extends CustomPainter {
  const CandyPainter({
    required this.face,
    required this.edge,
    this.press = 0,
    this.depth = 6,
    this.radius = 20,
    this.circle = false,
    this.world,
  });

  final Color face;
  final Color edge;
  final double press;
  final double depth;
  final double radius;
  final bool circle;
  final GameWorld? world;

  @override
  void paint(Canvas canvas, Size size) => (world ?? activeWorld)
      .paintButton(canvas, size, face: face, edge: edge, press: press, depth: depth, radius: radius, circle: circle);

  @override
  bool shouldRepaint(CandyPainter old) =>
      old.face != face ||
      old.edge != edge ||
      old.press != press ||
      old.depth != depth ||
      old.radius != radius ||
      old.circle != circle ||
      old.world?.id != world?.id;
}

/// Pill badge for the HUD (coins, streak, timer…): a cream pill with an icon on the left.
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    this.emoji,
    this.icon,
    required this.text,
    this.color,
    this.textColor,
    this.onTap,
    this.big = false,
  });

  final String? emoji;
  final Widget? icon;
  final String text;

  /// Pill fill and text; the World's paper and ink by default.
  final Color? color;
  final Color? textColor;
  final VoidCallback? onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final world = worldOf(context);
    final h = big ? 44.0 : 38.0;
    final pill = Container(
      height: h,
      padding: EdgeInsets.only(left: 5, right: big ? 16 : 13),
      decoration: world.pill(color ?? world.palette.paper, h),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox.square(
          dimension: h - 10,
          child: icon ?? FittedBox(child: Text(emoji ?? '', style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 6),
        Text(text, style: world.text(big ? 20 : 17, color: textColor ?? world.palette.ink)),
      ]),
    );
    return onTap == null ? pill : Bouncy(onTap: onTap, child: pill);
  }
}

/// A coin: gold disc, rim and a shine.
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(dimension: size, child: const CustomPaint(painter: _CoinPainter()));
}

class _CoinPainter extends CustomPainter {
  const _CoinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width, size.height);
    final c = size.center(Offset.zero);
    canvas.drawCircle(c + Offset(0, s * 0.05), s * 0.46, Paint()..color = const Color(0xFFD38A12));
    canvas.drawCircle(c, s * 0.46, Paint()..color = const Color(0xFFFFCF40));
    canvas.drawCircle(c, s * 0.33, Paint()..color = const Color(0xFFF5B321));
    final star = starPath(c, s * 0.2, s * 0.09);
    canvas.drawPath(star, Paint()..color = const Color(0xFFFFE27A));
    canvas.drawCircle(c, s * 0.46, Paint()
      ..color = const Color(0xFFB7700A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, s * 0.06));
    canvas.drawOval(Rect.fromLTWH(c.dx - s * 0.3, c.dy - s * 0.36, s * 0.22, s * 0.14), Paint()..color = Colors.white.withValues(alpha: 0.6));
  }

  @override
  bool shouldRepaint(_CoinPainter old) => false;
}

/// The streak icon: a flame in the Meadow, a campfire that grows with [streak] in the Lodge.
class FlameIcon extends StatelessWidget {
  const FlameIcon({super.key, this.size = 28, this.lit = true, this.streak = 0});

  final double size;
  final bool lit;
  final int streak;

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: size, child: CustomPaint(painter: _FlamePainter(worldOf(context), lit, streak)));
}

class _FlamePainter extends CustomPainter {
  const _FlamePainter(this.world, this.lit, this.streak);

  final GameWorld world;
  final bool lit;
  final int streak;

  @override
  void paint(Canvas canvas, Size size) => world.paintStreak(canvas, size, lit: lit, streak: streak);

  @override
  bool shouldRepaint(_FlamePainter old) => old.lit != lit || old.streak != streak || old.world.id != world.id;
}

/// Coins pill whose number rolls up or down to [value].
class CoinCounter extends StatelessWidget {
  const CoinCounter({super.key, required this.value, this.iconKey, this.big = false});

  final int value;

  /// Where flying coins land.
  final GlobalKey? iconKey;
  final bool big;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: value.toDouble()),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => StatPill(
          icon: CoinIcon(key: iconKey, size: big ? 34 : 28),
          text: '${v.round()}',
          big: big,
        ),
      );
}

/// Round candy icon button (back, settings…).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onPressed, this.tooltip, this.size = 48, this.color});

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  /// Face color; the World's secondary button color ([WorldPalette.sky]) by default.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final world = worldOf(context);
    final face = color ?? world.palette.sky;
    final depth = world.buttonDepth(false) == 0 ? 0.0 : size * 0.1;
    final button = Bouncy(
      onTap: onPressed,
      builder: (context, p, child) {
        final pressed = p.clamp(0.0, 1.0);
        return CustomPaint(
          painter: CandyPainter(face: face, edge: world.edgeOf(face), press: pressed, depth: depth, circle: true, world: world),
          child: SizedBox(
            width: size,
            height: size + depth,
            child: Padding(padding: EdgeInsets.only(top: depth * pressed, bottom: depth * (1 - pressed)), child: child),
          ),
        );
      },
      child: Center(
        child: Icon(icon, color: world.iconColor(face), size: size * 0.56, shadows: world.iconShadows(face)),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

/// Red count bubble on a button.
class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 26),
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: bad,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [BoxShadow(color: shadow, offset: const Offset(0, 2))],
        ),
        child: Text('$count', textAlign: TextAlign.center, style: chunky(14, color: Colors.white)),
      );
}

/// Pops in from small, once, when first built.
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero, this.duration = const Duration(milliseconds: 420)});

  final Widget child;
  final Duration delay;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final total = delay + duration;
    final start = total.inMicroseconds == 0 ? 0.0 : delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, t, child) {
        final local = start >= 1 ? 1.0 : ((t - start) / (1 - start)).clamp(0.0, 1.0);
        final scale = Curves.elasticOut.transform(local).clamp(0.0, 1.3);
        return Opacity(opacity: local.clamp(0.0, 1.0), child: Transform.scale(scale: scale, child: child));
      },
      child: child,
    );
  }
}

/// Fades and rises in after [delay]: staggered entrances.
class SlideIn extends StatelessWidget {
  const SlideIn({super.key, required this.child, this.delay = Duration.zero, this.offset = 26});

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  Widget build(BuildContext context) {
    const duration = Duration(milliseconds: 520);
    final total = delay + duration;
    final start = delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, t, child) {
        final local = ((t - start) / (1 - start)).clamp(0.0, 1.0);
        final y = (1 - Curves.easeOutBack.transform(local)) * offset;
        return Opacity(opacity: Curves.easeOut.transform(local), child: Transform.translate(offset: Offset(0, y), child: child));
      },
      child: child,
    );
  }
}

/// The big home title ("Critter Logic"): a wooden sign hanging from two ropes in the Meadow.
class WoodSign extends StatelessWidget {
  const WoodSign({super.key, required this.title, this.subtitle, this.fontSize = 40});

  final String title;
  final String? subtitle;
  final double fontSize;

  @override
  Widget build(BuildContext context) =>
      worldOf(context).sign(context, title: title, subtitle: subtitle, fontSize: fontSize);
}

/// A header plaque with a title (a wooden one in the Meadow).
class WoodLabel extends StatelessWidget {
  const WoodLabel({super.key, required this.text, this.subtitle, this.fontSize = 22});

  final String text;
  final String? subtitle;
  final double fontSize;

  @override
  Widget build(BuildContext context) =>
      worldOf(context).label(context, text: text, subtitle: subtitle, fontSize: fontSize);
}

/// Standard top bar: back button, wooden title, and trailing badges.
class MeadowTopBar extends StatelessWidget {
  const MeadowTopBar({super.key, required this.title, this.subtitle, this.trailing = const [], this.onBack, this.backKey, this.backIcon, this.backTooltip});

  final String title;
  final String? subtitle;
  final List<Widget> trailing;
  final VoidCallback? onBack;
  final Key? backKey;
  final IconData? backIcon;
  final String? backTooltip;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: Row(children: [
          RoundIconButton(
            key: backKey,
            icon: backIcon ?? Icons.arrow_back_rounded,
            tooltip: backTooltip,
            onPressed: onBack ?? () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Align(alignment: Alignment.centerLeft, child: WoodLabel(text: title, subtitle: subtitle)),
          ),
          for (final t in trailing) ...[const SizedBox(width: 6), t],
        ]),
      );
}

/// A five-point star path.
Path starPath(Offset c, double outer, double inner) {
  final p = Path();
  for (var k = 0; k < 10; k++) {
    final r = k.isEven ? outer : inner;
    final a = -pi / 2 + k * pi / 5;
    final o = c + Offset(cos(a), sin(a)) * r;
    k == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
  }
  return p..close();
}

/// A chubby game star, gold when [filled].
class StarIcon extends StatelessWidget {
  const StarIcon({super.key, this.size = 40, this.filled = true});

  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) => SizedBox.square(dimension: size, child: CustomPaint(painter: _StarPainter(filled)));
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.filled);

  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = min(size.width, size.height);
    final c = size.center(Offset(0, s * 0.04));
    final path = starPath(c, s * 0.48, s * 0.25);
    final join = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = s * 0.12;
    if (!filled) {
      canvas.drawPath(path, join..color = const Color(0x44000000));
      canvas.drawPath(path, Paint()..color = const Color(0x55000000));
      return;
    }
    canvas.drawPath(path.shift(Offset(0, s * 0.05)), join..color = const Color(0xFFD38A12));
    canvas.drawPath(path, join..color = const Color(0xFFE59A12));
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFEC8A), Color(0xFFFFC21E)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(starPath(c - Offset(s * 0.04, s * 0.06), s * 0.2, s * 0.09), Paint()..color = Colors.white.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.filled != filled;
}

/// Three star slots; earned stars slam in one by one with a sparkle burst.
class StarRow extends StatefulWidget {
  const StarRow({super.key, required this.stars, this.size = 52, this.animate = true, this.delay = const Duration(milliseconds: 350)});

  final int stars;
  final double size;
  final bool animate;
  final Duration delay;

  @override
  State<StarRow> createState() => _StarRowState();
}

class _StarRowState extends State<StarRow> with SingleTickerProviderStateMixin {
  static const _each = 0.26;
  late final _c = AnimationController(
    vsync: this,
    duration: widget.delay + Duration(milliseconds: 380 * widget.stars + 500),
  );
  final _played = <int>{};

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _c.addListener(_sounds);
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  double _startOf(int i) {
    final total = _c.duration!.inMilliseconds;
    return (widget.delay.inMilliseconds + 380 * i) / total;
  }

  void _sounds() {
    for (var i = 0; i < widget.stars; i++) {
      if (!_played.contains(i) && _c.value >= _startOf(i) + _each * 0.5) {
        _played.add(i);
        Services.of(context).sound.play(Sfx.place);
        HapticFeedback.lightImpact();
      }
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == 1 ? s * 0.22 : 0, left: 2, right: 2),
            child: SizedBox.square(
              dimension: i == 1 ? s * 1.18 : s,
              child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                StarIcon(size: i == 1 ? s * 1.18 : s, filled: false),
                if (i < widget.stars) ...[
                  _burst(i, s),
                  _star(i, i == 1 ? s * 1.18 : s),
                ],
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _star(int i, double size) {
    final local = ((_c.value - _startOf(i)) / _each).clamp(0.0, 1.0);
    if (local <= 0) return const SizedBox.shrink();
    final scale = local < 0.55 ? 2.6 - 1.75 * Curves.easeIn.transform(local / 0.55) : 0.85 + 0.15 * Curves.elasticOut.transform((local - 0.55) / 0.45);
    return Opacity(
      opacity: (local * 3).clamp(0.0, 1.0),
      child: Transform.rotate(angle: (1 - local) * -0.8, child: Transform.scale(scale: scale, child: StarIcon(size: size))),
    );
  }

  Widget _burst(int i, double s) {
    final t = ((_c.value - _startOf(i) - _each * 0.5) / 0.3).clamp(0.0, 1.0);
    if (t <= 0 || t >= 1) return const SizedBox.shrink();
    return Positioned(
      left: -s,
      top: -s,
      right: -s,
      bottom: -s,
      child: IgnorePointer(child: CustomPaint(painter: SparklePainter(t, seed: i))),
    );
  }
}

/// A burst of little sparkles flying out from the center, for t in 0..1.
class SparklePainter extends CustomPainter {
  SparklePainter(this.t, {this.seed = 0, this.color = const Color(0xFFFFE066), this.count = 10});

  final double t;
  final int seed;
  final Color color;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = Random(seed);
    final reach = min(size.width, size.height) / 2;
    final fade = 1 - t;
    for (var k = 0; k < count; k++) {
      final a = k * 2 * pi / count + r.nextDouble() * 0.5;
      final d = reach * (0.35 + 0.65 * Curves.easeOut.transform(t)) * (0.7 + r.nextDouble() * 0.3);
      final p = c + Offset(cos(a), sin(a)) * d;
      final s = reach * 0.1 * fade * (0.6 + r.nextDouble() * 0.6);
      final paint = Paint()..color = (k.isEven ? color : Colors.white).withValues(alpha: fade);
      canvas.drawPath(starPath(p, s, s * 0.4), paint);
    }
  }

  @override
  bool shouldRepaint(SparklePainter old) => old.t != t;
}

/// A rounded paper dialog with a wooden title plaque.
Future<T?> showSoftDialog<T>(
  BuildContext context, {
  required String title,
  String? body,
  Widget? content,
  String? emoji,
  required List<Widget> actions,
}) =>
    showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: activeWorld.palette.barrier,
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (context, a, _, child) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack), child: child),
      ),
      pageBuilder: (context, _, _) => SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Material(
                type: MaterialType.transparency,
                child: SoftCard(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    if (emoji != null) Text(emoji, style: const TextStyle(fontSize: 46)),
                    if (emoji != null) const SizedBox(height: 6),
                    Text(title, textAlign: TextAlign.center, style: chunky(24)),
                    if (body != null) ...[
                      const SizedBox(height: 8),
                      Text(body, textAlign: TextAlign.center, style: chunky(16, color: inkSoft, weight: FontWeight.w500)),
                    ],
                    if (content != null) ...[const SizedBox(height: 12), content],
                    const SizedBox(height: 14),
                    for (final a in actions) Padding(padding: const EdgeInsets.only(top: 8), child: a),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );

/// Is the ambient (looping) motion on? Re-exported for screens that only import widgets.
bool motionOn(BuildContext context) => ambientMotion(context);
