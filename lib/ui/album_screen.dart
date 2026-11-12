
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../meta/album.dart';
import '../meta/economy.dart';
import '../meta/set_rewards.dart';
import 'capsule_screen.dart';
import 'cosmetics.dart';
import 'critter_image.dart';
import 'meadow.dart';
import 'navigation.dart';
import 'palette.dart';
import 'services.dart';
import 'widgets.dart';

const setEmoji = {'farm': '🌾', 'friends': '🏡', 'savanna': '🌍', 'jungle': '🌴', 'polar': '❄️'};

/// Paper tint of each set's scrapbook page.
const _pageTint = {
  'farm': Color(0xFFFFF6DE),
  'friends': Color(0xFFFFF0EC),
  'savanna': Color(0xFFFFF3D9),
  'jungle': Color(0xFFF0F8E4),
  'polar': Color(0xFFEFF6FC),
};

/// The collection as a scrapbook: one paper page per set, critters as taped photos; missing ones as silhouettes.
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
    final goldFrame = Services.of(context).retention.progress.cosmetics.contains('frame.album_gold');
    return MeadowScaffold(
      child: Column(children: [
        MeadowTopBar(
          title: l10n.album,
          backTooltip: l10n.back,
          trailing: [
            StatPill(
              key: const Key('albumCount'),
              icon: const Icon(Icons.menu_book_rounded, color: woodDark),
              text: '${album.where((c) => owned.contains(c.id)).length}/${album.length}',
            ),
          ],
        ),
        Expanded(
          child: ListView(padding: EdgeInsets.fromLTRB(16, 14, 16, 24 + MediaQuery.viewPaddingOf(context).bottom), children: [
            SoftCard(
              key: const Key('albumCapsules'),
              color: waiting > 0 ? goldSoft : paper,
              border: waiting > 0 ? gold : null,
              onTap: _openCapsules,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(children: [
                CapsuleEgg(size: 44, golden: stats.goldenCapsules > 0, dim: waiting == 0),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(waiting > 0 ? l10n.capsulesWaiting(waiting) : l10n.capsulesHowTo, style: chunky(16)),
                ),
                const Icon(Icons.chevron_right_rounded, color: woodDark, size: 30),
              ]),
            ),
            if (goldFrame) ...[
              const SizedBox(height: 16),
              _GoldBanner(text: l10n.albumCompleteTitle),
            ],
            const SizedBox(height: 6),
            Container(
              key: goldFrame ? const Key('albumGoldFrame') : null,
              padding: goldFrame ? const EdgeInsets.fromLTRB(10, 0, 10, 16) : EdgeInsets.zero,
              decoration: goldFrame
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: gold, width: 6),
                      gradient: const LinearGradient(colors: [Color(0x33FFE47A), Color(0x22FFC23D)]),
                      boxShadow: const [BoxShadow(color: goldEdge, offset: Offset(0, 4))],
                    )
                  : null,
              child: Column(children: [
                for (final (i, set) in albumSets.indexed) ...[
                  const SizedBox(height: 22),
                  SlideIn(
                    delay: Duration(milliseconds: 80 * i),
                    child: _SetPage(set: set, owned: owned, tilt: i.isEven ? -0.012 : 0.012),
                  ),
                ],
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _SetPage extends StatelessWidget {
  const _SetPage({required this.set, required this.owned, required this.tilt});

  final String set;
  final Set<String> owned;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final critters = album.where((c) => c.set == set).toList();
    final have = critters.where((c) => owned.contains(c.id)).length;
    final complete = have == critters.length;
    return Transform.rotate(
      angle: tilt,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          key: Key('set-$set'),
          padding: const EdgeInsets.fromLTRB(14, 30, 14, 14),
          decoration: BoxDecoration(
            color: _pageTint[set] ?? paper,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: complete ? gold : paperEdge, width: complete ? 3.5 : 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x22000000), offset: Offset(2, 6), blurRadius: 8),
              BoxShadow(color: paperEdge, offset: Offset(3, 3)),
            ],
          ),
          child: CustomPaint(
            painter: const _RuledPainter(),
            child: Column(children: [
              LayoutBuilder(builder: (context, constraints) {
                const gap = 12.0;
                final w = (constraints.maxWidth - 2 * gap) / 3;
                return Wrap(spacing: gap, runSpacing: gap, children: [
                  for (final (i, c) in critters.indexed)
                    SizedBox(width: w, child: _Photo(critter: c, owned: owned.contains(c.id), tilt: ((i * 37) % 5 - 2) * 0.02)),
                ]);
              }),
              const SizedBox(height: 12),
              _SetReward(set: set, complete: complete),
            ]),
          ),
        ),
        // Wooden name tag pinned at the top.
        Positioned(
          left: 12,
          top: -14,
          child: CustomPaint(
            painter: const WoodPainter(radius: 12, nails: false, plank: 80),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 12, 7),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(setEmoji[set] ?? '', style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(setName(l10n, set), style: outlinedText(18, color: const Color(0xFFFFF4D6))),
              ]),
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: -10,
          child: complete
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: gold,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: goldEdge, width: 2),
                  ),
                  child: Text('✓ ${l10n.setComplete}', style: outlinedText(13, stroke: goldEdge, width: 1.2)),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: paper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: paperEdge, width: 2),
                  ),
                  child: Text('$have/${critters.length}', style: chunky(15, color: woodDark)),
                ),
        ),
      ]),
    );
  }
}

/// What finishing the set gives: its coins and its hat; "Unlocked!" once done.
class _SetReward extends StatelessWidget {
  const _SetReward({required this.set, required this.complete});

  final String set;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hat = setUnlocks[set];
    final shownHat = hat != null && shownCosmetic(hat) ? hat : null;
    return Container(
      key: Key('setReward-$set'),
      padding: const EdgeInsets.fromLTRB(8, 6, 10, 6),
      decoration: BoxDecoration(
        color: complete ? goldSoft : Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: complete ? gold : paperEdge, width: 2),
      ),
      child: Row(children: [
        if (shownHat != null)
          SizedBox(width: 40, height: 32, child: CustomPaint(painter: HatPainter(shownHat)))
        else
          const CoinIcon(size: 28),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            l10n.setRewardLabel([
              l10n.rewardCoins(Economy.setComplete),
              if (shownHat != null) cosmeticName(l10n, shownHat),
            ].join(' · ')),
            style: chunky(14, color: woodDark, weight: FontWeight.w600),
          ),
        ),
        if (complete) Text(l10n.setUnlockedBadge, style: chunky(14, color: leafEdge)),
      ]),
    );
  }
}

class _GoldBanner extends StatelessWidget {
  const _GoldBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFE47A), gold]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: goldEdge, width: 2.5),
            boxShadow: const [BoxShadow(color: goldEdge, offset: Offset(0, 3))],
          ),
          child: Text('👑 $text', style: outlinedText(18, stroke: goldEdge, width: 1.4)),
        ),
      );
}

/// Faint ruled lines on a scrapbook page.
class _RuledPainter extends CustomPainter {
  const _RuledPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x147A5235)
      ..strokeWidth = 1;
    for (var y = 18.0; y < size.height; y += 22) {
      canvas.drawLine(Offset(-8, y), Offset(size.width + 8, y), line);
    }
  }

  @override
  bool shouldRepaint(_RuledPainter old) => false;
}

/// A critter photo taped on the page.
class _Photo extends StatelessWidget {
  const _Photo({required this.critter, required this.owned, required this.tilt});

  final Critter critter;
  final bool owned;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (bg, frame) = switch (critter.rarity) {
      Rarity.golden => (goldSoft, gold),
      Rarity.rare => (rareSoft, rareBlue),
      Rarity.common => (const Color(0xFFF1EADB), null),
    };
    Widget image = CritterImage(critter.id, size: 58);
    if (!owned) image = Silhouette(color: const Color(0x404A3426), child: image);
    Widget photo = Container(
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: frame == null ? null : Border.all(color: owned ? frame : frame.withValues(alpha: 0.3), width: 2.5),
        boxShadow: const [BoxShadow(color: Color(0x2A000000), offset: Offset(1, 3), blurRadius: 3)],
      ),
      child: Column(children: [
        Container(
          height: 70,
          decoration: BoxDecoration(color: owned ? bg : const Color(0xFFE8E2D6), borderRadius: BorderRadius.circular(2)),
          child: Center(child: image),
        ),
        const SizedBox(height: 3),
        Text(owned ? critterName(l10n, critter.id) : '???',
            key: Key('critter-${critter.id}'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: chunky(12, color: owned ? ink : inkSoft)),
      ]),
    );
    if (owned && critter.rarity == Rarity.golden) photo = Shimmer(child: photo);
    return Transform.rotate(
      angle: tilt,
      child: Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
        photo,
        // A strip of tape.
        Positioned(
          top: -6,
          child: Transform.rotate(
            angle: -tilt * 3 + 0.05,
            child: Container(
              width: 34,
              height: 12,
              decoration: BoxDecoration(color: const Color(0x99FFF1B8), borderRadius: BorderRadius.circular(2)),
            ),
          ),
        ),
      ]),
    );
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
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600), value: 0.3);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (ambientMotion(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

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
