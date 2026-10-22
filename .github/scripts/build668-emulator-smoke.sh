#!/usr/bin/env bash
set -uo pipefail
ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
mkdir -p "$ROOT/screenshots"
adb devices
adb shell settings put system accelerometer_rotation 0 || true
adb shell settings put system user_rotation 0 || true
cd "$ROOT/source/android-v6323" || exit 20
bash ./gradlew --no-daemon --max-workers=2 :app:connectedDiagnosticAndroidTest '-Pandroid.testInstrumentationRunnerArguments.class=tr.borsatakip.v5.ui.Build668VisualScreenshotTest,tr.borsatakip.v5.ui.VisualScreenshotTest' > "$ROOT/instrumentation.log" 2>&1
status=$?
tail -n 90 "$ROOT/instrumentation.log" || true
cd "$ROOT" || exit 21
adb pull /data/local/tmp/build668-screens screenshots/build668-screens || true
adb pull /sdcard/Android/data/tr.borsatakip.v5.diagnostic.v666.work/files/visual-screenshots screenshots/stock-detail || true
adb shell am start -n tr.borsatakip.v5.diagnostic.v666.work/tr.borsatakip.v5.ui.MainActivity || true
sleep 4
adb shell screencap -p /sdcard/build668-launch.png || true
adb pull /sdcard/build668-launch.png screenshots/build668-launch.png || true
echo "Build 668 instrumentation exit status: $status"
exit "$status"
