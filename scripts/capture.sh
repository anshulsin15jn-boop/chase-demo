#!/bin/bash
set -euo pipefail
APP="build/Simulator/Build/Products/Debug-iphonesimulator/BankingHackathonDemo.app"
BUNDLE="io.hackathon.fictionalbank.chaselookalike"
xcrun simctl boot "$SIMULATOR_ID" 2>/dev/null || true
xcrun simctl bootstatus "$SIMULATOR_ID" -b
xcrun simctl install "$SIMULATOR_ID" "$APP"
mkdir -p build/screenshots
for screen in accounts directory hub amount search review confirmation; do
  xcrun simctl terminate "$SIMULATOR_ID" "$BUNDLE" 2>/dev/null || true
  xcrun simctl launch "$SIMULATOR_ID" "$BUNDLE" --demo-screen "$screen"
  sleep 3
  xcrun simctl io "$SIMULATOR_ID" screenshot "build/screenshots/$screen.png"
done
