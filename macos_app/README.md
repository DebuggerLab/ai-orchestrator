# AI Orchestrator Manager - macOS App

A native macOS application for easy setup, configuration, and management of the AI Orchestrator.

## Features

- **One-Click Installation**: Automatically installs the AI Orchestrator with all dependencies
- **Configuration Management**: Securely store API keys in macOS Keychain
- **Server Control**: Start, stop, and monitor the MCP server
- **Real-time Logs**: View and filter server logs in real-time
- **Menu Bar Integration**: Quick access to server controls from the menu bar
- **Auto-Start**: Optionally start the server at login

## System Requirements

- macOS 13.0 (Ventura) or later
- Python 3.9 or later
- Git (for installation)
- Xcode Command Line Tools

## Quick Start

### Building from Source

1. **Clone the repository**:
   ```bash
   cd ai_orchestrator/macos_app/AI\ Orchestrator\ Manager
   ```

2. **Build the application**:
   ```bash
   chmod +x Scripts/build.sh
   ./Scripts/build.sh
   ```

3. **Install**:
   ```bash
   ./Scripts/install.sh
   ```

### Using the App

1. Launch **AI Orchestrator Manager** from Applications
2. Complete the setup wizard:
   - Check system requirements
   - Choose installation location
   - Click "Install"
3. Configure your API keys in the Configuration screen
4. Start the MCP server

## Project Structure

```
AI Orchestrator Manager/
├── Package.swift              # Swift Package Manager manifest
├── Sources/
│   ├── App/
│   │   ├── AIOrchestatorManagerApp.swift  # Main app entry
│   │   └── ContentView.swift              # Root view
│   ├── Views/
│   │   ├── WelcomeView.swift       # Setup wizard
│   │   ├── ConfigurationView.swift # API keys config
│   │   ├── ServerManagementView.swift
│   │   ├── DashboardView.swift     # Status overview
│   │   ├── LogsViewerView.swift    # Log viewer
│   │   ├── MenuBarView.swift       # Menu bar dropdown
│   │   └── SettingsView.swift      # App settings
│   ├── Managers/
│   │   ├── InstallationManager.swift
│   │   ├── ServerManager.swift
│   │   └── ConfigurationManager.swift
│   ├── Models/
│   │   ├── AppState.swift         # App state management
│   │   └── Configuration.swift    # Data models
│   └── Utils/
│       └── ErrorHandler.swift     # Error handling
├── Resources/
│   ├── Info.plist               # App metadata
│   ├── AI_Orchestrator_Manager.entitlements
│   └── com.debuggerlab.ai-orchestrator-manager.plist
└── Scripts/
    ├── build.sh                 # Build script
    ├── create_dmg.sh            # DMG creation
    ├── codesign.sh              # Code signing
    ├── notarize.sh              # Apple notarization
    └── install.sh               # Installation
```

## Building for Distribution

### 1. Build the Application
```bash
./Scripts/build.sh
```

### 2. Create DMG
```bash
./Scripts/create_dmg.sh
```

### 3. Code Sign (requires Apple Developer ID)
```bash
./Scripts/codesign.sh
```

### 4. Notarize with Apple
```bash
./Scripts/notarize.sh
```

## Configuration

### API Keys

API keys are stored securely in the macOS Keychain. Supported providers:

- **OpenAI**: GPT-4, GPT-4 Turbo, GPT-3.5 Turbo
- **Anthropic**: Claude 3.5 Sonnet, Claude 3 Opus, Haiku
- **Google Gemini**: Gemini 2.5 Flash, Gemini 2.5 Pro
- **Moonshot (Kimi)**: Moonshot V1 models

### Server Configuration

- **Port**: Default 3000 (configurable)
- **Auto-start**: Enable to start server at login
- **Log Level**: Debug, Info, Warning, Error

## Troubleshooting

### Server Won't Start

1. Check if Python 3.9+ is installed:
   ```bash
   python3 --version
   ```

2. Check if the port is in use:
   ```bash
   lsof -i :3000
   ```

3. View server logs in the Logs tab

### Installation Fails

1. Ensure Git is installed:
   ```bash
   git --version
   ```

2. Check internet connection

3. Try manual installation:
   ```bash
   git clone https://github.com/debuggerlab/ai-orchestrator.git ~/ai_orchestrator
   cd ~/ai_orchestrator
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

### API Connection Errors

1. Verify API keys are correct
2. Check network connectivity
3. Ensure API service is available

## Development

### Requirements

- Xcode 15.0+
- Swift 5.9+
- macOS 13.0+

### Building in Xcode

1. Open `Package.swift` in Xcode
2. Select "My Mac" as the destination
3. Build and run (Cmd + R)

### Adding New Features

1. Create views in `Sources/Views/`
2. Add business logic in `Sources/Managers/`
3. Define models in `Sources/Models/`
4. Handle errors using `ErrorHandler`

## License

MIT License - See LICENSE file for details.

## Support

- GitHub Issues: [Report a bug](https://github.com/debuggerlab/ai-orchestrator/issues)
- Documentation: [Full documentation](https://github.com/debuggerlab/ai-orchestrator/wiki)
