# AI Orchestrator Examples

This directory contains examples demonstrating how to use the AI Orchestrator for various development workflows.

## Examples Overview

### Task Orchestration Examples

| Example | Description | Key Concepts |
|---------|-------------|--------------|
| [01_rest_api.md](01_rest_api.md) | Building a REST API with task routing | Multi-model orchestration, task breakdown |
| [02_fullstack_webapp.md](02_fullstack_webapp.md) | Full-stack web app development | Complex workflows, frontend + backend |
| [03_code_review.md](03_code_review.md) | Security review and refactoring | Code review routing to Kimi |

### Execution & Auto-Fix Examples

| Example | Description | Key Concepts |
|---------|-------------|--------------|
| [04_auto_fix_workflow.md](04_auto_fix_workflow.md) | How auto-fix handles common errors | Error detection, fix strategies |
| [05_full_development_cycle.md](05_full_development_cycle.md) | Complete project from idea to code | Full development workflow |
| [06_debugging_and_testing.md](06_debugging_and_testing.md) | Debugging and testing guide | Test frameworks, debugging tools |

### Sample Projects for Practice

| Project | Description | Bugs to Fix |
|---------|-------------|-------------|
| [nodejs_buggy/](sample_projects/nodejs_buggy/) | Node.js Express API with bugs | 5 intentional bugs |
| [flask_buggy/](sample_projects/flask_buggy/) | Python Flask API with issues | 6 intentional bugs |

## Quick Start

### 1. For Task Orchestration

Start with the REST API example to understand basic multi-model routing:

```
@ai-orchestrator orchestrate_task("Design and implement a REST API")
```

### 2. For Auto-Fix Learning

Use the sample projects to practice:

```
# Try to run a buggy project
@ai-orchestrator run_project("/path/to/sample_projects/nodejs_buggy")

# Analyze errors
@ai-orchestrator analyze_errors("/path/to/sample_projects/nodejs_buggy")

# Auto-fix everything
@ai-orchestrator verify_project("/path/to/sample_projects/nodejs_buggy")
```

### 3. For Full Development

Follow the full development cycle example to build a complete project:

```
# 1. Plan
@ai-orchestrator orchestrate_task("Design the architecture...")

# 2. Implement
@ai-orchestrator orchestrate_task("Implement based on design...")

# 3. Verify
@ai-orchestrator verify_project("/path/to/project")

# 4. Review
@ai-orchestrator orchestrate_task("Review for security...")
```

## Recommended Reading Order

1. **New to AI Orchestrator?**
   - Start with `01_rest_api.md` for basics
   - Then `04_auto_fix_workflow.md` for auto-fix features

2. **Want to learn execution tools?**
   - Start with `06_debugging_and_testing.md`
   - Practice with `sample_projects/nodejs_buggy/`

3. **Building a new project?**
   - Follow `05_full_development_cycle.md` step by step

4. **Doing code review?**
   - See `03_code_review.md` for best practices

## Related Documentation

- [DEVELOPMENT_WORKFLOW.md](../DEVELOPMENT_WORKFLOW.md) - Complete workflow diagrams
- [CURSOR_SETUP.md](../CURSOR_SETUP.md) - Cursor IDE setup guide
- [WORKFLOWS.md](../../WORKFLOWS.md) - Visual workflow decision trees
- [.cursorrules](../.cursorrules) - AI behavior configuration
