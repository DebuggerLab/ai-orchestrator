# AI Orchestrator for Xcode

A Source Editor Extension that brings AI-powered coding assistance directly into Xcode.

## Features

- **Fix Code Issues** - Automatically detect and fix code problems
- **Explain Code** - Get AI explanations of selected code
- **Refactor Code** - AI-powered code refactoring suggestions
- **Generate Documentation** - Automatically generate code documentation
- **Generate Tests** - Create unit tests for your code
- **Build and Fix** - Build your project and automatically fix errors

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- AI Orchestrator MCP server running

## Installation

### Quick Start (macOS only)

```bash
cd xcode_extension

# Generate the Xcode project and build
./Scripts/build.sh --generate

# Install the extension
./Scripts/install.sh
```

### Manual Build

1. **Generate the Xcode project:**
   ```bash
   ./Scripts/generate-xcode-project.sh
   ```

2. **Open in Xcode:**
   ```bash
   open AIOrchestratorXcode.xcodeproj
   ```

3. **Build and Run:**
   - Select the "AI Orchestrator" scheme
   - Build (⌘B) and Run (⌘R)
   - A second Xcode instance will launch with the extension enabled

### Enable the Extension

1. Open **System Preferences** → **Privacy & Security** → **Extensions**
2. Find "AI Orchestrator Extension" under "Xcode Source Editor"
3. Enable the extension
4. Restart Xcode

## Usage

Once installed, find the AI Orchestrator commands under:
**Editor** → **AI Orchestrator**

Or assign keyboard shortcuts in:
**Xcode** → **Settings** → **Key Bindings**

## Configuration

The extension connects to the AI Orchestrator MCP server. Configure the server URL in:
- `~/Library/Preferences/com.debuggerlab.ai-orchestrator-xcode.plist`

Or via the Settings command in Xcode.

## Troubleshooting

### "No such module 'XcodeKit'" Error

**Cause:** XcodeKit is only available when building as an Xcode Source Editor Extension, not with Swift Package Manager.

**Solution:**
1. Use the provided build script which generates a proper Xcode project:
   ```bash
   ./Scripts/build.sh --generate
   ```
2. Do NOT use `swift build` directly - it will fail.

### Extension Not Appearing in Xcode

1. Make sure the extension is enabled in System Preferences
2. Quit and restart Xcode
3. Check Console.app for any extension loading errors

### Commands Are Grayed Out

1. Make sure you have a file open in the source editor
2. For some commands, text must be selected

### MCP Server Connection Failed

1. Verify the MCP server is running:
   ```bash
   cd /path/to/ai_orchestrator
   ./scripts/start-server.sh --fg
   ```
2. Check the server URL in extension settings
3. View server logs: `tail -f logs/mcp-server.log`

## Development

### Project Structure

```
xcode_extension/
├── Sources/
│   ├── Extension/           # Main extension code
│   │   ├── SourceEditorExtension.swift
│   │   ├── BaseCommand.swift
│   │   └── Commands/        # Individual command implementations
│   ├── MCP/                 # MCP client for server communication
│   ├── Models/              # Data models
│   ├── UI/                  # UI components
│   └── Utils/               # Utility classes
├── Resources/               # Plists and assets
├── Scripts/                 # Build scripts
├── Tests/                   # Unit tests
└── Package.swift            # SPM manifest (for IDE support only)
```

### Building for Development

```bash
# Generate and open the Xcode project
./Scripts/build.sh --generate --open
```

### Running Tests

```bash
xcodebuild test -project AIOrchestratorXcode.xcodeproj -scheme "AI Orchestrator Extension"
```

## License

Copyright © 2026 DebuggerLab. All rights reserved.
