#!/usr/bin/env bash
# Keep the emulator smoke sequence in ONE shell. The emulator runner invokes
# each line of its inline 'script' as a separate /bin/sh -c process.
set -euo pipefail
mkdir -p emulator-reports

# Preserve crash evidence even when installation, launch or assertions fail.
trap 'adb logcat -d -v brief > emulator-reports/logcat.txt 2>/dev/null || true' EXIT

adb wait-for-device
adb shell getprop sys.boot_completed | tee emulator-reports/boot.txt
grep -qx '1' emulator-reports/boot.txt

adb install -r "$APK_PATH" | tee emulator-reports/install.txt
grep -q 'Success' emulator-reports/install.txt

"$ANDROID_HOME/build-tools/35.0.0/aapt" dump badging "$APK_PATH" > emulator-reports/aapt-badging.txt
pkg="$(sed -n "s/^package: name='\\([^']*\\)'.*/\\1/p" emulator-reports/aapt-badging.txt | head -1)"
if [ -z "$pkg" ]; then
  echo "::error::Could not determine APK package from aapt badging" >&2
  exit 1
fi
printf '%s\n' "$pkg" | tee emulator-reports/package.txt

adb logcat -c
adb shell monkey -p "$pkg" -c android.intent.category.LAUNCHER 1 | tee emulator-reports/launch.txt
grep -q 'Events injected: 1' emulator-reports/launch.txt
sleep 12
adb shell dumpsys activity activities > emulator-reports/activities.txt
adb shell screencap -p /sdcard/build668-smoke.png
adb pull /sdcard/build668-smoke.png emulator-reports/screenshot.png
adb logcat -d -v brief > emulator-reports/logcat.txt

if grep -q 'FATAL EXCEPTION' emulator-reports/logcat.txt; then
  echo "::error::Fatal exception detected; inspect emulator-reports/logcat.txt" >&2
  exit 1
fi
test -s emulator-reports/screenshot.png
