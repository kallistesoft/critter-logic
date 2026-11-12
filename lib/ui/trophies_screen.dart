import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../meta/achievements.dart';
import 'coin_fly.dart';
import 'meadow.dart';
import 'palette.dart';
import 'retention_ui.dart';
import 'services.dart';
import 'widgets.dart';

(String, String) achievementText(AppLocalizations l10n, String id, int n) => switch (id) {
      'first_daily' => (l10n.achievementFirstDaily, l10n.achievementFirstDailyDesc),
      'dailies' => (l10n.achievementDailies, l10n.achievementDailiesDesc(n)),
      'streak' => (l10n.achievementStreak, l10n.achievementStreakDesc(n)),
      'both_dailies' => (l10n.achievementBothDailies, l10n.achievementBothDailiesDesc(n)),
      'perfect_daily' => (l10n.achievementPerfectDaily, l10n.achievementPerfectDailyDesc(n)),
      'fast_nests' => (l10n.achievementFastNests, l10n.achievementFastNestsDesc(n)),
      'fast_pairs' => (l10n.achievementFastPairs, l10n.achievementFastPairsDesc(n)),
      'nests_levels' => (l10n.achievementNestsLevels, l10n.achievementNestsLevelsDesc(n)),
      'pairs_levels' => (l10n.achievementPairsLevels, l10n.achievementPairsLevelsDesc(n)),
      'levels' => (l10n.achievementLevels, l10n.achievementLevelsDesc(n)),
      'no_hint' => (l10n.achievementNoHint, l10n.achievementNoHintDesc(n)),
      'critters' => (l10n.achievementCritters, l10n.achievementCrittersDesc(n)),
      'sets' => (l10n.achievementSets, l10n.achievementSetsDesc(n)),
      'golden' => (l10n.achievementGolden, l10n.achievementGoldenDesc(n)),
      'capsules' => (l10n.achievementCapsules, l10n.achievementCapsulesDesc(n)),
      'shares' => (l10n.achievementShares, l10n.achievementSharesDesc(n)),
      'calendar' => (l10n.achievementCalendar, l10n.achievementCalendarDesc(n)),
      'events' => (l10n.achievementEvents, l10n.achievementEventsDesc(n)),
      _ => (id, ''),
    };

const medalColors = {Tier.bronze: Color(0xFFE09A5B), Tier.silver: Color(0xFFCBD3DC), Tier.gold: Color(0xFFFFC93C)};

/// The trophy room: every achievement with its medals, progress and Claim buttons.
class TrophiesScreen extends StatefulWidget {
  const TrophiesScreen({super.key});

  @override
  State<TrophiesScreen> createState() => _TrophiesScreenState();
}

class _TrophiesScreenState extends State<TrophiesScreen> {
  final _coinTarget = GlobalKey();
  final _buttonKeys = <String, GlobalKey>{};
  int _coinsHeld = 0;
  final _busy = <String>{};

  Future<void> _claim(AchievementProgress a, Tier tier) async {
    if (!_busy.add(a.def.id)) return;
    final services = Services.of(context);
    final coins = await services.retention.claimAchievement(a.def.id, tier);
    if (!mounted) return;
    if (coins == null) {
      setState(() => _busy.remove(a.def.id));
      return;
    }
    setState(() => _coinsHeld += coins);
    final from = _buttonKeys[a.def.id]!;
    await flyCoins(context, from: from, to: _coinTarget, coins: tier == Tier.gold ? 12 : 8, onArrive: (_) {});
    if (!mounted) return;
    setState(() {
      _coinsHeld -= coins;
      _busy.remove(a.def.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = Services.of(context);
    final list = services.retention.achievements.evaluate();
    int rank(AchievementProgress a) => a.claimable.isNotEmpty ? 0 : (a.complete ? 2 : 1);
    final sorted = [...list]..sort((a, b) {
        final r = rank(a).compareTo(rank(b));
        return r != 0 ? r : b.fraction.compareTo(a.fraction);
      });
    final done = list.fold(0, (n, a) => n + a.claimed.length);
    final total = list.fold(0, (n, a) => n + a.def.targets.length);
    return MeadowScaffold(
      child: Column(children: [
        MeadowTopBar(
          title: l10n.trophies,
          subtitle: '$done/$total',
          backTooltip: l10n.back,
          trailing: [CoinCounter(value: services.stats.coins - _coinsHeld, iconKey: _coinTarget)],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              for (final (i, a) in sorted.indexed) ...[
                if (i > 0) const SizedBox(height: 12),
                SlideIn(
                  delay: Duration(milliseconds: 40 * i.clamp(0, 8)),
                  child: _TrophyCard(
                    key: Key('trophy-${a.def.id}'),
                    progress: a,
                    buttonKey: _buttonKeys.putIfAbsent(a.def.id, GlobalKey.new),
                    coinsFor: services.retention.settings.achievementCoins.of,
                    onClaim: _busy.contains(a.def.id) ? null : (t) => _claim(a, t),
                  ),
                ),
              ],
            ],
          ),
        ),
      ]),
    );
  }
}

class _TrophyCard extends StatelessWidget {
  const _TrophyCard({super.key, required this.progress, required this.buttonKey, required this.coinsFor, this.onClaim});

  final AchievementProgress progress;
  final GlobalKey buttonKey;
  final int Function(Tier) coinsFor;
  final void Function(Tier)? onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final a = progress;
    final (title, desc) = achievementText(l10n, a.def.id, a.target);
    final claimable = a.claimable.firstOrNull;
    final complete = a.complete && claimable == null;
    return SoftCard(
      color: claimable != null ? goldSoft : (complete ? goodSoft : paper),
      border: claimable != null ? gold : null,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Row(children: [
        _MedalStack(progress: a),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: chunky(18), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(desc, style: chunky(14, color: inkSoft, weight: FontWeight.w500)),
            const SizedBox(height: 6),
            if (complete)
              Text(l10n.trophyDone, style: chunky(15, color: leafEdge))
            else
              _ProgressBar(fraction: a.fraction, label: '${a.value.clamp(0, a.target)}/${a.target}'),
          ]),
        ),
        if (claimable != null) ...[
          const SizedBox(width: 10),
          KeyedSubtree(
            key: buttonKey,
            child: _ClaimButton(
              key: Key('claim-${a.def.id}'),
              coins: coinsFor(claimable),
              label: l10n.trophyClaim,
              onPressed: onClaim == null ? null : () => onClaim!(claimable),
            ),
          ),
        ] else
          SizedBox(key: buttonKey, width: 0, height: 0),
      ]),
    );
  }
}

class _ClaimButton extends StatelessWidget {
  const _ClaimButton({super.key, required this.coins, required this.label, this.onPressed});

  final int coins;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          const CoinIcon(size: 20),
          const SizedBox(width: 3),
          Text('+$coins', style: chunky(15, color: woodDark)),
        ]),
        const SizedBox(height: 4),
        ChunkyButton(label: label, small: true, color: leaf, onPressed: onPressed),
      ]);
}

/// Three medals; reached ones shine, claimed ones carry a check.
class _MedalStack extends StatelessWidget {
  const _MedalStack({required this.progress});

  final AchievementProgress progress;

  @override
  Widget build(BuildContext context) {
    final tiers = progress.def.tiers;
    final best = progress.claimed.isEmpty ? null : tiers.lastWhere(progress.claimed.contains);
    return SizedBox(
      width: 58,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        best == null
            ? const TrophyIcon(size: 44, color: Color(0xFFD8CDBB))
            : TrophyIcon(size: 44, color: medalColors[best]!),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final t in tiers)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Medal(tier: t, reached: progress.reached.contains(t), claimed: progress.claimed.contains(t), size: 16),
            ),
        ]),
      ]),
    );
  }
}

class Medal extends StatelessWidget {
  const Medal({super.key, required this.tier, required this.reached, required this.claimed, this.size = 18});

  final Tier tier;
  final bool reached;
  final bool claimed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = reached ? medalColors[tier]! : const Color(0xFFE8DFD0);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: edgeOf(c), width: 2)),
      child: claimed ? Icon(Icons.check_rounded, size: size * 0.7, color: edgeOf(c)) : null,
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.fraction, required this.label});

  final double fraction;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        height: 20,
        decoration: BoxDecoration(
          color: const Color(0xFFEFE3CC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: paperEdge, width: 1.5),
        ),
        child: Stack(children: [
          FractionallySizedBox(
            widthFactor: fraction.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF8EDB5E), leaf]),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Center(child: Text(label, style: chunky(12, color: ink))),
        ]),
      );
}
