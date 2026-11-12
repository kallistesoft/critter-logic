# Asset credits

All third-party assets are by **Kenney** ([kenney.nl](https://kenney.nl)) and released under
**Creative Commons Zero (CC0 1.0)** — <http://creativecommons.org/publicdomain/zero/1.0/>.
Credit is not required; we give it anyway. Thank you, Kenney!

| Pack | Page | License (checked in the pack's License.txt) | Used for |
|---|---|---|---|
| Animal Pack Remastered (the successor of "Animal Pack Redux"; kenney.nl/assets/animal-pack-redux redirects to it) | <https://kenney.nl/assets/animal-pack-remastered> | CC0 | `assets/critters/*.png` (all 30, "Round (outline)" style, from `Vector/roundOutline.svg`), the chick in `assets/icon/*` and the generated launcher icons |
| Interface Sounds 1.0 | <https://kenney.nl/assets/interface-sounds> | CC0 | `assets/sfx/`: tap, place, cross, erase, conflict, solve, coin, capsule, reveal, chest |
| RPG Audio | <https://kenney.nl/assets/rpg-audio> | CC0 | `assets/sfx/`: coin (`handleCoins2`), chest (`creak3`) |
| Casino Audio | <https://kenney.nl/assets/casino-audio> | CC0 | `assets/sfx/capsule.wav` (`dice-shake-1`) |

Exact source file → effect mapping: `tools/import_sfx.py` (`EFFECTS`). Critters: `tools/make_critters.py`
(pack file name = our critter id for all 30).

## Original

- `assets/music/loop.m4a` — original music, synthesized by `tools/make_music.py` (no samples).
- `assets/icon/*` board and background — drawn by `tools/make_icon.py`.

## Font

- `assets/fonts/Fredoka-{Medium,SemiBold,Bold}.ttf` — **Fredoka**, Copyright 2016 The Fredoka Project Authors
  (github.com/hafontia/Fredoka-One), from the official Google Fonts repository (<https://github.com/google/fonts/tree/main/ofl/fredoka>),
  licensed under the **SIL Open Font License 1.1** (full text in `assets/fonts/OFL.txt`). The three files are static
  instances (weights 500/600/700, width 100) cut from the variable `Fredoka[wdth,wght].ttf` with fontTools; the font
  is unmodified otherwise and keeps its name, as the OFL allows for instances.

## Meadow UI

The meadow world (sky, sun, clouds, hills, flowers, trees), wooden signs and panels, candy buttons, coins, stars,
the egg capsule and nest, the level trail and its decorations are all drawn in code (`lib/ui/meadow.dart`,
`lib/ui/widgets.dart`, `lib/ui/capsule_screen.dart`, `lib/ui/level_path_screen.dart`); no image assets were added.
