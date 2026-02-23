#!/bin/bash

# AI Orchestrator Manager - Installation Script
# Installs the built application to /Applications

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="AI Orchestrator Manager"

echo "=== Installing AI Orchestrator Manager ==="

# Check if app exists
if [ ! -d "$BUILD_DIR/$APP_NAME.app" ]; then
    echo "❌ App bundle not found. Run build.sh first."
    exit 1
fi

# Check if already installed
if [ -d "/Applications/$APP_NAME.app" ]; then
    echo "Existing installation found. Removing..."
    rm -rf "/Applications/$APP_NAME.app"
fi

# Copy to Applications
echo "Installing to /Applications..."
cp -r "$BUILD_DIR/$APP_NAME.app" "/Applications/"

echo ""
echo "✅ Installation complete!"
echo ""
echo "You can now launch AI Orchestrator Manager from:"
echo "  - Spotlight: Search for 'AI Orchestrator Manager'"
echo "  - Finder: Applications > AI Orchestrator Manager"
echo "  - Terminal: open -a 'AI Orchestrator Manager'"
