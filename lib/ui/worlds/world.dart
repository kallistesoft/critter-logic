import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../l10n/app_localizations.dart';
import 'level_mark.dart';
import 'lodge_world.dart';
import 'meadow_world.dart';
import 'neon_world.dart';
import 'pro_world.dart';
import 'winter_world.dart';

/// The colors every screen reads (through the getters in `palette.dart`). The names come from the Meadow, where they
/// were born; in other Worlds they keep their role: [paper] is the card fill, [ink] the text on it, [wood*] the
/// panels and plaques, [leaf] the main button, [sky*] the secondary button and the background.
class WorldPalette {
  const WorldPalette({
    required this.background,
    required this.surface,
    required this.ink,
    required this.inkSoft,
    required this.accent,
    required this.good,
    required this.bad,
    required this.gold,
    required this.skyTop,
    required this.skyMid,
    required this.skyLow,
    required this.hillFar,
    required this.hillMid,
    required this.grass,
    required this.grassDark,
    required this.soil,
    required this.wood,
    required this.woodLight,
    required this.woodDark,
    required this.woodEdge,
    required this.paper,
    required this.paperEdge,
    required this.leaf,
    required this.leafEdge,
    required this.sky,
    required this.skyEdge,
    required this.goldEdge,
    required this.coral,
    required this.coralEdge,
    required this.woodButton,
    required this.sunColor,
    required this.moonColor,
    required this.accentSoft,
    required this.goodSoft,
    required this.goldSoft,
    required this.rareBlue,
    required this.rareSoft,
    required this.tileEmpty,
    required this.tileGiven,
    required this.shadow,
    required this.onWood,
    required this.onWoodSoft,
    required this.barrier,
  });

  final Color background, surface, ink, inkSoft, accent, good, bad, gold;
  final Color skyTop, skyMid, skyLow, hillFar, hillMid, grass, grassDark, soil;
  final Color wood, woodLight, woodDark, woodEdge, paper, paperEdge;
  final Color leaf, leafEdge, sky, skyEdge, goldEdge, coral, coralEdge, woodButton;
  final Color sunColor, moonColor;
  final Color accentSoft, goodSoft, goldSoft, rareBlue, rareSoft, tileEmpty, tileGiven, shadow;

  /// Text on [wood] panels and plaques.
  final Color onWood, onWoodSoft;

  /// Dim layer behind dialogs.
  final Color barrier;
}

/// The colors of the game boards: Nests beds and zone borders, Pairs lawn and stones, Trail grass, path and walls,
/// and the little art on the home daily cards.
class BoardPalette {
  const BoardPalette({
    required this.zones,
    required this.bedShine,
    required this.speckles,
    required this.cellLine,
    required this.zoneEdge,
    required this.zoneEdgeInner,
    this.zoneDots,
    this.glow = false,
    required this.ruledOut,
    required this.lawnTop,
    required this.lawnBottom,
    required this.lawnEdge,
    required this.lawnTuft,
    required this.stoneTop,
    required this.stoneLow,
    required this.stoneEdge,
    required this.givenTop,
    required this.givenLow,
    required this.givenEdge,
    this.moss,
    required this.stoneShine,
    required this.linkFill,
    required this.linkEdge,
    required this.grassLight,
    required this.grassDark,
    required this.grassLine,
    required this.dirtEdge,
    required this.dirtFill,
    required this.dirtGlow,
    required this.dirtPrint,
    required this.pebbleTop,
    required this.pebbleLow,
    required this.pebbleRim,
    required this.pebbleText,
    required this.pebbleReachedTop,
    required this.pebbleReachedLow,
    required this.pebbleReachedRim,
    required this.pebbleReachedText,
    required this.cardNests,
    required this.cardPairs,
    required this.cardTrail,
    required this.cardEdge,
  });

  /// Nests zone colors, by zone id (up to 10 zones).
  final List<Color> zones;

  /// Soft light in each bed's top-left corner (transparent = none).
  final Color bedShine;

  /// Little soil speckles in the beds.
  final bool speckles;

  /// Lines between cells of one zone.
  final Color cellLine;

  /// Borders between zones (Nests) and walls (Trail): outer stroke, inner stroke, and dots along them.
  final Color zoneEdge, zoneEdgeInner;
  final Color? zoneDots;

  /// Borders glow (a blurred copy under them).
  final bool glow;

  /// The faint dot of an auto-crossed Nests cell.
  final Color ruledOut;

  final Color lawnTop, lawnBottom, lawnEdge, lawnTuft;
  final Color stoneTop, stoneLow, stoneEdge, givenTop, givenLow, givenEdge;
  final Color? moss;
  final Color stoneShine;
  final Color linkFill, linkEdge;

  final Color grassLight, grassDark, grassLine;
  final Color dirtEdge, dirtFill, dirtGlow, dirtPrint;
  final Color pebbleTop, pebbleLow, pebbleRim, pebbleText;
  final Color pebbleReachedTop, pebbleReachedLow, pebbleReachedRim, pebbleReachedText;

  /// Gradients behind the little game art on the home daily cards, and their border.
  final List<Color> cardNests, cardPairs, cardTrail;
  final Color cardEdge;
}

/// Where a critter is drawn: a game piece on a board, a decoration (home mascots, cheering), or a collectible
/// (album, capsules, rewards).
enum CritterRole { piece, decoration, collectible }

/// A full-app look. Same game, progress and rewards underneath; everything visible reads it.
///
/// Adding a World: subclass this (palette, board palette, fonts, background, panels, buttons, sign, critters), add it
/// to [worlds], add its `world.<id>` shop item and l10n name, and record any assets in `assets/CREDITS.md`.
abstract class GameWorld {
  const GameWorld();

  /// Shop item id, e.g. `world.meadow`.
  String get id;

  String name(AppLocalizations l10n);
  String blurb(AppLocalizations l10n);

  WorldPalette get palette;
  BoardPalette get board;

  /// Display font family (titles, numbers, buttons, body).
  String get font;

  /// Font family of big titles (the home sign, headers).
  String get titleFont => font;

  Brightness get brightness => Brightness.light;

  /// Decorative extras: home mascots, the market stall art, the nest prop, cheering critters. Off = flat and clean.
  bool get decorations => true;

  /// The cartoon props on the home ground (the striped market stall, the nest of pastel eggs). Off = plain plaques.
  bool get cartoonProps => decorations;

  /// Critters wear the equipped hat.
  bool get hats => true;

  /// Confetti and sparkle colors.
  List<Color> get celebration;

  /// Rounded corners of cards and buttons.
  double get radius => 20;

  /// Ground of the level map (top, middle, bottom of a vertical gradient).
  List<Color> get mapGround => const [Color(0xFF9ED97A), Color(0xFF6CC04A), Color(0xFF8BD26A)];

  /// Cartoon props on the level map (round bushes and trees, flowers, rocks, mushrooms).
  bool get mapProps => decorations;

  /// The album title.
  String albumTitle(AppLocalizations l10n) => l10n.album;

  /// The album is a field journal (lined paper, sketchy frames).
  bool get journal => false;

  // ---- Text ----

  /// Chunky type in the world's display font.
  TextStyle text(double size, {Color? color, FontWeight weight = FontWeight.w700, double? height, String? family}) =>
      TextStyle(
        fontFamily: family ?? font,
        color: color ?? palette.ink,
        fontSize: size,
        fontWeight: weight.value >= 700 ? FontWeight.w700 : (weight.value >= 600 ? FontWeight.w600 : FontWeight.w500),
        height: height,
        letterSpacing: 0.1,
      );

  /// Light text that stands out over the background (section titles) and on buttons: a cartoon outline by default.
  TextStyle outlined(double size, {Color? color, Color? stroke, double? width}) => text(size, color: color ?? Colors.white)
      .copyWith(shadows: cartoonOutline(stroke ?? palette.woodEdge, width ?? max(1.5, size * 0.07)));

  // ---- Background ----

  /// The full-screen landscape behind every page. Animate cheaply (RepaintBoundary) and stay still when
  /// [ambientMotionOn] is false.
  Widget background(BuildContext context);

  /// Bottom band behind the banner ad.
  Color get bannerStrip => palette.soil;
  Color get bannerEdge => palette.grassDark;

  // ---- Panels and buttons ----

  /// A "wood" panel (plaques, level cards, board frames): fills [size] from its top-left.
  void paintPanel(Canvas canvas, Size size, {double radius = 18, bool nails = true, double plank = 34});

  /// A paper card's look.
  BoxDecoration card({Color? fill, Color? border}) {
    final f = fill ?? palette.paper;
    final edge = border ?? Color.lerp(f, palette.woodDark, 0.32)!;
    return BoxDecoration(
      color: f,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border ?? palette.paperEdge, width: border == null ? 2.5 : 3.5),
      boxShadow: [
        BoxShadow(color: edge, offset: const Offset(0, 5)),
        BoxShadow(color: palette.shadow, blurRadius: 14, offset: const Offset(0, 9)),
      ],
    );
  }

  /// The pill behind HUD badges (coins, streak, timer).
  BoxDecoration pill(Color fill, double height) => BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(height),
        border: Border.all(color: palette.woodEdge.withValues(alpha: 0.75), width: 2.5),
        boxShadow: [BoxShadow(color: palette.shadow, offset: const Offset(0, 3), blurRadius: 3)],
      );

  /// The darker rim of a button face color.
  Color edgeOf(Color c) => Color.lerp(c, const Color(0xFF3A2010), 0.32)!;

  /// Button depth (the thick bottom edge), small or regular.
  double buttonDepth(bool small) => small ? 4 : 6;

  /// A button: [press] 0 at rest, 1 pressed; [depth] is the edge thickness.
  void paintButton(Canvas canvas, Size size,
      {required Color face, required Color edge, double press = 0, double depth = 6, double radius = 20, bool circle = false});

  /// Label style on a button of [face] color.
  TextStyle buttonText(double size, {required Color textColor, required Color rim}) =>
      textColor.computeLuminance() > 0.5 ? outlined(size, color: textColor, stroke: rim, width: 1.6) : text(size, color: textColor);

  /// Icon color and shadow on a round icon button.
  Color iconColor(Color face) => Colors.white;
  List<Shadow> iconShadows(Color face) => [Shadow(color: edgeOf(face), offset: const Offset(0, 2))];

  /// What a disabled button's face fades toward.
  Color get disabledButton => const Color(0xFFBDB3A6);

  // ---- Title sign and header plaque ----

  /// The big home title ("Critter Logic").
  Widget sign(BuildContext context, {required String title, String? subtitle, double fontSize = 40});

  /// A header plaque with a title (screen tops).
  Widget label(BuildContext context, {required String text, String? subtitle, double fontSize = 22});

  // ---- Critters ----

  /// A critter in this World's style.
  Widget critter(BuildContext context, String id, double size, {CritterRole role = CritterRole.collectible});

  /// A critter's level (⭐1–5) drawn over its picture: fills a [size] square laid over [critter]. Chunky gold stars
  /// along the bottom by default.
  Widget levelMark(BuildContext context, int level, double size) => LevelMark(level: level, size: size);

  // ---- Icons ----

  /// The streak icon (a flame by default): [streak] lets it grow.
  void paintStreak(Canvas canvas, Size size, {required bool lit, int streak = 0});

  /// The Nests "not here" mark.
  void paintCross(Canvas canvas, Size size);
}

/// Every World, in shop order.
const List<GameWorld> worlds = [MeadowWorld(), LodgeWorld(), NeonWorld(), WinterWorld(), ProWorld()];

GameWorld worldById(String? id) => worlds.firstWhere((w) => w.id == id, orElse: () => worlds.first);

/// The equipped World, for code without a [BuildContext] (painters, `palette.dart` getters). Set by [WorldHost].
GameWorld activeWorld = const MeadowWorld();

/// The World of this part of the tree (a preview can show another one), else the equipped one.
GameWorld worldOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<WorldScope>()?.world ?? activeWorld;

/// Provides a World to its subtree (the app, or a preview of another World).
class WorldScope extends InheritedWidget {
  const WorldScope({super.key, required this.world, required super.child});

  final GameWorld world;

  @override
  bool updateShouldNotify(WorldScope old) => old.world.id != world.id;
}

/// A cartoon outline around text, made of shadows (so it stays a single [Text]).
List<Shadow> cartoonOutline(Color color, double width, {double drop = 1.8}) => [
      for (var k = 0; k < 8; k++) Shadow(color: color, offset: Offset(cos(k * pi / 4) * width, sin(k * pi / 4) * width)),
      Shadow(color: color, offset: Offset(0, width * drop)),
    ];

/// False when the player asked the system for reduced motion (and in widget tests): ambient loops stay still.
bool ambientMotionOn(BuildContext context) => !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

/// Holds the equipped World above the app; [switchTo] changes it everywhere at once.
class WorldHost extends StatefulWidget {
  const WorldHost({super.key, required this.initial, required this.builder});

  final GameWorld initial;
  final Widget Function(BuildContext context, GameWorld world) builder;

  static WorldHostState of(BuildContext context) => context.findAncestorStateOfType<WorldHostState>()!;

  static WorldHostState? maybeOf(BuildContext context) => context.findAncestorStateOfType<WorldHostState>();

  @override
  State<WorldHost> createState() => WorldHostState();
}

class WorldHostState extends State<WorldHost> {
  late GameWorld _world = widget.initial;

  GameWorld get world => _world;

  @override
  void initState() {
    super.initState();
    activeWorld = _world;
  }

  /// Redraws the whole app in [next]. Screens read colors through getters, and some widgets and painters are
  /// constant, so after the switch every element is rebuilt and every render object repainted once.
  void switchTo(GameWorld next) {
    if (next.id == _world.id) return;
    setState(() {
      _world = next;
      activeWorld = next;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshTree());
    _refreshTree();
  }

  void _refreshTree() {
    if (!mounted) return;
    void rebuild(Element e) {
      e.markNeedsBuild();
      e.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
    void repaint(RenderObject r) {
      r.markNeedsPaint();
      r.visitChildren(repaint);
    }

    for (final view in RendererBinding.instance.renderViews) {
      repaint(view);
    }
  }

  @override
  Widget build(BuildContext context) {
    activeWorld = _world;
    return WorldScope(world: _world, child: Builder(builder: (context) => widget.builder(context, _world)));
  }
}
