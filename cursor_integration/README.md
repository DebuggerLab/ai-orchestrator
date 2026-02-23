# Cursor IDE Integration

This directory contains everything you need to integrate the AI Orchestrator with Cursor IDE using the Model Context Protocol (MCP).

## 📁 Contents

```
cursor_integration/
├── README.md              # This file
├── CURSOR_SETUP.md        # Comprehensive setup guide
├── .cursorrules           # Template for Cursor rules
├── cursor-settings.json   # MCP server configuration template
└── examples/
    ├── 01_rest_api.md         # REST API development workflow
    ├── 02_fullstack_webapp.md # Full-stack application workflow
    └── 03_code_review.md      # Code review and refactoring workflow
```

## 🚀 Quick Start

### 1. Install Dependencies

```bash
cd /home/ubuntu/ai_orchestrator
pip install -e .
cd mcp_server
pip install -r requirements.txt
```

### 2. Configure API Keys

```bash
cd /home/ubuntu/ai_orchestrator
cp .env.example .env
# Edit .env with your API keys
```

### 3. Add MCP Server to Cursor

Open Cursor settings (`Cmd+,` or `Ctrl+,`), search for "MCP", and add:

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

### 4. Restart Cursor and Start Using

```
@ai-orchestrator orchestrate_task("Build a REST API for todos")
```

## 📚 Documentation

| Document | Description |
|----------|-------------|
| [CURSOR_SETUP.md](./CURSOR_SETUP.md) | Complete setup guide with troubleshooting |
| [.cursorrules](./.cursorrules) | Rules for AI model selection in projects |
| [cursor-settings.json](./cursor-settings.json) | Settings template with examples |

## 📖 Examples

| Example | Description |
|---------|-------------|
| [01_rest_api.md](./examples/01_rest_api.md) | Building a REST API with task breakdown and model routing |
| [02_fullstack_webapp.md](./examples/02_fullstack_webapp.md) | Complex full-stack orchestration with React + FastAPI |
| [03_code_review.md](./examples/03_code_review.md) | Security review and refactoring workflow |

## 🔧 Using the .cursorrules File

Copy `.cursorrules` to your project root to help Cursor understand how to use the AI Orchestrator:

```bash
cp /home/ubuntu/ai_orchestrator/cursor_integration/.cursorrules /path/to/your/project/
```

This file instructs Cursor on:
- When to use each AI model
- How to break down complex projects
- Best practices for multi-model orchestration

## 🆘 Troubleshooting

See the [Troubleshooting section in CURSOR_SETUP.md](./CURSOR_SETUP.md#troubleshooting) for common issues and solutions.

## 📖 More Information

- Main project documentation: [../README.md](../README.md)
- MCP server documentation: [../mcp_server/README.md](../mcp_server/README.md)
- Model configuration: [../MODELS.md](../MODELS.md)
