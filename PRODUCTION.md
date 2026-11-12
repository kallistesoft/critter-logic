# Critter Logic: road to Google Play

## Owner steps (accounts and money: the owner clicks)
- [ ] **Firebase project** "Critter Logic" on contact@kallistesoft.ca (Analytics on, Gemini off): Android app
      `ca.kallistesoft.critterlogic` (+ `.debug` if needed). Put google-services.json in the `GOOGLE_SERVICES_JSON` repo
      secret and in `android/app/` locally.
- [ ] Firestore `(default)` (nam5), Anonymous auth on, App Check with Play Integrity (enforce on Firestore once the
      Play app signing SHA-256 is registered), rules from `firestore.rules`.
- [ ] Remote Config: `min_version_code`, `recommended_version_code` (+ `_debug`), and the `GameSettings` keys
      (`lib/services/game_settings.dart`), all at their defaults.
- [ ] **AdMob** app (account pub-7557144664039757): units interstitial "Puzzle done", rewarded "Hint / capsule /
      repair", banner "Bottom". Ad rating T and the same blocked categories as Block Daily; add the app to the EU and
      US-states consent messages (privacy URL below). Fill `lib/services/ad_ids.dart` and the AdMob app ID in
      `android/app/build.gradle.kts`. Link AdMob ↔ Firebase.
- [ ] **Play Console** app "Critter Logic: Daily Puzzles", in-app product `remove_ads` (3.99 CAD), upload key
      `~/Keys/kallistesoft/critter-logic-upload.jks` + `android/key.properties`.
- [ ] Privacy page on kallistesoft.ca: /en/privacy/critter-logic/ and /fr/confidentialite/critter-logic/.

## Store listing (Claude prepares, owner sends for review)
- [ ] `store/listing.json`: title, short and full description in en-US, fr-CA, fr-FR, de-DE, es-419, es-ES, es-US,
      it-IT, pt-BR, nl, pl, tr, ru, id, vi, th, ja, ko, zh-TW, hi.
- [ ] Icon 512, feature graphic 1024×500 (no text), 8 phone + 4 seven-inch + 4 ten-inch screenshots, EN and FR.
- [ ] 30 s video EN/FR, 16:9 + 9:16, public on the KallisteSoft YouTube channel; set in the listing.
- [ ] Data safety (analytics, crash logs, advertising ID, anonymous leaderboard ID), content rating, ads
      declaration, target audience 13+, category Puzzle, tags.
- [ ] Feature card on kallistesoft.ca (`.card.feature` layout).

## Before each Play upload
- [ ] `tools/build_release.sh` on a clean main; release APK smoke test on emulator-5554 (R8).
- [ ] Internal testing first; owner checks on the Pixel; then production.
