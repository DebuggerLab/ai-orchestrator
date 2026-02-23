#!/bin/bash
#
# Build script for AI Orchestrator Xcode Extension
# Copyright © 2026 DebuggerLab. All rights reserved.
#
# IMPORTANT: This extension must be built on macOS with Xcode installed.
# The XcodeKit framework is only available within Xcode.
#
# Usage:
#   ./Scripts/build.sh              # Build with Xcode project
#   ./Scripts/build.sh --generate   # Generate Xcode project first
#   ./Scripts/build.sh --help       # Show help

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

# Show help
show_help() {
    echo "Usage: ./Scripts/build.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --generate    Generate the Xcode project before building"
    echo "  --clean       Clean build artifacts before building"
    echo "  --open        Open the project in Xcode after building"
    echo "  --help        Show this help message"
    echo ""
    echo "Requirements:"
    echo "  - macOS 13.0 or later"
    echo "  - Xcode 15.0 or later with command line tools"
    echo ""
    echo "Note: XcodeKit is only available in Xcode projects, not Swift Package Manager."
    echo "This script will generate a proper Xcode project for the extension."
    exit 0
}

# Parse arguments
GENERATE=false
CLEAN=false
OPEN_XCODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --generate)
            GENERATE=true
            shift
            ;;
        --clean)
            CLEAN=true
            shift
            ;;
        --open)
            OPEN_XCODE=true
            shift
            ;;
        --help|-h)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            ;;
    esac
done

# Check for macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}Error: This script must be run on macOS${NC}"
    echo "The Xcode Source Editor Extension can only be built on macOS with Xcode."
    exit 1
fi

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

# Generate Xcode project if requested or doesn't exist
XCODEPROJ="$PROJECT_DIR/AIOrchestratorXcode.xcodeproj"

if [ "$GENERATE" = true ] || [ ! -d "$XCODEPROJ" ]; then
    echo -e "${YELLOW}Generating Xcode project...${NC}"
    
    # Create the Xcode project using a project spec
    bash "$SCRIPT_DIR/generate-xcode-project.sh"
    
    echo -e "${GREEN}✓${NC} Xcode project generated"
fi

# Verify Xcode project exists
if [ ! -d "$XCODEPROJ" ]; then
    echo -e "${RED}Error: Xcode project not found at $XCODEPROJ${NC}"
    echo "Run with --generate to create the project first."
    exit 1
fi

# Clean if requested
if [ "$CLEAN" = true ]; then
    echo -e "${YELLOW}Cleaning build artifacts...${NC}"
    rm -rf "$BUILD_DIR"
    mkdir -p "$BUILD_DIR"
    xcodebuild -project "$XCODEPROJ" -scheme "AIOrchestratorXcode" clean 2>/dev/null || true
    echo -e "${GREEN}✓${NC} Cleaned"
fi

# Build configuration
CONFIGURATION="Release"

echo -e "${BLUE}Building extension...${NC}"

# Build the extension
xcodebuild \
    -project "$XCODEPROJ" \
    -scheme "AIOrchestratorXcode" \
    -configuration "$CONFIGURATION" \
    -derivedDataPath "$BUILD_DIR/DerivedData" \
    ONLY_ACTIVE_ARCH=NO \
    MACOSX_DEPLOYMENT_TARGET="$MINIMUM_MACOS" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build 2>&1 | tee "$BUILD_DIR/build.log" | grep -E "(error:|warning:|Build |✓|✗)" || true

# Check build status
if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✓ Build completed successfully!${NC}"
    
    # Find the built app
    APP_PATH=$(find "$BUILD_DIR/DerivedData" -name "*.app" -type d | head -1)
    if [ -n "$APP_PATH" ]; then
        echo ""
        echo "Built app: $APP_PATH"
    fi
    
    echo ""
    echo "Build artifacts are in: $BUILD_DIR"
    echo ""
    echo "Next steps:"
    echo "  1. Run ./Scripts/install.sh to install the extension"
    echo "  2. Or run ./Scripts/codesign.sh to code sign for distribution"
    
    # Open in Xcode if requested
    if [ "$OPEN_XCODE" = true ]; then
        echo ""
        echo "Opening project in Xcode..."
        open "$XCODEPROJ"
    fi
else
    echo ""
    echo -e "${RED}✗ Build failed${NC}"
    echo ""
    echo "Check the full build log: $BUILD_DIR/build.log"
    echo ""
    echo "Common issues:"
    echo "  - XcodeKit not available: Make sure you're building with Xcode, not SPM"
    echo "  - Code signing: Run with proper signing identity or use install.sh"
    exit 1
fi
