import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../meta/game_flow.dart';
import '../meta/reminders.dart';
import '../meta/retention.dart';
import '../puzzles/nests/nests.dart';
import '../puzzles/puzzle.dart';
import '../services/leaderboard_service.dart';
import '../services/review_service.dart';
import '../services/share_text.dart';
import '../services/sound_service.dart';
import '../services/stats_store.dart';
import 'capsule_screen.dart';
import 'coin_fly.dart';
import 'critter_actor.dart';
import 'meadow.dart';
import 'game/confetti.dart';
import 'game/game_screen.dart';
import 'game/nests_board.dart';
import 'game/pairs_board.dart';
import 'game/session.dart';
import 'game/trail_board.dart';
import 'navigation.dart';
import 'palette.dart';
import 'services.dart';
import 'retention_ui.dart';
import 'share.dart';
import 'widgets.dart';

/// A solved daily: time with penalties, standing, top 10, share, and (on the first solve) the rewards.
class DailyResultScreen extends StatefulWidget {
  const DailyResultScreen({
    super.key,
    required this.kind,
    required this.number,
    required this.result,
    this.fresh = false,
    this.rewards,
    this.retention,
  });

  final GameKind kind;
  final int number;
  final DailyResult result;

  /// Just solved for the first time: post the time, run the once-per-solve effects, interstitial on leaving.
  final bool fresh;
  final DailyRewards? rewards;

  /// What the first solve did for the weekly event and the trophies.
  final RetentionUpdate? retention;

  @override
  State<DailyResultScreen> createState() => _DailyResultScreenState();
}

class _DailyResultScreenState extends State<DailyResultScreen> with SingleTickerProviderStateMixin {
  late final _confetti = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  late Services _services;
  Future<DailyStanding?>? _standing;

  /// Reward coins still flying to the counter.
  int _coinsHeld = 0;
  final _coinTarget = GlobalKey();
  final _coinSource = GlobalKey();
  GameSession? _board;
  bool _left = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_standing != null) return;
    _services = Services.of(context);
    final s = _services;
    final stats = s.stats;
    if (widget.fresh) {
      _confetti.forward();
      _standing = s.leaderboard.submitDaily(widget.kind, widget.number, widget.result.millis);
      s.leaderboard.submitProfile(bestStreak: stats.bestStreak, solved: stats.dailiesSolved);
      ReviewPrompter(stats, s.review).onDailySolved(widget.rewards?.streak ?? stats.streak(widget.number));
      planReminders(stats, s.reminders, AppLocalizations.of(context), s.today());
      final r = widget.rewards;
      if (r != null && (r.capsule || r.chest != null)) {
        s.sound.play(r.chest != null ? Sfx.chest : Sfx.coin);
      }
      final update = widget.retention;
      if (update != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showRetentionUpdate(context, update, tokens: false);
        });
      }
      if (r != null) {
        _coinsHeld = r.coins + (r.chest?.coins ?? 0);
        final total = _coinsHeld;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _flyRewardCoins(total);
        });
      }
    } else {
      _standing = s.leaderboard.standing(widget.kind, widget.number, myMillis: widget.result.millis);
    }
    _loadBoard();
  }

  Future<void> _flyRewardCoins(int total) async {
    if (ambientMotion(context)) await Future<void>.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;
    const pieces = 10;
    await flyCoins(context, from: _coinSource, to: _coinTarget, coins: pieces, onArrive: (n) {
      if (mounted) setState(() => _coinsHeld = total - (total * n / pieces).round());
    });
    if (mounted) setState(() => _coinsHeld = 0);
  }

  Future<void> _loadBoard() async {
    final p = _services.puzzles;
    final GameSession board = switch (widget.kind) {
      GameKind.nests =>
        await p
            .dailyNests(widget.number)
            .then(
              (puzzle) => NestsSession(
                puzzle,
                initial: [
                  for (var i = 0; i < puzzle.size * puzzle.size; i++)
                    puzzle.isCritterInSolution(i) ? NestMark.critter : NestMark.empty,
                ],
              ),
            ),
      GameKind.pairs =>
        await p.dailyPairs(widget.number).then((puzzle) => PairsSession(puzzle, initial: List.of(puzzle.solution))),
      GameKind.trail => await p.dailyTrail(widget.number).then((puzzle) => TrailSession(puzzle, path: puzzle.solution)),
    };
    if (mounted) setState(() => _board = board);
  }

  void _onLeft() {
    if (_left) return;
    _left = true;
    if (widget.fresh) _services.ads.showInterstitial();
  }

  Future<void> _share() async {
    final stats = _services.stats;
    final l10n = AppLocalizations.of(context);
    final results = [for (final k in GameKind.values) ?stats.daily(k, widget.number)];
    _services.analytics.share(daily: true);
    await shareText(context, dailyShareText(widget.number, results, streak: stats.streak(widget.number), l10n: l10n));
    final update = await _services.retention.recordEvent(const Shared(), _services.today());
    if (mounted) await showRetentionUpdate(context, update);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stats = _services.stats;
    // The next daily still to play today, if any.
    final other = GameKind.values.where((k) => k != widget.kind && stats.daily(k, widget.number) == null).firstOrNull;
    final streak = stats.streak(widget.number);
    final rewards = widget.fresh ? widget.rewards : null;
    final r = widget.result;
    final cheer = buddyCritters(stats, 3, seed: widget.number);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _onLeft();
      },
      child: MeadowScaffold(
        overlays: [Positioned.fill(child: Confetti(animation: _confetti, seed: 3))],
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(children: [
              RoundIconButton(
                key: const Key('resultHome'),
                icon: Icons.close_rounded,
                tooltip: l10n.home,
                color: woodButton,
                onPressed: () => Navigator.maybePop(context),
              ),
              const Spacer(),
              StatPill(icon: FlameIcon(lit: streak > 0), text: l10n.streakDays(streak), color: goldSoft),
              const SizedBox(width: 6),
              CoinCounter(value: stats.coins - _coinsHeld, iconKey: _coinTarget),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              children: [
                // Cheering critters on top of the big time panel.
                SizedBox(
                  height: 82,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    for (final (i, id) in cheer.indexed)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: CritterBuddy(id, size: i == 1 ? 80 : 62, cheer: widget.fresh, seed: i + 5, shadow: false),
                      ),
                  ]),
                ),
                PopIn(
                  child: SoftCard(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    child: Column(children: [
                      Text(
                        widget.fresh ? l10n.solved : l10n.alreadySolved,
                        textAlign: TextAlign.center,
                        style: outlinedText(34, color: const Color(0xFFFFE066), stroke: woodEdge, width: 2.6),
                      ),
                      Text(
                        '${gameName(l10n, widget.kind)} · ${l10n.dailyTitle(widget.number)}',
                        textAlign: TextAlign.center,
                        style: chunky(16, color: inkSoft, weight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      StarRow(stars: starsFor(hints: r.hints, mistakes: r.mistakes), size: 50, animate: widget.fresh),
                      const SizedBox(height: 8),
                      _timeBlock(l10n),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                _standingCard(l10n),
                if (rewards != null) ...[const SizedBox(height: 14), _rewardsCard(l10n, rewards)],
                const SizedBox(height: 20),
                ChunkyButton(
                  key: const Key('share'),
                  label: l10n.shareResult,
                  color: sky,
                  icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
                  expand: true,
                  onPressed: _share,
                ),
                const SizedBox(height: 12),
                if (other != null) ...[
                  ChunkyButton(
                    key: const Key('playOther'),
                    label: l10n.playOtherDaily(gameName(l10n, other)),
                    color: leaf,
                    expand: true,
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                    onPressed: () {
                      _onLeft();
                      openGame(context, other, PlayMode.daily, replace: true);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
                ChunkyButton(
                  key: const Key('home'),
                  label: l10n.home,
                  color: woodButton,
                  small: true,
                  expand: true,
                  icon: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.maybePop(context),
                ),
                if (_board != null) ...[
                  const SizedBox(height: 24),
                  Text(l10n.todaysGrid, textAlign: TextAlign.center, style: outlinedText(17, stroke: woodEdge)),
                  const SizedBox(height: 10),
                  Center(
                    child: SizedBox.square(
                      dimension: 220,
                      child: switch (_board!) {
                        final NestsSession s => NestsBoard(
                          session: s,
                          readOnly: true,
                          autoCross: false,
                          critter: boardCritter(stats, widget.number),
                        ),
                        final PairsSession s => PairsBoard(session: s, readOnly: true),
                        final TrailSession s => TrailBoard(
                          session: s,
                          readOnly: true,
                          critter: boardCritter(stats, widget.number),
                        ),
                        _ => const SizedBox.shrink(),
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _timeBlock(AppLocalizations l10n) {
    final r = widget.result;
    final penalty = rankedMillis(0, mistakes: r.mistakes, hints: r.hints);
    return Column(children: [
      Text(l10n.yourTime, style: chunky(15, color: inkSoft)),
      Text(formatTime(r.millis), key: const Key('resultTime'), style: chunky(58, height: 1.05, color: ink)),
      const SizedBox(height: 4),
      if (penalty == 0)
        Text(l10n.flawless, style: chunky(16, color: leafEdge))
      else
        Text(
          l10n.timeBreakdown(formatTime(r.millis - penalty), r.mistakes, r.hints, penalty ~/ 1000),
          textAlign: TextAlign.center,
          style: chunky(14, color: inkSoft, weight: FontWeight.w500),
        ),
    ]);
  }

  /// The standing, on a wooden scoreboard.
  Widget _standingCard(AppLocalizations l10n) => SoftCard(
        style: PanelStyle.wood,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: FutureBuilder<DailyStanding?>(
          future: _standing,
          builder: (context, snap) {
            final light = onWood;
            if (snap.connectionState != ConnectionState.done) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: light)),
                  const SizedBox(width: 10),
                  Text(l10n.leaderboardLoading, style: outlinedText(15, color: light)),
                ]),
              );
            }
            final standing = snap.data;
            if (standing == null) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  l10n.leaderboardOffline,
                  key: const Key('leaderboardOffline'),
                  textAlign: TextAlign.center,
                  style: outlinedText(15, color: light),
                ),
              );
            }
            final faster = standing.fasterThan;
            final rank = standing.rank;
            return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (faster != null)
                Text(l10n.fasterThan((faster * 100).round()), textAlign: TextAlign.center,
                    style: outlinedText(22, color: const Color(0xFFFFE066)))
              else if (rank != null)
                Text(l10n.rankOf(rank, standing.total), textAlign: TextAlign.center,
                    style: outlinedText(22, color: const Color(0xFFFFE066))),
              if (faster != null && rank != null)
                Text(l10n.rankOf(rank, standing.total), textAlign: TextAlign.center, style: outlinedText(15, color: light)),
              const SizedBox(height: 10),
              Text(l10n.topTimes, textAlign: TextAlign.center, style: outlinedText(16, color: light)),
              const SizedBox(height: 4),
              for (final (i, (millis, mine)) in standing.top.indexed)
                SlideIn(
                  delay: Duration(milliseconds: 120 * i),
                  offset: 12,
                  child: Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: mine ? goldSoft : paper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: mine ? gold : paperEdge, width: 2),
                      boxShadow: [BoxShadow(color: woodEdge, offset: Offset(0, 3))],
                    ),
                    child: Row(children: [
                      SizedBox(
                        width: 36,
                        child: i < 3
                            ? _Medal(place: i)
                            : Text('${i + 1}.', style: chunky(16, color: inkSoft)),
                      ),
                      Expanded(child: Text(mine ? l10n.you : l10n.player, style: chunky(16, color: mine ? ink : inkSoft))),
                      Text(formatTime(millis), style: chunky(16)),
                    ]),
                  ),
                ),
            ]);
          },
        ),
      );

  Widget _rewardsCard(AppLocalizations l10n, DailyRewards r) {
    final rows = <Widget>[
      _RewardRow(icon: const CoinIcon(size: 28), text: l10n.rewardCoins(r.coins)),
      if (r.capsule) _RewardRow(icon: const CapsuleEgg(size: 32), text: l10n.rewardDailyCapsule),
      if (r.chest != null) _RewardRow(icon: const Text('🎁', style: TextStyle(fontSize: 26)), text: l10n.rewardChest(r.streak, r.chest!.coins)),
      if (r.chest?.capsule ?? false)
        _RewardRow(
          icon: CapsuleEgg(size: 32, golden: r.chest!.golden),
          text: r.chest!.golden ? l10n.rewardGoldenCapsule : l10n.rewardCapsule,
        ),
    ];
    return SoftCard(
      key: const Key('rewards'),
      color: goldSoft,
      border: gold,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(l10n.rewards, textAlign: TextAlign.center, style: outlinedText(22, color: const Color(0xFFFFE066), stroke: goldEdge)),
        const SizedBox(height: 6),
        for (final (i, row) in [...rows, ?_tokensRow(l10n)].indexed)
          PopIn(
            key: i == 0 ? _coinSource : null,
            delay: Duration(milliseconds: 900 + 220 * i),
            duration: const Duration(milliseconds: 600),
            child: row,
          ),
      ]),
    );
  }
}

/// "+3 🐾 Panda Week" under the rewards.
extension on _DailyResultScreenState {
  Widget? _tokensRow(AppLocalizations l10n) {
    final u = widget.retention;
    final event = _services.retention.event.current(_services.today());
    if (u == null || u.tokens <= 0 || event == null) return null;
    return Padding(
      key: const Key('eventTokensRow'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(l10n.eventTokensShort(u.tokens, eventName(l10n, event.theme.id)),
          textAlign: TextAlign.center, style: chunky(17, color: coralEdge)),
    );
  }
}

/// A round gold / silver / bronze medal with the place number.
class _Medal extends StatelessWidget {
  const _Medal({required this.place});

  final int place;

  @override
  Widget build(BuildContext context) {
    const colors = [Color(0xFFFFC93C), Color(0xFFCBD3DC), Color(0xFFE09A5B)];
    final c = colors[place];
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle, border: Border.all(color: edgeOf(c), width: 2.5)),
        alignment: Alignment.center,
        child: Text('${place + 1}', style: chunky(13, color: edgeOf(c), height: 1)),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.icon, required this.text});

  final Widget icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SizedBox(width: 34, child: Center(child: icon)),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: chunky(17))),
        ]),
      );
}
