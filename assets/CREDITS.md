# Asset credits

Every asset is free: CC0 / public domain, the SIL Open Font License, or drawn in code. The critter sprites and
sounds are by **Kenney** ([kenney.nl](https://kenney.nl)), released under **Creative Commons Zero (CC0 1.0)** —
<http://creativecommons.org/publicdomain/zero/1.0/>. Credit is not required; we give it anyway. Thank you, Kenney!

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

## Fonts

All under the **SIL Open Font License 1.1**, from the official Google Fonts repository
(<https://github.com/google/fonts/tree/main/ofl>); the licence text ships next to each font. None of them has a
Reserved Font Name, so the instancing/subsetting below keeps their names, as the OFL allows.

- `assets/fonts/Fredoka-{Medium,SemiBold,Bold}.ttf` — **Fredoka**, Copyright 2016 The Fredoka Project Authors
  (github.com/hafontia/Fredoka-One), from the official Google Fonts repository (<https://github.com/google/fonts/tree/main/ofl/fredoka>),
  licensed under the **SIL Open Font License 1.1** (full text in `assets/fonts/OFL.txt`). The three files are static
  instances (weights 500/600/700, width 100) cut from the variable `Fredoka[wdth,wght].ttf` with fontTools; the font
  is unmodified otherwise and keeps its name, as the OFL allows for instances.
- `assets/fonts/ZillaSlab-{Medium,SemiBold,Bold}.ttf` — **Zilla Slab**, Copyright 2017 The Mozilla Foundation
  (`ofl/zillaslab`), licence `assets/fonts/licenses/ZillaSlab-OFL.txt`. Wild Lodge UI font.
- `assets/fonts/Bevan-Regular.ttf` — **Bevan**, Copyright 2016 The Bevan Project Authors (`ofl/bevan`), licence
  `assets/fonts/licenses/Bevan-OFL.txt`. Wild Lodge title sign (registered as weight 700).
- `assets/fonts/Exo2-{Medium,SemiBold,Bold}.ttf` — **Exo 2**, Copyright 2013 The Exo 2 Project Authors (`ofl/exo2`),
  licence `assets/fonts/licenses/Exo2-OFL.txt`. Night Neon font; static 500/600/700 instances of `Exo2[wght].ttf`.
- `assets/fonts/Inter-{Medium,SemiBold,Bold}.ttf` — **Inter**, Copyright 2020 The Inter Project Authors (`ofl/inter`),
  licence `assets/fonts/licenses/Inter-OFL.txt`. Clean Pro font; static 500/600/700 instances (opsz 14) of
  `Inter[opsz,wght].ttf`.

The World fonts (all but Fredoka) are subset with fontTools to Latin + Latin Extended + punctuation (English, French,
Spanish) to keep the app small. Orbitron was considered for Night Neon and dropped: it has a Reserved Font Name, so a
subset would have to be renamed.

## Wild Lodge wildlife silhouettes (`assets/silhouettes/`)

From **PhyloPic** (<https://www.phylopic.org>). Each image's licence was read from its own PhyloPic API record
(`https://api.phylopic.org/images/<uuid>`, `_links.license.href`) on 2026-11-12; only **CC0 1.0**
(<https://creativecommons.org/publicdomain/zero/1.0/>) and the **Public Domain Mark 1.0**
(<https://creativecommons.org/publicdomain/mark/1.0/>) were accepted, nothing CC-BY/NC/SA. No attribution is
required; contributors are listed as thanks. Processing: PhyloPic's largest raster → one black color on transparent,
trimmed, 512 px on the long side (the panda's patches and zebra's stripes stay as transparent gaps). The game tints
them in a medallion; the file is named after the album critter it stands for, as a wild cousin where the critter is
a farm animal.

| File | Animal shown | Contributor | Licence | Source |
|---|---|---|---|---|
| `chick.png` | California quail (*Callipepla californica*) | Ferran Sayol | CC0 1.0 | <https://www.phylopic.org/images/48053987-63c1-47bc-87c3-2abf84480a6f> |
| `chicken.png` | Wild turkey (Merriam's), strutting (*Meleagris gallopavo merriami*) | T. Michael Keesey | CC0 1.0 | <https://www.phylopic.org/images/101ad9ab-dae8-442f-b102-8109b02b2a69> |
| `duck.png` | Mallard (swimming) (*Anas platyrhynchos*) | Andy Wilson | CC0 1.0 | <https://www.phylopic.org/images/97f833ff-fcd8-4113-8948-721c75372462> |
| `pig.png` | Wild boar (*Sus scrofa*) | Ferran Sayol | CC0 1.0 | <https://www.phylopic.org/images/87047da1-b40e-4b31-8492-4db262f129f5> |
| `goat.png` | Nubian ibex (*Capra nubiana*) | Gopal Murali | CC0 1.0 | <https://www.phylopic.org/images/52c28a94-15e2-482d-ac4d-f75ce7b09b95> |
| `cow.png` | American bison (*Bos bison*) | Tracy A. Heath / uploaded by Tracy Heath | CC0 1.0 | <https://www.phylopic.org/images/d44d834e-1c32-4a08-a5d5-f30139de4450> |
| `dog.png` | Grey wolf (howling) (*Canis lupus monstrabilis*) | Tracy A. Heath / uploaded by Tracy Heath | CC0 1.0 | <https://www.phylopic.org/images/e4e306cd-73b6-4ca3-a08c-753a856f7f12> |
| `rabbit.png` | European hare (*Lepus europaeus*) | Ferran Sayol | CC0 1.0 | <https://www.phylopic.org/images/9ab9aa41-a1b2-4def-84e9-b86de786064a> |
| `frog.png` | American bullfrog (*Rana catesbeiana*) | Chuanixn Yu / uploaded by Chuanxin Yu | CC0 1.0 | <https://www.phylopic.org/images/77f50b2e-9679-4ded-9faf-ff77d490c40a> |
| `horse.png` | Horse (trotting) (*Equus ferus caballus*) | An Ignorant Atheist / uploaded by Jody Taylor | CC0 1.0 | <https://www.phylopic.org/images/7aa15a09-470e-4e71-b1fe-5ab15622cbb2> |
| `owl.png` | Eurasian eagle-owl (*Bubo bubo*) | the von Wright brothers / uploaded by T. Michael Keesey | Public Domain Mark 1.0 | <https://www.phylopic.org/images/d7d457c1-4c08-4e7e-9af4-f537020c2775> |
| `panda.png` | Giant panda (3/4 view, black patches + outline, white areas transparent) (*Ailuropoda melanoleuca*) | Margot Michaud | CC0 1.0 | <https://www.phylopic.org/images/3d259941-f8c2-48cb-843b-af4a178031e9> |
| `zebra.png` | Plains zebra (Chapman's), striped line-art, white areas transparent (*Equus quagga chapmani*) | Andy Wilson | CC0 1.0 | <https://www.phylopic.org/images/22f808e2-da14-4bfe-9672-0e5422d27212> |
| `buffalo.png` | African (Cape) buffalo (*Syncerus caffer*) | An Ignorant Atheist / uploaded by Jody Taylor | CC0 1.0 | <https://www.phylopic.org/images/65c4a9b3-dcde-4f0f-9a1f-8d71e74be9ec> |
| `hippo.png` | Hippopotamus (*Hippopotamus amphibius*) | An Ignorant Atheist / uploaded by Jody Taylor | CC0 1.0 | <https://www.phylopic.org/images/e130f877-a96c-48d8-9f26-bb131021397f> |
| `rhino.png` | White rhinoceros (*Ceratotherium simum simum*) | Kai Caspar | CC0 1.0 | <https://www.phylopic.org/images/7f867be1-815c-4fe4-a341-be7c22970890> |
| `giraffe.png` | Giraffe (*Giraffa*) | An Ignorant Atheist / uploaded by Jody Taylor | CC0 1.0 | <https://www.phylopic.org/images/bbce74cf-4df3-4b7d-8b1d-f5b24dd3264a> |
| `elephant.png` | African elephant (*Loxodonta*) | An Ignorant Atheist / uploaded by Jody Taylor | CC0 1.0 | <https://www.phylopic.org/images/47a8b95c-4981-4873-a87a-c51e99f34f63> |
| `snake.png` | Prairie rattlesnake (*Crotalus viridis*) | Blair Perry | CC0 1.0 | <https://www.phylopic.org/images/b58a7ca7-8d14-4d7b-88a5-f2b05de79c85> |
| `crocodile.png` | Saltwater crocodile (*Crocodylus porosus*) | Steven Traver | CC0 1.0 | <https://www.phylopic.org/images/a796420f-5158-4e96-acbe-e30ef36b26d6> |
| `parrot.png` | Scarlet macaw (*Ara macao*) | Myriam_Ramirez / uploaded by Myriam Ramirez | CC0 1.0 | <https://www.phylopic.org/images/0d19238f-25ca-42a5-a1e2-d108defb75f1> |
| `gorilla.png` | Western gorilla (silverback) (*Gorilla gorilla*) | Margot Michaud | CC0 1.0 | <https://www.phylopic.org/images/142e0571-3b5f-443d-a887-b572a224ea22> |
| `monkey.png` | Rhesus macaque (*Macaca mulatta*) | Ben Murrell | CC0 1.0 | <https://www.phylopic.org/images/63169c26-e130-4f3b-8c34-02ec8b0862c7> |
| `sloth.png` | Three-toed sloth (hanging on branch) (*Bradypus*) | Cecina Babich Morrow | CC0 1.0 | <https://www.phylopic.org/images/dbc172df-a4c7-4d0d-9388-c337d01aca52> |
| `moose.png` | Moose (bull) (*Alces alces*) | (no attribution given) / uploaded by T. Michael Keesey | Public Domain Mark 1.0 | <https://www.phylopic.org/images/1a20a65d-1342-4833-a9dd-1611b9fb383c> |
| `bear.png` | Grizzly bear (*Ursus arctos horribilis*) | xgirouxb | Public Domain Mark 1.0 | <https://www.phylopic.org/images/0cd82109-bb1c-4e08-ab11-c845d8a82eba> |
| `walrus.png` | Walrus (*Odobenus rosmarus*) | Margot Michaud | CC0 1.0 | <https://www.phylopic.org/images/d2575005-1fcb-4a86-8c83-e3bda619adf2> |
| `whale.png` | Humpback whale (*Balaenoptera novaeangliae*) | (no attribution given) / uploaded by T. Michael Keesey | Public Domain Mark 1.0 | <https://www.phylopic.org/images/fd8d3e5e-24a0-4aa2-9211-987ff86007dd> |
| `penguin.png` | King penguin (*Aptenodytes patagonicus*) | Alexandre Vong | CC0 1.0 | <https://www.phylopic.org/images/4c20cc68-1acd-4c5a-adfe-86a61609748b> |
| `narwhal.png` | Narwhal (*Monodon monoceros*) | (no attribution given) / uploaded by Olesja Bogomaz | CC0 1.0 | <https://www.phylopic.org/images/d2616332-2584-4504-a463-2bf6f9fc6412> |

## Worlds UI

The World landscapes (Lodge dusk forest and campfire, Neon grid and skyline, Winter aurora, cabin and snow, Clean Pro
slate), panels, buttons, signs, badges, scarves, streak icons and board marks are all drawn in code
(`lib/ui/worlds/`); no image assets besides the silhouettes above.

## Meadow UI

The meadow world (sky, sun, clouds, hills, flowers, trees), wooden signs and panels, candy buttons, coins, stars,
the egg capsule and nest, the level trail and its decorations are all drawn in code (`lib/ui/worlds/meadow_world.dart`,
`lib/ui/widgets.dart`, `lib/ui/capsule_screen.dart`, `lib/ui/level_path_screen.dart`); no image assets were added.
