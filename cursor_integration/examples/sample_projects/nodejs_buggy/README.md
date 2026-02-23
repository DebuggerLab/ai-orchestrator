# Node.js Buggy Project

This project contains **intentional bugs** for practicing with the AI Orchestrator's auto-fix capabilities.

## Purpose

Use this project to see how the orchestrator:
1. Detects various error types
2. Analyzes root causes
3. Generates and applies fixes
4. Verifies fixes work

## Bugs Included

| Bug | Type | File | What's Wrong |
|-----|------|------|-------------|
| 1 | Dependency | package.json | Missing `express` dependency |
| 2 | Syntax | src/app.js | Missing closing parenthesis |
| 3 | Runtime | src/routes/users.js | Accessing property of undefined |
| 4 | Import | src/routes/tasks.js | Wrong import path |
| 5 | Type | src/utils/validator.js | Type mismatch in function |

## How to Use

### Step 1: Try to Run

```
@ai-orchestrator run_project("/path/to/nodejs_buggy")
```

Expected: Multiple errors

### Step 2: Analyze

```
@ai-orchestrator analyze_errors("/path/to/nodejs_buggy")
```

See what errors are detected

### Step 3: Auto-Fix

```
@ai-orchestrator verify_project("/path/to/nodejs_buggy")
```

Watch the orchestrator fix issues iteratively

### Step 4: Compare

After fixes, compare with the `.fixed` versions in each file comments

## Expected Fix Output

```
╔══════════════════════════════════════════════════════════════╗
║                    VERIFICATION LOOP                          ║
╠══════════════════════════════════════════════════════════════╣
║ Cycle 1: 5 errors → Fixed 3 (dependency, syntax, import)    ║
║ Cycle 2: 2 errors → Fixed 2 (runtime, type)                 ║
║ Cycle 3: 0 errors → ✅ SUCCESS                               ║
╚══════════════════════════════════════════════════════════════╝
```

## Resetting the Project

To practice again, reset using git:

```bash
git checkout -- .
```

Or re-copy the original files.
