#!/usr/bin/env bash
set -euo pipefail

script_directory=$(cd "$(dirname "$0")" && pwd)
watch_directory="$script_directory/WatchCompanion"

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "Install XcodeGen first: brew install xcodegen" >&2
    exit 1
fi
if ! command -v xcodebuild >/dev/null 2>&1; then
    echo "The Apple Watch app must be built on macOS with Xcode." >&2
    exit 1
fi

cd "$watch_directory"
xcodegen generate --spec project.yml

# Always perform an unsigned compile first. This catches source and project
# errors without requiring a paid Apple Developer Program membership.
xcodebuild \
    -project HomeAssistantLegacyWatch.xcodeproj \
    -scheme HomeAssistantLegacyWatch \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    CODE_SIGNING_ALLOWED=NO \
    build

if [[ -z "${DEVELOPMENT_TEAM:-}" ]]; then
    echo "Unsigned iPhone + Watch build completed."
    echo "To create a device archive, rerun with DEVELOPMENT_TEAM set to your Apple team ID."
    exit 0
fi

xcodebuild \
    -project HomeAssistantLegacyWatch.xcodeproj \
    -scheme HomeAssistantLegacyWatch \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$watch_directory/build/HomeAssistantLegacyWatch.xcarchive" \
    DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" \
    archive
