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
ANTHROPIC_MODEL=claude-3-5-sonnet-20240620
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

# Test all API connections at once
ai-orchestrator test-api
```

---

## Step 7: Test Each AI Model

### Test All Models at Once

```bash
# Activate venv first!
source venv/bin/activate

# Test all configured APIs
ai-orchestrator test-api
```

### Test Individual Models

```bash
# Test OpenAI (ChatGPT) - Architecture & Design
ai-orchestrator ask -m openai "Say hello in one word"

# Test Anthropic (Claude) - Coding & Implementation
ai-orchestrator ask -m anthropic "Say hello in one word"

# Test Google (Gemini) - Reasoning & Analysis
ai-orchestrator ask -m gemini "Say hello in one word"

# Test Moonshot (Kimi) - Code Review
ai-orchestrator ask -m moonshot "Say hello in one word"
```

### Test Specific Model API Connection

```bash
ai-orchestrator test-api -m openai
ai-orchestrator test-api -m anthropic
ai-orchestrator test-api -m gemini
ai-orchestrator test-api -m moonshot
```

---

## Step 8: Run Your First Tasks

```bash
# Activate venv first!
source venv/bin/activate

# Run a simple task (auto-routed)
ai-orchestrator run "Explain what an API is in 2 sentences"

# Force a specific model
ai-orchestrator run -m anthropic "Write a Python hello world function"

# Save output to file
ai-orchestrator run -m openai "Design a simple REST API" -o api-design.md

# Use quiet mode for scripts
ai-orchestrator ask -m anthropic -q "Write a sorting function"
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

## Common Usage Examples

### Task Routing by Model Type

| Task Type | Best Model | Example Command |
|-----------|------------|-----------------|
| Architecture | OpenAI | `ai-orchestrator run -m openai "Design a microservices architecture"` |
| Coding | Anthropic | `ai-orchestrator run -m anthropic "Implement a rate limiter in Python"` |
| Reasoning | Gemini | `ai-orchestrator run -m gemini "Explain time complexity of quicksort"` |
| Code Review | Moonshot | `ai-orchestrator run -m moonshot "Review this function for security"` |

### Analyze Task Without Executing

```bash
ai-orchestrator analyze "Build a web application with authentication"
```

### List Available Gemini Models

```bash
ai-orchestrator list-models gemini
```

### Use Debug Mode

```bash
ai-orchestrator ask -m anthropic -d "Your prompt"
```

---

## CLI Command Reference

| Command | Purpose |
|---------|---------|
| `ai-orchestrator run "task"` | Execute task with orchestration |
| `ai-orchestrator run -m MODEL "task"` | Force specific model |
| `ai-orchestrator ask -m MODEL "prompt"` | Quick query to model |
| `ai-orchestrator status` | Check configuration |
| `ai-orchestrator test-api` | Test all API connections |
| `ai-orchestrator test-api -m MODEL` | Test specific model |
| `ai-orchestrator analyze "task"` | Preview routing |
| `ai-orchestrator list-models gemini` | List available models |
| `ai-orchestrator init` | Initialize .env file |

---

## Need More Help?

- 📖 [Main README](README.md) - Full documentation
- 📚 [USAGE_GUIDE.md](USAGE_GUIDE.md) - Complete CLI reference
- ⚡ [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - Copy-paste commands
- 🔧 [Troubleshooting Guide](TROUBLESHOOTING.md) - Common issues
- 📋 [Model Documentation](MODELS.md) - Available models

---

**Last Updated**: February 2026
