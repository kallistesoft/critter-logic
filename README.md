# Critter Logic

Daily logic puzzles with cute critters, for Android (iOS later), free with ads. Flutter, forked from Block Daily.

- **Nests**: one critter per row, column and color zone; critters never touch.
- **Pairs**: suns and moons, equal in every row and column, never three in a row, =/× links hold.
- **Daily**: one puzzle per game, the same for everyone, changing at local midnight (daily #1 = 2026-12-01, `lib/daily.dart`).
  Ranked by the first attempt's time on anonymous Firestore boards (`firestore.rules`).
- **Levels**: endless track per game, generated on the device.
- **Rewards**: coins (hints), a capsule with a collectible critter for solving both dailies, streak chests.

## Setup
- `android/app/google-services.json` (Firebase) is git-ignored; CI gets it from the `GOOGLE_SERVICES_JSON` secret.
- `android/key.properties` (upload key, kept in ~/Keys/kallistesoft/) is git-ignored.
- Debug builds use Google's test ads; release ad units go in `lib/services/ad_ids.dart` and the AdMob app ID in
  `android/app/build.gradle.kts`.
- Release: `tools/build_release.sh` on a clean main.

## Credits
Art and sounds from Kenney (kenney.nl), CC0.
