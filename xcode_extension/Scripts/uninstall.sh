#!/bin/bash
#
# Uninstallation script for AI Orchestrator Xcode Extension
# Copyright © 2026 DebuggerLab. All rights reserved.
#

set -e

# Configuration
PROJECT_NAME="AI Orchestrator for Xcode"
EXTENSION_DIR="$HOME/Library/Developer/Xcode/Extensions"
CONFIG_DIR="$HOME/.config/ai-orchestrator"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Uninstalling $PROJECT_NAME ===${NC}"
echo ""

# Remove extension
if [ -d "$EXTENSION_DIR/AIOrchestratorXcode.appex" ]; then
    rm -rf "$EXTENSION_DIR/AIOrchestratorXcode.appex"
    echo -e "${GREEN}✓${NC} Extension removed"
else
    echo -e "${YELLOW}Extension not found in $EXTENSION_DIR${NC}"
fi

# Ask about configuration
if [ -d "$CONFIG_DIR" ]; then
    echo ""
    read -p "Remove configuration files? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        echo -e "${GREEN}✓${NC} Configuration removed"
    else
        echo -e "${YELLOW}Configuration preserved at: $CONFIG_DIR${NC}"
    fi
fi

echo ""
echo -e "${GREEN}=== Uninstallation Complete ===${NC}"
echo ""
echo "Note: Restart Xcode for changes to take effect."
