/// How hard a critter is to get from a capsule.
enum Rarity { common, rare, golden }

/// A collectible critter. [id] is also the sprite name in assets/critters/.
class Critter {
  const Critter(this.id, this.set, this.rarity);

  final String id;
  final String set;
  final Rarity rarity;
}

/// The album: 5 sets of 6, each with 4 common, 1 rare and 1 golden critter (golden ones use a gold frame).
const album = <Critter>[
  Critter('chick', 'farm', Rarity.common),
  Critter('chicken', 'farm', Rarity.common),
  Critter('duck', 'farm', Rarity.common),
  Critter('pig', 'farm', Rarity.common),
  Critter('goat', 'farm', Rarity.rare),
  Critter('cow', 'farm', Rarity.golden),
  Critter('dog', 'friends', Rarity.common),
  Critter('rabbit', 'friends', Rarity.common),
  Critter('frog', 'friends', Rarity.common),
  Critter('horse', 'friends', Rarity.common),
  Critter('owl', 'friends', Rarity.rare),
  Critter('panda', 'friends', Rarity.golden),
  Critter('zebra', 'savanna', Rarity.common),
  Critter('buffalo', 'savanna', Rarity.common),
  Critter('hippo', 'savanna', Rarity.common),
  Critter('rhino', 'savanna', Rarity.common),
  Critter('giraffe', 'savanna', Rarity.rare),
  Critter('elephant', 'savanna', Rarity.golden),
  Critter('snake', 'jungle', Rarity.common),
  Critter('crocodile', 'jungle', Rarity.common),
  Critter('parrot', 'jungle', Rarity.common),
  Critter('gorilla', 'jungle', Rarity.common),
  Critter('monkey', 'jungle', Rarity.rare),
  Critter('sloth', 'jungle', Rarity.golden),
  Critter('moose', 'polar', Rarity.common),
  Critter('bear', 'polar', Rarity.common),
  Critter('walrus', 'polar', Rarity.common),
  Critter('whale', 'polar', Rarity.common),
  Critter('penguin', 'polar', Rarity.rare),
  Critter('narwhal', 'polar', Rarity.golden),
];

const albumSets = ['farm', 'friends', 'savanna', 'jungle', 'polar'];

final critterById = {for (final c in album) c.id: c};
