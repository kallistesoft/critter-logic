import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sound_service.dart';
import 'meadow.dart';
import 'palette.dart';
import 'services.dart';

/// Chunky, friendly type in the rounded display font.
TextStyle chunky(double size, {Color color = ink, FontWeight weight = FontWeight.w700, double? height}) => TextStyle(
      fontFamily: displayFont,
      color: color,
      fontSize: size,
      fontWeight: weight.value >= 700 ? FontWeight.w700 : (weight.value >= 600 ? FontWeight.w600 : FontWeight.w500),
      height: height,
      letterSpacing: 0.1,
    );

/// A cartoon outline around text, made of shadows (so it stays a single [Text]).
List<Shadow> outline(Color color, double width, {double drop = 1.8}) => [
      for (var k = 0; k < 8; k++)
        Shadow(color: color, offset: Offset(cos(k * pi / 4) * width, sin(k * pi / 4) * width)),
      Shadow(color: color, offset: Offset(0, width * drop)),
    ];

/// Light text with a dark cartoon outline, for titles over the sky and on candy buttons.
TextStyle outlinedText(double size, {Color color = Colors.white, Color stroke = woodEdge, double? width}) =>
    chunky(size, color: color).copyWith(shadows: outline(stroke, width ?? max(1.5, size * 0.07)));

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
    final Widget card;
    if (style == PanelStyle.wood) {
      card = CustomPaint(painter: const WoodPainter(), child: Padding(padding: padding, child: child));
    } else {
      final fill = color ?? paper;
      final edge = border ?? Color.lerp(fill, woodDark, 0.32)!;
      card = Container(
        padding: padding,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: border ?? paperEdge, width: border == null ? 2.5 : 3.5),
          boxShadow: [
            BoxShadow(color: edge, offset: const Offset(0, 5)),
            const BoxShadow(color: shadow, blurRadius: 14, offset: Offset(0, 9)),
          ],
        ),
        child: child,
      );
    }
    return onTap == null ? card : Bouncy(onTap: onTap, child: card);
  }
}

/// Wood planks with seams, grain and nails.
class WoodPainter extends CustomPainter {
  const WoodPainter({this.radius = 18, this.nails = true, this.plank = 34});

  final double radius;
  final bool nails;
  final double plank;

  @override
  void paint(Canvas canvas, Size size) {
    final rr = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius));
    canvas.drawRRect(rr.shift(const Offset(0, 9)), Paint()
      ..color = shadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    canvas.drawRRect(rr.shift(const Offset(0, 5)), Paint()..color = woodEdge);
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [woodLight, wood],
        ).createShader(Offset.zero & size),
    );
    canvas.save();
    canvas.clipRRect(rr);
    final seam = Paint()
      ..color = woodDark.withValues(alpha: 0.55)
      ..strokeWidth = 2;
    final grain = Paint()
      ..color = woodDark.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final rows = max(1, (size.height / plank).round());
    final ph = size.height / rows;
    final r = Random(size.width.round() * 31 + size.height.round());
    for (var i = 0; i < rows; i++) {
      final y = i * ph;
      if (i > 0) canvas.drawLine(Offset(0, y), Offset(size.width, y), seam);
      canvas.drawLine(Offset(0, y + 1.5), Offset(size.width, y + 1.5), Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..strokeWidth = 1.5);
      for (var g = 0; g < 2; g++) {
        final gy = y + ph * (0.3 + 0.4 * r.nextDouble());
        final x0 = r.nextDouble() * size.width * 0.5;
        final path = Path()
          ..moveTo(x0, gy)
          ..quadraticBezierTo(x0 + size.width * 0.2, gy - 3, x0 + size.width * 0.45, gy + 1);
        canvas.drawPath(path, grain);
      }
    }
    canvas.restore();
    canvas.drawRRect(rr.deflate(1.5), Paint()
      ..color = woodEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    canvas.drawRRect(rr.deflate(4.5), Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    if (nails && size.width > 60 && size.height > 40) {
      for (final o in [
        Offset(11, 11),
        Offset(size.width - 11, 11),
        Offset(11, size.height - 11),
        Offset(size.width - 11, size.height - 11),
      ]) {
        canvas.drawCircle(o, 3.2, Paint()..color = woodEdge);
        canvas.drawCircle(o - const Offset(0.8, 0.8), 1.3, Paint()..color = Colors.white.withValues(alpha: 0.5));
      }
    }
  }

  @override
  bool shouldRepaint(WoodPainter old) => old.radius != radius || old.nails != nails || old.plank != plank;
}

/// The face and edge colors of a candy button for a base color.
Color edgeOf(Color c) => Color.lerp(c, const Color(0xFF3A2010), 0.32)!;

/// Chunky 3D "candy" button: thick darker edge, glossy top, squashes when pressed and springs back.
class ChunkyButton extends StatelessWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = leaf,
    this.edge,
    this.textColor = Colors.white,
    this.expand = false,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color color;
  final Color? edge;
  final Color textColor;
  final bool expand;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final face = enabled ? color : Color.lerp(color, const Color(0xFFBDB3A6), 0.65)!;
    final rim = enabled ? (edge ?? edgeOf(color)) : edgeOf(face);
    final light = textColor.computeLuminance() > 0.5;
    final fontSize = small ? 16.0 : 20.0;
    final depth = small ? 4.0 : 6.0;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, SizedBox(width: small ? 6 : 8)],
        Flexible(
          child: Text(label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: light
                  ? outlinedText(fontSize, color: textColor, stroke: rim, width: 1.6)
                  : chunky(fontSize, color: textColor)),
        ),
      ],
    );
    return Bouncy(
      onTap: onPressed,
      builder: (context, p, child) {
        final pressed = p.clamp(0.0, 1.0);
        return CustomPaint(
          painter: CandyPainter(face: face, edge: rim, press: pressed, depth: depth, radius: small ? 16 : 20),
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

/// Paints a candy button: dark outline, thick bottom edge, gradient face and a glossy highlight.
class CandyPainter extends CustomPainter {
  const CandyPainter({required this.face, required this.edge, this.press = 0, this.depth = 6, this.radius = 20, this.circle = false});

  final Color face;
  final Color edge;
  final double press;
  final double depth;
  final double radius;
  final bool circle;

  @override
  void paint(Canvas canvas, Size size) {
    final r = circle ? size.height / 2 : radius;
    final outer = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(r));
    final top = depth * press;
    final faceRect = RRect.fromLTRBR(0, top, size.width, size.height - depth + top, Radius.circular(r));
    canvas.drawRRect(outer.shift(const Offset(0, 3)), Paint()
      ..color = shadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawRRect(outer, Paint()..color = edge);
    canvas.drawRRect(
      faceRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(face, Colors.white, 0.28)!, face],
        ).createShader(faceRect.outerRect),
    );
    // Gloss on the upper half.
    final g = faceRect.outerRect;
    final gloss = RRect.fromLTRBR(g.left + r * 0.45, g.top + 3, g.right - r * 0.45, g.top + g.height * 0.45, Radius.circular(r));
    canvas.drawRRect(gloss, Paint()..color = Colors.white.withValues(alpha: 0.28));
    canvas.drawRRect(outer.deflate(1), Paint()
      ..color = Color.lerp(edge, Colors.black, 0.25)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(CandyPainter old) =>
      old.face != face || old.edge != edge || old.press != press || old.depth != depth || old.radius != radius;
}

/// Pill badge for the HUD (coins, streak, timer…): a cream pill with an icon on the left.
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    this.emoji,
    this.icon,
    required this.text,
    this.color = paper,
    this.textColor = ink,
    this.onTap,
    this.big = false,
  });

  final String? emoji;
  final Widget? icon;
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final h = big ? 44.0 : 38.0;
    final pill = Container(
      height: h,
      padding: EdgeInsets.only(left: 5, right: big ? 16 : 13),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(h),
        border: Border.all(color: woodEdge.withValues(alpha: 0.75), width: 2.5),
        boxShadow: const [BoxShadow(color: shadow, offset: Offset(0, 3), blurRadius: 3)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox.square(
          dimension: h - 10,
          child: icon ?? FittedBox(child: Text(emoji ?? '', style: const TextStyle(fontSize: 22))),
        ),
        const SizedBox(width: 6),
        Text(text, style: chunky(big ? 20 : 17, color: textColor)),
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
    canvas.drawCircle(c + Offset(0, s * 0.05), s * 0.46, Paint()..color = goldEdge);
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

/// The streak flame.
class FlameIcon extends StatelessWidget {
  const FlameIcon({super.key, this.size = 28, this.lit = true});

  final double size;
  final bool lit;

  @override
  Widget build(BuildContext context) => SizedBox.square(dimension: size, child: CustomPaint(painter: _FlamePainter(lit)));
}

class _FlamePainter extends CustomPainter {
  const _FlamePainter(this.lit);

  final bool lit;

  Path _flame(Size size, double k) {
    final w = size.width, h = size.height;
    final cx = w / 2;
    return Path()
      ..moveTo(cx, h * (0.04 + (1 - k) * 0.4))
      ..cubicTo(cx + w * 0.42 * k, h * 0.35, cx + w * 0.44 * k, h * 0.95, cx, h * 0.96)
      ..cubicTo(cx - w * 0.44 * k, h * 0.95, cx - w * 0.42 * k, h * 0.5, cx - w * 0.1 * k, h * 0.42)
      ..cubicTo(cx - w * 0.05, h * 0.3, cx, h * 0.2, cx, h * (0.04 + (1 - k) * 0.4))
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final outer = lit ? const Color(0xFFFF6B2C) : const Color(0xFFFFB892);
    final inner = lit ? const Color(0xFFFFC93C) : const Color(0xFFFFE6C8);
    canvas.drawPath(_flame(size, 1), Paint()..color = outer);
    canvas.save();
    canvas.translate(0, size.height * 0.12);
    canvas.drawPath(_flame(size, 0.6), Paint()..color = inner);
    canvas.restore();
    canvas.drawPath(_flame(size, 1), Paint()
      ..color = lit ? const Color(0xFFC2410C) : const Color(0xFFD9895F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1, size.width * 0.06));
  }

  @override
  bool shouldRepaint(_FlamePainter old) => old.lit != lit;
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
  const RoundIconButton({super.key, required this.icon, required this.onPressed, this.tooltip, this.size = 48, this.color = sky});

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final depth = size * 0.1;
    final button = Bouncy(
      onTap: onPressed,
      builder: (context, p, child) {
        final pressed = p.clamp(0.0, 1.0);
        return CustomPaint(
          painter: CandyPainter(face: color, edge: edgeOf(color), press: pressed, depth: depth, circle: true),
          child: SizedBox(
            width: size,
            height: size + depth,
            child: Padding(padding: EdgeInsets.only(top: depth * pressed, bottom: depth * (1 - pressed)), child: child),
          ),
        );
      },
      child: Center(
        child: Icon(icon, color: Colors.white, size: size * 0.56, shadows: [Shadow(color: edgeOf(color), offset: const Offset(0, 2))]),
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
          boxShadow: const [BoxShadow(color: shadow, offset: Offset(0, 2))],
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

/// The "Critter Logic" wooden sign hanging from two ropes.
class WoodSign extends StatelessWidget {
  const WoodSign({super.key, required this.title, this.subtitle, this.fontSize = 40});

  final String title;
  final String? subtitle;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const _SignPainter(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(30, 34, 30, subtitle == null ? 18 : 14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(title, textAlign: TextAlign.center, style: outlinedText(fontSize, color: const Color(0xFFFFF4D6), stroke: woodEdge, width: 2.6)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, textAlign: TextAlign.center, style: chunky(15, color: const Color(0xFFFFE9C2), weight: FontWeight.w600)),
          ],
        ]),
      ),
    );
  }
}

class _SignPainter extends CustomPainter {
  const _SignPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const top = 22.0;
    final board = Rect.fromLTWH(0, top, size.width, size.height - top - 4);
    // Ropes up to the top edge.
    final rope = Paint()
      ..color = const Color(0xFFB88A55)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final x in [size.width * 0.18, size.width * 0.82]) {
      canvas.drawLine(Offset(x, 0), Offset(x, top + 10), rope);
      canvas.drawLine(Offset(x, 0), Offset(x, top + 10), Paint()
        ..color = const Color(0xFF8A6238)
        ..strokeWidth = 1.2);
      canvas.drawCircle(Offset(x, 2), 4, Paint()..color = woodEdge);
    }
    canvas.save();
    canvas.translate(board.left, board.top);
    const WoodPainter(radius: 22, plank: 30).paint(canvas, board.size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SignPainter old) => false;
}

/// A wooden plaque with a title, for screen headers.
class WoodLabel extends StatelessWidget {
  const WoodLabel({super.key, required this.text, this.subtitle, this.fontSize = 22});

  final String text;
  final String? subtitle;
  final double fontSize;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: const WoodPainter(radius: 16, nails: false, plank: 60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: outlinedText(fontSize, color: const Color(0xFFFFF4D6), stroke: woodEdge, width: 2)),
            if (subtitle != null)
              Text(subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: chunky(14, color: const Color(0xFFFFE6BC), weight: FontWeight.w600)),
          ]),
        ),
      );
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
    canvas.drawPath(path.shift(Offset(0, s * 0.05)), join..color = goldEdge);
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
      barrierColor: const Color(0x664A3426),
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
