#!/bin/bash
set -e

PACKAGE="com.example.app_blocking_prototype"
SERVICE="$PACKAGE/$PACKAGE.AppBlockerAccessibilityService"

echo "== Step 1: Uninstalling app =="
adb uninstall "$PACKAGE" || echo "(not installed, continuing)"

echo ""
echo "== Step 2: Building and installing fresh =="
echo "Running flutter run in the background, logging to flutter_run.log..."
flutter run -d emulator-5554 > flutter_run.log 2>&1 &
FLUTTER_PID=$!

echo "Waiting for the app to actually install on the device..."
for i in $(seq 1 60); do
    if adb shell pm list packages | grep -q "$PACKAGE"; then
        echo "App installed."
        break
    fi
    sleep 2
    if [ "$i" -eq 60 ]; then
        echo "Timed out waiting for install. Check flutter_run.log for errors:"
        tail -n 30 flutter_run.log
        exit 1
    fi
done

echo "Giving it a few extra seconds to finish launching..."
sleep 5

echo ""
echo "== Step 3: Checking accessibility state before re-enabling =="
adb shell dumpsys accessibility | grep -A2 "Bound services"
adb shell dumpsys accessibility | grep -A2 "Enabled services"

echo ""
echo "== Step 4: Clearing AppOps restriction first =="
adb shell cmd appops set "$PACKAGE" ACCESS_RESTRICTED_SETTINGS allow

echo ""
echo "== Step 5: Re-enabling the service via settings =="
adb shell settings put secure accessibility_enabled 1
adb shell settings put secure enabled_accessibility_services "$SERVICE"

echo ""
echo "Verifying settings stuck:"
echo -n "accessibility_enabled: "
adb shell settings get secure accessibility_enabled
echo -n "enabled_accessibility_services: "
adb shell settings get secure enabled_accessibility_services

echo ""
echo "== Step 6: Checking accessibility state after re-enabling =="
adb shell dumpsys accessibility | grep -A2 "Bound services"
adb shell dumpsys accessibility | grep -A2 "Enabled services"

echo ""
echo "Waiting 15s to confirm the setting stays enabled (not silently reverted)..."
sleep 15
echo -n "accessibility_enabled after wait: "
adb shell settings get secure accessibility_enabled

echo ""
echo "== Step 7: Watching logs =="
echo "Clearing old log buffer so we only see fresh output..."
adb logcat -c

echo "Switch between a couple of apps on the emulator now."
echo "Watching for anything tagged AppBlocker (Ctrl+C to stop)..."
echo ""

adb logcat -s "AppBlocker:V"