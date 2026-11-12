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
