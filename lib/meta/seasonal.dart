import 'album.dart';

/// A month and day, for yearly date windows.
class MonthDay {
  const MonthDay(this.month, this.day);

  final int month;
  final int day;

  int get _key => month * 100 + day;
}

/// A critter of a seasonal set: an existing [album] critter ([base], same sprite) shown in a seasonal [frame]
/// (e.g. 'snowy'), so no new art is needed. Its collectible id is `<base>@<set id>`.
class SeasonalCritter {
  const SeasonalCritter(this.base, this.rarity, {required this.frame});

  final String base;
  final Rarity rarity;
  final String frame;

  /// The album critter this one reuses.
  Critter get critter => critterById[base]!;
}

/// A limited-time set, available between [start] and [end] inclusive each year (local dates); a window may cross
/// New Year (Dec → Feb). Data only for now: capsules, album and events don't use them yet.
class SeasonalSet {
  const SeasonalSet({required this.id, required this.start, required this.end, required this.critters});

  final String id;
  final MonthDay start;
  final MonthDay end;
  final List<SeasonalCritter> critters;

  bool isActive(DateTime now) {
    final key = now.month * 100 + now.day;
    return start._key <= end._key
        ? key >= start._key && key <= end._key
        : key >= start._key || key <= end._key;
  }

  /// Collectible id of [critter] in this set, kept apart from the album's ids.
  String idOf(SeasonalCritter critter) => '${critter.base}@$id';
}

/// Winter: the polar critters in a snowy frame, Dec 1 – Feb 28 (Feb 29 of leap years is outside the window).
const winterSet = SeasonalSet(
  id: 'winter',
  start: MonthDay(12, 1),
  end: MonthDay(2, 28),
  critters: [
    SeasonalCritter('moose', Rarity.common, frame: 'snowy'),
    SeasonalCritter('bear', Rarity.common, frame: 'snowy'),
    SeasonalCritter('walrus', Rarity.common, frame: 'snowy'),
    SeasonalCritter('whale', Rarity.common, frame: 'snowy'),
    SeasonalCritter('penguin', Rarity.rare, frame: 'snowy'),
    SeasonalCritter('narwhal', Rarity.golden, frame: 'snowy'),
  ],
);

const seasonalSets = [winterSet];

/// Seasonal sets on at [now] (local time).
List<SeasonalSet> activeSeasonalSets(DateTime now) => [for (final s in seasonalSets) if (s.isActive(now)) s];
