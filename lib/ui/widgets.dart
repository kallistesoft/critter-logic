import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sound_service.dart';
import 'palette.dart';
import 'services.dart';

/// Chunky, friendly type.
TextStyle chunky(double size, {Color color = ink, FontWeight weight = FontWeight.w900, double? height}) =>
    TextStyle(color: color, fontSize: size, fontWeight: weight, height: height, letterSpacing: -0.2);

/// Centers screen content at phone width, also on tablets.
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({super.key, required this.child, this.maxWidth = 480});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Center(
          child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child),
        ),
      );
}

/// Squishes a little under the finger, plays a tap and a light haptic.
class Bouncy extends StatefulWidget {
  const Bouncy({super.key, required this.child, this.onTap, this.sound = true});

  final Widget child;
  final VoidCallback? onTap;
  final bool sound;

  @override
  State<Bouncy> createState() => _BouncyState();
}

class _BouncyState extends State<Bouncy> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTap: enabled
          ? () {
              if (widget.sound) Services.of(context).sound.play(Sfx.tap);
              HapticFeedback.selectionClick();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.94 : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// White rounded card with a soft shadow.
class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.color = surface, this.padding = const EdgeInsets.all(16), this.onTap, this.border});

  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: border == null ? null : Border.all(color: border!, width: 2.5),
        boxShadow: const [BoxShadow(color: shadow, blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: child,
    );
    return onTap == null ? card : Bouncy(onTap: onTap, child: card);
  }
}

/// Big pill button with a darker "ledge" under it, so it looks pressable.
class ChunkyButton extends StatelessWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = accent,
    this.textColor = Colors.white,
    this.expand = false,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color color;
  final Color textColor;
  final bool expand;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = onPressed == null ? color.withValues(alpha: 0.45) : color;
    final ledge = Color.lerp(c, Colors.black, 0.18)!;
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[icon!, SizedBox(width: small ? 6 : 8)],
        Flexible(
          child: Text(label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: chunky(small ? 15 : 18, color: textColor, weight: FontWeight.w800)),
        ),
      ],
    );
    return Bouncy(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: small ? 16 : 22, vertical: small ? 10 : 15),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [BoxShadow(color: ledge, offset: const Offset(0, 4))],
        ),
        child: content,
      ),
    );
  }
}

/// Small rounded counter: 🔥 5, 🪙 120…
class StatPill extends StatelessWidget {
  const StatPill({super.key, required this.emoji, required this.text, this.color = surface, this.textColor = ink, this.onTap});

  final String emoji;
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(40),
        boxShadow: const [BoxShadow(color: shadow, blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(text, style: chunky(16, color: textColor, weight: FontWeight.w800)),
      ]),
    );
    return onTap == null ? pill : Bouncy(onTap: onTap, child: pill);
  }
}

/// Round white icon button (back, settings…).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onPressed, this.tooltip, this.size = 44});

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final button = Bouncy(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: surface,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: shadow, blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Icon(icon, color: ink, size: size * 0.55),
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
        constraints: const BoxConstraints(minWidth: 22),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: bad,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: surface, width: 2),
        ),
        child: Text('$count', textAlign: TextAlign.center, style: chunky(12, color: Colors.white)),
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

/// A rounded dialog in the app's style.
Future<T?> showSoftDialog<T>(
  BuildContext context, {
  required String title,
  String? body,
  Widget? content,
  String? emoji,
  required List<Widget> actions,
}) =>
    showDialog<T>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (emoji != null) Text(emoji, style: const TextStyle(fontSize: 44)),
            if (emoji != null) const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: chunky(22)),
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center, style: chunky(15, color: inkSoft, weight: FontWeight.w600)),
            ],
            if (content != null) ...[const SizedBox(height: 12), content],
            const SizedBox(height: 18),
            for (final a in actions) Padding(padding: const EdgeInsets.only(top: 8), child: a),
          ]),
        ),
      ),
    );
