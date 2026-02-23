# AI Orchestrator MCP Server

This MCP (Model Context Protocol) server exposes the AI Orchestrator functionality, allowing integration with Cursor IDE and other MCP-compatible tools.

## Features

The MCP server provides the following tools:

| Tool | Description |
|------|-------------|
| `orchestrate_task` | Main tool to orchestrate a task across multiple AI models |
| `analyze_task` | Analyze how a task would be routed without executing |
| `check_status` | Check configuration and model availability |
| `route_to_model` | Route a specific task to a specific model |
| `get_available_models` | List all configured and available models |

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
- `ANTHROPIC_API_KEY` - For coding and debugging tasks  
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

#### Option C: Using a virtual environment

```json
{
  "mcpServers": {
    "ai-orchestrator": {
      "command": "/path/to/venv/bin/python",
      "args": ["/home/ubuntu/ai_orchestrator/mcp_server/server.py"]
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

## Example Usage

### In Cursor IDE

Once connected, you can use the orchestrator tools directly in Cursor:

```
@ai-orchestrator Please design a REST API architecture for a user management system
```

```
@ai-orchestrator Analyze how this task would be routed: "Build a Python function to parse CSV files with error handling"
```

```
@ai-orchestrator Check the status of the AI orchestrator
```

### Tool Examples

#### orchestrate_task
Execute a task with automatic model routing:
```json
{
  "task": "Design and implement a rate limiting middleware for Express.js"
}
```

#### analyze_task
Preview the routing plan without execution:
```json
{
  "task": "Create a caching strategy with Redis integration"
}
```

#### check_status
Check configuration (no parameters needed):
```json
{}
```

#### route_to_model
Send directly to a specific model:
```json
{
  "task": "Review this code for security vulnerabilities",
  "model": "anthropic"
}
```

#### get_available_models
List all models (no parameters needed):
```json
{}
```

## Response Format

All tools return JSON responses with relevant information:

### orchestrate_task Response
```json
{
  "success": true,
  "original_task": "...",
  "consolidated_output": "...",
  "subtask_results": [...],
  "errors": []
}
```

### analyze_task Response
```json
{
  "task": "...",
  "detected_task_types": ["coding", "architecture"],
  "routing_plan": [...],
  "models_to_be_used": ["anthropic", "openai"],
  "estimated_steps": 2
}
```

### check_status Response
```json
{
  "status": "operational",
  "available_models": ["openai", "anthropic", "gemini"],
  "model_configurations": {...},
  "total_available": 3
}
```

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
3. Add the handler to `call_tool()`

## License

This MCP server is part of the AI Orchestrator project.

## See Also

- [MCP Protocol Specification](https://modelcontextprotocol.io/)
- [AI Orchestrator Documentation](../README.md)
- [Cursor MCP Integration](https://docs.cursor.com/context/model-context-protocol)
