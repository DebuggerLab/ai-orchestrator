#!/bin/bash

# AI Orchestrator Manager - Notarization Script
# Notarizes the app with Apple for distribution outside the App Store

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="AI Orchestrator Manager"
DMG_NAME="AI-Orchestrator-Manager-1.0.0"
BUNDLE_ID="com.debuggerlab.ai-orchestrator-manager"

echo "=== Apple Notarization ==="
echo ""
echo "This script will notarize your app with Apple."
echo "Requirements:"
echo "  - Valid Apple Developer account"
echo "  - App-specific password for notarytool"
echo "  - App must be code signed first"
echo ""

# Check for DMG
if [ ! -f "$BUILD_DIR/$DMG_NAME.dmg" ]; then
    echo "❌ DMG not found. Run create_dmg.sh first."
    exit 1
fi

# Get credentials
read -p "Enter your Apple ID: " APPLE_ID
read -p "Enter your Team ID: " TEAM_ID
read -s -p "Enter your app-specific password: " APP_PASSWORD
echo ""

echo ""
echo "Submitting for notarization..."
echo "This may take several minutes..."

# Submit for notarization
xcrun notarytool submit "$BUILD_DIR/$DMG_NAME.dmg" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_PASSWORD" \
    --wait

# Staple the ticket to the DMG
echo ""
echo "Stapling notarization ticket..."
xcrun stapler staple "$BUILD_DIR/$DMG_NAME.dmg"

# Verify
echo ""
echo "Verifying notarization..."
xcrun stapler validate "$BUILD_DIR/$DMG_NAME.dmg"

echo ""
echo "✅ Notarization complete!"
echo "Your DMG is now ready for distribution: $BUILD_DIR/$DMG_NAME.dmg"
