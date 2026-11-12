import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../meta/album.dart';
import 'capsule_screen.dart';
import 'critter_image.dart';
import 'navigation.dart';
import 'palette.dart';
import 'services.dart';
import 'widgets.dart';

const setEmoji = {'farm': '🌾', 'friends': '🏡', 'savanna': '🌍', 'jungle': '🌴', 'polar': '❄️'};

/// The collection: 5 sets of 6 critters; missing ones as silhouettes.
class AlbumScreen extends StatefulWidget {
  const AlbumScreen({super.key});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  Future<void> _openCapsules() async {
    await Navigator.of(context).push(softRoute(const CapsuleScreen(fromAlbum: true)));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = Services.of(context).stats;
    final owned = stats.owned;
    final waiting = stats.capsules + stats.goldenCapsules;
    return Scaffold(
      backgroundColor: background,
      body: ScreenFrame(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
          Row(children: [
            RoundIconButton(icon: Icons.arrow_back_rounded, onPressed: () => Navigator.maybePop(context), tooltip: l10n.back),
            const SizedBox(width: 12),
            Expanded(child: Text(l10n.album, style: chunky(26))),
            StatPill(
              key: const Key('albumCount'),
              emoji: '📖',
              text: '${album.where((c) => owned.contains(c.id)).length}/${album.length}',
            ),
          ]),
          const SizedBox(height: 16),
          SoftCard(
            key: const Key('albumCapsules'),
            color: waiting > 0 ? accentSoft : surface,
            onTap: _openCapsules,
            child: Row(children: [
              const Text('🥚', style: TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(waiting > 0 ? l10n.capsulesWaiting(waiting) : l10n.capsulesHowTo,
                    style: chunky(15, weight: FontWeight.w800)),
              ),
              const Icon(Icons.chevron_right_rounded, color: inkSoft),
            ]),
          ),
          for (final set in albumSets) ...[
            const SizedBox(height: 16),
            _SetCard(set: set, owned: owned),
          ],
        ]),
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({required this.set, required this.owned});

  final String set;
  final Set<String> owned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final critters = album.where((c) => c.set == set).toList();
    final have = critters.where((c) => owned.contains(c.id)).length;
    final complete = have == critters.length;
    return SoftCard(
      key: Key('set-$set'),
      border: complete ? gold : null,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text(setEmoji[set] ?? '', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(child: Text(setName(l10n, set), style: chunky(19))),
          if (complete)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: gold, borderRadius: BorderRadius.circular(12)),
              child: Text('✓ ${l10n.setComplete}', style: chunky(13, color: Colors.white)),
            )
          else
            Text('$have/${critters.length}', style: chunky(15, color: inkSoft, weight: FontWeight.w800)),
        ]),
        const SizedBox(height: 12),
        LayoutBuilder(builder: (context, constraints) {
          const gap = 10.0;
          final w = (constraints.maxWidth - 2 * gap) / 3;
          return Wrap(spacing: gap, runSpacing: gap, children: [
            for (final c in critters) SizedBox(width: w, child: _CritterTile(critter: c, owned: owned.contains(c.id))),
          ]);
        }),
      ]),
    );
  }
}

class _CritterTile extends StatelessWidget {
  const _CritterTile({required this.critter, required this.owned});

  final Critter critter;
  final bool owned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (bg, frame) = switch (critter.rarity) {
      Rarity.golden => (goldSoft, gold),
      Rarity.rare => (rareSoft, rareBlue),
      Rarity.common => (tileEmpty, null),
    };
    Widget image = CritterImage(critter.id, size: 56);
    if (!owned) image = Silhouette(child: image);
    Widget tile = Container(
      height: 86,
      decoration: BoxDecoration(
        color: owned ? bg : tileEmpty,
        borderRadius: BorderRadius.circular(16),
        border: frame == null ? null : Border.all(color: owned ? frame : frame.withValues(alpha: 0.35), width: 3),
      ),
      child: Center(child: image),
    );
    if (owned && critter.rarity == Rarity.golden) tile = Shimmer(child: tile);
    return Column(children: [
      tile,
      const SizedBox(height: 4),
      Text(owned ? critterName(l10n, critter.id) : '???',
          key: Key('critter-${critter.id}'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: chunky(12, color: owned ? ink : inkSoft, weight: FontWeight.w800)),
    ]);
  }
}

/// A slow sweep of light across golden things.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (context, child) {
          final x = -1.5 + _c.value * 4;
          return Stack(children: [
            child!,
            Positioned.fill(
              child: IgnorePointer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(x - 0.5, -1),
                        end: Alignment(x + 0.5, 1),
                        colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.55), Colors.white.withValues(alpha: 0)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]);
        },
      );
}
