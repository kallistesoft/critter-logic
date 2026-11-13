# Retention systems

Logic, persistence and tests for four systems that bring players back: the **login calendar**, **achievements**,
**weekly events** and **seasonal sets** (data only). Screens come after the meadow redesign; this page lists what
the UI has to call and where it should sit.

Code: `lib/meta/` (`retention.dart` is the one entry point) and `lib/services/retention_settings.dart`.
State lives in SharedPreferences under keys starting with `progress.` (`ProgressStore`); coins, capsules and critters
are paid into `StatsStore` as usual.

## Economy context

Hints cost **30** coins. A player who solves both dailies earns 40 coins a day (plus 10–15 per level), and streak
chests add 50/100/300. The numbers below keep each new system a side income, not a second salary:

| Source | Coins per week (typical) | Notes |
| --- | --- | --- |
| Dailies (both, every day) | 280 | existing |
| Login calendar | 170 (340 if every coin day is doubled by an ad) | + 3 capsules per loop |
| Weekly event | 40 | + 1 capsule + 1 critter of the set + a frame |
| Achievements | front-loaded, ~2 900 lifetime | 52 tiers; long tail |

## 1. Login calendar (`LoginCalendar`)

A 7-step track. It moves **one step per local calendar day the reward is claimed**. Missing days doesn't reset it:
the track waits. After day 7 it loops to day 1. One claim per local day (the day changes at local midnight; daylight
saving days count as one day). A rewarded ad can double a coin day (the claim is once a day, so the double is too).
If the clock is set back before the last claim, nothing can be claimed until it catches up.

| Day | Default reward | Remote Config token |
| --- | --- | --- |
| 1 | 20 coins | `20` |
| 2 | 60 coins ("hint pack": two hints) | `60` |
| 3 | Capsule | `capsule` |
| 4 | 30 coins | `30` |
| 5 | Capsule | `capsule` |
| 6 | 60 coins | `60` |
| 7 | Capsule (golden would give away the 5 golden critters in ~5 weeks) | `capsule` |

API: `retention.calendar.state(now)` → `CalendarState` (`step` 0–6, `claimedToday`, `available`, `rewards`,
`canDouble`, `loops`); `retention.claimCalendar(now, doubled: bool)` claims **and pays** (returns `GrantResult`,
null if not available).

## 2. Achievements (`Achievements`)

20 achievements, 55 tiers. Each tier pays coins: **bronze 20, silver 50, gold 100** (Remote Config). Claimable tiers
show a badge (`retention.achievements.badgeCount`). Tiers can be claimed in any order once reached.

| id | Measures | Bronze / Silver / Gold |
| --- | --- | --- |
| `first_daily` | dailies solved | 1 (bronze only) |
| `dailies` | dailies solved | 7 / 30 / 100 |
| `streak` | best streak | 3 / 7 / 30 |
| `both_dailies` | days with both dailies solved | 3 / 15 / 50 |
| `perfect_daily` | dailies with no mistake and no hint | 5 / 25 / 100 |
| `fast_nests` | Nests dailies under 1 min (ranked time, penalties included) | 1 / 10 / 50 |
| `fast_pairs` | Pairs dailies under 1 min | 1 / 10 / 50 |
| `nests_levels` | Nests levels won | 10 / 50 / 200 |
| `pairs_levels` | Pairs levels won | 10 / 50 / 200 |
| `levels` | levels won, all games | 25 / 100 / 500 |
| `no_hint` | dailies and levels solved without a hint | 10 / 50 / 200 |
| `critters` | album critters owned | 10 / 20 / 30 |
| `sets` | album sets completed | 1 / 3 / 5 |
| `golden` | golden critters owned | 1 / 3 / 5 |
| `critter_level3` | critters at ⭐3 or more | 1 (bronze only) |
| `critter_level5` | critters at ⭐5 | 1 / 10 (bronze, silver) |
| `capsules` | capsules opened | 10 / 50 / 150 |
| `shares` | shares | 1 / 10 / 50 |
| `calendar` | login calendar days claimed | 7 / 30 / 100 |
| `events` | weekly events completed (top prize claimed) | 1 / 4 / 12 |

Dailies, streak, levels and album counts come from `StatsStore`; the others are counters in `ProgressStore`
filled by `recordEvent` (they start at 0 for existing players, which is fine before launch).

API: `retention.achievements.evaluate()` → `List<AchievementProgress>` (`value`, `target`, `fraction`, `reached`,
`claimed`, `claimable`, `nextTier`, `complete`); `retention.claimAchievement(id, tier)` → coins or null.
Names: l10n key `achievement_<id>` (title) with the tier target in the text.

## 3. Weekly events (`WeeklyEvent`)

A themed week, **Monday 00:00 → next Monday 00:00 local time**, rotating through the album sets from Monday
2026-11-30: **Polar Week, Panda Week (friends), Jungle Week, Safari Week (savanna), Farm Week**, then again. Solving
a daily for the first time gives **3 tokens**, winning a level **1 token**. Progress is per week (a new week starts
at 0; unclaimed prizes of a past week are lost, so the UI should nudge on Sunday).

| Tokens | Prize |
| --- | --- |
| 5 | 40 coins |
| 15 | Capsule |
| 30 | A critter of the week's set the player doesn't have (common or rare; 100 coins if they have them all) + the event frame `frame.<theme>` |

Both dailies every day = 42 tokens/week, so the top prize needs ~5 days of play (or dailies + levels).

API: `retention.event.current(now)` → `WeeklyEventState?` (`theme.id`, `theme.set`, `weekId`, `startsAt`,
`endsAt`, `remaining(now)`, `thresholds`, `prizes`, `tokens`, `claimed`, `claimable`, `nextThreshold`, `fraction`),
null when events are switched off; `retention.claimEventPrize(now, threshold)` claims and pays.
Names: l10n key `event_<theme id>` ("Panda Week"). Owned frames: `progress.cosmetics`.

### `weekly_event_json` (Remote Config, String, default empty = built-in)

```json
{
  "enabled": true,
  "thresholds": [5, 15, 30],
  "prizes": [{"coins": 40}, {"capsules": 1}, {"critter": true, "cosmetic": true}],
  "tokens_daily": 3,
  "tokens_level": 1,
  "rotation": [{"theme": "polar", "set": "polar"}, {"theme": "panda", "set": "friends"}],
  "weeks": {"2026-12-21": {"theme": "winter", "set": "polar"}}
}
```

Every field is optional; a bad field falls back to its default alone. Rules: 1–5 thresholds, 1–1000, strictly
increasing, as many prizes as thresholds (prize: `coins` 0–1000, `capsules` 0–5, `golden_capsules` 0–1, `critter`
and `cosmetic` booleans, not all empty); tokens 0–100; theme ids `[a-z_]`, sets from the album; `weeks` keys must be
Mondays. A new theme id needs its l10n string (`event_winter`) and frame art before it is used.

## 4. Seasonal sets (`seasonal.dart`, data only)

`SeasonalSet` = id + yearly window (`MonthDay` start/end, may cross New Year) + `SeasonalCritter`s that reuse an
album critter's sprite with a seasonal `frame`. Collectible ids are `<base>@<set>` so they never clash with the
album. One set is defined: **Winter**, the 6 polar critters in a `snowy` frame, **Dec 1 – Feb 28** (Feb 29 of leap
years is outside). Nothing uses them yet: capsules, album and events still only know the 30 album critters.
`activeSeasonalSets(now)` lists the ones on today.

## Hooks: where the UI and game flow call in

Create one `Retention(stats:, progress: await ProgressStore.open(), settings: updates?.retention.value ??
const RetentionSettings(), analytics:)` at start-up (main.dart) and put it in `Services`. All calls take
`services.today()` as `now` so tests can fix the clock.

| When | Where (today's code) | Call |
| --- | --- | --- |
| App opened / resumed, home shown | `HomeScreen` init and `AppLifecycleState.resumed` | `if (await retention.shouldShowCalendar(now))` show the calendar popup (once per local day) |
| Calendar "Claim" / "x2 (ad)" | calendar popup | `retention.claimCalendar(now)`; for x2: `if (await ads.showRewarded()) retention.claimCalendar(now, doubled: true)` + `analytics.adReward('calendar_double')` |
| A daily solved, first attempt | `game_screen.dart` `_onSolved()`, right after `grantDailyRewards` when `recordDaily` returned true | `retention.recordEvent(DailySolved(result), now)` |
| A level won | `game_screen.dart` `_onSolved()` level branch, after `addLevelWon` / `setLevel` | `retention.recordEvent(LevelWon(kind, hints: s.hints), now)` |
| Share completed | `result_screen.dart` `_share()` (and any other share button), after the share sheet | `retention.recordEvent(const Shared(), now)` |
| Capsule opened | `capsule_screen.dart` after `grantCritter` paid the critter | `retention.recordEvent(const CapsuleOpened(), now)` |
| Trophy screen "Claim" | achievements screen | `retention.claimAchievement(id, tier)` |
| Event prize "Claim" | event screen | `retention.claimEventPrize(now, threshold)` |

`recordEvent` returns a `RetentionUpdate`: `tokens` earned (show "+3 🐾" on the result screen),
`thresholdsReached` (toast "Event prize ready!") and `newAchievements` (toast "Trophy unlocked!", each announced
once). Badges: `achievements.badgeCount`, `event.current(now)!.claimable.isNotEmpty`, `calendar.state(now).available`.

## Analytics events

| Event | Params | Logged by |
| --- | --- | --- |
| `calendar_claim` | `day` 1–7, `reward` (coins/capsule/golden), `coins`, `doubled` 0/1 | `claimCalendar` |
| `achievement_claim` | `id`, `tier` (bronze/silver/gold), `coins` | `claimAchievement` |
| `event_threshold` | `theme`, `week`, `threshold` | `recordEvent` when tokens cross a threshold |
| `event_prize_claim` | `theme`, `week`, `threshold`, `reward` (coins/capsule/critter/…) | `claimEventPrize` |

The UI should also log `ad_reward` with `calendar_double` when the double is watched.

## Remote Config parameters

| Name | Type | Default | Range / format |
| --- | --- | --- | --- |
| `calendar_rewards` | String | `20,60,capsule,30,capsule,60,capsule` | 7 items: coins 1–500, `capsule`, `golden`; else default |
| `calendar_ad_double` | Boolean | `true` | |
| `achievement_bronze_coins` | Number | `20` | 0–500 |
| `achievement_silver_coins` | Number | `50` | 0–1000 |
| `achievement_gold_coins` | Number | `100` | 0–2000 |
| `weekly_event_json` | String (JSON) | empty | see above; empty = built-in rotation |

The defaults are also set in the app (`UpdateService` → `RetentionSettings.defaults`), so it works offline and
before the parameters exist in the console; `UpdateService.retention` holds the parsed values.

## Suggested placement in the meadow home

- **Calendar popup** on the first open of the local day: a wooden sign / picnic blanket with 7 tiles (day 7 larger,
  golden), today's tile bouncing, past ones stamped with a paw. Buttons: "Claim" and, on coin days, "x2 ▶" (rewarded
  ad). Also reachable from a small calendar button on home with a dot while `available`.
- **Trophy button** (top bar, next to coins): a little cup with a red badge = `badgeCount`. Screen: list of cards
  with bronze/silver/gold medals, progress bar to `target`, "Claim" on claimable tiers.
- **Event banner** under the daily cards: the week's golden critter of the set (panda for Panda Week), name,
  "ends in 2d 5h", progress bar with 3 markers at the thresholds, a "!" when a prize is claimable. Tap = event screen
  with the 3 prizes and the set's critters (owned ones coloured).
- **Result screen**: "+3 🐾 Panda Week" under the coins, and the trophy toast.

## Coin shop (`lib/meta/shop.dart`, `retention.shop`)
The main coin sink. Prices are set against income (~45 coins/day from dailies, ~170/week from the calendar).

| Item | Price | Notes |
|---|---|---|
| Capsule | 150 | always available |
| Streak repair | 100 | only when yesterday can be repaired (same once-a-week rule as the ad repair) |
| Worlds: Night Neon, Winter Cabin, Clean Pro (`world.neon`, `world.winter`, `world.pro`) | 1 500 / 2 000 / 1 500 | owned forever, one equipped; Meadow (`world.meadow`, default) and Wild Lodge (`world.lodge`) are free |
| Critter hats: flowers, party, beanie, crown | 200 / 200 / 250 / 500 | owned forever, one equipped, can be taken off |

- **Daily deal:** one unowned hat or paid World per day at −30% (the capsule once everything is owned), the same on
  every device for a given day.
- API: `offers(today)`, `buy(id, today)` → `PurchaseResult`, `equip(id)`, `equippedWorld`, `equippedHat`.
- Analytics: `shop_purchase` (`item`, `price`, `deal`), `world_equip` (`world`).
- UI: a shop stall on the home screen with Capsules / Hats / Worlds (/ Coins) tabs. Each World card shows a live
  mini preview; tapping it opens a full-screen preview before buying. The critters wear `equippedHat`.

## Worlds (`lib/ui/worlds/`)
A World is a full-app theme: background, palette, fonts, panels, buttons, title sign, board palettes, the way
critters are drawn and the streak icon. Same game, progress and rewards underneath.

| World | Price | Look |
|---|---|---|
| Meadow (`world.meadow`) | free, default | sky, sun, clouds, hills, wooden signs, candy buttons, Kenney critters |
| Wild Lodge (`world.lodge`) | free | dusk sky, pine forest, mountains, campfire glow, dark wood + brass, slab type; critters as wildlife badges; album = field journal; streak = campfire |
| Night Neon (`world.neon`) | 1 500 | dark synthwave grid, glowing cyan/magenta/lime outlines, glowing critters |
| Winter Cabin (`world.winter`) | 2 000 | snowy pines at night, northern lights, warm cabin windows, gentle snow, knit panels; critters wear scarves |
| Clean Pro (`world.pro`) | 1 500 | minimal slate + gold, flat cards, no decorations; critters only in the album and rewards |

- The equipped World is `progress.equipped('world')` (via `shop.equippedWorld`). On first launch a welcome screen
  shows Meadow and Wild Lodge with live previews (skippable → Meadow); `progress.worldChosen` remembers it was seen.
- Adding a World: a `GameWorld` subclass (palette, fonts, painters, critter renderer) in `lib/ui/worlds/`, its entry
  in `worlds` (`world.dart`), a `world.<id>` shop item, its l10n name, and any OFL/CC0 assets in `assets/CREDITS.md`.

## Lucky Nest (`lib/meta/lucky_nest.dart`, `retention.luckyNest`)
A cozy egg draw (deliberately no casino look: no slots, chips or "bet" wording; odds always shown).
- **1 free egg per day**, then **paid eggs at 50 coins, no daily limit**.
- Odds: golden capsule 1.5%, capsule 12%, 40–120 coins 20%, free hint 30%, feather (nothing) 36.5%.
  Average value per egg ≈ 49 coins for a 50-coin price: a sink that still feels generous.
- Free hints won here live in `ProgressStore.freeHints`. **Hook:** the hint button must call
  `progress.useFreeHint()` first and only charge coins (or offer the ad) when it returns false; show the free hint count
  on the button.
- API: `state(today)` (free available, paid left, price), `draw(today)` → `LuckyDraw` or null.
- Analytics: `lucky_draw` (`prize`, `coins`, `free`).
- UI: a nest with 3 eggs on the home meadow, badge when the free egg is ready; tap → wobble → crack → prize; an
  "Odds" link listing `settings.odds`.

### More Remote Config parameters
| Name | Type | Default |
|---|---|---|
| `shop_prices` | String | empty (catalog prices); `id=price` pairs, 10–5000 |
| `shop_deal_percent` | Number | `30` (0–90; 0 = no deal) |
| `lucky_nest` | String | empty (defaults); `golden=15,capsule=120,coins=200,hint=300,price=50,paid_per_day=0 (0 = no limit),min_coins=40,max_coins=120` (odds in per mille) |
| `lucky_nest` | String | empty (defaults); `golden=15,capsule=120,coins=200,hint=300,price=60,paid_per_day=3,min_coins=50,max_coins=150` (odds in per mille) |
| `critter_levels` | String | `common=1,2,4,7,10;rare=1,2,3,5,7;golden=1,2,3,4,5` (total copies for ⭐1..⭐5; 5 increasing numbers starting at 1, ≤100; a bad entry keeps that rarity's default) |

## Critter levels (`lib/meta/collection.dart`)
Every critter copy counts (`StatsStore.critterCopies`; the old `album` list migrates to 1 copy each). Copies give
⭐1–5 per `critter_levels`. All critters are granted by `grantCritter` (capsules, event prizes, rewards): a new
critter pays nothing (plus 200 for a finished set, as before), a level-up pays ⭐2 +10, ⭐3 +20, ⭐4 +30, ⭐5 +50
(`Economy.levelUp`), a copy between levels pays nothing, a copy past ⭐5 pays `Economy.duplicateCritter` (25).
Capsules prefer missing critters of the rolled rarity, then ones below ⭐5, then any. Analytics: `critter_level_up`
(`id`, `level`), `album_full` (once).

## Album set unlocks (`lib/meta/set_rewards.dart`)
Completing a set still pays `Economy.setComplete` (200 coins) and also unlocks a hat (owned forever, so it
disappears from the shop's for-sale list) or bonus coins:

| Set | Unlock |
|---|---|
| Farm | Flower crown hat (`hat.flowers`) |
| Friends | +300 coins |
| Savanna | Party hat (`hat.party`) |
| Jungle | +300 coins |
| Polar | +300 coins |
| All 30 critters | Crown hat, gold album frame (`frame.album_gold`) + 1 000 coins |

- `grantSetUnlocks(stats, progress)` gives every pending unlock once; `Retention.recordEvent(CapsuleOpened())` calls it
  and returns them in `RetentionUpdate.setUnlocks`; event prizes queue theirs in `takePendingSetUnlocks()`.
- UI: after a capsule reveal that completes a set, show "Set complete!" with the unlocked item and an "Equip" button
  (`shop.equip(id)`). Analytics: `set_unlock` (`set`, `cosmetics`).
