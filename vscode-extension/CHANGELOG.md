# Changelog

All notable changes to the **AI Orchestrator** extension will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-02-26

### 🔀 Repository Integration
- Integrated VS Code extension into main AI Orchestrator repository
- Extension now lives in `vscode-extension/` directory on `vscode-extension` branch
- Updated repository URLs to point to `DebuggerLab/ai-orchestrator`

### 🔄 Model Updates
- **Anthropic**: Fixed default model to `claude-3-5-sonnet-20240620` (correct version)
- Added new Claude models: `claude-sonnet-4-6`, `claude-opus-4-6`
- Removed deprecated model: `claude-3-sonnet-20240229`

### 📚 Documentation
- Added comprehensive extension README
- Updated integration with main project documentation

---

## [1.1.0] - 2026-02-24

### 🔄 Updated

#### Organization Migration
- Migrated repository to DebuggerLab organization
- Updated all repository URLs to use `DebuggerLab/ai-orchestrator-vscode`

#### Model Updates
- **OpenAI**: Updated default model to `gpt-4o-mini` (faster and more cost-effective)
- **Anthropic**: Updated default model to `claude-3-5-sonnet-20241022`
- **Gemini**: Updated default model to `gemini-2.5-flash` (latest flash model)
- Added new model options: `gpt-4o`, `gemini-2.5-pro`, `gemini-1.5-flash`

#### Dependencies
- Updated `@google/generative-ai` to `^0.21.0` for latest API compatibility

### 🔗 Synced with AI Orchestrator Core
- Aligned model configurations with main AI Orchestrator project
- Improved consistency with backend model handling

---

## [1.0.0] - 2026-02-18

### 🎉 Initial Release

We're excited to announce the first public release of AI Orchestrator!

### ✨ Added

#### Core Features
- **Multi-Model Orchestration**: Support for OpenAI (GPT-4), Anthropic (Claude 3), Google (Gemini), and Moonshot (Kimi)
- **Intelligent Task Routing**: Automatic task detection and routing to specialized models
- **Parallel Execution**: Run multiple models simultaneously for complex tasks
- **Result Consolidation**: Unified output from multiple AI responses

#### User Interface
- **Sidebar Chat Panel**: Modern chat-like interface with real-time progress
- **Task History View**: Browse, re-run, and export past orchestrations
- **Status Bar Integration**: Quick access to orchestrator status
- **Syntax Highlighting**: Beautiful code formatting using highlight.js

#### Commands
- `AI Orchestrator: Run Task` - Submit a new task
- `AI Orchestrator: Configure` - Set up API keys
- `AI Orchestrator: Check Status` - View model status and statistics
- `AI Orchestrator: Clear History` - Clear task history
- `Send to AI Orchestrator` - Process selected code (context menu)

#### Configuration
- Model selection for each provider
- Task routing preferences
- UI customization options
- History management settings

#### Security
- Secure API key storage using VS Code Secrets API
- Direct API calls (no intermediary servers)
- Content Security Policy for webviews

### 🔧 Technical

- TypeScript implementation with full type safety
- Webview-based UI with modern CSS
- Support for VS Code 1.85.0+
- Compatible with Windows, macOS, and Linux

---

## [Unreleased]

### Planned Features
- [ ] Custom model endpoint support
- [ ] Conversation history within sessions
- [ ] Code insertion directly into editor
- [ ] Workspace-aware context
- [ ] Custom prompt templates

---

**Full Changelog**: https://github.com/DebuggerLab/ai-orchestrator-vscode/commits/v1.0.0
