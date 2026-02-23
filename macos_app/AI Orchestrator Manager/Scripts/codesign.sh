#!/bin/bash

# AI Orchestrator Manager - Code Signing Script
# Signs the application for distribution

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="AI Orchestrator Manager"
ENTITLEMENTS="$PROJECT_DIR/Resources/AI_Orchestrator_Manager.entitlements"

# Your Developer ID - replace with your own
DEVELOPER_ID="Developer ID Application: YOUR_TEAM_NAME (YOUR_TEAM_ID)"

echo "=== Code Signing ==="
echo ""
echo "Note: You need a valid Apple Developer ID for code signing."
echo "Current identity: $DEVELOPER_ID"
echo ""

# Check if app exists
if [ ! -d "$BUILD_DIR/$APP_NAME.app" ]; then
    echo "❌ App bundle not found. Run build.sh first."
    exit 1
fi

# List available signing identities
echo "Available signing identities:"
security find-identity -v -p codesigning
echo ""

read -p "Enter your Developer ID identity (or press Enter to skip): " IDENTITY

if [ -z "$IDENTITY" ]; then
    echo "Skipping code signing."
    exit 0
fi

echo "Signing application..."

# Sign the app with hardened runtime
codesign --force --deep --sign "$IDENTITY" \
    --entitlements "$ENTITLEMENTS" \
    --options runtime \
    --timestamp \
    "$BUILD_DIR/$APP_NAME.app"

# Verify signature
echo ""
echo "Verifying signature..."
codesign --verify --deep --strict --verbose=2 "$BUILD_DIR/$APP_NAME.app"

# Check with spctl
echo ""
echo "Checking with Gatekeeper..."
spctl --assess --type execute --verbose "$BUILD_DIR/$APP_NAME.app" || echo "Note: App may need notarization for Gatekeeper approval."

echo ""
echo "✅ Code signing complete!"
