import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sound_service.dart';
import 'meadow.dart';
import 'services.dart';
import 'widgets.dart';

/// Center of a laid-out widget, in global coordinates.
Offset? centerOf(GlobalKey key) {
  final box = key.currentContext?.findRenderObject() as RenderBox?;
  if (box == null || !box.attached || !box.hasSize) return null;
  return box.localToGlobal(box.size.center(Offset.zero));
}

/// Coins fly in an arc from [from] to [to], with a coin tick on each landing; [onArrive] gets the landed count.
Future<void> flyCoins(
  BuildContext context, {
  required GlobalKey from,
  required GlobalKey to,
  int coins = 8,
  void Function(int landed)? onArrive,
}) async {
  final sound = Services.of(context).sound;
  final start = centerOf(from), end = centerOf(to);
  if (!ambientMotion(context) || start == null || end == null) {
    sound.play(Sfx.coin);
    onArrive?.call(coins);
    return;
  }
  final overlay = Overlay.of(context);
  final done = Completer<void>();
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _CoinFlight(
      start: start,
      end: end,
      coins: coins,
      size: 30 * UiScale.of(context),
      onArrive: (n) {
        sound.play(Sfx.coin);
        HapticFeedback.selectionClick();
        onArrive?.call(n);
      },
      onDone: () {
        entry.remove();
        done.complete();
      },
    ),
  );
  overlay.insert(entry);
  return done.future;
}

class _CoinFlight extends StatefulWidget {
  const _CoinFlight({
    required this.start,
    required this.end,
    required this.coins,
    required this.size,
    required this.onArrive,
    required this.onDone,
  });

  final Offset start, end;
  final int coins;
  final double size;
  final void Function(int landed) onArrive;
  final VoidCallback onDone;

  @override
  State<_CoinFlight> createState() => _CoinFlightState();
}

class _CoinFlightState extends State<_CoinFlight> with SingleTickerProviderStateMixin {
  static const _flight = 0.5;
  late final _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (900 + widget.coins * 90).clamp(900, 2000)),
  );
  late final List<Offset> _spread;
  int _landed = 0;

  @override
  void initState() {
    super.initState();
    final r = Random(5);
    _spread = [for (var i = 0; i < widget.coins; i++) Offset((r.nextDouble() - 0.5) * 90, (r.nextDouble() - 0.5) * 60)];
    _c.addListener(_check);
    _c.forward().whenComplete(() {
      if (_landed < widget.coins) widget.onArrive(widget.coins);
      widget.onDone();
    });
  }

  double _t(int i) {
    final s = widget.coins <= 1 ? 0.0 : i / (widget.coins - 1) * (1 - _flight);
    return ((_c.value - s) / _flight).clamp(0.0, 1.0);
  }

  void _check() {
    var landed = 0;
    for (var i = 0; i < widget.coins; i++) {
      if (_t(i) >= 1) landed++;
    }
    if (landed != _landed) {
      _landed = landed;
      widget.onArrive(landed);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(children: [
          for (var i = 0; i < widget.coins; i++)
            if (_t(i) > 0 && _t(i) < 1) _coin(i),
        ]),
      ),
    );
  }

  Widget _coin(int i) {
    final t = _t(i);
    // Burst out a little, then swoop to the counter.
    final burst = widget.start + _spread[i] * Curves.easeOut.transform((t / 0.25).clamp(0, 1));
    final k = Curves.easeInCubic.transform(((t - 0.15) / 0.85).clamp(0, 1));
    final control = Offset((burst.dx + widget.end.dx) / 2 + 60, min(burst.dy, widget.end.dy) - 80);
    final p = _bezier(burst, control, widget.end, k);
    final s = widget.size * (1 - 0.25 * k);
    return Positioned(
      left: p.dx - s / 2,
      top: p.dy - s / 2,
      child: Transform.rotate(angle: t * 4, child: CoinIcon(size: s)),
    );
  }

  static Offset _bezier(Offset a, Offset b, Offset c, double t) => a * ((1 - t) * (1 - t)) + b * (2 * (1 - t) * t) + c * (t * t);
}
