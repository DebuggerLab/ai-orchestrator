# AI Orchestrator - VS Code Extension

<p align="center">
  <img src="media/icon.png" alt="AI Orchestrator Logo" width="128" height="128">
</p>

<p align="center">
  <strong>Intelligently orchestrate multiple AI models for complex development tasks</strong>
</p>

<p align="center">
  <a href="https://marketplace.visualstudio.com/items?itemName=debugger-lab.ai-orchestrator">
    <img src="https://img.shields.io/visual-studio-marketplace/v/debugger-lab.ai-orchestrator" alt="VS Marketplace Version">
  </a>
  <a href="https://marketplace.visualstudio.com/items?itemName=debugger-lab.ai-orchestrator">
    <img src="https://img.shields.io/visual-studio-marketplace/i/debugger-lab.ai-orchestrator" alt="Installs">
  </a>
  <a href="https://marketplace.visualstudio.com/items?itemName=debugger-lab.ai-orchestrator">
    <img src="https://img.shields.io/visual-studio-marketplace/r/debugger-lab.ai-orchestrator" alt="Rating">
  </a>
  <a href="https://github.com/DebuggerLab/ai-orchestrator/blob/vscode-extension/LICENSE">
    <img src="https://img.shields.io/github/license/DebuggerLab/ai-orchestrator" alt="License">
  </a>
</p>

---

## 🌟 Overview

**AI Orchestrator** is a powerful VS Code extension that intelligently routes your development tasks to the most suitable AI models. Instead of switching between ChatGPT, Claude, Gemini, and other AI assistants, let the orchestrator automatically select and combine the best models for each task.

### Key Features

- 🧠 **Multi-Model Support**: OpenAI (GPT-4o), Anthropic (Claude 3.5), Google (Gemini), Moonshot (Kimi)
- 🎯 **Intelligent Routing**: Automatically routes tasks to specialized models
- ⚡ **Parallel Execution**: Run multiple models simultaneously for complex tasks
- 📊 **Unified Results**: Consolidated output from multiple AI responses
- 📜 **Task History**: Browse, re-run, and export past orchestrations
- 🎨 **Modern UI**: Beautiful chat interface with syntax highlighting

---

## 🚀 Quick Start

### Installation

1. Open VS Code
2. Press `Ctrl+Shift+X` (Windows/Linux) or `Cmd+Shift+X` (macOS)
3. Search for "AI Orchestrator"
4. Click Install

Or install directly from the [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=debugger-lab.ai-orchestrator).

### Configuration

1. Open VS Code Settings (`Ctrl+,` or `Cmd+,`)
2. Search for "AI Orchestrator"
3. Add your API keys:
   - `aiOrchestrator.openai.apiKey` - Your OpenAI API key
   - `aiOrchestrator.anthropic.apiKey` - Your Anthropic API key
   - `aiOrchestrator.gemini.apiKey` - Your Google AI API key
   - `aiOrchestrator.moonshot.apiKey` - Your Moonshot API key

You only need to configure the models you want to use.

---

## 🎯 Model Specialization

Each AI model excels at different tasks:

| Model | Provider | Specialization | Default For |
|-------|----------|----------------|-------------|
| `gpt-4o-mini` | OpenAI | Architecture, Planning | Architecture tasks |
| `claude-3-5-sonnet-20240620` | Anthropic | Coding, Implementation | Coding tasks |
| `gemini-2.5-flash` | Google | Reasoning, Analysis | Reasoning tasks |
| `moonshot-v1-8k` | Moonshot | Code Review | Review tasks |

### Task Routing Examples

| Task Type | Routed To | Why |
|-----------|-----------|-----|
| "Design a REST API" | OpenAI | Architecture planning |
| "Implement authentication" | Claude | Code implementation |
| "Explain why this fails" | Gemini | Logical reasoning |
| "Review this function" | Kimi | Code review |

---

## 📖 Usage

### Running a Task

1. Click the AI Orchestrator icon in the Activity Bar
2. Type your task in the chat input
3. Press Enter or click Send
4. Watch as the orchestrator routes and processes your task

### Context Menu

Select code in the editor, right-click, and choose "Send to AI Orchestrator" to:
- Get explanations for selected code
- Request improvements or refactoring
- Ask for bug fixes or optimizations

### Commands

| Command | Description |
|---------|-------------|
| `AI Orchestrator: Run Task` | Open task input dialog |
| `AI Orchestrator: Configure` | Open settings |
| `AI Orchestrator: Check Status` | View model connection status |
| `AI Orchestrator: Clear History` | Clear task history |

---

## ⚙️ Configuration Options

### Model Selection

```json
{
  "aiOrchestrator.openai.model": "gpt-4o-mini",
  "aiOrchestrator.anthropic.model": "claude-3-5-sonnet-20240620",
  "aiOrchestrator.gemini.model": "gemini-2.5-flash",
  "aiOrchestrator.moonshot.model": "moonshot-v1-8k"
}
```

### Routing Preferences

Override default model routing:

```json
{
  "aiOrchestrator.routing.preferredArchitectureModel": "openai",
  "aiOrchestrator.routing.preferredCodingModel": "anthropic",
  "aiOrchestrator.routing.preferredReasoningModel": "gemini",
  "aiOrchestrator.routing.preferredReviewModel": "moonshot"
}
```

### UI Settings

```json
{
  "aiOrchestrator.ui.showDetailedProgress": true,
  "aiOrchestrator.history.maxItems": 50
}
```

---

## 🔗 Integration with AI Orchestrator Core

This VS Code extension is part of the **AI Orchestrator** ecosystem. It shares the same intelligent routing logic and model configurations as the core Python library.

### Related Projects

- **[AI Orchestrator Core](https://github.com/DebuggerLab/ai-orchestrator)** - Python library and CLI
- **[MCP Server](https://github.com/DebuggerLab/ai-orchestrator/tree/main/mcp_server)** - Model Context Protocol server
- **[Cursor Integration](https://github.com/DebuggerLab/ai-orchestrator/tree/main/cursor_integration)** - Cursor IDE integration
- **[macOS App](https://github.com/DebuggerLab/ai-orchestrator/tree/main/macos_app)** - Native macOS application

---

## 🏗️ Building from Source

### Prerequisites

- Node.js 18+
- npm 9+
- VS Code 1.85+

### Build Steps

```bash
# Clone the repository
git clone https://github.com/DebuggerLab/ai-orchestrator.git
cd ai-orchestrator

# Switch to vscode-extension branch
git checkout vscode-extension

# Navigate to extension directory
cd vscode-extension

# Install dependencies
npm install

# Compile TypeScript
npm run compile

# Package extension
npm run package
```

### Development

```bash
# Watch for changes
npm run watch

# Run tests
npm test

# Lint code
npm run lint
```

---

## 📋 Available Models

### OpenAI Models
- `gpt-4o-mini` (default) - Fast and cost-effective
- `gpt-4o` - Most capable GPT-4 model
- `gpt-4-turbo` - High performance
- `gpt-4` - Original GPT-4
- `gpt-3.5-turbo` - Fast and economical

### Anthropic Models
- `claude-3-5-sonnet-20240620` (default) - Best for coding
- `claude-sonnet-4-6` - Latest Sonnet
- `claude-opus-4-6` - Most capable Claude
- `claude-3-opus-20240229` - Previous flagship
- `claude-3-haiku-20240307` - Fast and efficient

### Google Gemini Models
- `gemini-2.5-flash` (default) - Fast reasoning
- `gemini-2.5-pro` - Advanced capabilities
- `gemini-1.5-pro` - Strong reasoning
- `gemini-1.5-flash` - Quick responses

### Moonshot Models
- `moonshot-v1-8k` (default) - Standard context
- `moonshot-v1-32k` - Extended context
- `moonshot-v1-128k` - Maximum context

---

## 🔒 Security

- API keys are stored securely in VS Code's secrets storage
- Keys are never sent to any server other than the respective AI providers
- All communications use HTTPS

---

## 🐛 Troubleshooting

### Common Issues

**Extension not activating:**
- Ensure VS Code version is 1.85 or higher
- Check the Output panel for errors

**API errors:**
- Verify your API keys are correct
- Check your API quota and billing status
- Ensure network connectivity

**Models not responding:**
- Some models may have rate limits
- Try using alternative models from settings

### Getting Help

- [Report Issues](https://github.com/DebuggerLab/ai-orchestrator/issues)
- [Discussions](https://github.com/DebuggerLab/ai-orchestrator/discussions)
- Email: support@debuggerlab.com

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- OpenAI for GPT models
- Anthropic for Claude models
- Google for Gemini models
- Moonshot for Kimi models
- The VS Code team for the excellent extension API

---

<p align="center">
  Made with ❤️ by <a href="https://debuggerlab.com">Debugger Lab</a>
</p>
