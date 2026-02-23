# Cursor IDE Integration Guide for AI Orchestrator

This guide walks you through setting up the AI Orchestrator MCP server with Cursor IDE, enabling intelligent multi-model task routing directly in your development environment.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Step-by-Step Setup](#step-by-step-setup)
- [Verifying the Connection](#verifying-the-connection)
- [Using the Orchestrator](#using-the-orchestrator)
- [Example Workflows](#example-workflows)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)

---

## Overview

The AI Orchestrator integrates with Cursor IDE via the Model Context Protocol (MCP), providing:

- **Multi-model routing**: Automatically route tasks to the best AI model
- **Task decomposition**: Break complex projects into manageable subtasks
- **Specialized execution**: Use ChatGPT for architecture, Claude for coding, Gemini for reasoning, and Kimi for reviews

```
┌─────────────────────────────────────────────────────────────┐
│                      Cursor IDE                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │                   MCP Client                           │  │
│  └───────────────────────┬───────────────────────────────┘  │
│                          │                                   │
│                          ▼                                   │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              AI Orchestrator MCP Server                │  │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐     │  │
│  │  │ ChatGPT │ │ Claude  │ │ Gemini  │ │  Kimi   │     │  │
│  │  │(Arch)   │ │(Code)   │ │(Reason) │ │(Review) │     │  │
│  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘     │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

Before starting, ensure you have:

### 1. Required Software
- **Cursor IDE** (version 0.40.0 or later with MCP support)
- **Python 3.9+** installed
- **pip** package manager

### 2. API Keys
You'll need API keys for the AI models you want to use:

| Model | Required | Get API Key |
|-------|----------|-------------|
| OpenAI (ChatGPT) | Yes | [platform.openai.com](https://platform.openai.com/api-keys) |
| Anthropic (Claude) | Yes | [console.anthropic.com](https://console.anthropic.com/) |
| Google (Gemini) | Optional | [aistudio.google.com](https://aistudio.google.com/app/apikey) |
| Moonshot (Kimi) | Optional | [platform.moonshot.cn](https://platform.moonshot.cn/) |

### 3. AI Orchestrator Installed
```bash
cd /home/ubuntu/ai_orchestrator
pip install -e .
cd mcp_server
pip install -r requirements.txt
```

---

## Step-by-Step Setup

### Step 1: Configure API Keys

Create or update the `.env` file in the ai_orchestrator directory:

```bash
cd /home/ubuntu/ai_orchestrator
cp .env.example .env
```

Edit `.env` with your API keys:

```env
# Required
OPENAI_API_KEY=sk-your-openai-key-here
ANTHROPIC_API_KEY=sk-ant-your-anthropic-key-here

# Optional (but recommended)
GEMINI_API_KEY=your-gemini-key-here
MOONSHOT_API_KEY=your-moonshot-key-here

# Model Configuration (optional - uses defaults if not set)
OPENAI_MODEL=gpt-4o-mini
ANTHROPIC_MODEL=claude-3-5-sonnet-20241022
GEMINI_MODEL=gemini-2.5-flash
MOONSHOT_MODEL=moonshot-v1-8k
```

### Step 2: Test the MCP Server

Before configuring Cursor, verify the server starts correctly:

```bash
cd /home/ubuntu/ai_orchestrator/mcp_server
./start.sh
```

You should see:
```
Starting AI Orchestrator MCP Server...
Server ready and listening for connections.
```

Press `Ctrl+C` to stop.

### Step 3: Configure Cursor IDE

#### Option A: Using the Settings UI

1. Open Cursor IDE
2. Press `Cmd+,` (Mac) or `Ctrl+,` (Windows/Linux) to open Settings
3. Search for "MCP" in the settings search bar
4. Click "Edit in settings.json" under MCP Servers
5. Add the AI Orchestrator configuration (see Step 4)

#### Option B: Edit settings.json Directly

1. Open Cursor IDE
2. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows/Linux)
3. Type "Open Settings (JSON)" and select it
4. Add the MCP server configuration

### Step 4: Add MCP Server Configuration

Add this to your Cursor `settings.json`:

```json
{
  "mcpServers": {
    "ai-orchestrator": {
      "command": "python",
      "args": ["/home/ubuntu/ai_orchestrator/mcp_server/server.py"],
      "env": {
        "PYTHONPATH": "/home/ubuntu/ai_orchestrator"
      },
      "cwd": "/home/ubuntu/ai_orchestrator/mcp_server"
    }
  }
}
```

**For Windows users**, adjust paths:
```json
{
  "mcpServers": {
    "ai-orchestrator": {
      "command": "python",
      "args": ["C:\\path\\to\\ai_orchestrator\\mcp_server\\server.py"],
      "env": {
        "PYTHONPATH": "C:\\path\\to\\ai_orchestrator"
      },
      "cwd": "C:\\path\\to\\ai_orchestrator\\mcp_server"
    }
  }
}
```

### Step 5: Restart Cursor

1. Close Cursor completely
2. Reopen Cursor
3. The MCP server will start automatically

---

## Verifying the Connection

### Check MCP Server Status

1. Open Cursor's Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`)
2. Type "MCP: Show Tools" or look for MCP-related commands
3. You should see the AI Orchestrator tools listed:
   - `orchestrate_task`
   - `analyze_task`
   - `check_status`
   - `route_to_model`
   - `get_available_models`

### Test with a Simple Query

In Cursor's chat or composer, try:

```
@ai-orchestrator analyze_task("Create a Python function to parse JSON files")
```

You should receive a response showing:
- Detected task type (coding)
- Recommended model (Claude)
- Suggested subtasks

### Verify Model Availability

```
@ai-orchestrator check_status()
```

This shows which AI models are configured and available.

---

## Using the Orchestrator

### Available Tools

The AI Orchestrator provides 11 tools organized into three categories:

#### Task Orchestration Tools

##### 1. `orchestrate_task`
Fully process a task with automatic model routing and execution.

```
@ai-orchestrator orchestrate_task("Design and implement a REST API for a todo app")
```

##### 2. `analyze_task`
Analyze a task without executing it - see the routing plan.

```
@ai-orchestrator analyze_task("Review this code for security vulnerabilities")
```

##### 3. `route_to_model`
Route directly to a specific model.

```
@ai-orchestrator route_to_model("Explain how async/await works in Python", "gemini")
```

##### 4. `check_status`
Check which models are available.

```
@ai-orchestrator check_status()
```

##### 5. `get_available_models`
List all configured models and their specializations.

```
@ai-orchestrator get_available_models()
```

#### Execution & Testing Tools

##### 6. `run_project`
Execute a project with automatic type detection (Python, Node.js, React, etc.).

```
@ai-orchestrator run_project("/path/to/project")
```

**Parameters:**
- `project_path`: Path to the project directory
- `timeout` (optional): Max execution time in seconds (default: 300)

**Returns:**
- Execution status (success/error/timeout)
- Stdout and stderr output
- Detected project type
- Error analysis if failed

##### 7. `test_project`
Run tests with automatic framework detection (pytest, jest, mocha, etc.).

```
@ai-orchestrator test_project("/path/to/project")
```

**Parameters:**
- `project_path`: Path to the project directory
- `test_path` (optional): Specific test file/directory
- `pattern` (optional): Test name pattern to match

**Returns:**
- Test results (passed, failed, skipped counts)
- Individual test case details
- Failure messages and stack traces

##### 8. `analyze_errors`
Deep analysis of project errors with AI-powered root cause detection.

```
@ai-orchestrator analyze_errors("/path/to/project")
```

**Parameters:**
- `project_path`: Path to the project directory
- `error_log` (optional): Paste specific error text to analyze

**Returns:**
- Error categorization (syntax, runtime, dependency, etc.)
- Root cause analysis
- Suggested fixes with confidence scores
- File and line number identification

##### 9. `fix_issues`
Apply automated fixes to detected issues.

```
@ai-orchestrator fix_issues("/path/to/project")
```

**Parameters:**
- `project_path`: Path to the project directory
- `strategy` (optional): Specific fix strategy to use
- `dry_run` (optional): Preview fixes without applying

**Returns:**
- List of applied fixes
- Backup file locations
- Fix confidence scores
- Validation results

##### 10. `verify_project`
Run the complete verification loop: execute → test → analyze → fix → repeat.

```
@ai-orchestrator verify_project("/path/to/project")
```

**Parameters:**
- `project_path`: Path to the project directory
- `max_cycles` (optional): Maximum fix cycles (default: 10)
- `run_tests` (optional): Whether to run tests (default: true)

**Returns:**
- Final status (success/partial/failed)
- Number of cycles completed
- All fixes applied
- Progress report
- Recommendations if manual fix needed

##### 11. `orchestrate_full_development`
Complete development workflow from planning to review.

```
@ai-orchestrator orchestrate_full_development(
  "Build a REST API with user authentication",
  "/path/to/project"
)
```

**Parameters:**
- `description`: Project description/requirements
- `project_path`: Where to create the project

**Returns:**
- Architecture design
- Implementation code
- Execution results
- Test results
- Code review
- Final status

---

## Example Workflows

### Workflow 1: Building a New Feature

```
1. Start with architecture:
   @ai-orchestrator orchestrate_task("Design a user authentication system with JWT tokens")
   
   → ChatGPT designs the architecture
   → Claude implements the code
   → Kimi reviews the implementation

2. Ask for specific improvements:
   @ai-orchestrator route_to_model("Optimize this JWT verification function", "claude")
```

### Workflow 2: Debugging Complex Issues

```
1. Analyze the problem:
   @ai-orchestrator analyze_task("Debug why my async function is causing deadlocks")
   
2. Get reasoning help:
   @ai-orchestrator route_to_model("Explain the deadlock scenario step by step", "gemini")
   
3. Get the fix:
   @ai-orchestrator route_to_model("Fix this deadlock issue: [paste code]", "claude")
```

### Workflow 3: Code Review

```
@ai-orchestrator orchestrate_task("Review this PR for best practices, security, and performance: [paste code or describe changes]")

→ Routes to Kimi for comprehensive code review
→ Provides actionable feedback
```

### Workflow 4: Learning & Documentation

```
1. Understand a concept:
   @ai-orchestrator route_to_model("Explain microservices architecture patterns", "gemini")
   
2. Get implementation guidance:
   @ai-orchestrator route_to_model("Show me how to implement an API gateway in Python", "claude")
```

---

## Troubleshooting

### Common Issues

#### Issue: "MCP server not found" or "Connection failed"

**Solution:**
1. Verify the server path is correct in settings.json
2. Ensure Python is in your PATH:
   ```bash
   which python  # or `where python` on Windows
   ```
3. Test the server manually:
   ```bash
   cd /home/ubuntu/ai_orchestrator/mcp_server
   python server.py
   ```

#### Issue: "API key not found" errors

**Solution:**
1. Check your `.env` file exists and has the correct keys
2. Verify the path in settings.json points to the correct location
3. Try setting environment variables system-wide

#### Issue: "Module not found" errors

**Solution:**
1. Ensure PYTHONPATH is set correctly:
   ```bash
   export PYTHONPATH=/home/ubuntu/ai_orchestrator:$PYTHONPATH
   ```
2. Install dependencies:
   ```bash
   cd /home/ubuntu/ai_orchestrator
   pip install -e .
   cd mcp_server
   pip install -r requirements.txt
   ```

#### Issue: Server starts but tools don't appear

**Solution:**
1. Restart Cursor completely (not just reload)
2. Check Cursor's Output panel for MCP-related errors
3. Verify your Cursor version supports MCP (0.40.0+)

#### Issue: Responses are slow

**Solution:**
1. This is normal for complex tasks that route to multiple models
2. For simple queries, use `route_to_model` to target a specific model
3. Check your internet connection and API rate limits

### Debug Mode

To enable verbose logging, modify the server start:

```bash
DEBUG=1 python /home/ubuntu/ai_orchestrator/mcp_server/server.py
```

### Check Server Logs

Look in Cursor's Output panel (View → Output) and select "MCP" from the dropdown to see server logs.

---

## Execution Tool Troubleshooting

### Issue: `run_project` fails immediately

**Solutions:**
1. Check project has valid entry point:
   - Python: `main.py`, `app.py`, or `run.py`
   - Node.js: Check `package.json` for `main` or `scripts.start`
   
2. Verify dependencies are installed:
   ```
   @ai-orchestrator fix_issues("/path/to/project")
   ```

3. Check project type detection:
   ```
   @ai-orchestrator run_project("/path/to/project")
   # Look at "detected_type" in response
   ```

### Issue: `test_project` doesn't find tests

**Solutions:**
1. Verify test files exist with correct naming:
   - Python: `test_*.py` or `*_test.py`
   - JavaScript: `*.test.js` or `*.spec.js`

2. Check test framework config exists:
   - Python: `pytest.ini`, `setup.cfg`, or `pyproject.toml`
   - JavaScript: `jest.config.js` or in `package.json`

3. Run specific test file:
   ```
   @ai-orchestrator test_project("/path/to/project", test_path="tests/")
   ```

### Issue: `fix_issues` not applying fixes

**Solutions:**
1. Check confidence threshold - low confidence fixes aren't auto-applied
2. Run analysis first to understand errors:
   ```
   @ai-orchestrator analyze_errors("/path/to/project")
   ```
3. Try with explicit strategy:
   ```
   @ai-orchestrator fix_issues("/path/to/project", strategy="dependency")
   ```

### Issue: `verify_project` stuck in loop

**Solutions:**
1. Loop auto-terminates after 10 cycles by default
2. Same error 3+ times triggers stop
3. Check the report for "stuck" indicators
4. Manual intervention may be needed for:
   - Logic errors
   - Architecture issues
   - External service dependencies

### Issue: Backups not created

**Solutions:**
1. Check `.backups/` directory exists
2. Verify write permissions
3. Backups only created when fixes are applied
4. Manual backup before major changes:
   ```bash
   git commit -am "Before auto-fix"
   ```

---

## FAQ

### Q: Can I use this with other IDEs?
**A:** The MCP server works with any IDE that supports the Model Context Protocol. Check your IDE's documentation for MCP support.

### Q: How do I add my own AI models?
**A:** Create a new client in `ai_orchestrator/models/` following the `BaseModelClient` interface, then update the router and orchestrator.

### Q: What if I only have some API keys?
**A:** The orchestrator will use available models and skip unavailable ones. At minimum, you need OpenAI and Anthropic keys for basic functionality.

### Q: How are tokens/costs tracked?
**A:** Each response includes token usage information. Monitor your API dashboards for billing details.

### Q: Can I customize which model handles which tasks?
**A:** Yes! Edit `ai_orchestrator/router.py` to modify the task-to-model mappings.

---

## Next Steps

1. **Copy the .cursorrules file**: Use the provided template to enhance AI interactions
2. **Explore examples**: Check the `examples/` directory for common scenarios
3. **Customize**: Modify router rules to match your workflow
4. **Contribute**: Submit improvements via pull requests

---

## Support

- **Issues**: Report bugs via GitHub issues
- **Documentation**: See the main README.md for additional details
- **Model Configuration**: Check MODELS.md for available models and settings
