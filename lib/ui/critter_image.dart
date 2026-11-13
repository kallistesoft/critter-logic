import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'album_screen.dart' show Shimmer;
import 'services.dart';
import 'worlds/world.dart';

/// Emoji stand-ins while (or if) a sprite is missing.
const critterEmoji = {
  'chick': '🐤',
  'chicken': '🐔',
  'duck': '🦆',
  'pig': '🐷',
  'goat': '🐐',
  'cow': '🐮',
  'dog': '🐶',
  'rabbit': '🐰',
  'frog': '🐸',
  'horse': '🐴',
  'owl': '🦉',
  'panda': '🐼',
  'zebra': '🦓',
  'buffalo': '🐃',
  'hippo': '🦛',
  'rhino': '🦏',
  'giraffe': '🦒',
  'elephant': '🐘',
  'snake': '🐍',
  'crocodile': '🐊',
  'parrot': '🦜',
  'gorilla': '🦍',
  'monkey': '🐵',
  'sloth': '🦥',
  'moose': '🫎',
  'bear': '🐻',
  'walrus': '🦭',
  'whale': '🐳',
  'penguin': '🐧',
  'narwhal': '🐋',
};

/// A critter drawn the World's way: the Kenney sprite in the Meadow, a wildlife badge in the Lodge, a glowing
/// outline in Neon, and so on. With a [level] (1–5) the World's level stars sit over it ([GameWorld.levelMark]),
/// and ⭐5 sparkles; [showLevel] reads the player's level of this critter instead.
class CritterImage extends StatelessWidget {
  const CritterImage(this.id,
      {super.key, required this.size, this.role = CritterRole.collectible, this.level, this.showLevel = false});

  final String id;
  final double size;
  final CritterRole role;
  final int? level;
  final bool showLevel;

  @override
  Widget build(BuildContext context) {
    final world = worldOf(context);
    final image = world.critter(context, id, size, role: role);
    final lvl = level ?? (showLevel ? critterLevel(context, id) : 0);
    if (lvl <= 0) return image;
    final marked = Semantics(
      label: AppLocalizations.of(context).critterLevelLabel(lvl),
      child: Stack(clipBehavior: Clip.none, children: [
        image,
        Positioned.fill(child: IgnorePointer(child: Center(child: world.levelMark(context, lvl, size)))),
      ]),
    );
    return lvl >= 5 ? Shimmer(child: marked) : marked;
  }
}

/// The player's level (0–5) of critter [id], from its copies and the Remote Config thresholds.
int critterLevel(BuildContext context, String id) {
  final services = Services.of(context);
  return services.retention.settings.critterLevels.levelOf(id, services.stats.copies(id));
}

/// The critter's sprite (`assets/critters/<id>.png`), or its emoji when the sprite isn't there.
class CritterSprite extends StatelessWidget {
  const CritterSprite(this.id, {super.key, required this.size});

  final String id;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'assets/critters/$id.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, _, _) => Center(
            child: Text(critterEmoji[id] ?? '🐾', style: TextStyle(fontSize: size * 0.78, height: 1)),
          ),
        ),
      );
}

/// Shows a critter as a flat silhouette (not collected yet).
class Silhouette extends StatelessWidget {
  const Silhouette({super.key, required this.child, this.color = const Color(0x333D3A4B)});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) => ColorFiltered(colorFilter: ColorFilter.mode(color, BlendMode.srcIn), child: child);
}

String critterName(AppLocalizations l10n, String id) => switch (id) {
      'chick' => l10n.critterChick,
      'chicken' => l10n.critterChicken,
      'duck' => l10n.critterDuck,
      'pig' => l10n.critterPig,
      'goat' => l10n.critterGoat,
      'cow' => l10n.critterCow,
      'dog' => l10n.critterDog,
      'rabbit' => l10n.critterRabbit,
      'frog' => l10n.critterFrog,
      'horse' => l10n.critterHorse,
      'owl' => l10n.critterOwl,
      'panda' => l10n.critterPanda,
      'zebra' => l10n.critterZebra,
      'buffalo' => l10n.critterBuffalo,
      'hippo' => l10n.critterHippo,
      'rhino' => l10n.critterRhino,
      'giraffe' => l10n.critterGiraffe,
      'elephant' => l10n.critterElephant,
      'snake' => l10n.critterSnake,
      'crocodile' => l10n.critterCrocodile,
      'parrot' => l10n.critterParrot,
      'gorilla' => l10n.critterGorilla,
      'monkey' => l10n.critterMonkey,
      'sloth' => l10n.critterSloth,
      'moose' => l10n.critterMoose,
      'bear' => l10n.critterBear,
      'walrus' => l10n.critterWalrus,
      'whale' => l10n.critterWhale,
      'penguin' => l10n.critterPenguin,
      'narwhal' => l10n.critterNarwhal,
      _ => id,
    };

String setName(AppLocalizations l10n, String set) => switch (set) {
      'farm' => l10n.setFarm,
      'friends' => l10n.setFriends,
      'savanna' => l10n.setSavanna,
      'jungle' => l10n.setJungle,
      'polar' => l10n.setPolar,
      _ => set,
    };

/// Under an owned critter: a thin bar toward the next level and "2/4 → ⭐3" (or "Max ⭐5").
class CritterLevelProgress extends StatelessWidget {
  const CritterLevelProgress({
    super.key,
    required this.copies,
    required this.level,
    required this.need,
    required this.ink,
    required this.track,
    required this.fill,
  });

  final int copies;
  final int level;

  /// Copies for the next level; null at ⭐5.
  final int? need;
  final Color ink, track, fill;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final need = this.need;
    final text = need == null ? l10n.critterLevelMax : l10n.critterLevelProgress(copies, need, level + 1);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: SizedBox(
          height: 4,
          child: LinearProgressIndicator(
            value: need == null ? 1 : (copies / need).clamp(0.0, 1.0),
            backgroundColor: track,
            valueColor: AlwaysStoppedAnimation(fill),
          ),
        ),
      ),
      const SizedBox(height: 1),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, maxLines: 1, style: worldOf(context).text(10.5, color: ink, weight: FontWeight.w600, height: 1.15)),
      ),
    ]);
  }
}
