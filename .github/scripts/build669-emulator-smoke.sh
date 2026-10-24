#!/usr/bin/env bash
set -euo pipefail
APK="${1:?APK path required}"
mkdir -p emulator-evidence
adb wait-for-device
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
adb shell am start -n "$PKG/$ACT" | tee emulator-evidence/launch.txt
sleep 20
adb shell pidof "$PKG" | tee emulator-evidence/pid.txt
test -s emulator-evidence/pid.txt
adb shell dumpsys activity activities > emulator-evidence/activities.txt
# Preserve crash and visual evidence even when UIAutomator hangs or fails.
adb exec-out screencap -p > emulator-evidence/launch.png
test -s emulator-evidence/launch.png
adb logcat -d > emulator-evidence/logcat.txt
# /sdcard/window.xml was unreadable in run 40100699177 (Permission denied).
# The shell-owned temp directory avoids shared-storage access.
adb shell rm -f /data/local/tmp/window.xml || true
adb shell uiautomator dump /data/local/tmp/window.xml > emulator-evidence/uiautomator.txt 2>&1 || true
adb exec-out cat /data/local/tmp/window.xml > emulator-evidence/window.xml 2> emulator-evidence/ui-read-error.txt || true
if grep -A 15 'FATAL EXCEPTION' emulator-evidence/logcat.txt | grep -F "Process: $PKG"; then
  echo "SMOKE_FAIL: app FATAL EXCEPTION" | tee emulator-evidence/result.txt
  exit 1
fi
# A running PID and screenshot do not prove the app is usable. The previous
# successful run showed a blocking Android "Process system isn't responding"
# dialog over the app, with only the system dialog in the UI hierarchy.
if [[ ! -s emulator-evidence/window.xml ]]; then
  echo "SMOKE_FAIL: missing foreground UI hierarchy (see uiautomator.txt and ui-read-error.txt)" | tee emulator-evidence/result.txt
  exit 1
fi
if grep -Eq 'resource-id="android:id/aerr_|text="[^"]*(isn.t responding|keeps stopping)' emulator-evidence/window.xml; then
  echo "SMOKE_FAIL: blocking Android ANR/crash dialog visible (may be system-side)" | tee emulator-evidence/result.txt
  exit 1
fi
if ! grep -Fq "package=\"$PKG\"" emulator-evidence/window.xml; then
  echo "SMOKE_FAIL: app not present in foreground UI hierarchy" | tee emulator-evidence/result.txt
  exit 1
fi
echo "SMOKE_PASS: boot, install, process, foreground UI, screenshot; chart and S/D interactions NOT verified" | tee emulator-evidence/result.txt
