import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../meta/album.dart';
import '../meta/weekly_event.dart';
import '../services/sound_service.dart';
import 'capsule_screen.dart';
import 'coin_fly.dart';
import 'critter_image.dart';
import 'album_screen.dart';
import 'meadow.dart';
import 'palette.dart';
import 'retention_ui.dart';
import 'services.dart';
import 'widgets.dart';

/// The golden critter of a set: the face of its event week.
String goldenOf(String set) =>
    album.firstWhere((c) => c.set == set && c.rarity == Rarity.golden, orElse: () => album.first).id;

String timeLeft(AppLocalizations l10n, Duration d) {
  if (d.isNegative) d = Duration.zero;
  return d.inDays >= 1
      ? l10n.eventEndsDays(d.inDays, d.inHours % 24)
      : l10n.eventEndsHours(d.inHours, d.inMinutes % 60);
}

String prizeText(AppLocalizations l10n, EventPrize p, String set) {
  final parts = <String>[
    if (p.critter) l10n.eventPrizeCritter(setName(l10n, set)),
    if (p.coins > 0) l10n.rewardCoins(p.coins),
    if (p.goldenCapsules > 0) l10n.rewardGoldenCapsule,
    if (p.capsules > 0) p.capsules == 1 ? l10n.rewardCapsule : '+${p.capsules} ${l10n.shopCapsules.toLowerCase()}',
  ];
  return parts.join(' · ');
}

/// The weekly event on the home screen: the set's golden critter, the name, time left and the progress to the gifts.
class EventBanner extends StatelessWidget {
  const EventBanner({super.key, required this.state, required this.onTap});

  final WeeklyEventState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = Services.of(context).today();
    final ready = state.claimable.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SoftCard(
          key: const Key('eventBanner'),
          color: ready ? goldSoft : const Color(0xFFFFF3E6),
          border: ready ? gold : coral,
          padding: const EdgeInsets.fromLTRB(8, 8, 14, 10),
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(colors: [Color(0xFFFFF0A0), Color(0xFFFFC23D)]),
                  border: Border.all(color: goldEdge, width: 2.5),
                ),
                child: Center(child: CritterImage(goldenOf(state.theme.set), size: 50)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: Text(
                            eventName(l10n, state.theme.id),
                            maxLines: 1,
                            style: chunky(18, color: coralEdge),
                          )),
                        ),
                        Text(
                          timeLeft(l10n, state.remaining(now)),
                          style: chunky(13, color: inkSoft, weight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    EventProgress(state: state, height: 16, giftSize: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (ready)
          Positioned(
            right: -6,
            top: -8,
            child: Container(
              key: const Key('eventReady'),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: bad,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              alignment: Alignment.center,
              child: Text('!', style: chunky(16, color: Colors.white, height: 1)),
            ),
          ),
      ],
    );
  }
}

/// The token bar with a gift at each threshold (open and gold once reached).
class EventProgress extends StatelessWidget {
  const EventProgress({super.key, required this.state, this.height = 18, this.giftSize = 28, this.showCount = true});

  /// The token count on the left of the bar.
  final bool showCount;

  final WeeklyEventState state;
  final double height;
  final double giftSize;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (showCount) ...[
        Text(
          '${state.tokens.clamp(0, state.thresholds.last)} 🐾',
          style: chunky(height * 0.85, color: coralEdge, height: 1),
        ),
        const SizedBox(width: 8),
      ],
      Expanded(child: _bar()),
    ],
  );

  Widget _bar() => LayoutBuilder(
    builder: (context, box) {
      final w = box.maxWidth - giftSize / 2;
      final last = state.thresholds.last;
      return SizedBox(
        height: giftSize + 4,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            Container(
              width: w,
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFFEFE3CC),
                borderRadius: BorderRadius.circular(height),
                border: Border.all(color: paperEdge, width: 1.5),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: state.fraction,
                  heightFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFFB38A), coral]),
                      borderRadius: BorderRadius.circular(height),
                    ),
                  ),
                ),
              ),
            ),
            for (final t in state.thresholds)
              Positioned(
                left: w * t / last - giftSize / 2,
                child: _Gift(size: giftSize, reached: state.tokens >= t, claimed: state.claimed.contains(t)),
              ),
          ],
        ),
      );
    },
  );
}

class _Gift extends StatelessWidget {
  const _Gift({required this.size, required this.reached, required this.claimed});

  final double size;
  final bool reached;
  final bool claimed;

  @override
  Widget build(BuildContext context) {
    final c = claimed ? const Color(0xFFCFC4B2) : (reached ? gold : const Color(0xFFFFB38A));
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: edgeOf(c), width: 2),
      ),
      alignment: Alignment.center,
      child: claimed
          ? Icon(Icons.check_rounded, size: size * 0.7, color: edgeOf(c))
          : Text('🎁', style: TextStyle(fontSize: size * 0.58, height: 1)),
    );
  }
}

/// This week's event: tokens, the three prizes with Claim buttons, how to earn tokens and the set's critters.
class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final _coinTarget = GlobalKey();
  final _prizeKeys = <int, GlobalKey>{};
  int _coinsHeld = 0;
  bool _busy = false;

  Future<void> _claim(int threshold) async {
    if (_busy) return;
    final services = Services.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final result = await services.retention.claimEventPrize(services.today(), threshold);
    if (!mounted) return;
    if (result == null) {
      setState(() => _busy = false);
      return;
    }
    final coins = result.totalCoins;
    setState(() => _coinsHeld = coins);
    final r = result.reward;
    if (coins > 0) {
      await flyCoins(context, from: _prizeKeys[threshold]!, to: _coinTarget, coins: 8);
    } else {
      services.sound.play(Sfx.chest);
    }
    if (!mounted) return;
    setState(() => _coinsHeld = 0);
    if (r.critter != null) {
      await showSoftDialog<void>(
        context,
        title: critterName(l10n, r.critter!),
        body: result.duplicate ? null : l10n.capsuleNew,
        content: PopIn(child: CritterImage(r.critter!, size: 120)),
        actions: [ChunkyButton(label: l10n.nice, expand: true, onPressed: () => Navigator.pop(context))],
      );
    } else if (r.capsules > 0 || r.goldenCapsules > 0) {
      showToast(context, [
        r.goldenCapsules > 0 ? l10n.rewardGoldenCapsule : l10n.rewardCapsule,
      ], icon: CapsuleEgg(size: 28, golden: r.goldenCapsules > 0));
    }
    if (!mounted) return;
    final unlocks = services.retention.takePendingSetUnlocks();
    if (unlocks.isNotEmpty) await showSetUnlocks(context, unlocks);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final services = Services.of(context);
    final now = services.today();
    final retention = services.retention;
    final s = retention.event.current(now);
    if (s == null) {
      return MeadowScaffold(
        child: MeadowTopBar(title: l10n.calendarTitle, backTooltip: l10n.back),
      );
    }
    final remaining = s.remaining(now);
    final owned = services.stats.owned;
    final critters = album.where((c) => c.set == s.theme.set).toList();
    return MeadowScaffold(
      child: Column(
        children: [
          MeadowTopBar(
            title: eventName(l10n, s.theme.id),
            subtitle: timeLeft(l10n, remaining),
            backTooltip: l10n.back,
            trailing: [CoinCounter(value: services.stats.coins - _coinsHeld, iconKey: _coinTarget)],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 24 + MediaQuery.viewPaddingOf(context).bottom),
              children: [
                SoftCard(
                  color: const Color(0xFFFFF3E6),
                  border: coral,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const RadialGradient(colors: [Color(0xFFFFF0A0), Color(0xFFFFC23D)]),
                              border: Border.all(color: goldEdge, width: 3),
                            ),
                            child: Center(child: Shimmer(child: CritterImage(goldenOf(s.theme.set), size: 70))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${s.tokens}',
                                      key: const Key('eventTokens'),
                                      style: outlinedText(34, color: const Color(0xFFFFE066), stroke: coralEdge),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('🐾', style: TextStyle(fontSize: 26)),
                                  ],
                                ),
                                Text(
                                  l10n.eventHowTo(
                                    retention.settings.events.tokensPerDaily,
                                    retention.settings.events.tokensPerLevel,
                                  ),
                                  style: chunky(14, color: inkSoft, weight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      EventProgress(state: s, height: 20, giftSize: 32, showCount: false),
                    ],
                  ),
                ),
                if (remaining.inHours < 24 && s.claimable.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    l10n.eventLastDay,
                    textAlign: TextAlign.center,
                    style: outlinedText(17, stroke: coralEdge),
                  ),
                ],
                for (final t in s.thresholds) ...[
                  const SizedBox(height: 12),
                  _PrizeCard(
                    key: _prizeKeys.putIfAbsent(t, GlobalKey.new),
                    threshold: t,
                    text: prizeText(l10n, s.prizeFor(t), s.theme.set),
                    prize: s.prizeFor(t),
                    set: s.theme.set,
                    reached: s.tokens >= t,
                    claimed: s.claimed.contains(t),
                    onClaim: _busy ? null : () => _claim(t),
                  ),
                ],
                const SizedBox(height: 18),
                Text(l10n.eventSetCritters, style: outlinedText(20, stroke: woodEdge)),
                const SizedBox(height: 8),
                SoftCard(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 18,
                    runSpacing: 12,
                    children: [
                      for (final c in critters)
                        owned.contains(c.id)
                            ? CritterImage(c.id, size: 80)
                            : Silhouette(child: CritterImage(c.id, size: 80)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrizeCard extends StatelessWidget {
  const _PrizeCard({
    super.key,
    required this.threshold,
    required this.text,
    required this.prize,
    required this.set,
    required this.reached,
    required this.claimed,
    this.onClaim,
  });

  final int threshold;
  final String text;
  final EventPrize prize;
  final String set;
  final bool reached;
  final bool claimed;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final Widget icon = prize.critter
        ? Silhouette(
            color: const Color(0x995A3A1C),
            child: CritterImage(album.firstWhere((c) => c.set == set).id, size: 44),
          )
        : prize.capsules > 0 || prize.goldenCapsules > 0
        ? CapsuleEgg(size: 44, golden: prize.goldenCapsules > 0)
        : const CoinIcon(size: 40);
    return SoftCard(
      color: reached && !claimed ? goldSoft : paper,
      border: reached && !claimed ? gold : null,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          SizedBox(width: 52, child: Center(child: icon)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$threshold 🐾', style: chunky(15, color: coralEdge)),
                Text(text, style: chunky(16)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (claimed)
            Text(l10n.eventClaimed, style: chunky(15, color: leafEdge))
          else if (reached)
            ChunkyButton(
              key: Key('eventClaim-$threshold'),
              label: l10n.eventClaim,
              small: true,
              color: leaf,
              onPressed: onClaim,
            )
          else
            const Icon(Icons.lock_rounded, color: paperEdge, size: 28),
        ],
      ),
    );
  }
}
