import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../meta/album.dart';
import '../meta/game_flow.dart';
import '../puzzles/puzzle.dart';
import '../services/share_text.dart';
import '../services/stats_store.dart';
import '../services/sound_service.dart';
import 'album_screen.dart';
import 'capsule_screen.dart';
import 'critter_actor.dart';
import 'critter_image.dart';
import 'game/game_screen.dart';
import 'game/pairs_board.dart';
import 'level_path_screen.dart';
import 'meadow.dart';
import 'navigation.dart';
import 'palette.dart';
import 'remove_ads.dart';
import 'services.dart';
import 'settings_screen.dart';
import 'widgets.dart';

/// Home: today's dailies, streak, coins, levels, album and capsules, with critters playing on the grass.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(softRoute(screen));
    if (mounted) setState(() {});
  }

  Future<void> _play(GameKind kind, PlayMode mode) async {
    await openGame(context, kind, mode);
    if (mounted) setState(() {});
  }

  Future<void> _repair(int today) async {
    final services = Services.of(context);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (await services.ads.showRewarded()) {
      await services.stats.repairYesterday(today);
      services.analytics.adReward('repair');
      services.sound.play(Sfx.chest);
      messenger.showSnackBar(SnackBar(content: Text(l10n.streakRepaired)));
      if (mounted) setState(() {});
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l10n.noAdAvailable)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds when the home route becomes visible again, so stats shown here are fresh.
    ModalRoute.of(context);
    final services = Services.of(context);
    final stats = services.stats;
    final today = todayNumber(services.today());
    final l10n = AppLocalizations.of(context);
    final streak = stats.streak(today);
    final waiting = stats.capsules + stats.goldenCapsules;
    final owned = stats.owned;
    var order = 0;
    Widget enter(Widget child) => SlideIn(
      delay: Duration(milliseconds: 70 * order++),
      child: child,
    );

    return MeadowScaffold(
      banner: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                StatPill(
                  key: const Key('streak'),
                  icon: FlameIcon(lit: streak > 0),
                  text: l10n.streakDays(streak),
                  color: streak > 0 ? goldSoft : paper,
                ),
                const SizedBox(width: 8),
                CoinCounter(key: const Key('homeCoins'), value: stats.coins),
                const Spacer(),
                RoundIconButton(
                  key: const Key('settings'),
                  icon: Icons.settings_rounded,
                  color: woodButton,
                  tooltip: l10n.settings,
                  onPressed: () => _open(const SettingsScreen()),
                ),
              ],
            ),
          ),
          Expanded(
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white, Color(0x00FFFFFF)],
                stops: [0, 0.94, 1],
              ).createShader(r),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
                children: [
                  enter(
                    Center(
                      child: WoodSign(title: 'Critter Logic', subtitle: l10n.tagline, fontSize: 38),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (stats.canRepair(today)) ...[
                    enter(_RepairCard(onRepair: () => _repair(today))),
                    const SizedBox(height: 14),
                  ],
                  enter(_SectionTitle(text: l10n.todaysPuzzles, trailing: l10n.dailyTitle(today))),
                  const SizedBox(height: 8),
                  enter(
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final kind in GameKind.values) ...[
                            if (kind != GameKind.values.first) const SizedBox(width: 12),
                            Expanded(
                              child: _DailyCard(
                                key: Key('daily-${kind.name}'),
                                kind: kind,
                                result: stats.daily(kind, today),
                                onTap: () => _play(kind, PlayMode.daily),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (stats.allDailiesDone(today)) ...[
                    const SizedBox(height: 10),
                    Text(
                      l10n.allDailiesDone,
                      textAlign: TextAlign.center,
                      style: outlinedText(16, stroke: leafEdge),
                    ),
                  ],
                  const SizedBox(height: 18),
                  enter(_SectionTitle(text: l10n.levels)),
                  const SizedBox(height: 8),
                  enter(
                    Row(
                      children: [
                        for (final kind in GameKind.values) ...[
                          if (kind != GameKind.values.first) const SizedBox(width: 12),
                          Expanded(
                            child: _LevelCard(
                              key: Key('level-${kind.name}'),
                              kind: kind,
                              onTap: () => _open(LevelPathScreen(kind: kind)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  enter(
                    Row(
                      children: [
                        Expanded(
                          child: SoftCard(
                            key: const Key('album'),
                            padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                            onTap: () => _open(const AlbumScreen()),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 50,
                                  height: 44,
                                  child: Stack(
                                    children: [
                                      for (final (i, id) in buddyCritters(stats, 2, seed: 3).indexed)
                                        Positioned(left: i * 14.0, top: i * 6.0, child: CritterImage(id, size: 36)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.album, style: chunky(18), overflow: TextOverflow.ellipsis),
                                      Text(
                                        '${album.where((c) => owned.contains(c.id)).length}/${album.length}',
                                        style: chunky(14, color: inkSoft, weight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              SoftCard(
                                key: const Key('capsules'),
                                color: waiting > 0 ? goldSoft : paper,
                                border: waiting > 0 ? gold : null,
                                padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
                                onTap: () => _open(const CapsuleScreen()),
                                child: Row(
                                  children: [
                                    CapsuleEgg(size: 44, golden: stats.goldenCapsules > 0, dim: waiting == 0),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(l10n.capsules, style: chunky(18), overflow: TextOverflow.ellipsis),
                                          Text(
                                            waiting > 0 ? l10n.openNow : l10n.capsuleShort,
                                            overflow: TextOverflow.ellipsis,
                                            style: chunky(
                                              14,
                                              color: waiting > 0 ? coralEdge : inkSoft,
                                              weight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (waiting > 0)
                                Positioned(
                                  right: -6,
                                  top: -8,
                                  child: CountBadge(key: const Key('capsuleBadge'), count: waiting),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (!stats.reviewed)
                    Center(
                      child: TextButton.icon(
                        key: const Key('rate'),
                        onPressed: () async {
                          await stats.setReviewed(true);
                          await services.review.openStoreListing();
                          if (mounted) setState(() {});
                        },
                        icon: const StarIcon(size: 24),
                        label: Text(l10n.rateApp, style: outlinedText(16, stroke: woodEdge)),
                      ),
                    ),
                  RemoveAdsButtons(premium: services.premium),
                  if (services.privacyOptionsRequired != null)
                    ValueListenableBuilder(
                      valueListenable: services.privacyOptionsRequired!,
                      builder: (_, required, _) => required
                          ? TextButton(
                              key: const Key('privacy'),
                              onPressed: services.showPrivacyOptions,
                              child: Text(
                                l10n.privacyOptions,
                                style: chunky(14, color: ink, weight: FontWeight.w500),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
          ),
          _Mascots(ids: buddyCritters(stats, 4)),
        ],
      ),
    );
  }
}

/// White outlined section title over the sky, with an optional chip on the right.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: outlinedText(21, stroke: woodEdge),
        ),
      ),
      if (trailing != null)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: paper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: woodEdge.withValues(alpha: 0.7), width: 2),
          ),
          child: Text(trailing!, style: chunky(14, color: woodDark)),
        ),
    ],
  );
}

/// Critters playing on the grass at the bottom of the home screen.
class _Mascots extends StatelessWidget {
  const _Mascots({required this.ids});

  final List<String> ids;

  static const _sizes = [66.0, 84.0, 74.0, 62.0];

  @override
  Widget build(BuildContext context) {
    // Short phones get smaller critters, so the list keeps its room.
    final k = (MediaQuery.sizeOf(context).height / 820).clamp(0.72, 1.0);
    return SizedBox(
      height: 104 * k,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, id) in ids.indexed)
            Padding(
              padding: EdgeInsets.only(bottom: (i.isEven ? 4 : 12) * k),
              child: PopIn(
                delay: Duration(milliseconds: 350 + 120 * i),
                duration: const Duration(milliseconds: 650),
                child: CritterBuddy(id, key: Key('mascot-$i'), size: _sizes[i % _sizes.length] * k, seed: i),
              ),
            ),
        ],
      ),
    );
  }
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({super.key, required this.kind, required this.result, required this.onTap});

  final GameKind kind;
  final DailyResult? result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = result;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: kind == GameKind.nests
                    ? const [Color(0xFFDDF5C6), Color(0xFFB9E596)]
                    : const [Color(0xFFD6ECFF), Color(0xFFB4D8F7)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: paperEdge, width: 2),
            ),
            child: Center(child: kind == GameKind.nests ? const _NestsArt() : const _PairsArt()),
          ),
          const SizedBox(height: 8),
          Text(gameName(l10n, kind), textAlign: TextAlign.center, style: chunky(22)),
          const SizedBox(height: 6),
          if (r == null)
            ChunkyButton(
              label: l10n.play,
              small: true,
              expand: true,
              icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
              onPressed: onTap,
            )
          else
            Column(
              children: [
                StarRow(
                  stars: starsFor(hints: r.hints, mistakes: r.mistakes),
                  size: 22,
                  animate: false,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(color: goodSoft, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, color: leafEdge, size: 20),
                      const SizedBox(width: 4),
                      Text(formatTime(r.millis), style: chunky(17, color: leafEdge)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({super.key, required this.kind, required this.onTap});

  final GameKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = Services.of(context).stats;
    return Bouncy(
      onTap: onTap,
      child: CustomPaint(
        painter: const WoodPainter(radius: 18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gameName(l10n, kind),
                      overflow: TextOverflow.ellipsis,
                      style: outlinedText(19, color: const Color(0xFFFFF4D6)),
                    ),
                    Text(
                      l10n.levelTitle(stats.level(kind)),
                      overflow: TextOverflow.ellipsis,
                      style: chunky(15, color: const Color(0xFFFFE6BC), weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const _MapPin(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A little round map badge with a flag, on the level cards.
class _MapPin extends StatelessWidget {
  const _MapPin();

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: leaf,
      shape: BoxShape.circle,
      border: Border.all(color: leafEdge, width: 3),
    ),
    child: const Icon(Icons.flag_rounded, color: Colors.white, size: 22),
  );
}

/// A tiny garden plot with a critter in it.
class _NestsArt extends StatelessWidget {
  const _NestsArt();

  @override
  Widget build(BuildContext context) {
    const colors = [1, 1, 3, 1, 0, 3, 0, 0, 3];
    return Container(
      width: 70,
      height: 70,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: woodDark,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: woodEdge, offset: Offset(0, 3))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: GridView.count(
          crossAxisCount: 3,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            for (var i = 0; i < 9; i++)
              Container(
                decoration: BoxDecoration(
                  color: zoneColors[colors[i]],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 0.75),
                ),
                child: i == 4 ? const Center(child: CritterImage('chick', size: 20)) : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _PairsArt extends StatelessWidget {
  const _PairsArt();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (i, v) in const [0, 1].indexed) ...[
        if (i > 0) const SizedBox(width: 8),
        Transform.rotate(
          angle: i == 0 ? -0.08 : 0.08,
          child: Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFEFE6D6),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0xFFB4A58C), offset: Offset(0, 4))],
            ),
            child: SymbolIcon(v),
          ),
        ),
      ],
    ],
  );
}

class _RepairCard extends StatelessWidget {
  const _RepairCard({required this.onRepair});

  final VoidCallback onRepair;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SoftCard(
      color: accentSoft,
      border: coral,
      child: Column(
        children: [
          Row(
            children: [
              const FlameIcon(size: 34, lit: false),
              const SizedBox(width: 10),
              Expanded(child: Text(l10n.streakBroken, style: chunky(16))),
            ],
          ),
          const SizedBox(height: 10),
          ChunkyButton(
            key: const Key('repair'),
            label: l10n.repairStreak,
            small: true,
            expand: true,
            color: leaf,
            icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
            onPressed: onRepair,
          ),
        ],
      ),
    );
  }
}
