# AI Orchestrator for Xcode

An Xcode Source Editor Extension that integrates AI Orchestrator capabilities directly into your Xcode workflow.

## Features

- **Fix Code Issues**: Automatically detect and fix code errors using AI
- **Explain Code**: Get detailed explanations of selected code
- **Generate Tests**: Create comprehensive unit tests for functions and classes
- **Refactor Code**: Improve code quality with AI-powered refactoring
- **Generate Documentation**: Create Swift documentation comments automatically
- **Build and Fix**: Build your project and auto-fix compilation errors

## Requirements

- macOS 13.0 or later
- Xcode 15.0 or later
- Running MCP server (AI Orchestrator)
- Swift 5.9 or later

## Quick Start

### 1. Start the MCP Server

```bash
cd /path/to/ai_orchestrator/mcp_server
./start.sh
```

### 2. Install the Extension

```bash
cd xcode_extension
./Scripts/install.sh
```

### 3. Enable in System Settings

1. Open **System Settings** > **Privacy & Security** > **Extensions** > **Xcode Source Editor**
2. Enable **AI Orchestrator for Xcode**

### 4. Use in Xcode

Open Xcode and access commands via:
- **Editor** > **AI Orchestrator** > *[Command]*

## Documentation

- [Installation Guide](INSTALLATION.md)
- [Usage Guide](USAGE.md)
- [Keyboard Shortcuts](SHORTCUTS.md)
- [Configuration](CONFIGURATION.md)
- [Troubleshooting](TROUBLESHOOTING.md)

## Keyboard Shortcuts

| Command | Shortcut |
|---------|----------|
| Fix Code Issues | `Cmd+Shift+F` |
| Explain Code | `Cmd+Shift+E` |
| Generate Tests | `Cmd+Shift+T` |
| Refactor Code | `Cmd+Shift+R` |
| Generate Documentation | `Cmd+Shift+D` |
| Build and Fix | `Cmd+Shift+B` |

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Xcode IDE    │     │   Extension     │     │   MCP Server    │
│                │────▶│   (Swift)       │────▶│   (Python)      │
│  Source Editor │     │   Commands      │     │   AI Models     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

## License

Copyright © 2026 DebuggerLab. All rights reserved.
