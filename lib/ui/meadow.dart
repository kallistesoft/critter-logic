import 'dart:math';

import 'package:flutter/material.dart';

import 'banner_slot.dart';
import 'services.dart';
import 'worlds/world.dart';

export 'worlds/meadow_world.dart' show meadowGround;

/// False when the player asked the system for reduced motion (and in widget tests): ambient loops stay still.
bool ambientMotion(BuildContext context) => ambientMotionOn(context);

/// The World every screen sits in: its landscape behind the navigator, so pages slide over the same background.
class WorldBackdrop extends StatelessWidget {
  const WorldBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final world = worldOf(context);
    return Stack(children: [
      Positioned.fill(child: KeyedSubtree(key: ValueKey(world.id), child: world.background(context))),
      Positioned.fill(child: child),
    ]);
  }
}

/// Lays a phone-sized layout out and scales it up on tablets, so cards, text and boards fill the screen.
class UiScale extends StatelessWidget {
  const UiScale({super.key, required this.child});

  final Widget child;

  static double factorFor(Size s) {
    if (s.width <= 520) return 1;
    final byWidth = min(s.width / 460, 1.65);
    final byHeight = max(1.0, s.height / 660);
    return min(byWidth, byHeight);
  }

  static double of(BuildContext context) => factorFor(MediaQuery.sizeOf(context));

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final s = factorFor(box.biggest);
        if (s <= 1.0001) return child;
        final inner = Size(box.maxWidth / s, box.maxHeight / s);
        return FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          child: SizedBox.fromSize(
            size: inner,
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(size: inner, padding: EdgeInsets.zero, viewPadding: EdgeInsets.zero),
              child: child,
            ),
          ),
        );
      });
}

/// A transparent screen over the meadow: safe area, tablet scaling, a centered column, and optionally the ad strip.
class MeadowScaffold extends StatelessWidget {
  const MeadowScaffold({super.key, required this.child, this.banner = false, this.overlays = const [], this.maxWidth = 480});

  final Widget child;
  final bool banner;
  final double maxWidth;

  /// Full-screen layers on top (confetti, win panel…), not scaled.
  final List<Widget> overlays;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(children: [
        Expanded(
          child: Stack(children: [
            Positioned.fill(
              child: SafeArea(
                bottom: !banner,
                child: UiScale(
                  child: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxWidth), child: child)),
                ),
              ),
            ),
            ...overlays,
          ]),
        ),
        if (banner) const BannerStrip(),
      ]),
    );
  }
}

/// The banner ad in its own strip (soil-colored in the Meadow), under the World.
class BannerStrip extends StatelessWidget {
  const BannerStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final services = Services.of(context);
    return ListenableBuilder(
      listenable: services.premium,
      builder: (context, _) {
        final empty = services.premium.isPremium || services.banner == null;
        final world = worldOf(context);
        return Container(
          decoration: BoxDecoration(
            color: empty ? Colors.transparent : world.bannerStrip,
            border: empty ? null : Border(top: BorderSide(color: world.bannerEdge, width: 4)),
          ),
          child: SafeArea(top: false, child: empty ? const SizedBox(width: double.infinity) : const BannerSlot()),
        );
      },
    );
  }
}
