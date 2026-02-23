#!/bin/bash

# AI Orchestrator Manager - Build Script
# Builds the macOS application bundle

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="AI Orchestrator Manager"

echo "=== AI Orchestrator Manager Build Script ==="
echo "Project directory: $PROJECT_DIR"
echo ""

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Xcode Command Line Tools are required"
    echo "Install with: xcode-select --install"
    exit 1
fi

# Check for Swift
if ! command -v swift &> /dev/null; then
    echo "❌ Swift is required"
    exit 1
fi

echo "✅ Build tools found"

# Create build directory
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo ""
echo "Building application..."

# Build with Swift Package Manager
cd "$PROJECT_DIR"
swift build -c release

# Create app bundle structure
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy executable
cp ".build/release/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# Copy Info.plist
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/"

# Create PkgInfo
echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo ""
echo "✅ Build complete!"
echo "Application bundle: $APP_BUNDLE"
echo ""
echo "To install, copy to /Applications:"
echo "  cp -r \"$APP_BUNDLE\" /Applications/"
