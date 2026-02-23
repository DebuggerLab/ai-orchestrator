# Installation Guide

## Prerequisites

### System Requirements

- **macOS**: 13.0 (Ventura) or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later (included with Xcode)

### Dependencies

1. **AI Orchestrator MCP Server** must be running
2. **Python 3.10+** (for MCP server)
3. **API Keys** configured in the MCP server

## Installation Methods

### Method 1: Automated Installation (Recommended)

```bash
# Clone the repository (if not already done)
git clone https://github.com/debuggerlab/ai-orchestrator.git
cd ai-orchestrator/xcode_extension

# Run installation script
./Scripts/install.sh
```

The script will:
1. Build the extension
2. Install to `~/Library/Developer/Xcode/Extensions/`
3. Create configuration directory
4. Set up default configuration
5. Optionally restart Xcode

### Method 2: Manual Installation

#### Step 1: Build the Extension

```bash
cd xcode_extension
./Scripts/build.sh
```

#### Step 2: Install Extension Bundle

```bash
# Create extensions directory
mkdir -p ~/Library/Developer/Xcode/Extensions

# Copy extension
cp -R build/AIOrchestratorXcode.appex ~/Library/Developer/Xcode/Extensions/
```

#### Step 3: Enable Extension

1. Open **System Settings**
2. Navigate to **Privacy & Security** > **Extensions** > **Xcode Source Editor**
3. Enable **AI Orchestrator for Xcode**

#### Step 4: Restart Xcode

```bash
# Close and reopen Xcode
osascript -e 'quit app "Xcode"'
open -a Xcode
```

### Method 3: Development Installation

For development and debugging:

1. Open `AIOrchestratorXcode.xcodeproj` in Xcode
2. Select the extension scheme
3. Build and Run (Xcode will launch with the extension loaded)

## Post-Installation Setup

### 1. Configure MCP Server

Edit `~/.config/ai-orchestrator/settings.json`:

```json
{
    "mcpServerURL": "http://localhost:3000",
    "preferredModel": "claude-3-5-sonnet"
}
```

### 2. Set Up Keyboard Shortcuts

1. Open **Xcode** > **Settings** > **Key Bindings**
2. Search for "AI Orchestrator"
3. Assign shortcuts:
   - Fix Code: `Cmd+Shift+F`
   - Explain Code: `Cmd+Shift+E`
   - Generate Tests: `Cmd+Shift+T`
   - Refactor: `Cmd+Shift+R`
   - Generate Docs: `Cmd+Shift+D`
   - Build & Fix: `Cmd+Shift+B`

### 3. Verify Installation

```bash
# Test MCP server connection
./Scripts/test-connection.sh
```

### 4. Start MCP Server

Make sure the MCP server is running:

```bash
cd ../mcp_server
./start.sh
```

## Updating

To update the extension:

```bash
git pull
./Scripts/install.sh
```

## Uninstallation

```bash
./Scripts/uninstall.sh
```

This will:
1. Remove the extension from Xcode
2. Optionally remove configuration files

## Troubleshooting Installation

### Extension Not Appearing

1. Ensure extension is enabled in System Settings
2. Restart Xcode completely
3. Check Console.app for errors

### Build Failures

```bash
# Clean and rebuild
rm -rf build
./Scripts/build.sh
```

### Permission Issues

```bash
# Make scripts executable
chmod +x Scripts/*.sh
```

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for more solutions.
