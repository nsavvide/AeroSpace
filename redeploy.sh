#!/usr/bin/env bash
# Rebuild the debug AeroSpace and relaunch the AeroSpaceDebug.app login-item bundle.
#
# Why not build-debug.sh? That also builds the AppBundleTests target, which needs XCTest
# from a full Xcode install (not present here) and aborts the script before deploy. This
# builds only the app/CLI targets, which is all we need to run AeroSpace.
#
# Note: if you change command grammar or CLI args (the *Generated.swift files / shell
# completion), run ./generate.sh once — this script intentionally skips that for speed.
set -euo pipefail

cd "$(dirname "$0")"
export PATH="/opt/homebrew/bin:$PATH" # swiftly + brew tools

echo "==> Building (swiftly toolchain pinned by .swift-version)..."
swiftly run swift build

echo "==> Copying binaries into .debug/ ..."
mkdir -p .debug
cp .build/debug/aerospace .build/debug/AeroSpaceApp .debug/

echo "==> Relaunching AeroSpaceDebug.app ..."
killall AeroSpaceApp 2>/dev/null || true
sleep 1
open "$HOME/Applications/AeroSpaceDebug.app"
sleep 2

echo "==> Status:"
pgrep -fl AeroSpaceApp >/dev/null || { echo "❌ AeroSpaceApp is not running"; exit 1; }
./.debug/aerospace --version | tail -1
echo "✅ Redeployed. If macOS prompts for Accessibility, grant it once."
