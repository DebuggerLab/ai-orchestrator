# 🤖 AI Orchestrator

A powerful Python CLI tool that intelligently orchestrates multiple AI models for automatic task distribution. Route your tasks to the most suitable AI model based on task type.

## 🎯 Features

- **Multi-Model Integration**: Seamlessly connects to OpenAI, Anthropic, Google Gemini, and Moonshot AI
- **Intelligent Task Routing**: Automatically determines the best model for each task type
- **Task Decomposition**: Breaks complex tasks into subtasks and routes each optimally
- **Beautiful CLI Output**: Rich formatting with progress indicators and colored output
- **Error Handling**: Graceful fallback when models are unavailable
- **Cursor IDE Ready**: Designed to work perfectly from Cursor's integrated terminal

## 🏗️ Model Specializations

| Model | Provider | Specialization |
|-------|----------|----------------|
| **ChatGPT** | OpenAI | Architecture, Roadmap, System Design |
| **Claude** | Anthropic | Coding, Implementation, Debugging |
| **Gemini** | Google | Reasoning, Logic, Analysis |
| **Kimi** | Moonshot AI | Code Review, Quality Assurance |

## 📦 Installation

### Quick Install

```bash
cd ai_orchestrator
pip install -e .
```

### Manual Install

```bash
pip install -r requirements.txt
```

## ⚙️ Configuration

### 1. Create Configuration File

```bash
# Option A: Use the init command
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

**Note**: You don't need all API keys - the tool works with any combination of available models.

## 🚀 Usage

### Basic Usage

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

## 🖥️ Cursor IDE Integration

### Setting Up in Cursor

1. **Open Terminal**: Press `` Ctrl+` `` in Cursor to open the integrated terminal

2. **Navigate to Project**: 
   ```bash
   cd /path/to/your/project
   ```

3. **Initialize Configuration**:
   ```bash
   ai-orchestrator init
   # Edit .env with your API keys
   ```

4. **Use AI Orchestrator**:
   ```bash
   ai-orchestrator run "Your task here"
   ```

### Cursor Workflow Examples

#### Example 1: Feature Development
```bash
# Step 1: Get architecture guidance
ai-orchestrator run "Design the architecture for user authentication with OAuth2"

# Step 2: Get implementation
ai-orchestrator run "Implement OAuth2 authentication handler in Python" -o auth.py

# Step 3: Review the code
ai-orchestrator run "Review this OAuth implementation for security issues"
```

#### Example 2: Bug Investigation
```bash
# Analyze and debug
ai-orchestrator run "Debug: API returns 500 error when user data contains unicode"
```

#### Example 3: Complex Task
```bash
# AI Orchestrator automatically breaks this into subtasks
ai-orchestrator run "Design and implement a caching layer for our API with Redis, including architecture decisions and code review"
```

### Creating a Cursor Task

Add to `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "AI Orchestrator",
      "type": "shell",
      "command": "ai-orchestrator run \"${input:taskDescription}\"",
      "problemMatcher": [],
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    }
  ],
  "inputs": [
    {
      "id": "taskDescription",
      "type": "promptString",
      "description": "Enter your task description"
    }
  ]
}
```

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

## 🔧 Advanced Configuration

### Custom Model Selection

```env
# Override default model names
OPENAI_MODEL=gpt-4o
ANTHROPIC_MODEL=claude-3-opus-20240229
GEMINI_MODEL=gemini-1.5-pro
MOONSHOT_MODEL=moonshot-v1-32k
```

> 📖 See [MODELS.md](MODELS.md) for a complete list of available models, pricing, and access requirements.

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

## ❓ Troubleshooting

### Model Access Errors (404 Not Found)

If you see errors like `404: Model 'gpt-4' not found` or `404: Model 'gemini-pro' not found`, this means the model names are outdated.

**Solution:**

1. Update to the latest version of AI Orchestrator
2. Or manually update your `.env` file with current model names:

```env
# Use these current model names
OPENAI_MODEL=gpt-4o-mini
ANTHROPIC_MODEL=claude-3-5-sonnet-20241022
GEMINI_MODEL=gemini-1.5-flash
MOONSHOT_MODEL=moonshot-v1-8k
```

### Common Model Errors

| Error | Provider | Solution |
|-------|----------|----------|
| `404 model not found` | OpenAI | Use `gpt-4o-mini` instead of `gpt-4` |
| `404 model not found` | Gemini | Use `gemini-1.5-flash` instead of `gemini-pro` |
| `invalid_api_key` | Any | Regenerate API key in provider console |
| `insufficient_quota` | OpenAI | Add billing to your OpenAI account |
| `rate_limit_exceeded` | Any | Wait and retry, or upgrade API tier |

### API Key Issues

If models aren't being detected:

1. **Check your `.env` file exists** in the project directory
2. **Verify API key format**:
   - OpenAI: Starts with `sk-`
   - Anthropic: Starts with `sk-ant-`
   - Gemini: Alphanumeric string
   - Moonshot: Check provider documentation

3. **Run status check**:
```bash
ai-orchestrator status
```

### Getting Help

- 📖 See [MODELS.md](MODELS.md) for detailed model information
- 🐛 Report issues on GitHub
- 💬 Check provider documentation for API-specific issues

---

## 🛠️ Development

### Project Structure

```
ai_orchestrator/
├── ai_orchestrator/
│   ├── __init__.py
│   ├── cli.py              # CLI interface
│   ├── config.py           # Configuration management
│   ├── orchestrator.py     # Main orchestration logic
│   ├── router.py           # Task routing logic
│   └── models/
│       ├── __init__.py
│       ├── base.py         # Base model client
│       ├── openai_client.py
│       ├── anthropic_client.py
│       ├── gemini_client.py
│       └── moonshot_client.py
├── .env.example
├── requirements.txt
├── pyproject.toml
└── README.md
```

### Running Tests

```bash
# Run with pytest
pytest tests/

# Run with coverage
pytest --cov=ai_orchestrator tests/
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- OpenAI for ChatGPT API
- Anthropic for Claude API
- Google for Gemini API
- Moonshot AI for Kimi API
