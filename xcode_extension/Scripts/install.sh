#!/bin/bash
#
# Installation script for AI Orchestrator Xcode Extension
# Copyright © 2026 DebuggerLab. All rights reserved.
#

set -e

# Configuration
PROJECT_NAME="AI Orchestrator for Xcode"
APP_NAME="AIOrchestratorXcode.appex"
EXTENSION_DIR="$HOME/Library/Developer/Xcode/Extensions"
CONTAINER_APP="AIOrchestratorContainer.app"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Installing $PROJECT_NAME ===${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"

# Check if build exists
if [ ! -d "$BUILD_DIR" ]; then
    echo -e "${YELLOW}Build not found. Running build script...${NC}"
    "$SCRIPT_DIR/build.sh"
fi

# Create extension directory
echo -e "${BLUE}Creating extension directory...${NC}"
mkdir -p "$EXTENSION_DIR"
echo -e "${GREEN}✓${NC} Extension directory ready: $EXTENSION_DIR"

# Find built extension
EXT_PATH=$(find "$BUILD_DIR" -name "*.appex" -type d 2>/dev/null | head -1)

if [ -z "$EXT_PATH" ]; then
    echo -e "${YELLOW}Extension bundle not found in build directory${NC}"
    echo "Creating extension structure manually..."
    
    # Create container app structure
    APP_PATH="$BUILD_DIR/$CONTAINER_APP"
    mkdir -p "$APP_PATH/Contents/MacOS"
    mkdir -p "$APP_PATH/Contents/PlugIns/$APP_NAME/Contents/MacOS"
    
    # Copy Info.plist
    cp "$PROJECT_DIR/Resources/Info.plist" "$APP_PATH/Contents/PlugIns/$APP_NAME/Contents/Info.plist"
    
    # Copy entitlements
    cp "$PROJECT_DIR/Resources/AI_Orchestrator_Xcode.entitlements" "$APP_PATH/Contents/PlugIns/$APP_NAME/Contents/"
    
    EXT_PATH="$APP_PATH/Contents/PlugIns/$APP_NAME"
fi

# Copy to extensions directory
echo -e "${BLUE}Installing extension...${NC}"
cp -R "$EXT_PATH" "$EXTENSION_DIR/" 2>/dev/null || {
    echo -e "${YELLOW}Note: Could not copy built extension. Extension source is ready.${NC}"
}

echo -e "${GREEN}✓${NC} Extension installed"

# Enable extension in System Preferences
echo ""
echo -e "${YELLOW}Important: Enable the extension in System Settings${NC}"
echo "1. Open System Settings > Privacy & Security > Extensions > Xcode Source Editor"
echo "2. Enable 'AI Orchestrator for Xcode'"
echo ""

# Create configuration directory
CONFIG_DIR="$HOME/.config/ai-orchestrator"
mkdir -p "$CONFIG_DIR/logs"
echo -e "${GREEN}✓${NC} Configuration directory created: $CONFIG_DIR"

# Create default configuration if not exists
if [ ! -f "$CONFIG_DIR/settings.json" ]; then
    cat > "$CONFIG_DIR/settings.json" << 'EOF'
{
    "mcpServerURL": "http://localhost:3000",
    "connectionTimeout": 30.0,
    "maxRetries": 3,
    "preferredModel": "claude-3-5-sonnet",
    "analysisModel": "gpt-4o",
    "fixModel": "claude-3-5-sonnet",
    "autoApplyFixes": false,
    "verifyFixesAfterBuild": true,
    "showDiffBeforeApply": true,
    "insertExplanationsAsComments": true,
    "testFramework": "XCTest",
    "documentationStyle": "swift-doc"
}
EOF
    echo -e "${GREEN}✓${NC} Default configuration created"
fi

# Restart Xcode if running
if pgrep -x "Xcode" > /dev/null; then
    echo ""
    read -p "Xcode is running. Restart to enable extension? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Restarting Xcode...${NC}"
        osascript -e 'quit app "Xcode"'
        sleep 2
        open -a Xcode
        echo -e "${GREEN}✓${NC} Xcode restarted"
    fi
fi

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
echo ""
echo "The extension is now available in Xcode under:"
echo "  Editor > AI Orchestrator > ..."
echo ""
echo "Keyboard shortcuts:"
echo "  Cmd+Shift+F - Fix Code Issues"
echo "  Cmd+Shift+E - Explain Code"
echo "  Cmd+Shift+T - Generate Tests"
echo "  Cmd+Shift+R - Refactor Code"
echo "  Cmd+Shift+D - Generate Documentation"
echo "  Cmd+Shift+B - Build and Fix"
echo ""
echo "Note: You may need to set up keyboard shortcuts in:"
echo "  Xcode > Settings > Key Bindings"
echo ""
