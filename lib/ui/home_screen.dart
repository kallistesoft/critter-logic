import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../meta/album.dart';
import '../meta/game_flow.dart';
import '../meta/progress_store.dart';
import '../puzzles/puzzle.dart';
import '../services/share_text.dart';
import '../services/stats_store.dart';
import '../services/sound_service.dart';
import 'album_screen.dart';
import 'capsule_screen.dart';
import 'critter_actor.dart';
import 'critter_image.dart';
import 'event_screen.dart';
import 'game/game_screen.dart';
import 'game/pairs_board.dart';
import 'level_path_screen.dart';
import 'lucky_nest_screen.dart';
import 'meadow.dart';
import 'navigation.dart';
import 'palette.dart';
import 'remove_ads.dart';
import 'retention_ui.dart';
import 'services.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'trophies_screen.dart';
import 'widgets.dart';

/// Home: today's dailies, streak, coins, levels, album and capsules, with critters playing on the grass.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _coinTarget = GlobalKey();
  bool _calendarOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCalendar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _maybeCalendar();
  }

  /// The login calendar pops up on the first visit of the local day (app open or resume, home on screen).
  Future<void> _maybeCalendar() async {
    if (!mounted || _calendarOpen || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    final services = Services.of(context);
    if (!await services.retention.shouldShowCalendar(services.today())) return;
    if (mounted) await _openCalendar();
  }

  Future<void> _openCalendar() async {
    if (_calendarOpen) return;
    _calendarOpen = true;
    await showCalendarPopup(context, coinTarget: _coinTarget);
    _calendarOpen = false;
    if (mounted) setState(() {});
  }

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
    final retention = services.retention;
    final now = services.today();
    final calendar = retention.calendar.state(now);
    final trophyBadge = retention.achievements.badgeCount;
    final event = retention.event.current(now);
    final luckyFree = retention.luckyNest.state(localDay(now)).freeAvailable;
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
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(children: [
                      StatPill(
                        key: const Key('streak'),
                        icon: FlameIcon(lit: streak > 0),
                        text: l10n.streakDays(streak),
                        color: streak > 0 ? goldSoft : paper,
                      ),
                      const SizedBox(width: 8),
                      CoinCounter(key: const Key('homeCoins'), value: stats.coins, iconKey: _coinTarget),
                    ]),
                  ),
                ),
                const SizedBox(width: 6),
                _BadgedButton(
                  badge: calendar.available ? const _Dot() : null,
                  child: RoundIconButton(
                    key: const Key('calendarButton'),
                    icon: Icons.calendar_month_rounded,
                    color: coral,
                    size: 44,
                    tooltip: l10n.calendarTitle,
                    onPressed: _openCalendar,
                  ),
                ),
                const SizedBox(width: 6),
                _BadgedButton(
                  badge: trophyBadge > 0 ? CountBadge(key: const Key('trophyBadge'), count: trophyBadge) : null,
                  child: RoundIconButton(
                    key: const Key('trophies'),
                    icon: Icons.emoji_events_rounded,
                    color: gold,
                    size: 44,
                    tooltip: l10n.trophies,
                    onPressed: () => _open(const TrophiesScreen()),
                  ),
                ),
                const SizedBox(width: 6),
                RoundIconButton(
                  key: const Key('settings'),
                  icon: Icons.settings_rounded,
                  color: woodButton,
                  size: 44,
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
                  if (event != null) ...[
                    enter(EventBanner(state: event, onTap: () => _open(const EventScreen()))),
                    const SizedBox(height: 14),
                  ],
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
          _Foreground(
            mascots: buddyCritters(stats, 3),
            luckyFree: luckyFree,
            onShop: () => _open(const ShopScreen()),
            onNest: () => _open(const LuckyNestScreen()),
          ),
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

/// The grass at the bottom of the home screen: the market stall, critters playing, and the Lucky Nest.
class _Foreground extends StatelessWidget {
  const _Foreground({required this.mascots, required this.luckyFree, required this.onShop, required this.onNest});

  final List<String> mascots;
  final bool luckyFree;
  final VoidCallback onShop;
  final VoidCallback onNest;

  static const _sizes = [70.0, 84.0, 66.0];

  @override
  Widget build(BuildContext context) {
    // Short phones get smaller critters, so the list keeps its room.
    final k = (MediaQuery.sizeOf(context).height / 820).clamp(0.72, 1.0);
    return SizedBox(
      height: 108 * k,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Padding(
            padding: EdgeInsets.only(bottom: 4 * k),
            child: PopIn(
              delay: const Duration(milliseconds: 300),
              child: ShopStall(key: const Key('shopStall'), size: 92 * k, onTap: onShop),
            ),
          ),
          Expanded(
            // Scales down on narrow phones instead of overflowing.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomCenter,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (final (i, id) in mascots.indexed)
                  Padding(
                    padding: EdgeInsets.fromLTRB(4, 0, 4, (i.isEven ? 4 : 12) * k),
                    child: PopIn(
                      delay: Duration(milliseconds: 350 + 120 * i),
                      duration: const Duration(milliseconds: 650),
                      child: CritterBuddy(id, key: Key('mascot-$i'), size: _sizes[i % _sizes.length] * k, seed: i),
                    ),
                  ),
              ]),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 6 * k),
            child: PopIn(
              delay: const Duration(milliseconds: 750),
              child: LuckyNestProp(key: const Key('luckyNest'), free: luckyFree, size: 84 * k, onTap: onNest),
            ),
          ),
        ]),
      ),
    );
  }
}

/// A round button with a badge on its top-right corner.
class _BadgedButton extends StatelessWidget {
  const _BadgedButton({required this.child, this.badge});

  final Widget child;
  final Widget? badge;

  @override
  Widget build(BuildContext context) => Stack(clipBehavior: Clip.none, children: [
        child,
        if (badge != null) Positioned(right: -6, top: -6, child: badge!),
      ]);
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('calendarDot'),
        width: 16,
        height: 16,
        decoration: BoxDecoration(color: bad, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2.5)),
      );
}

/// A little market stall with a striped awning: the way into the shop.
class ShopStall extends StatelessWidget {
  const ShopStall({super.key, required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Bouncy(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: l10n.shop,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: const _StallPainter(),
            child: Align(
              alignment: const Alignment(0, 0.56),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size * 0.14),
                child: FittedBox(
                  child: Text(l10n.shop, style: outlinedText(15, color: const Color(0xFFFFF4D6), stroke: woodEdge, width: 1.4)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StallPainter extends CustomPainter {
  const _StallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final post = Paint()..color = woodDark;
    canvas.drawOval(Rect.fromLTWH(w * 0.04, h * 0.9, w * 0.92, h * 0.1), Paint()..color = const Color(0x2A000000));
    // Posts.
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, h * 0.22, w * 0.07, h * 0.72), const Radius.circular(3)), post);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.81, h * 0.22, w * 0.07, h * 0.72), const Radius.circular(3)), post);
    // Goods on the counter: a capsule, a coin pile and a party hat.
    canvas.drawCircle(Offset(w * 0.3, h * 0.53), w * 0.08, Paint()..color = coral);
    canvas.drawCircle(Offset(w * 0.3, h * 0.58), w * 0.075, Paint()..color = const Color(0xFFFFFBF3));
    canvas.drawRect(Rect.fromLTWH(w * 0.22, h * 0.545, w * 0.16, h * 0.022), Paint()..color = Colors.white);
    for (final (x, y) in const [(0.64, 0.58), (0.74, 0.58), (0.69, 0.52)]) {
      canvas.drawCircle(Offset(w * x, h * y), w * 0.055, Paint()..color = goldEdge);
      canvas.drawCircle(Offset(w * x, h * y - 1), w * 0.05, Paint()..color = gold);
    }
    final cone = Path()
      ..moveTo(w * 0.42, h * 0.63)
      ..lineTo(w * 0.5, h * 0.42)
      ..lineTo(w * 0.58, h * 0.63)
      ..close();
    canvas.drawPath(cone, Paint()..color = sky);
    canvas.drawCircle(Offset(w * 0.5, h * 0.42), w * 0.035, Paint()..color = const Color(0xFFFFE066));
    // Counter.
    final counter = Rect.fromLTWH(w * 0.02, h * 0.62, w * 0.96, h * 0.32);
    canvas.save();
    canvas.translate(counter.left, counter.top);
    WoodPainter(radius: 8, nails: false, plank: h * 0.16).paint(canvas, counter.size);
    canvas.restore();
    // Striped awning with a scalloped edge.
    final top = h * 0.04, bottom = h * 0.28;
    final awning = Path()
      ..moveTo(w * 0.1, top)
      ..lineTo(w * 0.9, top)
      ..lineTo(w, bottom)
      ..lineTo(0, bottom)
      ..close();
    canvas.drawPath(awning.shift(const Offset(0, 3)), Paint()..color = const Color(0x33000000));
    const stripes = 6;
    final cream = Paint()..color = const Color(0xFFFFF8E7);
    final red = Paint()..color = bad;
    canvas.save();
    canvas.clipPath(awning);
    for (var i = 0; i < stripes; i++) {
      canvas.drawRect(Rect.fromLTWH(w * i / stripes, 0, w / stripes, h), i.isEven ? red : cream);
    }
    canvas.restore();
    for (var i = 0; i < stripes; i++) {
      canvas.drawArc(Rect.fromLTWH(w * i / stripes, bottom - h * 0.06, w / stripes, h * 0.12), 0, pi, true, i.isEven ? red : cream);
    }
    canvas.drawPath(awning, Paint()
      ..color = const Color(0xFFA8323A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_StallPainter old) => false;
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
