#!/usr/bin/env bash
# Keep the emulator smoke sequence in ONE shell. The emulator runner invokes
# each line of its inline 'script' as a separate /bin/sh -c process.
set -euo pipefail
mkdir -p emulator-reports

# Preserve crash evidence even when installation, launch or assertions fail.
collect_evidence() {
  adb logcat -d -v brief > emulator-reports/logcat.txt 2>/dev/null || true
  if [ ! -s emulator-reports/screenshot.png ]; then
    adb exec-out screencap -p > emulator-reports/screenshot.png 2>/dev/null || true
  fi
}
trap collect_evidence EXIT

adb wait-for-device
adb shell getprop sys.boot_completed | tee emulator-reports/boot.txt
grep -qx '1' emulator-reports/boot.txt

adb install -r "$APK_PATH" | tee emulator-reports/install.txt
grep -q 'Success' emulator-reports/install.txt

"$ANDROID_HOME/build-tools/35.0.0/aapt" dump badging "$APK_PATH" > emulator-reports/aapt-badging.txt
pkg="$(sed -n "s/^package: name='\([^']*\)'.*/\1/p" emulator-reports/aapt-badging.txt | head -1)"
if [ -z "$pkg" ]; then
  echo "::error::Could not determine APK package from aapt badging" >&2
  exit 1
fi
printf '%s\n' "$pkg" | tee emulator-reports/package.txt

# Monkey can abort on unrelated Android system ANRs; launch the manifest's
# explicit exported launcher Activity instead, and verify the app process.
activity="$(sed -n "s/^launchable-activity: name='\([^']*\)'.*/\1/p" emulator-reports/aapt-badging.txt | head -1)"
if [ -z "$activity" ]; then
  echo "::error::No launchable Activity in APK manifest" >&2
  exit 1
fi
adb logcat -c
adb shell am start -W -a android.intent.action.MAIN -c android.intent.category.LAUNCHER -n "$pkg/$activity" | tee emulator-reports/launch.txt
grep -q 'Status: ok' emulator-reports/launch.txt
sleep 12
adb shell pidof "$pkg" | tee emulator-reports/pid.txt
test -s emulator-reports/pid.txt
adb shell dumpsys activity activities > emulator-reports/activities.txt
adb exec-out screencap -p > emulator-reports/screenshot.png
adb logcat -d -v brief > emulator-reports/logcat.txt

if grep -q 'FATAL EXCEPTION' emulator-reports/logcat.txt; then
  echo "::error::Fatal exception detected; inspect emulator-reports/logcat.txt" >&2
  exit 1
fi
test -s emulator-reports/screenshot.png
