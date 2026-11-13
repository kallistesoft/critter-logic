import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
/// outline in Neon, and so on.
class CritterImage extends StatelessWidget {
  const CritterImage(this.id, {super.key, required this.size, this.role = CritterRole.collectible});

  final String id;
  final double size;
  final CritterRole role;

  @override
  Widget build(BuildContext context) => worldOf(context).critter(context, id, size, role: role);
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

/// Wild Lodge shows the wild cousin on each badge (a quail for the chick, a boar for the pig…), so it uses its name.
String? _lodgeName(AppLocalizations l10n, String id) => switch (id) {
      'chick' => l10n.lodgeChick,
      'chicken' => l10n.lodgeChicken,
      'pig' => l10n.lodgePig,
      'goat' => l10n.lodgeGoat,
      'cow' => l10n.lodgeCow,
      'dog' => l10n.lodgeDog,
      'rabbit' => l10n.lodgeRabbit,
      'frog' => l10n.lodgeFrog,
      'owl' => l10n.lodgeOwl,
      'bear' => l10n.lodgeBear,
      'monkey' => l10n.lodgeMonkey,
      'snake' => l10n.lodgeSnake,
      'parrot' => l10n.lodgeParrot,
      'gorilla' => l10n.lodgeGorilla,
      _ => null,
    };

String critterName(AppLocalizations l10n, String id) =>
    (activeWorld.id == 'world.lodge' ? _lodgeName(l10n, id) : null) ?? _critterName(l10n, id);

String _critterName(AppLocalizations l10n, String id) => switch (id) {
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
