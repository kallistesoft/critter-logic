# Daily YouTube Shorts

`tools/daily_shorts.py` makes one Short a day from **yesterday's** daily puzzle (Nests, Pairs, Trail in turn): about
17 s, 1080 × 1920, real gameplay from the promo build on the emulator. "Can you solve it?" on the empty board with the
rules and "Pause & try it", the solve (long ones sped up to about 9 s), "Solved!", then a "Free on Google Play" card.
Each Short goes public every day at 17:00 New York time (14:00 Los Angeles, 16:00 Mexico City), shortly before the
evening peak of North American viewers and after the daily it shows is over in every time zone. Until the game is live
on Google Play, the end card and description say "Coming soon to Google Play" (checked at render time: render again
after launch).

```sh
# Promo build on an emulator (never a phone), see store/README.md:
flutter build apk --profile -t tools/promo_main.dart
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-profile.apk

python3 tools/daily_shorts.py render --days 7          # the next 7 days -> build/shorts/<date>-en.mp4 + .json
python3 tools/daily_shorts.py render 2026-11-20 --lang fr   # one day in French (for TikTok/Reels by hand)
python3 tools/daily_shorts.py render --days 7 --live   # launch day: "Free on Google Play" before the page is up
python3 tools/daily_shorts.py upload --dry-run         # what would be scheduled
python3 tools/daily_shorts.py upload                   # schedule them on the KallisteSoft channel
```

`render` re-edits an earlier recording of the same day unless you pass `--rerecord`. `upload` skips days already in
`uploads.json` (video ids, committed) and days whose publish time has passed.

The Shorts never show ranking numbers: the promo build runs with `boards=false` because its stand-in leaderboard has
made-up player counts.

## YouTube setup (done 2026-11-13)

The channel is KallisteSoft (kallistesoft@gmail.com). Google Cloud project **kallistesoft-youtube** (org
kallistesoft.ca, contact@kallistesoft.ca, no billing), shared by every game's Shorts:

- YouTube Data API v3 enabled.
- OAuth consent screen "KallisteSoft Shorts", External, **published** (logins don't expire after 7 days). Home page
  https://kallistesoft.ca/en/, privacy https://kallistesoft.ca/en/privacy/, authorized domain kallistesoft.ca.
- Desktop OAuth client "daily-shorts": its JSON is `~/Keys/kallistesoft/youtube-client-secret.json` (never commit it).

`python3 tools/daily_shorts.py login` opens the browser once: sign in as kallistesoft@gmail.com and pick the KallisteSoft
channel (Google warns "unverified app": continue, it's your own). The token is saved to
`~/Keys/kallistesoft/youtube-shorts-token.json`. `upload` reuses it.

### The audit (important)

YouTube locks every video uploaded through the API by an **unaudited** project as **private**, and a scheduled publish
time doesn't change that. To let the scheduled Shorts go public, the project has to pass YouTube's free API compliance
audit ("YouTube API Services – Audit and Quota Extension Form"). It usually takes a few weeks. Until then:

- run `upload` anyway to check the setup (the videos stay private), or
- upload the files from `build/shorts/` in YouTube Studio by hand: copy the title and description from the `.json`,
  set "Schedule" to the date at 17:00 New York time. A week takes about 10 minutes.

The default API quota allows only a few uploads a day. When it runs out, `upload` stops cleanly; run it again the next
day.

## Instagram, TikTok, links

Links in Shorts, Reels and TikTok captions aren't clickable, so the end card says "Free on Google Play" and people search
the store. Put the Play link (https://play.google.com/store/apps/details?id=ca.kallistesoft.critterlogic) in each
profile's bio, and in the YouTube channel's links.
