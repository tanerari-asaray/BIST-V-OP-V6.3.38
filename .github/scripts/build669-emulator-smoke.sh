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
# Require the actual stock chart and a visible, clickable S/D control.
# Do not substitute a launch screenshot for chart evidence.
capture() {
  local name="$1"
  timeout 35 adb shell uiautomator dump /sdcard/window.xml
  adb pull /sdcard/window.xml "emulator-evidence/${name}.xml" >/dev/null
  timeout 35 adb exec-out screencap -p > "emulator-evidence/${name}.png"
  test -s "emulator-evidence/${name}.png"
}
capture chart-navigation-required
python3 - <<'PY'
import xml.etree.ElementTree as ET
root=ET.parse('emulator-evidence/chart-navigation-required.xml').getroot()
nodes=[n for n in root.iter('node') if n.attrib.get('text')=='S/D' or n.attrib.get('content-desc')=='S/D']
if len(nodes)!=1 or nodes[0].attrib.get('clickable')!='true':
    raise SystemExit('NOT_VERIFIED: navigate to stock chart and expose one clickable S/D button')
print('S/D visible and clickable')
PY
# No fabricated ON/OFF images: interaction must be implemented before screenshots
# can be named sd-on.png and sd-off.png.
echo 'NOT_VERIFIED: S/D toggle state transitions and ON/OFF screenshots not yet implemented' | tee emulator-evidence/result.txt
exit 1
