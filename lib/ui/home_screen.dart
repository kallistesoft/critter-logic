import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../meta/album.dart';
import '../meta/game_flow.dart';
import '../puzzles/puzzle.dart';
import '../services/share_text.dart';
import '../services/sound_service.dart';
import 'album_screen.dart';
import 'banner_slot.dart';
import 'capsule_screen.dart';
import 'critter_image.dart';
import 'game/game_screen.dart';
import 'game/pairs_board.dart';
import 'navigation.dart';
import 'palette.dart';
import 'remove_ads.dart';
import 'services.dart';
import 'settings_screen.dart';
import 'widgets.dart';

/// Home: today's dailies, streak, coins, levels, album and capsules.
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

    return Scaffold(
      backgroundColor: background,
      body: Column(children: [
        Expanded(
          child: ScreenFrame(
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), children: [
              Row(children: [
                StatPill(key: const Key('streak'), emoji: '🔥', text: l10n.streakDays(streak), color: streak > 0 ? accentSoft : surface),
                const SizedBox(width: 8),
                StatPill(key: const Key('homeCoins'), emoji: '🪙', text: '${stats.coins}'),
                const Spacer(),
                RoundIconButton(
                  key: const Key('settings'),
                  icon: Icons.settings_rounded,
                  tooltip: l10n.settings,
                  onPressed: () => _open(const SettingsScreen()),
                ),
              ]),
              const SizedBox(height: 6),
              const _Mascots(),
              const SizedBox(height: 4),
              Text('Critter Logic', textAlign: TextAlign.center, style: chunky(36, color: ink)),
              Text(l10n.tagline, textAlign: TextAlign.center, style: chunky(15, color: inkSoft, weight: FontWeight.w700)),
              const SizedBox(height: 16),
              if (stats.canRepair(today)) ...[
                _RepairCard(onRepair: () => _repair(today)),
                const SizedBox(height: 14),
              ],
              Row(children: [
                Expanded(child: Text(l10n.todaysPuzzles, overflow: TextOverflow.ellipsis, style: chunky(18))),
                Text(l10n.dailyTitle(today), style: chunky(14, color: inkSoft, weight: FontWeight.w800)),
              ]),
              const SizedBox(height: 10),
              IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  for (final kind in GameKind.values) ...[
                    if (kind != GameKind.values.first) const SizedBox(width: 12),
                    Expanded(
                      child: _DailyCard(
                        key: Key('daily-${kind.name}'),
                        kind: kind,
                        millis: stats.daily(kind, today)?.millis,
                        onTap: () => _play(kind, PlayMode.daily),
                      ),
                    ),
                  ],
                ]),
              ),
              if (stats.allDailiesDone(today)) ...[
                const SizedBox(height: 10),
                Text(l10n.allDailiesDone, textAlign: TextAlign.center, style: chunky(14, color: good, weight: FontWeight.w800)),
              ],
              const SizedBox(height: 16),
              Text(l10n.levels, style: chunky(18)),
              const SizedBox(height: 10),
              Row(children: [
                for (final kind in GameKind.values) ...[
                  if (kind != GameKind.values.first) const SizedBox(width: 12),
                  Expanded(
                    child: SoftCard(
                      key: Key('level-${kind.name}'),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      onTap: () => _play(kind, PlayMode.level),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(gameName(l10n, kind), style: chunky(16)),
                            Text(l10n.levelTitle(stats.level(kind)), style: chunky(13, color: inkSoft, weight: FontWeight.w700)),
                          ]),
                        ),
                        const Icon(Icons.play_circle_fill_rounded, color: accent, size: 30),
                      ]),
                    ),
                  ),
                ],
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: SoftCard(
                    key: const Key('album'),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    onTap: () => _open(const AlbumScreen()),
                    child: Row(children: [
                      const Text('📖', style: TextStyle(fontSize: 26)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l10n.album, style: chunky(16)),
                          Text('${album.where((c) => owned.contains(c.id)).length}/${album.length}',
                              style: chunky(13, color: inkSoft, weight: FontWeight.w700)),
                        ]),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Stack(clipBehavior: Clip.none, children: [
                    SoftCard(
                      key: const Key('capsules'),
                      color: waiting > 0 ? accentSoft : surface,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      onTap: () => _open(const CapsuleScreen()),
                      child: Row(children: [
                        const Text('🥚', style: TextStyle(fontSize: 26)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l10n.capsules, style: chunky(16), overflow: TextOverflow.ellipsis),
                            Text(waiting > 0 ? l10n.openNow : l10n.capsuleShort,
                                overflow: TextOverflow.ellipsis, style: chunky(13, color: waiting > 0 ? accent : inkSoft, weight: FontWeight.w700)),
                          ]),
                        ),
                      ]),
                    ),
                    if (waiting > 0) Positioned(right: -4, top: -6, child: CountBadge(key: const Key('capsuleBadge'), count: waiting)),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              if (!stats.reviewed)
                Center(
                  child: TextButton.icon(
                    key: const Key('rate'),
                    onPressed: () async {
                      await stats.setReviewed(true);
                      await services.review.openStoreListing();
                      if (mounted) setState(() {});
                    },
                    icon: const Icon(Icons.star_rounded, color: gold),
                    label: Text(l10n.rateApp, style: chunky(15, color: inkSoft, weight: FontWeight.w800)),
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
                          child: Text(l10n.privacyOptions, style: const TextStyle(color: inkSoft)),
                        )
                      : const SizedBox.shrink(),
                ),
            ]),
          ),
        ),
        const SafeArea(top: false, child: BannerSlot()),
      ]),
    );
  }
}

/// Three critters peeking over the title.
class _Mascots extends StatelessWidget {
  const _Mascots();

  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (final (i, id) in const ['frog', 'chick', 'panda'].indexed)
          Padding(
            padding: EdgeInsets.only(left: 4, right: 4, bottom: i == 1 ? 10 : 0),
            child: PopIn(delay: Duration(milliseconds: 120 * i), child: CritterImage(id, size: i == 1 ? 52 : 42)),
          ),
      ]);
}

class _DailyCard extends StatelessWidget {
  const _DailyCard({super.key, required this.kind, required this.millis, required this.onTap});

  final GameKind kind;
  final int? millis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final solved = millis != null;
    final tint = kind == GameKind.nests ? zoneColors[0] : const Color(0xFFDCE2FF);
    return SoftCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          height: 82,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(radius)),
          ),
          child: Center(child: kind == GameKind.nests ? const _NestsIcon() : const _PairsIcon()),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(gameName(l10n, kind), style: chunky(20)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: solved ? goodSoft : accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(solved ? Icons.check_circle_rounded : Icons.play_arrow_rounded, color: solved ? good : Colors.white, size: 20),
                const SizedBox(width: 4),
                Text(solved ? formatTime(millis!) : l10n.play,
                    style: chunky(16, color: solved ? good : Colors.white, weight: FontWeight.w800)),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// A tiny Nests board: two zones and a critter.
class _NestsIcon extends StatelessWidget {
  const _NestsIcon();

  @override
  Widget build(BuildContext context) {
    const colors = [1, 1, 3, 1, 2, 3, 2, 2, 3];
    return Container(
      width: 66,
      height: 66,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ink.withValues(alpha: 0.7), width: 2.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GridView.count(
          crossAxisCount: 3,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            for (var i = 0; i < 9; i++)
              Container(
                decoration: BoxDecoration(
                  color: zoneColors[colors[i]],
                  border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 0.75),
                ),
                child: i == 4 ? const CritterImage('chick', size: 18) : null,
              ),
          ],
        ),
      ),
    );
  }
}

class _PairsIcon extends StatelessWidget {
  const _PairsIcon();

  @override
  Widget build(BuildContext context) => const Row(mainAxisSize: MainAxisSize.min, children: [
        SizedBox.square(dimension: 40, child: SymbolIcon(0)),
        SizedBox(width: 6),
        SizedBox.square(dimension: 40, child: SymbolIcon(1)),
      ]);
}

class _RepairCard extends StatelessWidget {
  const _RepairCard({required this.onRepair});

  final VoidCallback onRepair;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SoftCard(
      color: accentSoft,
      child: Column(children: [
        Row(children: [
          const Text('🩹', style: TextStyle(fontSize: 30)),
          const SizedBox(width: 10),
          Expanded(child: Text(l10n.streakBroken, style: chunky(15, weight: FontWeight.w800))),
        ]),
        const SizedBox(height: 10),
        ChunkyButton(
          key: const Key('repair'),
          label: l10n.repairStreak,
          small: true,
          expand: true,
          color: good,
          icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 20),
          onPressed: onRepair,
        ),
      ]),
    );
  }
}
