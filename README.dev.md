# AI Orchestrator - Development Branch

Welcome to the **dev** branch! This branch includes multiple setup options to configure your development environment.

## ⚠️ CRITICAL: Virtual Environment Activation

**You MUST activate the virtual environment before using the CLI!**

```bash
# Every time you open a new terminal:
cd ~/ai-orchestrator  # or your installation directory
source venv/bin/activate

# Then you can use the CLI
ai-orchestrator --help
```

**Or use the quick-start script:**
```bash
./quick-start.sh --help
```

---

## 🚀 Quick Start Options

### Option 1: Interactive Installation (Recommended for Beginners)

```bash
git clone https://github.com/DebuggerLab/ai-orchestrator.git
cd ai-orchestrator
git checkout dev
./install.sh  # Choose [1] for Interactive Wizard
```

### Option 2: Manual .env Setup (Recommended for Experienced Users)

```bash
git clone https://github.com/DebuggerLab/ai-orchestrator.git
cd ai-orchestrator
git checkout dev
./install.sh  # Choose [2] for Manual .env
```

### Option 3: Fully Manual Setup

```bash
# 1. Clone and switch to dev branch
git clone https://github.com/DebuggerLab/ai-orchestrator.git
cd ai-orchestrator
git checkout dev

# 2. Create and activate virtual environment
python3 -m venv venv
source venv/bin/activate  # ⚠️ REQUIRED!

# 3. Install dependencies
pip install --upgrade pip
pip install -r requirements.txt
pip install -e .

# 4. Create .env from template
cp .env.example .env
nano .env  # Add your API keys

# 5. Verify setup
ai-orchestrator status
```

### Option 4: Two-Step Secure Setup (For CI/CD)

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

# 3. Activate the virtual environment (REQUIRED!)
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
- **Anthropic** (claude-3-5-sonnet-20240620) - Coding and debugging
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

### CLI Commands

```bash
# Help and status
ai-orchestrator --help              # Show all commands
ai-orchestrator status              # Check configuration status
ai-orchestrator test-api            # Test all API connections
ai-orchestrator test-api -m MODEL   # Test specific model

# Task execution
ai-orchestrator run "task"          # Run task with auto-routing
ai-orchestrator run -m MODEL "task" # Force specific model
ai-orchestrator analyze "task"      # Preview routing without executing

# Direct model queries
ai-orchestrator ask -m openai "prompt"     # Query OpenAI
ai-orchestrator ask -m anthropic "prompt"  # Query Anthropic
ai-orchestrator ask -m gemini "prompt"     # Query Gemini
ai-orchestrator ask -m moonshot "prompt"   # Query Moonshot

# Model management
ai-orchestrator list-models gemini  # List available Gemini models
ai-orchestrator init                # Initialize .env file
```

### Server Commands

```bash
./scripts/start-server.sh           # Start the MCP server
./scripts/stop-server.sh            # Stop the MCP server
./scripts/restart-server.sh         # Restart the MCP server
./scripts/status.sh                 # Check server status
```

---

## 🧪 Testing During Development

### Test Each AI Model

```bash
# Activate venv first!
source venv/bin/activate

# Quick test for each model
ai-orchestrator ask -m openai "Say OK"      # Test OpenAI
ai-orchestrator ask -m anthropic "Say OK"   # Test Anthropic
ai-orchestrator ask -m gemini "Say OK"      # Test Gemini
ai-orchestrator ask -m moonshot "Say OK"    # Test Moonshot

# Or test all at once
ai-orchestrator test-api
```

### Test with Debug Output

```bash
# See detailed debug info during API calls
ai-orchestrator ask -m anthropic -d "Test prompt"
ai-orchestrator run -m openai -d "Test task"
```

### Test Task Routing

```bash
# See how a task would be routed without executing
ai-orchestrator analyze "Design and implement a REST API"
```

### Model-Specific Development Tests

#### OpenAI (Architecture & Design)
```bash
ai-orchestrator run -m openai "Design a microservices architecture for a chat app"
ai-orchestrator run -m openai "Create a database schema for user management"
```

#### Anthropic (Coding & Implementation)
```bash
ai-orchestrator run -m anthropic "Write a Python rate limiter class"
ai-orchestrator run -m anthropic "Implement binary search in TypeScript"
```

#### Gemini (Reasoning & Analysis)
```bash
ai-orchestrator run -m gemini "Explain the time complexity of merge sort"
ai-orchestrator run -m gemini "Compare REST vs GraphQL for a mobile app"
```

#### Moonshot (Code Review)
```bash
ai-orchestrator run -m moonshot "Review this code for security issues"
```

### Verify Setup After Changes

```bash
# Run this after making configuration changes
source venv/bin/activate
ai-orchestrator status
ai-orchestrator test-api
python -c "from ai_orchestrator.config import Config; c = Config(); print('Config loaded:', bool(c.openai_api_key or c.anthropic_api_key))"
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

### ⚠️ Most Common Issue: ModuleNotFoundError

**Error:**
```
ModuleNotFoundError: No module named 'ai_orchestrator'
```

**Cause:** Virtual environment not activated.

**Solution:**
```bash
cd ~/ai-orchestrator  # or your installation directory
source venv/bin/activate  # ⚠️ REQUIRED!
ai-orchestrator status
```

**Remember:** You must activate the venv EVERY TIME you open a new terminal!

### "command not found: ai-orchestrator"

**Cause:** Venv not activated OR package not installed.

```bash
source venv/bin/activate
pip install -e .
ai-orchestrator --help
```

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

Or manually edit the .env file:
```bash
nano .env  # Replace placeholders with real API keys
```

### Virtual Environment Issues
```bash
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pip install -e .
```

### Using the Quick Start Script

If you keep forgetting to activate venv, use the helper script:
```bash
./quick-start.sh status
./quick-start.sh run "Your task"
./quick-start.sh test-api
```

## 📚 Additional Resources

- [Main README](./README.md) - Full project documentation
- [USAGE_GUIDE.md](./USAGE_GUIDE.md) - Complete CLI reference
- [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) - Quick copy-paste commands
- [Installation Guide](./README_INSTALL.md) - Detailed installation instructions
- [Troubleshooting](./TROUBLESHOOTING.md) - Common issues and solutions
- [Model Documentation](./MODELS.md) - Available models and configuration
- [MANUAL_SETUP.md](./MANUAL_SETUP.md) - Step-by-step manual setup

---

**Dev Branch Maintainer**: DebuggerLab  
**Last Updated**: February 2026
