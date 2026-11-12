#!/usr/bin/env bash
# Builds the dev app (ca.kallistesoft.critterlogic.dev, "Critter Logic Dev": profile mode = fast, test ads) and
# installs it on every connected device except emulators, or on the serials given: tools/install_dev.sh [SERIAL...]
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
export JAVA_HOME="${JAVA_HOME:-/Applications/Android Studio.app/Contents/jbr/Contents/Home}"

flutter build apk --profile
apk=build/app/outputs/flutter-apk/app-profile.apk
serials=("$@")
[ ${#serials[@]} -gt 0 ] || serials=($(adb devices | awk 'NR>1 && $2=="device" && $1 !~ /^emulator-/ {print $1}'))
for s in "${serials[@]}"; do
  echo "$s ($(adb -s "$s" shell getprop ro.product.model | tr -d '\r'))"
  adb -s "$s" install -r "$apk"
  adb -s "$s" shell monkey -p ca.kallistesoft.critterlogic.dev -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 || true
done
