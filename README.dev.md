# AI Orchestrator - Development Branch

Welcome to the **dev** branch! This branch includes a secure two-step setup process that configures your development environment.

## 🚀 Quick Start (One-Liner)

```bash
# Complete setup in one command:
./quick-dev-setup.sh && ./inject-dev-keys.sh
```

Or step by step:
```bash
# 1. Clone and switch to dev branch
git clone https://github.com/DebuggerLab/ai-orchestrator.git
cd ai-orchestrator
git checkout dev

# 2. Run setup and inject keys
./quick-dev-setup.sh && ./inject-dev-keys.sh

# 3. Activate the virtual environment
source venv/bin/activate

# 4. Start using the AI Orchestrator
ai-orchestrator --help
```

## 🔐 Two-Step Setup Process

### Why Two Steps?

To keep API keys secure and out of GitHub, we use a **two-step process**:

| Step | Script | What it Does | In Git? |
|------|--------|--------------|---------|
| 1 | `quick-dev-setup.sh` | Creates config with **placeholder** keys | ✅ Yes |
| 2 | `inject-dev-keys.sh` | Replaces placeholders with **real** keys | ❌ No (git-ignored) |

This means:
- ✅ The setup script can be safely committed to GitHub
- ✅ Real API keys never touch version control
- ✅ New developers get a working template with clear placeholders

### Step 1: Run Quick Setup

```bash
./quick-dev-setup.sh
```

This creates the config file with placeholder values like:
```env
OPENAI_API_KEY=YOUR_OPENAI_KEY_HERE
ANTHROPIC_API_KEY=YOUR_ANTHROPIC_KEY_HERE
GEMINI_API_KEY=YOUR_GEMINI_KEY_HERE
MOONSHOT_API_KEY=YOUR_MOONSHOT_KEY_HERE
```

### Step 2: Inject Real Keys

```bash
./inject-dev-keys.sh
```

This replaces the placeholders with actual API keys.

> **⚠️ Note:** The `inject-dev-keys.sh` file is git-ignored. You need to create it locally or obtain it separately.

## 📝 Creating inject-dev-keys.sh (If You Don't Have It)

If you need to create your own `inject-dev-keys.sh`:

```bash
cat > inject-dev-keys.sh << 'EOF'
#!/bin/bash
CONFIG_FILE="$HOME/.config/ai-orchestrator/config.env"
sed -i 's|OPENAI_API_KEY=YOUR_OPENAI_KEY_HERE|OPENAI_API_KEY=your-actual-openai-key|g' "$CONFIG_FILE"
sed -i 's|ANTHROPIC_API_KEY=YOUR_ANTHROPIC_KEY_HERE|ANTHROPIC_API_KEY=your-actual-anthropic-key|g' "$CONFIG_FILE"
sed -i 's|GEMINI_API_KEY=YOUR_GEMINI_KEY_HERE|GEMINI_API_KEY=your-actual-gemini-key|g' "$CONFIG_FILE"
sed -i 's|MOONSHOT_API_KEY=YOUR_MOONSHOT_KEY_HERE|MOONSHOT_API_KEY=your-actual-moonshot-key|g' "$CONFIG_FILE"
echo "Keys injected!"
EOF
chmod +x inject-dev-keys.sh
```

Replace `your-actual-*-key` with your real API keys.

## 📦 What's Included

### Pre-configured Models
- **OpenAI** (gpt-4o-mini) - Architecture planning and roadmap generation
- **Anthropic** (claude-3-5-sonnet-20241022) - Coding and debugging
- **Google Gemini** (gemini-2.5-flash) - Reasoning and test design
- **Moonshot/Kimi** (moonshot-v1-8k) - Code review

### Development Tools Enabled
- Debug logging
- Verbose output
- Auto-fix with confidence threshold
- iOS development tools (when available)
- Xcode integration

## 📁 Configuration Location

| File | Location | Purpose |
|------|----------|---------|
| Config File | `~/.config/ai-orchestrator/config.env` | Main configuration with API keys |
| Local .env | `./.env` (symlink) | Convenience access for the project |
| Virtual Env | `./venv/` | Python dependencies |

## 🛠️ Available Commands

After setup, you can use these commands:

```bash
# CLI Commands
ai-orchestrator --help              # Show all commands
ai-orchestrator list-models gemini  # List available Gemini models
ai-orchestrator orchestrate "task"  # Run a task through the orchestrator

# Server Commands
./scripts/start-server.sh           # Start the MCP server
./scripts/stop-server.sh            # Stop the MCP server
./scripts/restart-server.sh         # Restart the MCP server
./scripts/status.sh                 # Check server status
```

## 🔒 Security Notes

### How Keys Stay Secure

1. **`quick-dev-setup.sh`** - Contains only placeholder values, safe to commit
2. **`inject-dev-keys.sh`** - Contains real keys, git-ignored, never committed
3. **Config file** - Stored at `~/.config/ai-orchestrator/config.env` with `chmod 600`

### Verifying Security

```bash
# Check that inject-dev-keys.sh is ignored
git status inject-dev-keys.sh
# Should not show as an untracked file

# Check config file permissions
ls -la ~/.config/ai-orchestrator/config.env
# Should show: -rw------- (600)
```

## 🧪 Testing Your Setup

```bash
# Test the configuration loading
python -c "from ai_orchestrator.config import Config; c = Config(); print('OpenAI:', 'OK' if c.openai_api_key else 'MISSING')"

# Test model connections
./scripts/test-apis.sh  # If available
```

## 🐛 Troubleshooting

### "Config file not found" Error
Run the setup script first:
```bash
./quick-dev-setup.sh
```

### "YOUR_*_KEY_HERE" Error
You haven't injected real keys. Run:
```bash
./inject-dev-keys.sh
```

### Virtual Environment Issues
```bash
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

## 📚 Additional Resources

- [Main README](./README.md) - Full project documentation
- [Installation Guide](./README_INSTALL.md) - Detailed installation instructions
- [Troubleshooting](./TROUBLESHOOTING.md) - Common issues and solutions
- [Model Documentation](./MODELS.md) - Available models and configuration

---

**Dev Branch Maintainer**: DebuggerLab  
**Last Updated**: February 2026
