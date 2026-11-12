import 'dart:async';
import 'worlds/world.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sound_service.dart';
import '../services/stats_store.dart';
import 'cosmetics.dart';
import 'critter_image.dart';
import 'meadow.dart';
import 'services.dart';

/// Critters to show around the UI: the player's own first, topped up with the starter friends.
List<String> buddyCritters(StatsStore stats, int count, {int seed = 0}) {
  final owned = stats.owned.toList()..sort();
  if (owned.isNotEmpty) {
    final r = Random(seed);
    owned.shuffle(r);
  }
  final out = <String>[...owned.take(count)];
  for (final id in const ['chick', 'frog', 'panda', 'pig', 'rabbit']) {
    if (out.length >= count) break;
    if (!out.contains(id)) out.add(id);
  }
  return out;
}

/// A living critter: breathes, hops and tilts its head now and then, and jumps with a squash when tapped.
class CritterBuddy extends StatefulWidget {
  const CritterBuddy(
    this.id, {
    super.key,
    required this.size,
    this.tappable = true,
    this.cheer = false,
    this.seed = 0,
    this.shadow = true,
    this.hat = true,
  });

  final String id;
  final double size;
  final bool tappable;

  /// Celebrating: hops in a loop (while motion is on).
  final bool cheer;
  final int seed;
  final bool shadow;

  /// Wears the equipped shop hat.
  final bool hat;

  @override
  State<CritterBuddy> createState() => _CritterBuddyState();
}

enum _Act { hop, tilt, jump }

class _CritterBuddyState extends State<CritterBuddy> with TickerProviderStateMixin {
  late final _breath = AnimationController(vsync: this, duration: Duration(milliseconds: 2200 + widget.seed * 170 % 600));
  late final _act = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
  _Act _kind = _Act.hop;
  Timer? _timer;
  late final _random = Random(widget.seed * 7919 + widget.id.hashCode);
  bool _motion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = ambientMotion(context);
    if (motion == _motion) return;
    _motion = motion;
    if (motion) {
      _breath.repeat(reverse: true);
      _schedule();
    } else {
      _breath.stop();
      _timer?.cancel();
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (!_motion) return;
    final wait = widget.cheer ? 250 + _random.nextInt(500) : 1800 + _random.nextInt(4200);
    _timer = Timer(Duration(milliseconds: wait), () {
      if (!mounted) return;
      _play(widget.cheer || _random.nextDouble() < 0.55 ? _Act.hop : _Act.tilt);
    });
  }

  Future<void> _play(_Act kind) async {
    _kind = kind;
    _act.duration = Duration(milliseconds: switch (kind) { _Act.hop => 560, _Act.tilt => 900, _Act.jump => 750 });
    await _act.forward(from: 0).orCancel.catchError((_) {});
    if (mounted) _schedule();
  }

  void _tap() {
    Services.of(context).sound.play(Sfx.place);
    HapticFeedback.lightImpact();
    if (_motion) {
      _timer?.cancel();
      _play(_Act.jump);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _breath.dispose();
    _act.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final image = RepaintBoundary(
      child: widget.hat
          ? HattedCritter(widget.id, size: s, role: CritterRole.decoration)
          : CritterImage(widget.id, size: s, role: CritterRole.decoration),
    );
    final body = AnimatedBuilder(
      animation: Listenable.merge([_breath, _act]),
      child: image,
      builder: (context, child) {
        final b = Curves.easeInOut.transform(_breath.value);
        // Breathing: a touch taller and narrower on the in-breath.
        var sx = 1 - 0.015 * b, sy = 1 + 0.035 * b;
        var dy = 0.0, angle = 0.0;
        final t = _act.value;
        if (_act.isAnimating || (t > 0 && t < 1)) {
          switch (_kind) {
            case _Act.tilt:
              angle = sin(t * pi * 3) * 0.16 * (1 - t);
            case _Act.hop:
            case _Act.jump:
              final high = _kind == _Act.jump ? 0.75 : 0.32;
              // Crouch (0–.2), fly (.2–.75), land squash (.75–1).
              if (t < 0.2) {
                final k = sin(t / 0.2 * pi / 2);
                sx = 1 + 0.18 * k;
                sy = 1 - 0.2 * k;
              } else if (t < 0.75) {
                final k = (t - 0.2) / 0.55;
                dy = -sin(k * pi) * s * high;
                sx = 1 - 0.1 * sin(k * pi);
                sy = 1 + 0.14 * sin(k * pi);
                if (_kind == _Act.jump) angle = sin(k * pi * 2) * 0.12;
              } else {
                final k = (t - 0.75) / 0.25;
                final sq = sin(k * pi) * (1 - k * 0.3);
                sx = 1 + 0.16 * sq;
                sy = 1 - 0.15 * sq;
              }
          }
        }
        final lift = (-dy / (s * 0.75)).clamp(0.0, 1.0);
        return SizedBox(
          width: s,
          height: s * 1.08,
          child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
            if (widget.shadow)
              Positioned(
                bottom: 0,
                child: Container(
                  width: s * 0.7 * (1 - 0.4 * lift),
                  height: s * 0.12 * (1 - 0.4 * lift),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.16 * (1 - 0.5 * lift)),
                    borderRadius: BorderRadius.all(Radius.elliptical(s * 0.35, s * 0.06)),
                  ),
                ),
              ),
            Positioned(
              bottom: s * 0.04,
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()
                    ..rotateZ(angle)
                    ..scaleByDouble(sx, sy, 1, 1),
                  child: child,
                ),
              ),
            ),
          ]),
        );
      },
    );
    return widget.tappable ? GestureDetector(behavior: HitTestBehavior.opaque, onTap: _tap, child: body) : body;
  }
}
