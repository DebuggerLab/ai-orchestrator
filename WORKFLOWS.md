# AI Orchestrator Workflows

This document provides visual workflow diagrams, common development scenarios, decision trees, and integration patterns for the AI Orchestrator.

## Table of Contents

- [Visual Workflow Diagrams](#visual-workflow-diagrams)
- [Common Development Scenarios](#common-development-scenarios)
- [Decision Trees](#decision-trees)
- [Integration Patterns](#integration-patterns)
- [Quick Reference](#quick-reference)

---

## Visual Workflow Diagrams

### Complete Development Workflow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                     COMPLETE DEVELOPMENT WORKFLOW                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────┐                                                              │
│  │   IDEA     │  "Build a REST API for task management"                     │
│  └─────┬──────┘                                                              │
│        │                                                                     │
│        ▼                                                                     │
│  ┌────────────┐  orchestrate_task()                                         │
│  │   PLAN     │  ─────────────────▶  ChatGPT designs architecture           │
│  │            │                       • System design                        │
│  │  (ChatGPT) │                       • Database schema                      │
│  │            │                       • API endpoints                        │
│  └─────┬──────┘                       • Project structure                    │
│        │                                                                     │
│        ▼                                                                     │
│  ┌────────────┐  orchestrate_task()                                         │
│  │   CODE     │  ─────────────────▶  Claude implements code                 │
│  │            │                       • Models & schemas                     │
│  │  (Claude)  │                       • Routes & controllers                 │
│  │            │                       • Error handling                       │
│  └─────┬──────┘                       • Tests                                │
│        │                                                                     │
│        ▼                                                                     │
│  ┌────────────┐  run_project()                                              │
│  │    RUN     │  ─────────────────▶  Execute project                        │
│  │            │                       • Detect project type                  │
│  │ (Executor) │                       • Install dependencies                 │
│  │            │                       • Run main entry point                 │
│  └─────┬──────┘                       • Capture output                       │
│        │                                                                     │
│   ┌────┴────┐                                                                │
│   │ Errors? │                                                                │
│   └────┬────┘                                                                │
│    YES │ NO                                                                  │
│        │  └──────────────────────────────────────┐                          │
│        ▼                                          │                          │
│  ┌────────────┐  test_project()                   │                          │
│  │   TEST     │  ─────────────────▶  Run tests    │                          │
│  │            │                       • pytest    │                          │
│  │ (pytest/   │                       • jest      │                          │
│  │  jest)     │                       • mocha     │                          │
│  └─────┬──────┘                                   │                          │
│        │                                          │                          │
│   ┌────┴────┐                                     │                          │
│   │ Failed? │                                     │                          │
│   └────┬────┘                                     │                          │
│    YES │ NO                                       │                          │
│        │  └──────────────────┐                    │                          │
│        ▼                     │                    │                          │
│  ┌────────────┐              │                    │                          │
│  │  ANALYZE   │              │                    │                          │
│  │            │              │                    │                          │
│  │ (Detector) │              │                    │                          │
│  └─────┬──────┘              │                    │                          │
│        │                     │                    │                          │
│        ▼                     │                    │                          │
│  ┌────────────┐              │                    │                          │
│  │    FIX     │              │                    │                          │
│  │            │              │                    │                          │
│  │ (AutoFixer)│              │                    │                          │
│  └─────┬──────┘              │                    │                          │
│        │                     │                    │                          │
│        └──────▶  Re-run  ────┘                    │                          │
│                                                   │                          │
│                                                   │                          │
│  ┌────────────┐  orchestrate_task() ◀────────────┘                          │
│  │  REVIEW    │  ─────────────────▶  Kimi reviews code                      │
│  │            │                       • Security audit                       │
│  │   (Kimi)   │                       • Best practices                       │
│  │            │                       • Performance check                    │
│  └─────┬──────┘                                                              │
│        │                                                                     │
│        ▼                                                                     │
│  ┌────────────┐                                                              │
│  │   DONE     │  ✅ Working, tested, reviewed project                        │
│  └────────────┘                                                              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Verification Loop Detail

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          VERIFICATION LOOP                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  verify_project("/path/to/project")                                         │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                         CYCLE 1                                       │   │
│  ├──────────────────────────────────────────────────────────────────────┤   │
│  │  RUN ─▶ 5 errors ─▶ FIX 3 ─▶ Progress: ████░░░░░░░░░░░░ 40%         │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                      │                                       │
│                                      ▼                                       │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                         CYCLE 2                                       │   │
│  ├──────────────────────────────────────────────────────────────────────┤   │
│  │  RUN ─▶ 2 errors ─▶ FIX 1 ─▶ Progress: ████████████░░░░ 80%         │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                      │                                       │
│                                      ▼                                       │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                         CYCLE 3                                       │   │
│  ├──────────────────────────────────────────────────────────────────────┤   │
│  │  RUN ─▶ 1 error ─▶ FIX 1 ─▶ Progress: ████████████████ 100% ✅       │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  Loop Termination Conditions:                                               │
│  ├─ ✅ All tests pass                                                       │
│  ├─ ⚠️  Max cycles reached (default: 10)                                    │
│  ├─ ⚠️  Same error 3+ times                                                 │
│  └─ ⚠️  No progress in 3 cycles                                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Auto-Fix Pipeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AUTO-FIX PIPELINE                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────┐                                                          │
│  │  ERROR INPUT   │  "ModuleNotFoundError: No module named 'flask'"         │
│  └───────┬────────┘                                                          │
│          │                                                                   │
│          ▼                                                                   │
│  ┌────────────────┐                                                          │
│  │    DETECT      │  Parse error message, extract details                   │
│  │   (Patterns)   │  ─▶ Type: DEPENDENCY                                    │
│  │                │  ─▶ Module: flask                                       │
│  └───────┬────────┘                                                          │
│          │                                                                   │
│          ▼                                                                   │
│  ┌────────────────┐                                                          │
│  │   CATEGORIZE   │  Classify error type                                    │
│  │                │  ─▶ Category: DEPENDENCY                                │
│  │                │  ─▶ Subcategory: PYTHON_PACKAGE                         │
│  └───────┬────────┘                                                          │
│          │                                                                   │
│          ▼                                                                   │
│  ┌────────────────┐                                                          │
│  │  SELECT FIX    │  Choose appropriate strategy                            │
│  │   STRATEGY     │  ─▶ Strategy: DependencyFixer                           │
│  │                │  ─▶ Command: pip install flask                          │
│  └───────┬────────┘                                                          │
│          │                                                                   │
│          ▼                                                                   │
│  ┌────────────────────────────────────────────────────────────────────────┐ │
│  │                    CONFIDENCE CHECK                                     │ │
│  ├────────────────────────────────────────────────────────────────────────┤ │
│  │  0.9+ HIGH     │  0.7-0.9 MEDIUM   │  <0.7 LOW                         │ │
│  │  ─▶ Auto-apply │  ─▶ Apply+backup  │  ─▶ Suggest only                  │ │
│  └────────────────────────────────────────────────────────────────────────┘ │
│          │                                                                   │
│          ▼                                                                   │
│  ┌────────────────┐                                                          │
│  │    VALIDATE    │  Check fix safety                                       │
│  │                │  ─▶ Syntax check passed                                 │
│  │                │  ─▶ No destructive changes                              │
│  └───────┬────────┘                                                          │
│          │                                                                   │
│          ▼                                                                   │
│  ┌────────────────┐                                                          │
│  │    BACKUP      │  Save original files                                    │
│  │                │  ─▶ .backups/requirements.txt.1708234567               │
│  └───────┬────────┘                                                          │
│          │                                                                   │
│          ▼                                                                   │
│  ┌────────────────┐                                                          │
│  │     APPLY      │  Execute the fix                                        │
│  │                │  ─▶ pip install flask                                   │
│  │                │  ─▶ Success!                                            │
│  └───────┬────────┘                                                          │
│          │                                                                   │
│          ▼                                                                   │
│  ┌────────────────┐                                                          │
│  │    VERIFY      │  Re-run to confirm fix                                  │
│  │                │  ─▶ No more "flask" errors                              │
│  └────────────────┘                                                          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Common Development Scenarios

### Scenario 1: New Project from Scratch

```
┌─────────────────────────────────────────────────────────────────┐
│ Goal: Build a new REST API                                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ Step 1: Design                                                   │
│ ─────────────────────────────────────────────────────────────── │
│ @ai-orchestrator orchestrate_task(                              │
│   "Design a REST API for user management with:                  │
│    - User registration and login                                │
│    - JWT authentication                                         │
│    - Role-based access control")                                │
│                                                                  │
│ Step 2: Implement                                                │
│ ─────────────────────────────────────────────────────────────── │
│ @ai-orchestrator orchestrate_task(                              │
│   "Implement the user management API based on the design")      │
│                                                                  │
│ Step 3: Verify & Fix                                            │
│ ─────────────────────────────────────────────────────────────── │
│ @ai-orchestrator verify_project("/path/to/api")                 │
│                                                                  │
│ Step 4: Review                                                   │
│ ─────────────────────────────────────────────────────────────── │
│ @ai-orchestrator orchestrate_task(                              │
│   "Review the API for security and best practices")             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Scenario 2: Debug Production Error

```
┌─────────────────────────────────────────────────────────────────┐
│ Goal: Fix a 500 error in production                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ Step 1: Analyze                                                  │
│ ─────────────────────────────────────────────────────────────── │
│ @ai-orchestrator analyze_errors(                                │
│   "/path/to/project",                                           │
│   error_log="TypeError: Cannot read property 'id' of null...")  │
│                                                                  │
│ Step 2: Understand                                               │
│ ─────────────────────────────────────────────────────────────── │
│ @ai-orchestrator route_to_model(                                │
│   "Explain why this null reference occurs and how to prevent",  │
│   "gemini")                                                     │
│                                                                  │
│ Step 3: Fix                                                      │
│ ─────────────────────────────────────────────────────────────── │
│ @ai-orchestrator fix_issues("/path/to/project")                 │
│                                                                  │
│ Step 4: Verify                                                   │
│ ─────────────────────────────────────────────────────────────── │
│ @ai-orchestrator verify_project("/path/to/project")             │
│                                                                  │
│ Step 5: Review Fix Safety                                        │
│ ─────────────────────────────────────────────────────────────── │
│ @ai-orchestrator route_to_model(                                │
│   "Review this fix for production safety", "moonshot")          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Scenario 3: Add Feature to Existing Project

```
┌─────────────────────────────────────────────────────────────────┐
│ Goal: Add OAuth login to existing app                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ Step 1: Understand Existing Code                                 │
│ ─────────────────────────────────────────────────────────────── │
│ @ai-orchestrator route_to_model(                                │
│   "Analyze the auth module structure in /path/to/project",      │
│   "gemini")                                                     │
│                                                                  │
│ Step 2: Design Integration                                       │
│ ─────────────────────────────────────────────────────────────── │
│ @ai-orchestrator orchestrate_task(                              │
│   "Design how to add Google OAuth to the existing auth system") │
│                                                                  │
│ Step 3: Implement                                                │
│ ─────────────────────────────────────────────────────────────── │
│ @ai-orchestrator orchestrate_task(                              │
│   "Implement Google OAuth following the integration design")    │
│                                                                  │
│ Step 4: Test                                                     │
│ ─────────────────────────────────────────────────────────────── │
│ @ai-orchestrator test_project("/path/to/project")               │
│                                                                  │
│ Step 5: Full Verification                                        │
│ ─────────────────────────────────────────────────────────────── │
│ @ai-orchestrator verify_project("/path/to/project")             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Scenario 4: Fix Failing Tests

```
┌─────────────────────────────────────────────────────────────────┐
│ Goal: All tests pass                                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│ Option A: Manual Control                                         │
│ ─────────────────────────────────────────────────────────────── │
│ @ai-orchestrator test_project("/path")     # See failures       │
│ @ai-orchestrator analyze_errors("/path")   # Understand why     │
│ @ai-orchestrator fix_issues("/path")       # Apply fixes        │
│ @ai-orchestrator test_project("/path")     # Verify fixed       │
│                                                                  │
│ Option B: Automated Loop                                         │
│ ─────────────────────────────────────────────────────────────── │
│ @ai-orchestrator verify_project("/path")   # Auto fix loop      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Decision Trees

### Which Tool Should I Use?

```
┌─────────────────────────────────────────────────────────────────┐
│                    TOOL SELECTION GUIDE                          │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │ What do you    │
                    │ want to do?    │
                    └───────┬────────┘
                            │
        ┌───────────────────┼───────────────────┬─────────────────┐
        │                   │                   │                 │
        ▼                   ▼                   ▼                 ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│ Build/Design  │  │ Debug/Fix     │  │ Run/Test      │  │ Review        │
│ something new │  │ an issue      │  │ existing code │  │ code quality  │
└───────┬───────┘  └───────┬───────┘  └───────┬───────┘  └───────┬───────┘
        │                  │                  │                  │
        ▼                  ▼                  ▼                  ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│orchestrate_   │  │ Know the      │  │ Just run or   │  │orchestrate_   │
│task()         │  │ error?        │  │ full verify?  │  │task() with    │
│               │  │               │  │               │  │review request │
│ Full workflow │  │ YES: analyze_ │  │ RUN: run_     │  │               │
│ with multiple │  │   errors()    │  │   project()   │  │ → Routes to   │
│ models        │  │ NO: run_      │  │               │  │   Kimi        │
│               │  │   project()   │  │ TEST: test_   │  │               │
│               │  │               │  │   project()   │  │               │
│               │  │ Then:         │  │               │  │               │
│               │  │ fix_issues()  │  │ FULL: verify_ │  │               │
│               │  │      or       │  │   project()   │  │               │
│               │  │ verify_       │  │               │  │               │
│               │  │ project()     │  │               │  │               │
└───────────────┘  └───────────────┘  └───────────────┘  └───────────────┘
```

### Which Model for This Task?

```
┌─────────────────────────────────────────────────────────────────┐
│                    MODEL SELECTION GUIDE                         │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌────────────────┐
                    │ Task involves  │
                    │ primarily...   │
                    └───────┬────────┘
                            │
    ┌───────────────────────┼───────────────────┬─────────────────┐
    │                       │                   │                 │
    ▼                       ▼                   ▼                 ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐   ┌─────────────┐
│ Planning    │     │ Writing     │     │ Analysis    │   │ Evaluation  │
│ Designing   │     │ Coding      │     │ Explaining  │   │ Reviewing   │
│ Structuring │     │ Debugging   │     │ Reasoning   │   │ Auditing    │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘   └──────┬──────┘
       │                   │                   │                 │
       ▼                   ▼                   ▼                 ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐   ┌─────────────┐
│   ChatGPT   │     │   Claude    │     │   Gemini    │   │    Kimi     │
│   (OpenAI)  │     │ (Anthropic) │     │  (Google)   │   │ (Moonshot)  │
├─────────────┤     ├─────────────┤     ├─────────────┤   ├─────────────┤
│ Architecture│     │ Code gen    │     │ Algorithms  │   │ Security    │
│ API design  │     │ Bug fixes   │     │ Trade-offs  │   │ Best practs │
│ DB schemas  │     │ Refactoring │     │ Comparisons │   │ Performance │
│ Roadmaps    │     │ Tests       │     │ Research    │   │ Style       │
└─────────────┘     └─────────────┘     └─────────────┘   └─────────────┘
```

### When to Use Verification Loop?

```
                    ┌────────────────┐
                    │ Should I use   │
                    │ verify_project?│
                    └───────┬────────┘
                            │
                            ▼
                    ┌────────────────┐
              NO    │ Multiple errors│    YES
            ◄───────┤   to fix?      ├───────►
            │       └────────────────┘        │
            │                                 │
            ▼                                 ▼
    ┌───────────────┐                 ┌───────────────┐
    │ Use individual│                 │ Want auto-fix │
    │ tools instead │           NO    │ loop?         │   YES
    │               │         ◄───────┤               ├───────►
    │ run_project() │         │       └───────────────┘        │
    │ analyze_()    │         │                                │
    │ fix_issues()  │         ▼                                ▼
    └───────────────┘  ┌───────────────┐               ┌───────────────┐
                       │ Manual control│               │ verify_project│
                       │ over each fix │               │               │
                       └───────────────┘               │ Automatic:    │
                                                       │ run→test→fix  │
                                                       │ until success │
                                                       └───────────────┘
```

---

## Integration Patterns

### Pattern 1: CI/CD Integration

```
┌─────────────────────────────────────────────────────────────────┐
│                     CI/CD Pipeline                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────┐    ┌────────┐    ┌────────┐    ┌────────┐          │
│  │  Push  │───▶│  Test  │───▶│ Analyze│───▶│ Report │          │
│  │        │    │        │    │        │    │        │          │
│  └────────┘    └───┬────┘    └───┬────┘    └────────┘          │
│                    │             │                              │
│                    ▼             ▼                              │
│               test_project  analyze_errors                      │
│                    │             │                              │
│                    │     ┌───────┴───────┐                      │
│                    │     │               │                      │
│                    │     ▼               ▼                      │
│                    │  fix_issues    Create PR                   │
│                    │  (auto)        with suggestions            │
│                    │                                            │
│                    └────────────────────────────────────────────┤
│                                                                  │
│  # In CI script:                                                 │
│  ai-orchestrator test "/app"                                     │
│  if [ $? -ne 0 ]; then                                          │
│    ai-orchestrator analyze-errors "/app" > report.md            │
│    ai-orchestrator fix-issues "/app" --dry-run >> report.md     │
│  fi                                                              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Pattern 2: IDE Integration (Cursor)

```
┌─────────────────────────────────────────────────────────────────┐
│                    Cursor IDE Workflow                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Developer Types in Chat:                                        │
│  ────────────────────────                                        │
│  "Build a REST API for my task manager"                         │
│                                                                  │
│          │                                                       │
│          ▼                                                       │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    AI Orchestrator                          │ │
│  │                                                              │ │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐      │ │
│  │  │orchestrate│→│   run    │→│   test   │→│  review  │      │ │
│  │  │  _task   │ │ _project │ │ _project │ │   code   │      │ │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────┘      │ │
│  │       │            │            │            │              │ │
│  │       ▼            ▼            ▼            ▼              │ │
│  │   ChatGPT →    Execute →    pytest →     Kimi →            │ │
│  │   Claude        Project     Jest        Review              │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│          │                                                       │
│          ▼                                                       │
│  Developer Receives:                                             │
│  ───────────────────                                             │
│  • Architecture design                                           │
│  • Working code files                                            │
│  • Test results                                                  │
│  • Code review feedback                                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Pattern 3: Programmatic Usage

```python
# Python Integration Example

from ai_orchestrator.orchestrator import Orchestrator
from ai_orchestrator.execution import ProjectRunner, VerificationLoop
from ai_orchestrator.config import Config

# Load configuration
config = Config.load()

# Initialize orchestrator
orchestrator = Orchestrator(config)

# Design phase
architecture = orchestrator.execute(
    "Design a REST API for user management"
)

# Implementation phase
implementation = orchestrator.execute(
    f"Implement based on this architecture: {architecture.consolidated_output}"
)

# Verification loop
loop = VerificationLoop(config)
report = loop.run_development_cycle(
    project_path="/path/to/project",
    max_cycles=10,
    run_tests=True
)

if report.status == "SUCCESS":
    # Code review
    review = orchestrator.execute(
        "Review the implementation for security and best practices",
        task_type="code_review"
    )
```

---

## Quick Reference

### Tool Summary Table

| Tool | Purpose | Input | Output |
|------|---------|-------|--------|
| `orchestrate_task` | Multi-model task | Task description | Consolidated result |
| `analyze_task` | Task planning | Task description | Routing plan |
| `route_to_model` | Direct routing | Task + model | Model response |
| `run_project` | Execute project | Project path | Execution result |
| `test_project` | Run tests | Project path | Test results |
| `analyze_errors` | Error analysis | Project path | Error details |
| `fix_issues` | Apply fixes | Project path | Fix report |
| `verify_project` | Full loop | Project path | Loop report |

### Common Commands

```bash
# Check available models
@ai-orchestrator check_status()

# Design something
@ai-orchestrator orchestrate_task("Design [description]")

# Build something
@ai-orchestrator orchestrate_task("Implement [feature]")

# Run a project
@ai-orchestrator run_project("/path")

# Test a project
@ai-orchestrator test_project("/path")

# Full verification
@ai-orchestrator verify_project("/path")

# Analyze specific error
@ai-orchestrator analyze_errors("/path", error_log="[error text]")
```

---

## See Also

- [DEVELOPMENT_WORKFLOW.md](cursor_integration/DEVELOPMENT_WORKFLOW.md) - Detailed workflow guide
- [Examples](cursor_integration/examples/) - Real-world examples
- [Sample Projects](cursor_integration/examples/sample_projects/) - Practice projects
- [CURSOR_SETUP.md](cursor_integration/CURSOR_SETUP.md) - IDE setup guide
