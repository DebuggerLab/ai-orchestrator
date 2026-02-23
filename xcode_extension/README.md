# AI Orchestrator for Xcode

Xcode Source Editor Extension for AI Orchestrator integration.

## Overview

This extension brings AI-powered coding assistance directly into Xcode, enabling developers to:

- 🔧 **Fix Code Issues** - Automatically detect and fix errors
- 📖 **Explain Code** - Get detailed explanations of complex code
- 🧪 **Generate Tests** - Create comprehensive unit tests
- ⚙️ **Refactor Code** - Improve code quality with AI suggestions
- 📝 **Generate Docs** - Add documentation comments automatically  
- 🛠️ **Build & Fix** - Fix compilation errors automatically

## Quick Start

```bash
# 1. Start the MCP server
cd ../mcp_server && ./start.sh

# 2. Install the extension
./Scripts/install.sh

# 3. Enable in System Settings > Privacy & Security > Extensions > Xcode Source Editor

# 4. Restart Xcode and use via Editor > AI Orchestrator menu
```

## Project Structure

```
xcode_extension/
├── Package.swift              # Swift Package Manager configuration
├── Sources/
│   ├── Extension/             # Xcode extension entry point and commands
│   │   ├── SourceEditorExtension.swift
│   │   ├── BaseCommand.swift
│   │   └── Commands/
│   │       ├── FixCodeCommand.swift
│   │       ├── ExplainCodeCommand.swift
│   │       ├── GenerateTestsCommand.swift
│   │       ├── RefactorCodeCommand.swift
│   │       ├── GenerateDocsCommand.swift
│   │       ├── BuildAndFixCommand.swift
│   │       └── SettingsCommand.swift
│   ├── MCP/                   # MCP client for server communication
│   │   ├── MCPClient.swift
│   │   └── MCPToolDefinitions.swift
│   ├── Models/                # Data models
│   │   └── ExtensionConfiguration.swift
│   ├── UI/                    # User interface components
│   │   ├── ProgressIndicator.swift
│   │   ├── DiffViewerWindow.swift
│   │   └── SettingsPanel.swift
│   └── Utils/                 # Helper utilities
│       ├── Logger.swift
│       ├── SwiftCodeParser.swift
│       ├── DiffGenerator.swift
│       └── CodeFormatter.swift
├── Resources/                 # Extension resources
│   ├── Info.plist
│   └── AI_Orchestrator_Xcode.entitlements
├── Scripts/                   # Build and installation scripts
│   ├── build.sh
│   ├── install.sh
│   ├── uninstall.sh
│   └── test-connection.sh
└── Documentation/            # User documentation
    ├── README.md
    ├── INSTALLATION.md
    ├── USAGE.md
    ├── SHORTCUTS.md
    ├── CONFIGURATION.md
    └── TROUBLESHOOTING.md
```

## Requirements

- macOS 13.0+
- Xcode 15.0+
- Running MCP server
- Swift 5.9+

## Keyboard Shortcuts

| Command | Shortcut |
|---------|----------|
| Fix Code | `Cmd+Shift+F` |
| Explain Code | `Cmd+Shift+E` |
| Generate Tests | `Cmd+Shift+T` |
| Refactor | `Cmd+Shift+R` |
| Generate Docs | `Cmd+Shift+D` |
| Build & Fix | `Cmd+Shift+B` |

## Configuration

Edit `~/.config/ai-orchestrator/settings.json`:

```json
{
    "mcpServerURL": "http://localhost:3000",
    "preferredModel": "claude-3-5-sonnet",
    "autoApplyFixes": false,
    "showDiffBeforeApply": true
}
```

## Documentation

See [Documentation/](Documentation/) for complete guides:
- [Installation Guide](Documentation/INSTALLATION.md)
- [Usage Guide](Documentation/USAGE.md)
- [Configuration](Documentation/CONFIGURATION.md)
- [Troubleshooting](Documentation/TROUBLESHOOTING.md)

## License

Copyright © 2026 DebuggerLab. All rights reserved.
