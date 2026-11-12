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
| Login calendar | 170 (340 if every coin day is doubled by an ad) | + 2 capsules + 1 golden capsule per loop |
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
| 7 | Golden capsule | `golden` |

API: `retention.calendar.state(now)` → `CalendarState` (`step` 0–6, `claimedToday`, `available`, `rewards`,
`canDouble`, `loops`); `retention.claimCalendar(now, doubled: bool)` claims **and pays** (returns `GrantResult`,
null if not available).

## 2. Achievements (`Achievements`)

18 achievements, 52 tiers. Each tier pays coins: **bronze 20, silver 50, gold 100** (Remote Config). Claimable tiers
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
| Capsule opened | `capsule_screen.dart` after the critter / duplicate coins are paid | `retention.recordEvent(const CapsuleOpened(), now)` |
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
| `calendar_rewards` | String | `20,60,capsule,30,capsule,60,golden` | 7 items: coins 1–500, `capsule`, `golden`; else default |
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
