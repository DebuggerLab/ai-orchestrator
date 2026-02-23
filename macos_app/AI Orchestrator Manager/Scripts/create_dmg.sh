#!/bin/bash

# AI Orchestrator Manager - DMG Creation Script
# Creates a distributable DMG file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="AI Orchestrator Manager"
DMG_NAME="AI-Orchestrator-Manager-1.0.0"

echo "=== Creating DMG ==="

# Check if app exists
if [ ! -d "$BUILD_DIR/$APP_NAME.app" ]; then
    echo "❌ App bundle not found. Run build.sh first."
    exit 1
fi

# Create temporary DMG directory
DMG_TEMP="$BUILD_DIR/dmg_temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Copy app to temp directory
cp -r "$BUILD_DIR/$APP_NAME.app" "$DMG_TEMP/"

# Create symbolic link to Applications folder
ln -s /Applications "$DMG_TEMP/Applications"

# Create README file
cat > "$DMG_TEMP/README.txt" << 'EOF'
AI Orchestrator Manager
=======================

Installation:
1. Drag "AI Orchestrator Manager" to the Applications folder
2. Open the app from Applications
3. Follow the setup wizard to install the AI Orchestrator

Requirements:
- macOS 13.0 (Ventura) or later
- Python 3.9 or later
- Internet connection for installation

For more information, visit:
https://github.com/debuggerlab/ai-orchestrator

Support:
support@debuggerlab.com
EOF

# Create DMG
echo "Creating DMG file..."
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov \
    -format UDZO \
    "$BUILD_DIR/$DMG_NAME.dmg"

# Cleanup
rm -rf "$DMG_TEMP"

echo ""
echo "✅ DMG created: $BUILD_DIR/$DMG_NAME.dmg"
echo ""
echo "For distribution:"
echo "1. Code sign the DMG (see codesign.sh)"
echo "2. Notarize with Apple (see notarize.sh)"
