import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../meta/shop.dart';
import '../home_screen.dart';
import '../meadow.dart';
import '../navigation.dart';
import '../services.dart';
import '../widgets.dart';
import 'world.dart';
import 'world_preview.dart';

/// First launch: pick the free World to play in (Meadow or Wild Lodge), with live previews. Skipping keeps the
/// Meadow; either way it never shows again, and the shop's Worlds tab can switch any time.
class WelcomeWorldScreen extends StatefulWidget {
  const WelcomeWorldScreen({super.key});

  @override
  State<WelcomeWorldScreen> createState() => _WelcomeWorldScreenState();
}

class _WelcomeWorldScreenState extends State<WelcomeWorldScreen> {
  static final _choices = [
    for (final w in worlds)
      if (freeWorlds.contains(w.id)) w,
  ];
  String _picked = defaultWorld;

  Future<void> _finish(String? id) async {
    final services = Services.of(context);
    final host = WorldHost.of(context);
    final nav = Navigator.of(context);
    final shop = services.retention.shop;
    if (id != null) await shop.equip(id);
    await services.retention.progress.setWorldChosen();
    host.switchTo(worldById(shop.equippedWorld));
    nav.pushReplacement(softRoute(const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final world = worldOf(context);
    final picked = worldById(_picked);
    return MeadowScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: const Key('welcomeSkip'),
                onPressed: () => _finish(null),
                child: Text(l10n.welcomeWorldSkip, style: outlinedText(17, stroke: world.palette.woodEdge, width: 1.4)),
              ),
            ),
            WoodLabel(text: l10n.welcomeWorldTitle, fontSize: 26),
            const SizedBox(height: 10),
            Text(l10n.welcomeWorldBody, textAlign: TextAlign.center, style: outlinedText(16, width: 1.4)),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, w) in _choices.indexed) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(
                      child: _Choice(
                        key: Key('welcome-${w.id}'),
                        world: w,
                        selected: w.id == _picked,
                        onTap: () => setState(() => _picked = w.id),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            ChunkyButton(
              key: const Key('welcomeGo'),
              label: l10n.welcomeWorldGo(picked.name(l10n)),
              expand: true,
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
              onPressed: () => _finish(_picked),
            ),
          ],
        ),
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({super.key, required this.world, required this.selected, required this.onTap});

  final GameWorld world;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = activeWorld.palette;
    return Bouncy(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? p.gold : p.paper,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? p.goldEdge : p.paperEdge, width: 3),
          boxShadow: [BoxShadow(color: p.shadow, blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 380 / 600,
                  child: WorldMiniPreview(world: world),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(world.name(l10n), maxLines: 1, style: chunky(19, color: p.ink)),
            ),
            Text(
              world.blurb(l10n),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: chunky(12.5, color: p.inkSoft, weight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
