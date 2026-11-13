# Store listing (Google Play)

`listing.json` holds the Play Console text for every store language, in the same shape as Block Daily's
`store/listing.json`: one key per Play locale code, each with

| Field | Play Console field | Limit |
|---|---|---|
| `title` | App name | 30 |
| `short` | Short description | 80 |
| `full` | Full description | 4 000 |
| `releaseNotes` | Release notes for the first release (en-US, fr-*, es-* only) | 500 |

Languages (20): en-US, fr-CA, fr-FR, es-419, es-ES, es-US, de-DE, it-IT, pt-BR, nl-NL, pl-PL, tr-TR, ru-RU, id, vi, th,
ja-JP, ko-KR, zh-TW, hi-IN. en-US is the default language; Play shows its release notes in languages without their own.

- The app's menus are in English, French and Spanish only, so the other languages say so, and keep the in-app
  English names (Nests, Pairs, Trail, Lucky Nest, Meadow, Wild Lodge, Night Neon, Winter Cabin, Clean Pro) so players
  recognise them. French and Spanish use the app's own names (Nids/Paires/Sentier, Nidos/Parejas/Sendero, etc.).
- The Lucky Nest is described as an egg draw with the odds shown; no casino wording ("bet", "jackpot", "spin").
- No ranking claims (#1, best, top); the title and short description must not contain promo wording.

## Check before uploading

```sh
python3 store/check_listing.py
```

It prints each field's length against its limit and fails on a missing locale or field, an over-long field, or promo
wording in a title or short description. Lengths are Unicode code points (NFC), as Play counts them.

## Category and tags (Play Console › Store settings)

- App category: **Game › Puzzle**
- Tags (pick up to 5): **Logic**, **Brain games**, **Casual**, **Relaxing**, **Offline** (others that fit: Single
  player, Stylized, Cute)
- Contains ads: yes. In-app purchases: yes ("No ads" one-time, coin packs).
- Privacy policy: https://kallistesoft.ca/en/privacy/critter-logic/ (FR: https://kallistesoft.ca/confidentialite/critter-logic/)

## Graphics and promo videos

| File | What |
|---|---|
| `icon-512.png` | Play icon, 512 × 512, from `assets/icon/icon.png` |
| `feature-graphic-en.png`, `feature-graphic-fr.png` | Feature graphic, 1024 × 500 (fr for fr-CA and fr-FR) |
| `screenshots/<locale>/phone/` | 8 phone screenshots, 1080 × 1920 (en-US, fr-CA; fr-FR reuses fr-CA) |
| `screenshots/<locale>/tablet7/`, `tablet10/` | 4 each, 1200 × 1920 and 1600 × 2560 |
| `video/promo-<en\|fr>-<16x9\|9x16>.mp4` | 30 s promo videos, H.264 + AAC, 1920 × 1080 / 1080 × 1920, 30 fps (for YouTube; the Play listing takes a YouTube URL) |

Everything is real app footage: the promo build (`tools/promo_main.dart`) is the app on a staged save (12-day streak,
1,240 coins, 22/30 critters, levels with stars, daily #13, a local stand-in for the online ranking) with no ads at all,
run on the Android emulator with a clean status bar. Nothing here shows test ads or debug UI.

Regenerate (Android emulator `emulator-5554` running, never a phone; Python with Pillow + numpy; ffmpeg):

```sh
flutter build apk --profile -t tools/promo_main.dart
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-profile.apk

python3 tools/capture_store_shots.py en fr      # raw screens  -> build/promo/shots/
python3 tools/make_store_graphics.py            # screenshots, feature graphics, icon -> store/

python3 tools/record_promo_clips.py en          # gameplay clips + event times -> build/promo/clips/
python3 tools/record_promo_clips.py fr
python3 tools/make_promo_video.py en fr         # -> store/video/ (about 5 min per video)
```

- `tools/promo_device.py` holds the emulator driving (adb taps/drags, screen coordinates, `screenrecord`); the scripts
  turn the system animations on and put the emulator's settings back when they finish.
- `tools/make_promo_music.py` synthesizes the soundtrack (original, 120 BPM, no samples); `make_promo_video.py` cuts
  to its beats, layers the game's own sound effects (`assets/sfx`) and levels the mix to about −14 LUFS.
- Captions and texts are in `make_store_graphics.py` (`CAPTIONS`, `FEATURE`) and `make_promo_video.py` (`TEXT`).
- `make_promo_video.py --frames 30,450 --draft` writes stills to check the look without rendering a whole video.
