#!/usr/bin/env bash
set -u
ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
mkdir -p "$ROOT/screenshots"
adb wait-for-device
adb shell wm size 720x1600 || true
adb shell wm density 320 || true
adb shell settings put system font_scale 1.3 || true
adb shell settings put system accelerometer_rotation 0 || true
adb shell settings put system user_rotation 0 || true
cd "$ROOT/source/android-v6323" || exit 20
./gradlew --no-daemon --max-workers=2 :app:connectedDiagnosticAndroidTest '-Pandroid.testInstrumentationRunnerArguments.class=tr.borsatakip.v5.ui.Build668VisualScreenshotTest,tr.borsatakip.v5.ui.VisualScreenshotTest' > "$ROOT/large-font-android-test.log" 2>&1
STATUS=$?
tail -n 100 "$ROOT/large-font-android-test.log" || true
cd "$ROOT" || exit 21
adb pull /data/local/tmp/build668-screens screenshots/fullscreen-chart || true
adb pull /data/local/tmp/build668-hisse screenshots/scan-and-stock || true
echo "Large-font emulator test exit: $STATUS"
exit "$STATUS"
