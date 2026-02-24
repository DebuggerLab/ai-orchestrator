# AI Orchestrator Installation Guide

## 🚀 One-Command Installation

Install AI Orchestrator with a single command:

```bash
curl -fsSL https://raw.githubusercontent.com/DebuggerLab/ai-orchestrator/main/install.sh | bash
```

Or if you've cloned the repository:

```bash
./install.sh
```

---

## 📋 Prerequisites

### System Requirements
- **macOS**: 12.0 (Monterey) or later
- **Architecture**: Apple Silicon (M1/M2/M3) or Intel
- **Disk Space**: 2GB minimum
- **Internet**: Required for installation

### API Keys (Obtain before installation)
- **OpenAI API Key**: [Get it here](https://platform.openai.com/api-keys)
- **Anthropic API Key**: [Get it here](https://console.anthropic.com/settings/keys)
- **Google Gemini API Key**: [Get it here](https://aistudio.google.com/app/apikey) (optional)
- **Moonshot API Key**: [Get it here](https://platform.moonshot.cn/) (optional)

---

## 🛠️ What the Installation Script Does

1. **System Checks**
   - Detects macOS version and architecture
   - Verifies disk space availability
   - Tests network connectivity

2. **Installs Dependencies**
   - Xcode Command Line Tools (if not present)
   - Homebrew (if not present)
   - Python 3.11+ (if not present)

3. **Sets Up the Project**
   - Clones/updates repository to `~/ai-orchestrator`
   - Creates Python virtual environment
   - Installs all pip dependencies

4. **Configuration**
   - Runs interactive wizard for API keys
   - Generates `.env` configuration file
   - Sets up MCP server

5. **Cursor Integration**
   - Configures MCP settings for Cursor IDE
   - Installs `.cursorrules` file

6. **Auto-Start Setup**
   - Creates macOS Launch Agent (optional)
   - Starts MCP server automatically on login

7. **Verification**
   - Tests Python installation
   - Verifies pip packages
   - Tests API connections
   - Generates verification report

---

## ⚙️ Configuration Options

### Interactive Installation (install.sh)

The configuration wizard will prompt for:

| Setting | Default | Description |
|---------|---------|-------------|
| Installation Directory | `~/ai-orchestrator` | Where to install |
| OpenAI API Key | - | For GPT models |
| Anthropic API Key | - | For Claude models |
| Google Gemini API Key | - | For Gemini models |
| Moonshot API Key | - | For Kimi models |
| OpenAI Model | `gpt-4o-mini` | Default OpenAI model |
| Anthropic Model | `claude-3-5-sonnet-20241022` | Default Claude model |
| Gemini Model | `gemini-2.5-flash` | Default Gemini model |
| MCP Server Port | `3000` | Port for MCP server |
| Auto-start on login | `yes` | Start server automatically |
| Enable iOS development | `no` | Install iOS dev tools |

### Non-Interactive Installation (quick-install.sh)

For CI/CD or scripted deployments, use environment variables:

```bash
OPENAI_API_KEY="sk-..." \
ANTHROPIC_API_KEY="sk-ant-..." \
GEMINI_API_KEY="AIza..." \
INSTALL_DIR="$HOME/ai-orchestrator" \
MCP_PORT="3000" \
AUTO_START="yes" \
./quick-install.sh
```

#### Environment Variables

| Variable | Required | Default |
|----------|----------|---------|
| `OPENAI_API_KEY` | Yes | - |
| `ANTHROPIC_API_KEY` | Yes | - |
| `GEMINI_API_KEY` | No | - |
| `MOONSHOT_API_KEY` | No | - |
| `INSTALL_DIR` | No | `~/ai-orchestrator` |
| `MCP_PORT` | No | `3000` |
| `AUTO_START` | No | `yes` |
| `SKIP_VERIFICATION` | No | `no` |

---

## 📁 Installed File Structure

```
~/ai-orchestrator/
├── .env                    # Configuration file
├── install.sh              # Installation script
├── quick-install.sh        # Non-interactive install
├── uninstall.sh            # Uninstallation script
├── update.sh               # Update script
├── scripts/
│   ├── start-server.sh     # Start MCP server
│   ├── stop-server.sh      # Stop MCP server
│   ├── restart-server.sh   # Restart MCP server
│   ├── status.sh           # Show server status
│   ├── logs.sh             # View server logs
│   └── test-apis.sh        # Test API connections
├── logs/
│   ├── mcp-server.log      # Server output
│   └── mcp-server.error.log # Error log
├── venv/                   # Python virtual environment
├── ai_orchestrator/        # Main package
├── mcp_server/             # MCP server
└── cursor_integration/     # Cursor IDE files
```

---

## 🔧 Useful Commands

### Server Management

```bash
# Start MCP server
~/ai-orchestrator/scripts/start-server.sh

# Stop MCP server
~/ai-orchestrator/scripts/stop-server.sh

# Restart MCP server
~/ai-orchestrator/scripts/restart-server.sh

# Check server status
~/ai-orchestrator/scripts/status.sh
```

### Logs

```bash
# View last 50 lines
~/ai-orchestrator/scripts/logs.sh

# Follow logs in real-time
~/ai-orchestrator/scripts/logs.sh -f

# View error logs
~/ai-orchestrator/scripts/logs.sh -e

# Clear logs
~/ai-orchestrator/scripts/logs.sh --clear
```

### Testing

```bash
# Test all API connections
~/ai-orchestrator/scripts/test-apis.sh
```

### Updates

```bash
# Update to latest version
~/ai-orchestrator/update.sh

# Force update
~/ai-orchestrator/update.sh --force
```

### Uninstallation

```bash
# Full uninstall
~/ai-orchestrator/uninstall.sh

# Keep configuration backup
~/ai-orchestrator/uninstall.sh --keep-config

# Skip confirmation
~/ai-orchestrator/uninstall.sh --force
```

---

## 🔍 Troubleshooting

### Installation Issues

#### "Xcode Command Line Tools not found"
```bash
xcode-select --install
```

#### "Python 3.11+ not found"
```bash
brew install python@3.11
```

#### "Homebrew not found"
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Server Issues

#### "MCP server won't start"
1. Check logs: `~/ai-orchestrator/scripts/logs.sh -e`
2. Verify .env file exists: `ls -la ~/ai-orchestrator/.env`
3. Test API keys: `~/ai-orchestrator/scripts/test-apis.sh`

#### "Server crashes on startup"
1. Check for port conflicts: `lsof -i :3000`
2. Kill conflicting process: `kill -9 <PID>`
3. Restart server: `~/ai-orchestrator/scripts/restart-server.sh`

### API Issues

#### "Authentication failed"
- Verify API key is correct in `~/.env`
- Check API key hasn't expired
- Ensure you have credits/quota with the provider

#### "Connection timeout"
- Check internet connectivity
- Try again later (service may be down)
- Check firewall settings

### Cursor Integration Issues

#### "MCP tools not appearing in Cursor"
1. Restart Cursor IDE completely
2. Check MCP configuration:
   ```bash
   cat "$HOME/Library/Application Support/Cursor/User/globalStorage/mcp-settings.json"
   ```
3. Verify server is running: `~/ai-orchestrator/scripts/status.sh`

---

## 📖 Manual Installation (Fallback)

If the automated installation fails, follow these steps:

### 1. Install Prerequisites

```bash
# Install Xcode CLI Tools
xcode-select --install

# Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Python 3.11
brew install python@3.11
```

### 2. Clone Repository

```bash
git clone https://github.com/DebuggerLab/ai-orchestrator.git ~/ai-orchestrator
cd ~/ai-orchestrator
```

### 3. Setup Virtual Environment

```bash
python3.11 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
pip install -r mcp_server/requirements.txt
pip install -e .
```

### 4. Create Configuration

```bash
cp .env.example .env
# Edit .env with your API keys
nano .env
```

### 5. Configure Cursor

Create `~/Library/Application Support/Cursor/User/globalStorage/mcp-settings.json`:

```json
{
  "mcpServers": {
    "ai-orchestrator": {
      "command": "/Users/YOUR_USERNAME/ai-orchestrator/venv/bin/python",
      "args": ["-m", "mcp_server.server"],
      "cwd": "/Users/YOUR_USERNAME/ai-orchestrator",
      "env": {
        "PYTHONPATH": "/Users/YOUR_USERNAME/ai-orchestrator"
      }
    }
  }
}
```

### 6. Start Server

```bash
cd ~/ai-orchestrator
export PYTHONPATH="$PWD"
./venv/bin/python -m mcp_server.server
```

---

## 🔒 Security Notes

- API keys are stored in `~/.env` with restricted permissions (600)
- Never commit `.env` files to version control
- The installation script creates backups before modifying existing installations
- Launch agent runs with user privileges only

---

## 📞 Getting Help

- **Documentation**: See `README.md` and `cursor_integration/CURSOR_SETUP.md`
- **Logs**: Check `~/ai-orchestrator/logs/` for error details
- **Issues**: Report bugs on GitHub Issues

---

## 🔄 Idempotent Installation

The install script can be run multiple times safely:
- Existing installations are backed up
- Configuration is preserved
- Only missing components are installed
- Verification runs after each installation

---

## 📊 Verification Report

After installation, check `~/ai-orchestrator/verification_report.txt` for:
- Python version and installation status
- Installed packages verification
- API connection test results
- MCP server status
- Cursor configuration status
