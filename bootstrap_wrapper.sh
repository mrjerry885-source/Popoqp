#!/usr/bin/env bash
# Generates the Gradle wrapper (gradlew + gradle-wrapper.jar) using a locally installed Gradle.
# Android Studio users normally do not need this: opening the project is enough.
set -euo pipefail
cd "$(dirname "$0")/.."
gradle wrapper --gradle-version 8.9
echo "Wrapper created. Use ./gradlew from now on."
