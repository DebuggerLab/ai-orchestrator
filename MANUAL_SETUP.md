# Manual Setup Guide

This guide explains how to set up AI Orchestrator manually using the `.env` file approach, without going through the interactive wizard.

---

## Prerequisites

- **Python 3.10+** installed
- **pip** installed
- **Git** installed

---

## Step 1: Clone the Repository

```bash
git clone https://github.com/DebuggerLab/ai-orchestrator.git
cd ai-orchestrator
```

---

## Step 2: Create the Virtual Environment

```bash
# Create virtual environment
python3 -m venv venv

# Activate it (you MUST do this before every session!)
source venv/bin/activate
```

> ⚠️ **CRITICAL**: You must activate the virtual environment (`source venv/bin/activate`) before running any `ai-orchestrator` commands!

---

## Step 3: Install Dependencies

```bash
# Make sure venv is activated first!
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip

# Install requirements
pip install -r requirements.txt

# Install the package in editable mode
pip install -e .
```

---

## Step 4: Create Your .env File

### Option A: Copy from Template (Recommended)

```bash
# Copy the example file
cp .env.example .env

# Edit it with your favorite editor
nano .env
# or: vim .env
# or: code .env
```

### Option B: Create from Scratch

```bash
cat > .env << 'EOF'
# API Keys (at least one required)
OPENAI_API_KEY=sk-your-openai-key-here
ANTHROPIC_API_KEY=sk-ant-your-anthropic-key-here
GEMINI_API_KEY=AIza-your-gemini-key-here
MOONSHOT_API_KEY=sk-your-moonshot-key-here

# Model Configuration (optional)
OPENAI_MODEL=gpt-4o-mini
ANTHROPIC_MODEL=claude-3-5-sonnet-20241022
GEMINI_MODEL=gemini-2.5-flash
MOONSHOT_MODEL=moonshot-v1-8k
EOF
```

---

## Step 5: Edit Your API Keys

Open `.env` and replace the placeholder values with your actual API keys:

```bash
nano .env
```

**Required changes:**

| Variable | Replace With | Where to Get |
|----------|--------------|---------------|
| `OPENAI_API_KEY` | Your OpenAI key | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) |
| `ANTHROPIC_API_KEY` | Your Anthropic key | [console.anthropic.com/settings/keys](https://console.anthropic.com/settings/keys) |
| `GEMINI_API_KEY` | Your Google key | [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey) |
| `MOONSHOT_API_KEY` | Your Moonshot key (optional) | [platform.moonshot.cn](https://platform.moonshot.cn) |

> 💡 **Tip**: You only need ONE API key minimum. Start with OpenAI or Anthropic if you're not sure.

---

## Step 6: Verify Your Setup

```bash
# Make sure venv is activated!
source venv/bin/activate

# Check configuration status
ai-orchestrator status

# Test API connections
ai-orchestrator test-api
```

---

## Step 7: Test the CLI

```bash
# Activate venv first!
source venv/bin/activate

# Run a simple test
ai-orchestrator ask openai "Say hello!"

# Run a full task
ai-orchestrator run "Explain what an API is in 2 sentences"
```

---

## ⚠️ Common Mistakes & Solutions

### Error: `ModuleNotFoundError: No module named 'ai_orchestrator'`

**Cause**: Virtual environment not activated.

**Solution**:
```bash
cd /path/to/ai-orchestrator
source venv/bin/activate
ai-orchestrator status
```

### Error: `command not found: ai-orchestrator`

**Cause**: Either venv not activated OR package not installed.

**Solution**:
```bash
source venv/bin/activate
pip install -e .
```

### Error: API keys not found / All models show "Not configured"

**Cause**: .env file doesn't exist or contains placeholders.

**Solution**:
```bash
# Check if .env exists
ls -la .env

# Check its contents
cat .env | grep -v "^#"

# Make sure you replaced placeholders with real keys!
```

### Error: `FileNotFoundError: .env`

**Cause**: You're running from the wrong directory.

**Solution**:
```bash
cd /path/to/ai-orchestrator
source venv/bin/activate
ai-orchestrator status
```

---

## Quick Reference: Every Session

Every time you open a new terminal and want to use AI Orchestrator:

```bash
# 1. Navigate to the project directory
cd ~/ai-orchestrator  # or wherever you installed it

# 2. Activate the virtual environment
source venv/bin/activate

# 3. Now you can use the CLI
ai-orchestrator --help
```

**Or use the quick-start script:**

```bash
./quick-start.sh --help
```

---

## Directory Structure After Setup

```
ai-orchestrator/
├── .env                    # Your API keys (gitignored)
├── .env.example            # Template file
├── venv/                   # Virtual environment (gitignored)
│   └── bin/
│       ├── python
│       ├── pip
│       └── ai-orchestrator # CLI command
├── ai_orchestrator/        # Source code
├── quick-start.sh          # Helper script
└── README.md
```

---

## Alternative: System-Wide Configuration

If you want to store configuration outside the project:

```bash
# Create config directory
mkdir -p ~/.config/ai-orchestrator

# Copy config there
cp .env ~/.config/ai-orchestrator/config.env

# Edit it
nano ~/.config/ai-orchestrator/config.env
```

The CLI will automatically look for configuration in this location.

---

## Need More Help?

- 📖 [Main README](README.md) - Full documentation
- 🔧 [Troubleshooting Guide](TROUBLESHOOTING.md) - Common issues
- 📚 [Model Documentation](MODELS.md) - Available models

---

**Last Updated**: February 2026
