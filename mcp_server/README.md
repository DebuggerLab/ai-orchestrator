# AI Orchestrator MCP Server

This MCP (Model Context Protocol) server exposes the AI Orchestrator functionality, allowing integration with Cursor IDE and other MCP-compatible tools.

## Features

The MCP server provides **11 tools** organized into two categories:

### Task Orchestration Tools

| Tool | Description |
|------|-------------|
| `orchestrate_task` | Orchestrate a task across multiple AI models with automatic routing |
| `analyze_task` | Analyze how a task would be routed without executing |
| `check_status` | Check configuration and model availability |
| `route_to_model` | Route a specific task directly to a chosen model |
| `get_available_models` | List all configured and available models |

### Project Execution & Auto-Fix Tools

| Tool | Description |
|------|-------------|
| `run_project` | Execute a project with automatic type detection and dependency setup |
| `test_project` | Run tests with automatic framework detection |
| `analyze_errors` | Analyze errors from execution with AI-powered insights |
| `fix_issues` | Generate and optionally apply fixes for detected errors |
| `verify_project` | Run full verification loop: execute → test → fix → repeat |
| `orchestrate_full_development` | Complete development cycle from planning to working project |

## Installation

### Prerequisites

1. Python 3.10 or higher
2. The parent AI Orchestrator package installed
3. API keys configured in the `.env` file

### Install Dependencies

```bash
# Navigate to the mcp_server directory
cd /home/ubuntu/ai_orchestrator/mcp_server

# Install MCP server dependencies
pip install -r requirements.txt

# Make sure the parent package is installed
cd /home/ubuntu/ai_orchestrator
pip install -e .
```

## Configuration

### Environment Variables

The MCP server reads configuration from the AI Orchestrator's `.env` file located at `/home/ubuntu/ai_orchestrator/.env`.

Required API keys (at least one):
- `OPENAI_API_KEY` - For architecture and roadmap tasks
- `ANTHROPIC_API_KEY` - For coding, debugging, and fix generation
- `GEMINI_API_KEY` - For reasoning and logic tasks
- `MOONSHOT_API_KEY` - For code review tasks

Optional model configuration:
- `OPENAI_MODEL` - Default: `gpt-4o-mini`
- `ANTHROPIC_MODEL` - Default: `claude-3-5-sonnet-20241022`
- `GEMINI_MODEL` - Default: `gemini-2.5-flash`
- `MOONSHOT_MODEL` - Default: `moonshot-v1-8k`

### Example .env file

```bash
# API Keys
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GEMINI_API_KEY=AI...
MOONSHOT_API_KEY=sk-...

# Optional: Custom model names
OPENAI_MODEL=gpt-4o
ANTHROPIC_MODEL=claude-3-5-sonnet-20241022
GEMINI_MODEL=gemini-2.5-flash

# Auto-fix settings (optional)
MAX_VERIFICATION_CYCLES=10
FIX_CONFIDENCE_THRESHOLD=0.7
```

## Running the MCP Server

### Direct Execution

```bash
# Using the startup script
./start.sh

# Or directly with Python
python server.py
```

### As a Background Service

```bash
# Start in background
nohup python server.py > mcp_server.log 2>&1 &
```

## Connecting to Cursor IDE

### Step 1: Locate Cursor Settings

Open Cursor IDE and access settings:
- **macOS**: `Cmd + ,` or `Cursor > Settings > Cursor Settings`
- **Windows/Linux**: `Ctrl + ,` or `File > Preferences > Cursor Settings`

### Step 2: Configure MCP Server

In Cursor, navigate to `Features > MCP Servers` and add a new server configuration:

#### Option A: Using the startup script (Recommended)

```json
{
  "mcpServers": {
    "ai-orchestrator": {
      "command": "/home/ubuntu/ai_orchestrator/mcp_server/start.sh",
      "args": []
    }
  }
}
```

#### Option B: Direct Python execution

```json
{
  "mcpServers": {
    "ai-orchestrator": {
      "command": "python",
      "args": ["/home/ubuntu/ai_orchestrator/mcp_server/server.py"],
      "env": {
        "PYTHONPATH": "/home/ubuntu/ai_orchestrator"
      }
    }
  }
}
```

### Step 3: Verify Connection

After adding the configuration:
1. Restart Cursor IDE
2. Open a new chat/composer window
3. The AI Orchestrator tools should appear in the tools list
4. You can verify by asking Cursor to "check the status of the AI orchestrator"

---

## Tool Reference

### Task Orchestration Tools

#### orchestrate_task

Execute a task with automatic model routing based on task type analysis.

**Input:**
```json
{
  "task": "Design and implement a rate limiting middleware for Express.js"
}
```

**Output:**
```json
{
  "success": true,
  "original_task": "...",
  "consolidated_output": "...",
  "subtask_results": [
    {
      "subtask": { "task_type": "architecture", "target_model": "openai" },
      "response": { "success": true, "content": "..." }
    }
  ],
  "errors": []
}
```

#### analyze_task

Preview the routing plan without execution.

**Input:**
```json
{
  "task": "Create a caching strategy with Redis integration"
}
```

**Output:**
```json
{
  "task": "...",
  "detected_task_types": ["architecture", "coding"],
  "routing_plan": [...],
  "models_to_be_used": ["openai", "anthropic"],
  "estimated_steps": 2
}
```

#### check_status

Check configuration (no parameters needed).

**Output:**
```json
{
  "status": "operational",
  "available_models": ["openai", "anthropic", "gemini"],
  "model_configurations": {...},
  "execution_config": {
    "max_verification_cycles": 10,
    "fix_confidence_threshold": 0.7
  },
  "total_available": 3
}
```

#### route_to_model

Send directly to a specific model.

**Input:**
```json
{
  "task": "Review this code for security vulnerabilities",
  "model": "anthropic"
}
```

**Output:**
```json
{
  "success": true,
  "model_name": "claude-3-5-sonnet-20241022",
  "model_provider": "anthropic",
  "content": "..."
}
```

#### get_available_models

List all models with specializations.

**Output:**
```json
{
  "models": [
    {
      "provider": "openai",
      "model": "gpt-4o-mini",
      "specializations": ["architecture", "roadmap"],
      "available": true
    },
    ...
  ],
  "available_count": 3,
  "total_count": 4
}
```

---

### Project Execution Tools

#### run_project

Execute a project with automatic detection and setup.

**Input:**
```json
{
  "project_path": "/path/to/project",
  "setup_dependencies": true,
  "command": null,
  "timeout": 300
}
```

**Parameters:**
- `project_path` (required): Absolute path to the project directory
- `setup_dependencies` (optional, default: true): Install dependencies first
- `command` (optional): Custom run command (auto-detected if not provided)
- `timeout` (optional, default: 300): Execution timeout in seconds

**Output:**
```json
{
  "tool": "run_project",
  "status": "success",
  "project_type": "nodejs",
  "exit_code": 0,
  "duration_seconds": 2.5,
  "stdout": "Server started on port 3000",
  "stderr": "",
  "errors_detected": [],
  "config": {
    "entry_point": "index.js",
    "run_command": "node index.js",
    "framework": "express"
  }
}
```

**Supported Project Types:**
- Python (requirements.txt, setup.py)
- Node.js (package.json)
- React (package.json with react)
- Next.js (package.json with next)
- Flask (Flask in requirements)
- Django (manage.py)

---

#### test_project

Run tests with automatic framework detection.

**Input:**
```json
{
  "project_path": "/path/to/project",
  "test_command": null,
  "timeout": 180
}
```

**Parameters:**
- `project_path` (required): Absolute path to the project directory
- `test_command` (optional): Custom test command (auto-detected if not provided)
- `timeout` (optional, default: 180): Test timeout in seconds

**Output:**
```json
{
  "tool": "test_project",
  "project_path": "/path/to/project",
  "framework": "pytest",
  "status": "passed",
  "total_tests": 25,
  "passed": 23,
  "failed": 2,
  "skipped": 0,
  "duration_seconds": 5.3,
  "pass_rate": 92.0,
  "failed_tests": [
    "test_auth.py::test_login_invalid_credentials",
    "test_api.py::test_rate_limit"
  ]
}
```

**Supported Test Frameworks:**
- pytest (Python)
- jest (JavaScript/TypeScript)
- mocha (JavaScript)
- vitest (JavaScript/TypeScript)
- Django test runner

---

#### analyze_errors

Analyze errors with AI-powered insights.

**Input:**
```json
{
  "project_path": "/path/to/project",
  "error_logs": "TypeError: Cannot read property 'map' of undefined\n  at Component.render...",
  "use_ai": true
}
```

**Parameters:**
- `project_path` (required): Absolute path to the project directory
- `error_logs` (optional): Error logs to analyze (runs project if not provided)
- `use_ai` (optional, default: true): Use AI for deeper analysis

**Output:**
```json
{
  "tool": "analyze_errors",
  "project_path": "/path/to/project",
  "errors_detected": 3,
  "errors": [
    {
      "category": "runtime",
      "message": "TypeError: Cannot read property 'map' of undefined",
      "file": "src/components/List.js",
      "line": 15,
      "severity": "error",
      "suggested_fixes": ["Check if array is defined before mapping"]
    }
  ],
  "categories": {
    "runtime": 2,
    "syntax": 1
  },
  "ai_analysis": [
    {
      "error": {...},
      "root_cause": "The 'items' prop is undefined when component renders",
      "fix_suggestions": [
        "Add null check: items?.map(...)",
        "Set default prop value",
        "Add loading state"
      ],
      "affected_files": ["src/components/List.js", "src/App.js"],
      "confidence": 0.85,
      "requires_ai": true,
      "recommended_model": "anthropic"
    }
  ]
}
```

**Error Categories:**
- syntax, runtime, import, dependency
- type_error, reference_error, assertion
- configuration, permission, network
- build, timeout, unknown

---

#### fix_issues

Generate and apply fixes for errors.

**Input:**
```json
{
  "project_path": "/path/to/project",
  "errors": ["TypeError: Cannot read property 'map' of undefined"],
  "auto_apply": false,
  "max_attempts": 3
}
```

**Parameters:**
- `project_path` (required): Absolute path to the project directory
- `errors` (optional): List of error messages (detects if not provided)
- `auto_apply` (optional, default: false): Automatically apply fixes
- `max_attempts` (optional, default: 3): Max fix attempts per error

**Output (auto_apply: false):**
```json
{
  "tool": "fix_issues",
  "project_path": "/path/to/project",
  "errors_found": 2,
  "fixes_generated": 2,
  "fixes_applied": 0,
  "auto_apply_enabled": false,
  "generated_fixes": [
    {
      "error_message": "Cannot read property 'map' of undefined",
      "fix_type": "code_change",
      "description": "Add optional chaining to prevent undefined access",
      "confidence": 0.82,
      "model_used": "anthropic",
      "validation_passed": true,
      "files_to_modify": ["src/components/List.js"],
      "commands_to_run": []
    }
  ],
  "recommendation": "Review generated fixes and apply manually"
}
```

**Output (auto_apply: true):**
```json
{
  "tool": "fix_issues",
  "project_path": "/path/to/project",
  "errors_found": 2,
  "fixes_generated": 2,
  "fixes_applied": 2,
  "auto_apply_enabled": true,
  "generated_fixes": [...],
  "applied_fixes": [
    {
      "timestamp": "2026-02-23T10:30:00",
      "error_message": "...",
      "fix": {...},
      "result": { "success": true, "message": "Fix applied successfully" },
      "backup_path": "/path/to/project/.auto_fixer_backups/..."
    }
  ],
  "recommendation": "Fixes have been applied - run project to verify"
}
```

---

#### verify_project

Full verification loop until success.

**Input:**
```json
{
  "project_path": "/path/to/project",
  "max_cycles": 10,
  "run_tests": true,
  "auto_fix": true,
  "setup_first": true
}
```

**Parameters:**
- `project_path` (required): Absolute path to the project directory
- `max_cycles` (optional, default: 10): Maximum fix cycles
- `run_tests` (optional, default: true): Run tests in each cycle
- `auto_fix` (optional, default: true): Attempt automatic fixes
- `setup_first` (optional, default: true): Setup dependencies on first run

**Output:**
```json
{
  "tool": "verify_project",
  "project_path": "/path/to/project",
  "status": "success",
  "total_duration_seconds": 45.2,
  "progress": {
    "total_cycles": 3,
    "total_errors_found": 5,
    "total_errors_fixed": 5,
    "unique_errors_seen": 4,
    "repeated_errors": 1,
    "trend": "improving",
    "error_count_history": [5, 2, 0],
    "fix_success_rate": 100.0
  },
  "cycles": [
    {
      "cycle_number": 1,
      "status": "errors_found",
      "errors_found": 5,
      "fixes_attempted": 5,
      "fixes_successful": 3,
      "fixes_failed": 2
    },
    ...
  ],
  "final_execution": {
    "status": "success",
    "exit_code": 0
  },
  "final_tests": {
    "status": "passed",
    "total_tests": 25,
    "passed": 25
  },
  "summary": "Project verified successfully after 3 cycles",
  "recommendations": []
}
```

**Possible Statuses:**
- `success`: Project runs and tests pass
- `failed`: Errors remain after all attempts
- `max_retries_reached`: Hit max_cycles limit
- `stuck_in_loop`: Same errors repeating
- `needs_human_help`: Requires manual intervention

---

#### orchestrate_full_development

Complete development workflow from planning to working project.

**Input:**
```json
{
  "project_path": "/path/to/new-project",
  "project_description": "Build a REST API for user management with authentication",
  "requirements": [
    "JWT-based authentication",
    "CRUD operations for users",
    "Input validation",
    "Error handling"
  ],
  "run_project": true,
  "run_tests": true,
  "auto_fix": true
}
```

**Parameters:**
- `project_path` (required): Absolute path to project directory (created if needed)
- `project_description` (required): Description of what to build
- `requirements` (optional): List of specific requirements
- `run_project` (optional, default: true): Run project after implementation
- `run_tests` (optional, default: true): Run tests
- `auto_fix` (optional, default: true): Auto-fix any errors

**Output:**
```json
{
  "tool": "orchestrate_full_development",
  "project_path": "/path/to/new-project",
  "success": true,
  "status": "completed",
  "total_duration_seconds": 120.5,
  "phases": [
    {
      "name": "Architecture Planning",
      "model_provider": "openai",
      "task_type": "architecture",
      "success": true,
      "duration_seconds": 15.2,
      "response_preview": "## Architecture Design\n\n### API Structure..."
    },
    {
      "name": "Implementation",
      "model_provider": "anthropic",
      "task_type": "coding",
      "success": true,
      "duration_seconds": 45.3
    },
    {
      "name": "Project Execution",
      "model_provider": "execution",
      "success": true
    },
    {
      "name": "Test Design",
      "model_provider": "gemini",
      "task_type": "testing",
      "success": true
    },
    {
      "name": "Code Review",
      "model_provider": "moonshot",
      "task_type": "code_review",
      "success": true
    }
  ],
  "execution_result": {
    "status": "success",
    "project_type": "nodejs"
  },
  "verification_report": {...},
  "test_result": {
    "status": "passed",
    "total_tests": 15,
    "passed": 15
  },
  "final_review": {
    "model": "moonshot-v1-8k",
    "content": "Code review summary..."
  },
  "errors": [],
  "summary": "Project successfully developed and verified"
}
```

**Development Phases:**
1. **Architecture Planning** (ChatGPT/OpenAI) - Design system structure
2. **Implementation** (Claude/Anthropic) - Write the code
3. **Project Execution** - Run and verify the project works
4. **Error Verification & Fixing** - Auto-fix any issues (if needed)
5. **Test Design** (Gemini) - Generate comprehensive tests
6. **Code Review** (Kimi/Moonshot) - Final quality review

---

## Workflow Examples

### Example 1: Debug and Fix a Failing Project

```
Step 1: Check what's wrong
→ Use analyze_errors on the project

Step 2: Generate fixes
→ Use fix_issues with auto_apply: false to review

Step 3: Apply fixes
→ Use fix_issues with auto_apply: true

Step 4: Verify everything works
→ Use verify_project
```

### Example 2: Complete Auto-Fix Workflow

```
Single step:
→ Use verify_project with auto_fix: true

This will:
1. Run the project
2. Detect all errors
3. Generate and apply fixes
4. Repeat until success or max_cycles
5. Run tests to confirm
```

### Example 3: New Feature Development

```
Step 1: Plan and implement
→ Use orchestrate_full_development with description

Step 2: Check test results
→ Review the test_result in the response

Step 3: Fix remaining issues (if any)
→ Use verify_project if needed
```

### Example 4: Test-Driven Development

```
Step 1: Run existing tests
→ Use test_project to see what fails

Step 2: Analyze failures
→ Use analyze_errors with use_ai: true

Step 3: Fix test failures
→ Use fix_issues targeting specific errors

Step 4: Verify all tests pass
→ Use test_project again
```

---

## Troubleshooting

### Server Not Starting

1. Check Python version: `python --version` (must be 3.10+)
2. Verify dependencies: `pip install -r requirements.txt`
3. Check if parent package is installed: `pip install -e /home/ubuntu/ai_orchestrator`

### Connection Issues in Cursor

1. Verify the server path is correct
2. Check that the startup script has execute permissions: `chmod +x start.sh`
3. Test the server manually: `python server.py`
4. Check Cursor logs for MCP-related errors

### No Models Available

1. Verify API keys are set in `.env` file
2. Run `check_status` to see which models are configured
3. Ensure the `.env` file path is correct

### API Errors

1. Check API key validity
2. Verify model names are correct
3. Check API quotas and rate limits

### Project Execution Issues

| Issue | Solution |
|-------|----------|
| "Project path does not exist" | Verify the absolute path is correct |
| "No entry point found" | Specify custom `command` parameter |
| Timeout errors | Increase `timeout` parameter |
| Dependency installation fails | Run `setup_dependencies: false` and install manually |
| Tests not found | Specify `test_command` manually |

### Auto-Fix Issues

| Issue | Solution |
|-------|----------|
| Fixes not applied | Check `confidence` is above threshold (0.7) |
| Same error repeating | Loop may be stuck; reduce `max_cycles` or check manually |
| Backup restore needed | Look in `.auto_fixer_backups` directory |
| AI analysis unavailable | Check Anthropic API key for fix generation |

---

## Development

### Testing the Server

```bash
# Run the server
python server.py

# In another terminal, test with MCP inspector
npx @modelcontextprotocol/inspector python server.py
```

### Adding New Tools

To add new tools, modify `server.py`:

1. Add the tool definition in `list_tools()`
2. Add a handler function `handle_<tool_name>()`
3. Add the handler to `call_tool()` switch
4. Add helper functions for formatting results

### Project Structure

```
mcp_server/
├── server.py          # Main MCP server with all tools
├── requirements.txt   # Dependencies
├── start.sh          # Startup script
├── __init__.py       # Package init
└── README.md         # This documentation
```

---

## License

This MCP server is part of the AI Orchestrator project.

## See Also

- [MCP Protocol Specification](https://modelcontextprotocol.io/)
- [AI Orchestrator Documentation](../README.md)
- [Cursor MCP Integration](https://docs.cursor.com/context/model-context-protocol)
- [Cursor Integration Guide](../cursor_integration/CURSOR_SETUP.md)
