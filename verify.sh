#!/usr/bin/env bash
# Runs the same checks as CI: unit tests, lint, and a debug APK build.
# Requires JDK 17 and the Android SDK (ANDROID_HOME). Uses ./gradlew if present, otherwise `gradle`.
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -x ./gradlew ]; then GRADLE=./gradlew; else GRADLE=gradle; fi
$GRADLE testDebugUnitTest lintDebug assembleDebug --stacktrace
echo "APK: $(ls app/build/outputs/apk/debug/*.apk)"
