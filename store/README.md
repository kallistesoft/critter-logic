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
