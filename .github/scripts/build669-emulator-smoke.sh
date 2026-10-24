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
capture sd-before
python3 - <<'PY'
import xml.etree.ElementTree as ET
root=ET.parse('emulator-evidence/sd-before.xml').getroot()
matches=[n for n in root.iter('node') if (n.attrib.get('text','').strip()=='S/D' or n.attrib.get('content-desc','').strip()=='S/D') and n.attrib.get('clickable')=='true']
if len(matches)!=1:
    raise SystemExit('NOT_VERIFIED: expected exactly one clickable S/D button on chart screen')
bounds=matches[0].attrib.get('bounds','')
import re
xy=list(map(int,re.findall('[0-9]+',bounds)))
if len(xy)!=4: raise SystemExit('NOT_VERIFIED: invalid S/D bounds')
with open('emulator-evidence/sd-tap-coordinates.txt','w') as f:
    f.write(f'{(xy[0]+xy[2])//2} {(xy[1]+xy[3])//2}')
PY
read -r X Y < emulator-evidence/sd-tap-coordinates.txt
adb shell input tap "$X" "$Y"
sleep 3
capture sd-after-first-tap
adb shell input tap "$X" "$Y"
sleep 3
capture sd-after-second-tap
python3 - <<'PY'
import xml.etree.ElementTree as ET
files=['sd-before','sd-after-first-tap','sd-after-second-tap']
states=[]
for name in files:
    root=ET.parse('emulator-evidence/'+name+'.xml').getroot()
    matches=[n for n in root.iter('node') if n.attrib.get('text','').strip()=='S/D' or n.attrib.get('content-desc','').strip()=='S/D']
    if len(matches)!=1: raise SystemExit('NOT_VERIFIED: S/D control missing after tap')
    n=matches[0]
    states.append((n.attrib.get('selected'),n.attrib.get('checked'),n.attrib.get('content-desc')))
with open('emulator-evidence/sd-state-evidence.txt','w') as f:
    f.write(repr(states))
if states[0]==states[1] or states[0]!=states[2]:
    raise SystemExit('NOT_VERIFIED: S/D state must change and return after second tap')
print('S/D state transition observed; verify chart line pixels separately')
PY
# Screenshots are named by tap order until initial state is independently established.
echo 'S/D_TOGGLE_STATE_PASS: screenshots captured for both states; chart line hiding requires visual comparison' | tee emulator-evidence/result.txt
