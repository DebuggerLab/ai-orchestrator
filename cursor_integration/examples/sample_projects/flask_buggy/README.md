# Flask Buggy Project

This project contains **intentional bugs** for practicing with the AI Orchestrator's auto-fix capabilities.

## Purpose

Use this project to see how the orchestrator:
1. Detects Python-specific error types
2. Analyzes root causes
3. Generates and applies fixes
4. Verifies fixes work

## Bugs Included

| Bug | Type | File | What's Wrong |
|-----|------|------|-------------|
| 1 | Dependency | requirements.txt | Missing `flask` dependency |
| 2 | Import | app/routes.py | Circular import issue |
| 3 | Syntax | app/models.py | Indentation error |
| 4 | Runtime | app/routes.py | NoneType attribute access |
| 5 | Configuration | .env.example | Missing required env var |
| 6 | Type | app/utils.py | Wrong function signature |

## How to Use

### Step 1: Try to Run

```
@ai-orchestrator run_project("/path/to/flask_buggy")
```

Expected: Multiple errors

### Step 2: Analyze

```
@ai-orchestrator analyze_errors("/path/to/flask_buggy")
```

See what errors are detected

### Step 3: Auto-Fix

```
@ai-orchestrator verify_project("/path/to/flask_buggy")
```

Watch the orchestrator fix issues iteratively

### Step 4: Compare

After fixes, compare with the fixed versions in comments

## Expected Fix Output

```
╔══════════════════════════════════════════════════════════════╗
║                    VERIFICATION LOOP                          ║
╠══════════════════════════════════════════════════════════════╣
║ Cycle 1: 6 errors → Fixed 4 (dependency, syntax, import)    ║
║ Cycle 2: 2 errors → Fixed 2 (runtime, config)               ║
║ Cycle 3: 0 errors → ✅ SUCCESS                               ║
╚══════════════════════════════════════════════════════════════╝
```

## Running Tests

After fixing:
```bash
pytest tests/ -v
```

## Resetting the Project

To practice again:
```bash
git checkout -- .
```
