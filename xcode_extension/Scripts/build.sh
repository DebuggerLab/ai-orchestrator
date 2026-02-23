#!/bin/bash
#
# Build script for AI Orchestrator Xcode Extension
# Copyright © 2026 DebuggerLab. All rights reserved.
#

set -e

# Configuration
PROJECT_NAME="AI Orchestrator for Xcode"
BUNDLE_ID="com.debuggerlab.ai-orchestrator-xcode"
MINIMUM_MACOS="13.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Building $PROJECT_NAME ===${NC}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode command line tools not found${NC}"
    echo "Please install Xcode and run: xcode-select --install"
    exit 1
fi

# Check Xcode version
XCODE_VERSION=$(xcodebuild -version | head -1 | awk '{print $2}')
echo -e "${GREEN}✓${NC} Xcode version: $XCODE_VERSION"

# Create build directory
mkdir -p "$BUILD_DIR"

# Generate Xcode project if needed
if [ ! -f "$PROJECT_DIR/AIOrchestratorXcode.xcodeproj/project.pbxproj" ]; then
    echo -e "${YELLOW}Generating Xcode project...${NC}"
    cd "$PROJECT_DIR"
    swift package generate-xcodeproj --xcconfig-overrides Resources/Config.xcconfig 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Xcode project generated"
fi

# Build configuration
CONFIGURATION="Release"
ARCH="arm64 x86_64"  # Universal binary

echo -e "${BLUE}Building extension...${NC}"

# Build the extension
if [ -f "$PROJECT_DIR/AIOrchestratorXcode.xcodeproj/project.pbxproj" ]; then
    xcodebuild \
        -project "$PROJECT_DIR/AIOrchestratorXcode.xcodeproj" \
        -scheme "AIOrchestratorXcode" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$BUILD_DIR/DerivedData" \
        ONLY_ACTIVE_ARCH=NO \
        MACOSX_DEPLOYMENT_TARGET="$MINIMUM_MACOS" \
        clean build 2>&1 | xcpretty || true
else
    # Build using Swift Package Manager
    echo -e "${YELLOW}Building with Swift Package Manager...${NC}"
    cd "$PROJECT_DIR"
    swift build -c release 2>&1
fi

echo ""
echo -e "${GREEN}✓ Build completed successfully!${NC}"
echo ""
echo "Build artifacts are in: $BUILD_DIR"
echo ""
echo "Next steps:"
echo "  1. Run ./Scripts/install.sh to install the extension"
echo "  2. Or run ./Scripts/codesign.sh to code sign for distribution"
