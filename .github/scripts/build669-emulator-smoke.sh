#!/usr/bin/env bash
set -euo pipefail
APK="${1:?APK path required}"
mkdir -p emulator-evidence
timeout 240 adb wait-for-device
for i in $(seq 1 120); do
  if [[ "$(adb shell getprop sys.boot_completed | tr -d '\r')" == "1" ]]; then break; fi
  sleep 2
done
test "$(adb shell getprop sys.boot_completed | tr -d '\r')" = "1"
adb install -r "$APK"
AAPT="$ANDROID_HOME/build-tools/35.0.0/aapt"
PKG="$("$AAPT" dump badging "$APK" | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -1)"
ACT="$("$AAPT" dump badging "$APK" | sed -n "s/^launchable-activity: name='\([^']*\)'.*/\1/p" | head -1)"
test -n "$PKG" && test -n "$ACT"
adb logcat -c
timeout 45 adb shell am start -W -n "$PKG/$ACT" | tee emulator-evidence/launch.txt
sleep 20
adb shell pidof "$PKG" | tee emulator-evidence/pid.txt
test -s emulator-evidence/pid.txt
adb shell dumpsys activity activities > emulator-evidence/activities.txt
adb shell uiautomator dump /sdcard/window.xml || true
adb pull /sdcard/window.xml emulator-evidence/window.xml || true
timeout 30 adb exec-out screencap -p > emulator-evidence/launch.png
test -s emulator-evidence/launch.png
adb logcat -d > emulator-evidence/logcat.txt
if grep -A 15 'FATAL EXCEPTION' emulator-evidence/logcat.txt | grep -F "Process: $PKG"; then exit 1; fi
echo "SMOKE_PASS: boot, install, process, screenshot; chart and S/D interactions NOT verified" | tee emulator-evidence/result.txt
