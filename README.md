# 🤖 AI Orchestrator

A powerful Python CLI tool that intelligently orchestrates multiple AI models for automatic task distribution. Route your tasks to the most suitable AI model based on task type.

[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 📋 Table of Contents

- [Features](#-features)
- [Quick Start](#-quick-start)
- [IDE Integration Overview](#-ide-integration-overview)
- [Cursor IDE Setup](#-cursor-ide-setup)
- [Xcode Extension Setup](#-xcode-extension-setup)
- [Configuration](#️-configuration)
- [Usage](#-usage)
- [Complete Development Cycle](#-complete-development-cycle)
- [How It Works](#-how-it-works)
- [Troubleshooting](#-troubleshooting)
- [Development](#️-development)

---

## 🎯 Features

- **Multi-Model Integration**: Seamlessly connects to OpenAI, Anthropic, Google Gemini, and Moonshot AI
- **Intelligent Task Routing**: Automatically determines the best model for each task type
- **Task Decomposition**: Breaks complex tasks into subtasks and routes each optimally
- **Project Execution**: Run and test projects with auto-detection (Python, Node.js, React, Flask, Django, iOS/SwiftUI)
- **iOS/SwiftUI Development**: Build iOS apps, run in Simulator, execute XCTest, manage simulators
- **Auto-Fix System**: Automatically detect, analyze, and fix errors with AI-powered solutions
- **Verification Loop**: Iterative run → test → fix cycle until all tests pass
- **Beautiful CLI Output**: Rich formatting with progress indicators and colored output
- **Error Handling**: Graceful fallback when models are unavailable
- **IDE Integration**: Works with Cursor IDE (MCP) and Xcode Extension

### 🏗️ Model Specializations

| Model | Provider | Specialization |
|-------|----------|----------------|
| **ChatGPT** | OpenAI | Architecture, Roadmap, System Design |
| **Claude** | Anthropic | Coding, Implementation, Debugging |
| **Gemini** | Google | Reasoning, Logic, Analysis |
| **Kimi** | Moonshot AI | Code Review, Quality Assurance |

### 📦 SDK Migration Notice

> **Important**: As of February 2026, this project uses the new `google-genai` SDK (replacing the deprecated `google-generativeai` package). The deprecated SDK's support terminated on November 30, 2025.
> 
> - **Package change**: `google-generativeai` → `google-genai`
> - **Import change**: `import google.generativeai as genai` → `from google import genai`
> - **API change**: Uses client-based pattern: `client = genai.Client(api_key=...)`
> 
> See [google-genai documentation](https://github.com/googleapis/python-genai) for more details.

---

## 🚀 Quick Start

Get up and running in under a minute with one command!

### One-Command Installation

```bash
# Clone and install everything automatically
git clone https://github.com/DebuggerLab/ai-orchestrator.git && cd ai-orchestrator && ./install.sh
```

Or if you already have the repository:

```bash
cd ai_orchestrator
./install.sh
```

The installer will ask you to choose between:
1. **Interactive Wizard** - Answer prompts to configure API keys (recommended for beginners)
2. **Manual .env File** - Copy `.env.example` to `.env` and edit it yourself

### ⚠️ CRITICAL: Activate Virtual Environment

**You MUST activate the virtual environment before using the CLI!**

```bash
# Every time you open a new terminal:
cd ~/ai-orchestrator  # or your installation directory
source venv/bin/activate

# Then you can use the CLI
ai-orchestrator --help
```

**Or use the quick-start helper script:**

```bash
./quick-start.sh --help
./quick-start.sh status
./quick-start.sh run "Your task here"
```

### What Happens During Installation

The `install.sh` script automatically:

1. ✅ **Checks Prerequisites** - Verifies Python 3.10+ and pip are installed
2. ✅ **Creates Virtual Environment** - Sets up isolated Python environment
3. ✅ **Installs Dependencies** - Installs all required Python packages
4. ✅ **Installs CLI Tool** - Makes `ai-orchestrator` command available in venv
5. ✅ **Creates Config Template** - Copies `.env.example` to `.env`
6. ✅ **Sets Up MCP Server** - Prepares Cursor IDE integration
7. ✅ **Configures Cursor** - Auto-configures Cursor settings (if Cursor is installed)
8. ✅ **Verifies Installation** - Runs health check to confirm everything works

### Next Steps After Installation

```bash
# 1. Activate the virtual environment (REQUIRED!)
source venv/bin/activate

# 2. Add your API keys (if using manual setup)
nano .env   # or use your preferred editor

# 3. Verify everything is working
ai-orchestrator status

# 4. Run your first task
ai-orchestrator run "Design a REST API for a todo application"
```

### Installation Methods

| Method | Best For | Command |
|--------|----------|---------|
| **Interactive Wizard** | First-time users | `./install.sh` → choose [1] |
| **Manual .env File** | Experienced users | `./install.sh` → choose [2] |
| **Fully Manual** | Full control | See [MANUAL_SETUP.md](MANUAL_SETUP.md) |

> 📖 **Detailed installation guide:** See [README_INSTALL.md](README_INSTALL.md) for advanced options.
> 
> 📖 **Manual setup guide:** See [MANUAL_SETUP.md](MANUAL_SETUP.md) for step-by-step manual configuration.

---

## 🎯 IDE Integration Overview

AI Orchestrator integrates with two major IDEs, each with different capabilities:

### Feature Comparison

| Feature | Cursor IDE (MCP) | Xcode Extension |
|---------|------------------|-----------------|
| **Setup Complexity** | Easy (auto-config) | Medium (manual enable) |
| **Task Routing** | ✅ Full support | ✅ Full support |
| **Code Generation** | ✅ In-editor | ✅ In-editor |
| **Project Execution** | ✅ Full workflow | ⚠️ Build only |
| **Auto-Fix Loop** | ✅ Automated | ⚠️ Manual trigger |
| **iOS Simulator** | ❌ N/A | ✅ Native support |
| **Swift/SwiftUI** | ⚠️ Basic | ✅ Optimized |
| **Multi-file Edits** | ✅ Supported | ⚠️ Single file |
| **Real-time Chat** | ✅ MCP chat | ❌ Commands only |

### When to Use Which

| Use Case | Recommended IDE |
|----------|-----------------|
| Web development (JS/TS/Python) | **Cursor IDE** |
| iOS/macOS development | **Xcode Extension** |
| Full-stack projects | **Cursor IDE** |
| SwiftUI prototyping | **Xcode Extension** |
| Code review & refactoring | **Both work well** |
| Multi-model orchestration | **Cursor IDE** |
| XCTest integration | **Xcode Extension** |

---

## 📱 Cursor IDE Setup

Cursor IDE uses the **Model Context Protocol (MCP)** for seamless AI orchestration directly in the chat and composer.

### How MCP Integration Works

```
┌────────────────────────────────────────────────────────┐
│                    Cursor IDE                          │
│  ┌─────────────────────────────────────────────────┐  │
│  │           MCP Client (Built-in)                 │  │
│  └───────────────────────┬─────────────────────────┘  │
│                          │ JSON-RPC                    │
│                          ▼                             │
│  ┌─────────────────────────────────────────────────┐  │
│  │        AI Orchestrator MCP Server               │  │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌───────┐ │  │
│  │  │ ChatGPT │ │ Claude  │ │ Gemini  │ │ Kimi  │ │  │
│  │  │ (Arch)  │ │ (Code)  │ │(Reason) │ │(Review│ │  │
│  │  └─────────┘ └─────────┘ └─────────┘ └───────┘ │  │
│  └─────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────┘
```

### Automatic Setup (Recommended)

If you ran `./install.sh`, Cursor is already configured! Just restart Cursor.

### Manual Setup

If automatic setup didn't work or you prefer manual configuration:

#### Step 1: Install MCP Server Dependencies

```bash
cd /path/to/ai_orchestrator/mcp_server
pip install -r requirements.txt
```

#### Step 2: Configure Cursor

Open Cursor Settings (`Cmd+,` on Mac, `Ctrl+,` on Windows/Linux):

1. Search for "MCP" in settings
2. Click "Edit in settings.json"
3. Add the MCP server configuration:

```json
{
  "mcpServers": {
    "ai-orchestrator": {
      "command": "python",
      "args": ["/path/to/ai_orchestrator/mcp_server/server.py"],
      "env": {
        "PYTHONPATH": "/path/to/ai_orchestrator"
      },
      "cwd": "/path/to/ai_orchestrator/mcp_server"
    }
  }
}
```

> 💡 **Tip:** Replace `/path/to/ai_orchestrator` with your actual installation path.

#### Step 3: Restart Cursor

Close and reopen Cursor IDE for changes to take effect.

### How to Verify Cursor is Connected

1. **Open Cursor Chat** (`Cmd+L` or `Ctrl+L`)
2. **Type `@`** - You should see "ai-orchestrator" in the suggestions
3. **Check available tools** by asking: `@ai-orchestrator check_status()`

**Expected output:**
```
✅ MCP Server Connected
Available models:
  - OpenAI (ChatGPT): ✅ Configured
  - Anthropic (Claude): ✅ Configured
  - Google (Gemini): ✅ Configured
  - Moonshot (Kimi): ❌ Not configured
```

### Available Tools in Cursor

Use these tools by typing `@ai-orchestrator` followed by the tool name:

| Tool | Purpose | Example |
|------|---------|---------|
| `orchestrate_task` | Full multi-model task execution | `@ai-orchestrator orchestrate_task("Build a todo app")` |
| `analyze_task` | See routing plan without executing | `@ai-orchestrator analyze_task("Create a REST API")` |
| `route_to_model` | Send to specific model | `@ai-orchestrator route_to_model("Fix this bug", "anthropic")` |
| `run_project` | Execute any project | `@ai-orchestrator run_project("/path/to/project")` |
| `test_project` | Run test suite | `@ai-orchestrator test_project("/path/to/project")` |
| `analyze_errors` | Deep error analysis | `@ai-orchestrator analyze_errors("/path/to/project")` |
| `fix_issues` | AI-powered auto-fix | `@ai-orchestrator fix_issues("/path/to/project")` |
| `verify_project` | Full fix loop | `@ai-orchestrator verify_project("/path/to/project")` |
| `check_status` | Check available models | `@ai-orchestrator check_status()` |
| `get_available_models` | List all models | `@ai-orchestrator get_available_models()` |

### Example Usage in Cursor

**Design and implement a feature:**
```
@ai-orchestrator orchestrate_task("Design and implement a REST API for user management with JWT authentication")
```

**Debug a project:**
```
@ai-orchestrator analyze_errors("/Users/myuser/projects/myapp")
@ai-orchestrator fix_issues("/Users/myuser/projects/myapp")
```

**Full development cycle:**
```
@ai-orchestrator verify_project("/Users/myuser/projects/myapp")
```

### Troubleshooting Cursor Connection

#### ❌ "ai-orchestrator" not appearing in @ suggestions

1. **Check settings.json syntax** - JSON must be valid
2. **Verify file paths** - All paths must be absolute and exist
3. **Check Python** - Run `which python` to verify Python is accessible
4. **Restart Cursor** - Full restart, not just reload

#### ❌ "Connection refused" or timeout errors

```bash
# Test the server manually
cd /path/to/ai_orchestrator/mcp_server
python server.py
```

If it fails, check:
- Python version (requires 3.10+)
- Missing dependencies: `pip install -r requirements.txt`
- Missing API keys: Verify `.env` file exists

#### ❌ "No tools available"

Check that PYTHONPATH is set correctly in settings.json:
```json
"env": {
  "PYTHONPATH": "/path/to/ai_orchestrator"
}
```

#### ❌ Models showing "Not configured"

Add API keys to your `.env` file:
```bash
cd /path/to/ai_orchestrator
nano .env
```

> 📚 **Full Cursor documentation:** [`cursor_integration/CURSOR_SETUP.md`](cursor_integration/CURSOR_SETUP.md)

---

## 🔧 Xcode Extension Setup

The Xcode extension provides native AI orchestration for Swift and SwiftUI development.

### Prerequisites

| Requirement | Minimum Version |
|-------------|-----------------|
| **macOS** | 13.0 (Ventura) or later |
| **Xcode** | 15.0 or later |
| **Python** | 3.10 or later |

### Installation Steps

#### Step 1: Build the Extension

```bash
# Navigate to the macOS app directory
cd /path/to/ai_orchestrator/macos_app/AI\ Orchestrator\ Manager

# Run the build script
./Scripts/build.sh
```

#### Step 2: Install the Extension

```bash
# Run the installation script
./Scripts/install.sh
```

This will:
- Copy the extension to `~/Library/Developer/Xcode/Plug-ins/`
- Register the extension with Xcode
- Set up the connection to AI Orchestrator

#### Step 3: Enable the Extension in Xcode

1. **Open Xcode**
2. **Go to Settings** (`Cmd+,`)
3. **Select "Extensions"** tab
4. **Find "AI Orchestrator"** in the list
5. **Check the box** to enable it
6. **Restart Xcode**

```
┌─────────────────────────────────────────────────┐
│  Xcode > Settings > Extensions                  │
├─────────────────────────────────────────────────┤
│  ☑️ AI Orchestrator                             │
│     └── ☑️ Source Editor Commands               │
│     └── ☑️ Build System Commands                │
└─────────────────────────────────────────────────┘
```

### Available Commands and Keyboard Shortcuts

Access commands via **Editor menu** or keyboard shortcuts:

| Command | Shortcut | Description |
|---------|----------|-------------|
| **Orchestrate Selection** | `⌃⌥⌘O` | Route selected code to best AI model |
| **Generate Code** | `⌃⌥⌘G` | Generate code from comment/description |
| **Review Code** | `⌃⌥⌘R` | Get AI code review for selection |
| **Fix Errors** | `⌃⌥⌘F` | Auto-fix errors in current file |
| **Explain Code** | `⌃⌥⌘E` | Get explanation of selected code |
| **Generate Tests** | `⌃⌥⌘T` | Generate XCTest for selected code |
| **Optimize Code** | `⌃⌥⌘P` | Optimize selected code for performance |

### How to Use the Extension

#### Method 1: Editor Menu

1. **Select code** in Xcode editor
2. **Go to Editor menu** → **AI Orchestrator**
3. **Choose command** (e.g., "Review Code")

#### Method 2: Keyboard Shortcuts

1. **Select code** in Xcode editor
2. **Press shortcut** (e.g., `⌃⌥⌘R` for review)

#### Method 3: Right-Click Context Menu

1. **Select code** in Xcode editor
2. **Right-click** to open context menu
3. **Select AI Orchestrator** → Choose command

### Example Workflows

#### 🔄 SwiftUI View Development

```swift
// 1. Write a comment describing what you want
// TODO: Create a SwiftUI view for a user profile card with avatar, name, and bio

// 2. Select the comment
// 3. Press ⌃⌥⌘G (Generate Code)
// 4. AI Orchestrator generates:

struct UserProfileCard: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: user.avatarURL) { image in
                image.resizable()
            } placeholder: {
                Circle().fill(.gray.opacity(0.3))
            }
            .frame(width: 80, height: 80)
            .clipShape(Circle())
            
            Text(user.name)
                .font(.headline)
            
            Text(user.bio)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
```

#### 🐛 Error Fixing

```swift
// 1. You have code with errors
func fetchData() {
    let url = URL(string: "https://api.example.com/data")
    URLSession.shared.dataTask(with: url) { data, response, error in
        // Missing error handling, force unwrapping
        let json = try! JSONDecoder().decode(MyModel.self, from: data!)
        print(json)
    }
}

// 2. Select the function
// 3. Press ⌃⌥⌘F (Fix Errors)
// 4. AI Orchestrator suggests fixes with proper error handling
```

#### 🧪 Test Generation

```swift
// 1. Select a function you want to test
func calculateDiscount(price: Double, percentage: Double) -> Double {
    return price * (1 - percentage / 100)
}

// 2. Press ⌃⌥⌘T (Generate Tests)
// 3. AI Orchestrator generates XCTest:

class DiscountCalculatorTests: XCTestCase {
    func testCalculateDiscount_withValidPercentage() {
        let result = calculateDiscount(price: 100, percentage: 20)
        XCTAssertEqual(result, 80.0, accuracy: 0.001)
    }
    
    func testCalculateDiscount_withZeroPercentage() {
        let result = calculateDiscount(price: 100, percentage: 0)
        XCTAssertEqual(result, 100.0, accuracy: 0.001)
    }
    
    func testCalculateDiscount_with100Percentage() {
        let result = calculateDiscount(price: 100, percentage: 100)
        XCTAssertEqual(result, 0.0, accuracy: 0.001)
    }
}
```

### Troubleshooting Xcode Extension

#### ❌ Extension not appearing in Xcode settings

1. **Verify installation location:**
   ```bash
   ls ~/Library/Developer/Xcode/Plug-ins/
   # Should show: AIOrchestrator.xcplugin
   ```

2. **Re-run installation:**
   ```bash
   cd /path/to/ai_orchestrator/macos_app/AI\ Orchestrator\ Manager
   ./Scripts/install.sh
   ```

3. **Check macOS security:**
   - Go to **System Settings** → **Privacy & Security**
   - Allow the extension if blocked

#### ❌ Commands not responding

1. **Check AI Orchestrator is running:**
   ```bash
   cd /path/to/ai_orchestrator
   ./scripts/status.sh
   ```

2. **Verify API keys:**
   ```bash
   ai-orchestrator status
   ```

3. **Check Xcode console:**
   - Open **Xcode** → **View** → **Debug Area** → **Activate Console**
   - Look for error messages

#### ❌ Slow response times

1. **Check network connection**
2. **Verify API quotas** aren't exceeded
3. **Try simpler selections** (smaller code blocks)

#### ❌ Extension disabled after Xcode update

After major Xcode updates, you may need to:
1. **Re-enable the extension** in Xcode Settings
2. **Re-build** if needed: `./Scripts/build.sh`

> 📚 **Full Xcode documentation:** [`macos_app/AI Orchestrator Manager/USER_GUIDE.md`](macos_app/AI%20Orchestrator%20Manager/USER_GUIDE.md)

---

## ⚙️ Configuration

### 1. Create Configuration File

```bash
# Option A: Use the init command (recommended)
ai-orchestrator init

# Option B: Copy the example file
cp .env.example .env
```

### 2. Add Your API Keys

Edit `.env` and add your API keys:

```env
# OpenAI API Key (for ChatGPT - Architecture & Roadmap)
OPENAI_API_KEY=sk-your-openai-api-key-here

# Anthropic API Key (for Claude - Coding Tasks)
ANTHROPIC_API_KEY=sk-ant-your-anthropic-api-key-here

# Google Gemini API Key (for Reasoning)
GEMINI_API_KEY=your-gemini-api-key-here

# Moonshot AI API Key (for Kimi - Code Review)
MOONSHOT_API_KEY=your-moonshot-api-key-here
```

### 3. Verify Configuration

```bash
ai-orchestrator status
```

> **Note**: You don't need all API keys - the tool works with any combination of available models.

### Custom Model Selection

```env
# Override default model names
OPENAI_MODEL=gpt-4o
ANTHROPIC_MODEL=claude-3-opus-20240229
GEMINI_MODEL=gemini-2.5-flash          # Latest stable (default)
# GEMINI_MODEL=gemini-flash-latest     # Always use latest flash version
# GEMINI_MODEL=gemini-2.5-pro          # Premium model
MOONSHOT_MODEL=moonshot-v1-32k
```

> 📖 See [MODELS.md](MODELS.md) for a complete list of available models, pricing, and access requirements.

### Checking Available Models

```bash
# List available Gemini models
ai-orchestrator list-models gemini
```

---

## 🖥️ Usage

### Basic CLI Usage

```bash
# Run a task
ai-orchestrator run "Design a REST API for a todo application"

# Run with specific model
ai-orchestrator run -m anthropic "Implement a binary search algorithm in Python"

# Save output to file
ai-orchestrator run "Create a roadmap for mobile app" -o roadmap.md

# Quiet mode (minimal output)
ai-orchestrator run -q "Quick task"
```

### Commands

```bash
# Execute a task with AI orchestration
ai-orchestrator run "<task description>"

# Check configuration status
ai-orchestrator status

# Initialize .env file in current directory
ai-orchestrator init

# Analyze task routing without executing
ai-orchestrator analyze "<task description>"

# Show help
ai-orchestrator --help
```

### Task Type Examples

**Architecture Tasks** (→ OpenAI/ChatGPT):
```bash
ai-orchestrator run "Design a microservices architecture for an e-commerce platform"
ai-orchestrator run "Create a system design for a real-time chat application"
```

**Coding Tasks** (→ Anthropic/Claude):
```bash
ai-orchestrator run "Implement a rate limiter in Python with sliding window"
ai-orchestrator run "Write a React component for a data table with sorting"
```

**Reasoning Tasks** (→ Google/Gemini):
```bash
ai-orchestrator run "Analyze the trade-offs between SQL and NoSQL for this use case"
ai-orchestrator run "Explain why this algorithm has O(n log n) complexity"
```

**Code Review Tasks** (→ Moonshot/Kimi):
```bash
ai-orchestrator run "Review this code for security vulnerabilities"
ai-orchestrator run "Audit this function for best practices"
```

---

## 🔄 Complete Development Cycle

The AI Orchestrator supports a full development workflow:

```
PLAN → CODE → RUN → TEST → FIX → VERIFY → REVIEW → DONE
```

### Quick Start for Full Project Development

```bash
# In Cursor IDE with MCP:

# 1. Design & Implement
@ai-orchestrator orchestrate_task("Build a REST API for user management with JWT auth")

# 2. Run project and auto-fix any issues
@ai-orchestrator verify_project("/path/to/project")

# 3. Review the final code
@ai-orchestrator orchestrate_task("Review the implementation for security")
```

### What the Verification Loop Does

```
┌─────────────────────────────────────────────────────────────┐
│                    VERIFICATION LOOP                         │
├─────────────────────────────────────────────────────────────┤
│  Cycle 1: RUN → 5 errors → FIX 3 → Progress: 40%           │
│  Cycle 2: RUN → 2 errors → FIX 1 → Progress: 80%           │
│  Cycle 3: RUN → 1 error  → FIX 1 → Progress: 100% ✅        │
└─────────────────────────────────────────────────────────────┘
```

### Execution & Auto-Fix Tools

| Tool | Purpose | Example |
|------|---------|---------|
| `run_project` | Execute any project | `run_project("/path")` |
| `test_project` | Run test suite | `test_project("/path")` |
| `analyze_errors` | Deep error analysis | `analyze_errors("/path")` |
| `fix_issues` | AI-powered auto-fix | `fix_issues("/path")` |
| `verify_project` | Full fix loop | `verify_project("/path")` |
| `orchestrate_full_development` | Complete workflow | `orchestrate_full_development("desc", "/path")` |

📚 **See [WORKFLOWS.md](WORKFLOWS.md) for visual workflow diagrams and decision trees.**

---

## 📊 How It Works

### Task Routing Logic

1. **Analysis**: The router analyzes your task description for keywords
2. **Classification**: Determines task type(s) present in the request
3. **Routing**: Maps each task type to its specialized model
4. **Execution**: Sends prompts with appropriate system instructions
5. **Consolidation**: Combines results into a unified output

### Keyword Detection

| Task Type | Example Keywords |
|-----------|-----------------|
| Architecture | design, structure, system, blueprint, schema |
| Roadmap | plan, timeline, milestone, strategy, phase |
| Coding | implement, write, function, class, code |
| Debugging | fix, error, bug, crash, not working |
| Reasoning | analyze, why, compare, trade-off, evaluate |
| Code Review | review, audit, inspect, security, quality |

### Programmatic Usage

```python
from ai_orchestrator.config import Config
from ai_orchestrator.orchestrator import Orchestrator

# Load configuration
config = Config.load()

# Create orchestrator
orchestrator = Orchestrator(config)

# Execute task
result = orchestrator.execute("Implement a sorting algorithm")

# Access results
print(result.consolidated_output)
for subtask, response in result.subtask_results:
    print(f"{subtask.target_model}: {response.content[:100]}...")
```

---

## ❓ Troubleshooting

> 📚 **For comprehensive troubleshooting, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)**

### ⚠️ Most Common Issue: ModuleNotFoundError

**Error:**
```
ModuleNotFoundError: No module named 'ai_orchestrator'
```

**Cause:** The virtual environment is not activated.

**Solution:**
```bash
# 1. Navigate to the project directory
cd ~/ai-orchestrator  # or wherever you installed it

# 2. Activate the virtual environment
source venv/bin/activate

# 3. Now run your command
ai-orchestrator status
```

**Alternative:** Use the quick-start script:
```bash
./quick-start.sh status
```

> ⚠️ **Remember**: You must activate the venv EVERY TIME you open a new terminal!

### Quick Fixes for Common Issues

#### "command not found: ai-orchestrator"

**Cause:** Venv not activated OR package not installed.

```bash
# Solution:
source venv/bin/activate
pip install -e .
ai-orchestrator --help
```

#### MCP Server Not Starting / Empty Logs

```bash
# Run in foreground to see errors
./scripts/start-server.sh --fg

# Check the log file
tail -f logs/mcp-server.log
```

#### Xcode Extension Build Error: "No such module 'XcodeKit'"

```bash
# Use the build script (not swift build)
cd xcode_extension
./Scripts/build.sh --generate
```

XcodeKit is only available in Xcode projects, not Swift Package Manager.

#### Model Access Errors (404 Not Found)

Update your `.env` file with current model names:

```env
OPENAI_MODEL=gpt-4o-mini
ANTHROPIC_MODEL=claude-3-5-sonnet-20241022
GEMINI_MODEL=gemini-2.5-flash
MOONSHOT_MODEL=moonshot-v1-8k
```

#### API Keys Not Found / "All models show Not configured"

**Cause:** .env file doesn't exist or contains placeholders.

```bash
# Check if .env exists and has real values
cat .env | grep -v "^#" | grep API_KEY

# If you see "your_key_here", edit the file:
nano .env
```

### Common Error Reference

| Error | Likely Cause | Quick Solution |
|-------|--------------|----------------|
| `ModuleNotFoundError: 'ai_orchestrator'` | **Venv not activated** | `source venv/bin/activate` |
| `command not found: ai-orchestrator` | Venv not activated | `source venv/bin/activate` |
| `ModuleNotFoundError: 'mcp'` | Missing dependency | `pip install mcp` |
| `no such module 'XcodeKit'` | Using SPM | Use `./Scripts/build.sh --generate` |
| `404 model not found` | Outdated model name | Update model in `.env` |
| `Connection refused` | Server not running | `./scripts/start-server.sh` |
| `Logs are empty` | Normal for MCP | Check `logs/mcp-server.log` |

### Getting Help

- 📖 **Full troubleshooting guide**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- 📖 **Manual setup guide**: [MANUAL_SETUP.md](MANUAL_SETUP.md)
- 📚 **Model reference**: [MODELS.md](MODELS.md)
- 🖥️ **Cursor setup**: [cursor_integration/CURSOR_SETUP.md](cursor_integration/CURSOR_SETUP.md)
- 📱 **Xcode extension**: [xcode_extension/README.md](xcode_extension/README.md)
- 🐛 **Report issues** on GitHub

---

## 🛠️ Development

### Project Structure

```
ai_orchestrator/
├── ai_orchestrator/          # Core Python package
│   ├── cli.py                # CLI interface
│   ├── config.py             # Configuration management
│   ├── orchestrator.py       # Main orchestration logic
│   ├── router.py             # Task routing logic
│   ├── models/               # AI model clients
│   └── execution/            # Project execution & auto-fix
├── mcp_server/               # Cursor MCP integration
├── cursor_integration/       # Cursor setup docs & examples
├── macos_app/                # Xcode extension
├── scripts/                  # Server management scripts
├── .env.example              # Config template
├── install.sh                # One-command installation
├── requirements.txt          # Python dependencies
└── README.md                 # This file
```

### Running Tests

```bash
# Run with pytest
pytest tests/

# Run with coverage
pytest --cov=ai_orchestrator tests/
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- OpenAI for ChatGPT API
- Anthropic for Claude API
- Google for Gemini API
- Moonshot AI for Kimi API
