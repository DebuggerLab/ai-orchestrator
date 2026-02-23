#!/usr/bin/env python3
"""
MCP Server for AI Orchestrator

This server exposes the AI Orchestrator functionality via the Model Context Protocol (MCP),
allowing integration with Cursor IDE and other MCP-compatible tools.

Includes tools for:
- Task orchestration across multiple AI models
- Project execution and testing
- Error analysis and auto-fixing
- Complete development workflow orchestration
"""

import asyncio
import json
import sys
import os
import logging
from pathlib import Path
from typing import Any, Optional, Dict, List
from datetime import datetime

# Add parent directory to path for importing ai_orchestrator modules
sys.path.insert(0, str(Path(__file__).parent.parent))

# ============================================================================
# Logging Configuration
# ============================================================================
# MCP servers use stdio for communication, so we need file-based logging

def setup_logging():
    """Setup file-based logging for the MCP server."""
    log_dir = Path(__file__).parent.parent / "logs"
    log_dir.mkdir(exist_ok=True)
    
    log_file = log_dir / "mcp-server.log"
    
    # Configure logging to file only (not stdout which is used by MCP protocol)
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
        handlers=[
            logging.FileHandler(log_file, mode='a'),
        ]
    )
    
    # Also capture warnings
    logging.captureWarnings(True)
    
    return logging.getLogger("mcp_server")

# Initialize logger immediately
logger = setup_logging()
logger.info("=" * 60)
logger.info("MCP Server Starting...")
logger.info(f"Python version: {sys.version}")
logger.info(f"Working directory: {os.getcwd()}")

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import (
    Tool,
    TextContent,
    INVALID_PARAMS,
    INTERNAL_ERROR,
)

from ai_orchestrator.config import Config
from ai_orchestrator.orchestrator import Orchestrator, OrchestrationResult, ProjectDevelopmentResult
from ai_orchestrator.router import TaskRouter, ModelProvider, SubTask
from ai_orchestrator.models.base import TaskType

# Execution module imports
from ai_orchestrator.execution import (
    ProjectRunner,
    ExecutionResult,
    ExecutionStatus,
    ErrorDetector,
    DetectedError,
    ErrorCategory,
    TestExecutor,
    TestResult,
    TestFramework,
    TestStatus,
    AutoFixer,
    AnalysisResult,
    GeneratedFix,
    FixAttempt,
    VerificationLoop,
    LoopReport,
    LoopStatus,
    LoopProgress,
    CycleResult,
    ProgressTrend,
    detect_project_type,
    # iOS-specific imports
    iOSProject,
    iOSSimulatorManager,
    iOSProjectBuilder,
    Simulator,
    SimulatorResult,
    BuildResult,
    list_simulators,
    boot_simulator,
    build_ios_project,
    run_ios_tests,
    SimulatorFixer,
    SwiftPackageFixer,
)


# Initialize the MCP server
app = Server("ai-orchestrator")

# Global config and orchestrator (lazy loaded)
_config: Optional[Config] = None
_orchestrator: Optional[Orchestrator] = None


def get_config() -> Config:
    """Get or create the config instance."""
    global _config
    if _config is None:
        # Load from .env file in the ai_orchestrator directory
        env_path = Path(__file__).parent.parent / ".env"
        if not env_path.exists():
            env_path = Path(__file__).parent.parent / ".env.example"
        _config = Config.load(env_path if env_path.exists() else None)
    return _config


def get_orchestrator() -> Orchestrator:
    """Get or create the orchestrator instance."""
    global _orchestrator
    if _orchestrator is None:
        _orchestrator = Orchestrator(get_config())
    return _orchestrator


# ============================================================================
# Helper Functions for Formatting Results
# ============================================================================

def format_model_info(provider: ModelProvider, config: Config) -> dict:
    """Format model information for a provider."""
    model_names = {
        ModelProvider.OPENAI: config.models.openai_model,
        ModelProvider.ANTHROPIC: config.models.anthropic_model,
        ModelProvider.GEMINI: config.models.gemini_model,
        ModelProvider.MOONSHOT: config.models.moonshot_model,
    }
    
    specializations = {
        ModelProvider.OPENAI: ["architecture", "roadmap", "documentation", "general"],
        ModelProvider.ANTHROPIC: ["coding", "debugging"],
        ModelProvider.GEMINI: ["reasoning", "logic"],
        ModelProvider.MOONSHOT: ["code_review"],
    }
    
    return {
        "provider": provider.value,
        "model": model_names.get(provider, "unknown"),
        "specializations": specializations.get(provider, []),
        "available": provider.value in config.get_available_models()
    }


def format_subtask(subtask: SubTask) -> dict:
    """Format a subtask for JSON response."""
    return {
        "id": subtask.id,
        "description": subtask.description,
        "task_type": subtask.task_type.value,
        "target_model": subtask.target_model.value,
        "prompt_preview": subtask.prompt[:200] + "..." if len(subtask.prompt) > 200 else subtask.prompt,
        "dependencies": subtask.dependencies
    }


def format_orchestration_result(result: OrchestrationResult) -> dict:
    """Format orchestration result for JSON response."""
    return {
        "success": result.success,
        "original_task": result.original_task,
        "consolidated_output": result.consolidated_output,
        "subtask_results": [
            {
                "subtask": format_subtask(subtask),
                "response": {
                    "model_name": response.model_name,
                    "model_provider": response.model_provider,
                    "task_type": response.task_type,
                    "content": response.content,
                    "success": response.success,
                    "error": response.error,
                    "tokens_used": response.tokens_used
                }
            }
            for subtask, response in result.subtask_results
        ],
        "errors": result.errors
    }


def format_execution_result(result: ExecutionResult) -> dict:
    """Format project execution result for JSON response."""
    return {
        "status": result.status.value,
        "project_type": result.project_type,
        "exit_code": result.exit_code,
        "duration_seconds": round(result.duration, 2),
        "message": result.message,
        "stdout": truncate_output(result.stdout, 5000),
        "stderr": truncate_output(result.stderr, 3000),
        "setup_output": truncate_output(result.setup_output, 2000) if result.setup_output else None,
        "errors_detected": [format_detected_error(e) for e in result.errors] if result.errors else [],
        "test_results": format_test_result(result.test_results) if result.test_results else None,
        "config": {
            "entry_point": result.config.entry_point if result.config else None,
            "run_command": result.config.run_command if result.config else None,
            "framework": result.config.framework if result.config else None,
        } if result.config else None
    }


def format_detected_error(error: DetectedError) -> dict:
    """Format a detected error for JSON response."""
    return {
        "category": error.category.value if hasattr(error.category, 'value') else str(error.category),
        "message": error.message,
        "file": error.file,
        "line": error.line,
        "column": error.column,
        "severity": error.severity if hasattr(error, 'severity') else "error",
        "stack_trace": truncate_output(error.stack_trace, 1000) if hasattr(error, 'stack_trace') and error.stack_trace else None,
        "context": error.context if hasattr(error, 'context') else None,
        "suggested_fixes": error.suggested_fixes if hasattr(error, 'suggested_fixes') else [],
    }


def format_test_result(result: TestResult) -> dict:
    """Format test execution result for JSON response."""
    return {
        "framework": result.framework.value if hasattr(result.framework, 'value') else str(result.framework),
        "status": result.status.value if hasattr(result.status, 'value') else str(result.status),
        "total_tests": result.total,
        "passed": result.passed,
        "failed": result.failed,
        "skipped": result.skipped,
        "duration_seconds": round(result.duration, 2) if hasattr(result, 'duration') else None,
        "pass_rate": round((result.passed / result.total * 100), 1) if result.total > 0 else 0,
        "output": truncate_output(result.output, 3000) if hasattr(result, 'output') else None,
        "failed_tests": result.failed_tests if hasattr(result, 'failed_tests') else [],
        "error_output": truncate_output(result.error_output, 2000) if hasattr(result, 'error_output') else None,
    }


def format_error_analysis(analysis: AnalysisResult) -> dict:
    """Format error analysis result for JSON response."""
    return {
        "error": format_detected_error(analysis.error),
        "root_cause": analysis.root_cause,
        "fix_suggestions": analysis.fix_suggestions,
        "affected_files": analysis.affected_files,
        "confidence": round(analysis.confidence, 2),
        "requires_ai": analysis.requires_ai,
        "recommended_model": analysis.recommended_model,
    }


def format_generated_fix(fix: GeneratedFix) -> dict:
    """Format a generated fix for JSON response."""
    return {
        "error_message": fix.error.message if fix.error else None,
        "fix_type": fix.fix_type.value if hasattr(fix.fix_type, 'value') else str(fix.fix_type),
        "description": fix.description,
        "confidence": round(fix.confidence, 2),
        "model_used": fix.model_used,
        "reasoning": truncate_output(fix.reasoning, 500),
        "validation_passed": fix.validation_passed,
        "files_to_modify": list(fix.file_changes.keys()) if fix.file_changes else [],
        "commands_to_run": fix.commands,
    }


def format_fix_attempt(attempt: FixAttempt) -> dict:
    """Format a fix attempt record for JSON response."""
    return {
        "timestamp": attempt.timestamp.isoformat() if attempt.timestamp else None,
        "error_message": attempt.error.message if attempt.error else None,
        "fix": format_generated_fix(attempt.fix) if attempt.fix else None,
        "result": {
            "success": attempt.result.success if attempt.result else False,
            "message": attempt.result.message if attempt.result and hasattr(attempt.result, 'message') else None,
        } if attempt.result else None,
        "backup_path": attempt.backup_path,
        "rollback_needed": attempt.rollback_needed,
    }


def format_loop_progress(progress: LoopProgress) -> dict:
    """Format verification loop progress for JSON response."""
    return {
        "total_cycles": progress.total_cycles,
        "total_errors_found": progress.total_errors_found,
        "total_errors_fixed": progress.total_errors_fixed,
        "unique_errors_seen": progress.unique_errors_seen,
        "repeated_errors": progress.repeated_errors,
        "trend": progress.trend.value if hasattr(progress.trend, 'value') else str(progress.trend),
        "error_count_history": progress.error_count_history,
        "fix_success_rate": round(
            (progress.total_errors_fixed / progress.total_errors_found * 100), 1
        ) if progress.total_errors_found > 0 else 0,
    }


def format_cycle_result(cycle: CycleResult) -> dict:
    """Format a single verification cycle result."""
    return {
        "cycle_number": cycle.cycle_number,
        "status": cycle.status,
        "duration_seconds": round(cycle.duration, 2),
        "errors_found": len(cycle.errors_found),
        "fixes_attempted": len(cycle.fixes_attempted),
        "fixes_successful": cycle.fixes_successful,
        "fixes_failed": cycle.fixes_failed,
        "execution_status": cycle.execution_result.status.value if cycle.execution_result else None,
        "test_status": format_test_result(cycle.test_result) if cycle.test_result else None,
    }


def format_loop_report(report: LoopReport) -> dict:
    """Format complete verification loop report for JSON response."""
    return {
        "status": report.status.value if hasattr(report.status, 'value') else str(report.status),
        "total_duration_seconds": round(report.total_duration, 2),
        "start_time": report.start_time.isoformat() if report.start_time else None,
        "end_time": report.end_time.isoformat() if report.end_time else None,
        "progress": format_loop_progress(report.progress),
        "cycles": [format_cycle_result(c) for c in report.cycles],
        "final_execution": format_execution_result(report.final_execution_result) if report.final_execution_result else None,
        "final_tests": format_test_result(report.final_test_result) if report.final_test_result else None,
        "summary": report.summary,
        "recommendations": report.recommendations,
    }


def format_development_result(result: ProjectDevelopmentResult) -> dict:
    """Format complete project development result for JSON response."""
    return {
        "project_path": result.project_path,
        "success": result.success,
        "status": result.status,
        "total_duration_seconds": round(result.total_duration, 2),
        "phases": [
            {
                "name": phase.name,
                "model_provider": phase.model_provider,
                "task_type": phase.task_type.value if hasattr(phase.task_type, 'value') else str(phase.task_type),
                "success": phase.success,
                "duration_seconds": round(phase.duration, 2),
                "response_preview": truncate_output(phase.response.content, 500) if phase.response and phase.response.content else None,
            }
            for phase in result.phases
        ],
        "execution_result": format_execution_result(result.execution_result) if result.execution_result else None,
        "verification_report": format_loop_report(result.verification_report) if result.verification_report else None,
        "test_result": format_test_result(result.test_result) if result.test_result else None,
        "final_review": {
            "model": result.final_review.model_name if result.final_review else None,
            "content": truncate_output(result.final_review.content, 1000) if result.final_review and result.final_review.content else None,
        } if result.final_review else None,
        "errors": result.errors,
        "summary": result.summary,
    }


def truncate_output(text: str, max_length: int = 2000) -> str:
    """Truncate long output with indicator."""
    if not text:
        return ""
    if len(text) <= max_length:
        return text
    return text[:max_length] + f"\n... [truncated, {len(text) - max_length} more characters]"


# ============================================================================
# Tool Definitions
# ============================================================================

@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available tools for the MCP server."""
    return [
        # Original orchestration tools
        Tool(
            name="orchestrate_task",
            description="Orchestrate a task across multiple AI models. The orchestrator analyzes the task, routes it to the most appropriate model(s), and returns consolidated results. Best for general AI tasks like architecture design, code review, or documentation.",
            inputSchema={
                "type": "object",
                "properties": {
                    "task": {
                        "type": "string",
                        "description": "The task description to be orchestrated across AI models"
                    }
                },
                "required": ["task"]
            }
        ),
        Tool(
            name="analyze_task",
            description="Analyze how a task would be routed without actually executing it. Returns the routing plan with target models and subtasks. Useful for understanding which models will be used before execution.",
            inputSchema={
                "type": "object",
                "properties": {
                    "task": {
                        "type": "string",
                        "description": "The task description to analyze"
                    }
                },
                "required": ["task"]
            }
        ),
        Tool(
            name="check_status",
            description="Check the configuration status and model availability of the AI orchestrator. Shows which AI models are configured and available.",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": []
            }
        ),
        Tool(
            name="route_to_model",
            description="Route a specific task directly to a specific AI model, bypassing automatic routing. Use when you want to ensure a particular model handles the task.",
            inputSchema={
                "type": "object",
                "properties": {
                    "task": {
                        "type": "string",
                        "description": "The task to execute"
                    },
                    "model": {
                        "type": "string",
                        "enum": ["openai", "anthropic", "gemini", "moonshot"],
                        "description": "The model provider to use"
                    }
                },
                "required": ["task", "model"]
            }
        ),
        Tool(
            name="get_available_models",
            description="List all configured and available AI models with their specializations.",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": []
            }
        ),
        
        # New execution tools
        Tool(
            name="run_project",
            description="Run a project and capture its output. Automatically detects project type (Python, Node.js, React, Next.js, Flask, Django), sets up the environment, installs dependencies if needed, and executes the project. Returns execution status, stdout/stderr, detected errors, and project configuration.",
            inputSchema={
                "type": "object",
                "properties": {
                    "project_path": {
                        "type": "string",
                        "description": "Absolute path to the project directory"
                    },
                    "setup_dependencies": {
                        "type": "boolean",
                        "description": "Whether to install dependencies before running (default: true)",
                        "default": True
                    },
                    "command": {
                        "type": "string",
                        "description": "Custom run command (optional, auto-detected if not provided)"
                    },
                    "timeout": {
                        "type": "integer",
                        "description": "Execution timeout in seconds (default: 300)",
                        "default": 300
                    }
                },
                "required": ["project_path"]
            }
        ),
        Tool(
            name="test_project",
            description="Run tests for a project and get detailed results. Automatically detects the test framework (pytest, jest, mocha, vitest, django) and runs appropriate test commands. Returns pass/fail counts, test output, and detailed failure reports.",
            inputSchema={
                "type": "object",
                "properties": {
                    "project_path": {
                        "type": "string",
                        "description": "Absolute path to the project directory"
                    },
                    "test_command": {
                        "type": "string",
                        "description": "Custom test command (optional, auto-detected if not provided)"
                    },
                    "timeout": {
                        "type": "integer",
                        "description": "Test timeout in seconds (default: 180)",
                        "default": 180
                    }
                },
                "required": ["project_path"]
            }
        ),
        Tool(
            name="analyze_errors",
            description="Analyze errors from project execution or provided error logs. Categorizes errors (syntax, runtime, dependency, configuration, etc.), extracts stack traces, identifies affected files, and suggests fixes. Can use AI for deeper analysis.",
            inputSchema={
                "type": "object",
                "properties": {
                    "project_path": {
                        "type": "string",
                        "description": "Absolute path to the project directory"
                    },
                    "error_logs": {
                        "type": "string",
                        "description": "Error logs to analyze (optional, will run project if not provided)"
                    },
                    "use_ai": {
                        "type": "boolean",
                        "description": "Whether to use AI for deeper analysis (default: true)",
                        "default": True
                    }
                },
                "required": ["project_path"]
            }
        ),
        Tool(
            name="fix_issues",
            description="Generate and optionally apply fixes for detected errors. Uses AI models (Claude for coding) to analyze errors and generate fixes. Can automatically apply fixes with validation and backup, or just generate fix suggestions.",
            inputSchema={
                "type": "object",
                "properties": {
                    "project_path": {
                        "type": "string",
                        "description": "Absolute path to the project directory"
                    },
                    "errors": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "List of error messages to fix (optional, will detect if not provided)"
                    },
                    "auto_apply": {
                        "type": "boolean",
                        "description": "Whether to automatically apply fixes (default: false)",
                        "default": False
                    },
                    "max_attempts": {
                        "type": "integer",
                        "description": "Maximum fix attempts per error (default: 3)",
                        "default": 3
                    }
                },
                "required": ["project_path"]
            }
        ),
        Tool(
            name="verify_project",
            description="Run the full verification loop: execute → test → analyze errors → fix → repeat until success or max cycles reached. Provides comprehensive reporting on all attempts, fixes applied, and final project status. Best for ensuring a project works end-to-end.",
            inputSchema={
                "type": "object",
                "properties": {
                    "project_path": {
                        "type": "string",
                        "description": "Absolute path to the project directory"
                    },
                    "max_cycles": {
                        "type": "integer",
                        "description": "Maximum number of fix cycles (default: 10)",
                        "default": 10
                    },
                    "run_tests": {
                        "type": "boolean",
                        "description": "Whether to run tests in each cycle (default: true)",
                        "default": True
                    },
                    "auto_fix": {
                        "type": "boolean",
                        "description": "Whether to attempt automatic fixes (default: true)",
                        "default": True
                    },
                    "setup_first": {
                        "type": "boolean",
                        "description": "Whether to setup dependencies on first run (default: true)",
                        "default": True
                    }
                },
                "required": ["project_path"]
            }
        ),
        Tool(
            name="orchestrate_full_development",
            description="Run the complete development cycle from planning to working project. Phases: (1) Architecture planning with ChatGPT, (2) Implementation with Claude, (3) Project execution, (4) Error verification and auto-fixing, (5) Test design with Gemini, (6) Final review with Kimi. Returns comprehensive development report.",
            inputSchema={
                "type": "object",
                "properties": {
                    "project_path": {
                        "type": "string",
                        "description": "Absolute path to the project directory"
                    },
                    "project_description": {
                        "type": "string",
                        "description": "Description of what to build or implement"
                    },
                    "requirements": {
                        "type": "array",
                        "items": {"type": "string"},
                        "description": "List of specific requirements (optional)"
                    },
                    "run_project": {
                        "type": "boolean",
                        "description": "Whether to run the project after implementation (default: true)",
                        "default": True
                    },
                    "run_tests": {
                        "type": "boolean",
                        "description": "Whether to run tests (default: true)",
                        "default": True
                    },
                    "auto_fix": {
                        "type": "boolean",
                        "description": "Whether to auto-fix errors (default: true)",
                        "default": True
                    }
                },
                "required": ["project_path", "project_description"]
            }
        ),
        
        # iOS-specific tools
        Tool(
            name="list_ios_simulators",
            description="List all available iOS Simulators on the system. Returns device names, UDIDs, states (Booted/Shutdown), and iOS versions. Useful for choosing a target simulator before running iOS apps.",
            inputSchema={
                "type": "object",
                "properties": {
                    "available_only": {
                        "type": "boolean",
                        "description": "Only show available simulators (default: true)",
                        "default": True
                    }
                },
                "required": []
            }
        ),
        Tool(
            name="boot_ios_simulator",
            description="Boot an iOS Simulator by device name. Opens the Simulator app and boots the specified device. Useful before running iOS apps.",
            inputSchema={
                "type": "object",
                "properties": {
                    "device_name": {
                        "type": "string",
                        "description": "Device name to boot (e.g., 'iPhone 15', 'iPad Pro'). Default: 'iPhone 15'",
                        "default": "iPhone 15"
                    }
                },
                "required": []
            }
        ),
        Tool(
            name="build_ios_project",
            description="Build an iOS/SwiftUI project for the iOS Simulator using xcodebuild. Automatically detects .xcodeproj/.xcworkspace and builds with code signing disabled for simulator.",
            inputSchema={
                "type": "object",
                "properties": {
                    "project_path": {
                        "type": "string",
                        "description": "Absolute path to the iOS project directory"
                    },
                    "scheme": {
                        "type": "string",
                        "description": "Xcode scheme to build (auto-detected if not provided)"
                    },
                    "configuration": {
                        "type": "string",
                        "description": "Build configuration (default: Debug)",
                        "default": "Debug"
                    },
                    "simulator_device": {
                        "type": "string",
                        "description": "Target simulator device name (default: iPhone 15)",
                        "default": "iPhone 15"
                    }
                },
                "required": ["project_path"]
            }
        ),
        Tool(
            name="run_ios_app",
            description="Build and run an iOS app in the Simulator. Builds the project, installs the app on the simulator, and launches it.",
            inputSchema={
                "type": "object",
                "properties": {
                    "project_path": {
                        "type": "string",
                        "description": "Absolute path to the iOS project directory"
                    },
                    "scheme": {
                        "type": "string",
                        "description": "Xcode scheme to build (auto-detected if not provided)"
                    },
                    "simulator_device": {
                        "type": "string",
                        "description": "Target simulator device name (default: iPhone 15)",
                        "default": "iPhone 15"
                    },
                    "boot_simulator": {
                        "type": "boolean",
                        "description": "Boot simulator if not running (default: true)",
                        "default": True
                    }
                },
                "required": ["project_path"]
            }
        ),
        Tool(
            name="test_ios_project",
            description="Run XCTest tests for an iOS project. Uses xcodebuild test to run unit tests and UI tests in the simulator.",
            inputSchema={
                "type": "object",
                "properties": {
                    "project_path": {
                        "type": "string",
                        "description": "Absolute path to the iOS project directory"
                    },
                    "scheme": {
                        "type": "string",
                        "description": "Xcode scheme to test (auto-detected if not provided)"
                    },
                    "simulator_device": {
                        "type": "string",
                        "description": "Target simulator device name (default: iPhone 15)",
                        "default": "iPhone 15"
                    }
                },
                "required": ["project_path"]
            }
        ),
        Tool(
            name="take_simulator_screenshot",
            description="Capture a screenshot from the running iOS Simulator. Useful for documenting app states or debugging UI issues.",
            inputSchema={
                "type": "object",
                "properties": {
                    "output_path": {
                        "type": "string",
                        "description": "Path to save the screenshot (default: ./screenshot.png)",
                        "default": "./screenshot.png"
                    }
                },
                "required": []
            }
        ),
        Tool(
            name="reset_ios_simulator",
            description="Reset/erase an iOS Simulator to factory state. Removes all installed apps and data. Useful for clean test environments.",
            inputSchema={
                "type": "object",
                "properties": {
                    "device_name": {
                        "type": "string",
                        "description": "Device name to reset. If not provided, resets the booted simulator."
                    }
                },
                "required": []
            }
        ),
    ]


# ============================================================================
# Tool Handlers
# ============================================================================

@app.call_tool()
async def call_tool(name: str, arguments: dict[str, Any]) -> list[TextContent]:
    """Handle tool calls from MCP clients."""
    logger.info(f"Tool called: {name}")
    logger.debug(f"Tool arguments: {arguments}")
    
    try:
        # Original tools
        if name == "orchestrate_task":
            return await handle_orchestrate_task(arguments)
        elif name == "analyze_task":
            return await handle_analyze_task(arguments)
        elif name == "check_status":
            return await handle_check_status()
        elif name == "route_to_model":
            return await handle_route_to_model(arguments)
        elif name == "get_available_models":
            return await handle_get_available_models()
        
        # New execution tools
        elif name == "run_project":
            return await handle_run_project(arguments)
        elif name == "test_project":
            return await handle_test_project(arguments)
        elif name == "analyze_errors":
            return await handle_analyze_errors(arguments)
        elif name == "fix_issues":
            return await handle_fix_issues(arguments)
        elif name == "verify_project":
            return await handle_verify_project(arguments)
        elif name == "orchestrate_full_development":
            return await handle_orchestrate_full_development(arguments)
        
        # iOS-specific tools
        elif name == "list_ios_simulators":
            return await handle_list_ios_simulators(arguments)
        elif name == "boot_ios_simulator":
            return await handle_boot_ios_simulator(arguments)
        elif name == "build_ios_project":
            return await handle_build_ios_project(arguments)
        elif name == "run_ios_app":
            return await handle_run_ios_app(arguments)
        elif name == "test_ios_project":
            return await handle_test_ios_project(arguments)
        elif name == "take_simulator_screenshot":
            return await handle_take_simulator_screenshot(arguments)
        elif name == "reset_ios_simulator":
            return await handle_reset_ios_simulator(arguments)
        
        else:
            return [TextContent(
                type="text",
                text=json.dumps({"error": f"Unknown tool: {name}"}, indent=2)
            )]
    except Exception as e:
        import traceback
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": str(e),
                "error_type": type(e).__name__,
                "traceback": traceback.format_exc()
            }, indent=2)
        )]


# ============================================================================
# Original Tool Handlers
# ============================================================================

async def handle_orchestrate_task(arguments: dict[str, Any]) -> list[TextContent]:
    """Handle the orchestrate_task tool call."""
    task = arguments.get("task")
    if not task:
        return [TextContent(
            type="text",
            text=json.dumps({"error": "Missing required parameter: task"}, indent=2)
        )]
    
    orchestrator = get_orchestrator()
    
    # Execute the task (run in thread pool to avoid blocking)
    loop = asyncio.get_event_loop()
    result = await loop.run_in_executor(
        None,
        lambda: orchestrator.execute(task, verbose=False)
    )
    
    formatted_result = format_orchestration_result(result)
    
    return [TextContent(
        type="text",
        text=json.dumps(formatted_result, indent=2)
    )]


async def handle_analyze_task(arguments: dict[str, Any]) -> list[TextContent]:
    """Handle the analyze_task tool call."""
    task = arguments.get("task")
    if not task:
        return [TextContent(
            type="text",
            text=json.dumps({"error": "Missing required parameter: task"}, indent=2)
        )]
    
    config = get_config()
    router = TaskRouter(config.get_available_models())
    
    try:
        subtasks = router.analyze_and_route(task)
        
        response = {
            "task": task,
            "detected_task_types": [st.task_type.value for st in subtasks],
            "routing_plan": [format_subtask(st) for st in subtasks],
            "models_to_be_used": list(set(st.target_model.value for st in subtasks)),
            "estimated_steps": len(subtasks)
        }
        
        return [TextContent(
            type="text",
            text=json.dumps(response, indent=2)
        )]
    except ValueError as e:
        return [TextContent(
            type="text",
            text=json.dumps({"error": str(e)}, indent=2)
        )]


async def handle_check_status() -> list[TextContent]:
    """Handle the check_status tool call."""
    config = get_config()
    available = config.get_available_models()
    
    status = {
        "status": "operational" if available else "no_models_configured",
        "available_models": available,
        "model_configurations": {
            "openai": {
                "configured": bool(config.openai_api_key),
                "model": config.models.openai_model
            },
            "anthropic": {
                "configured": bool(config.anthropic_api_key),
                "model": config.models.anthropic_model
            },
            "gemini": {
                "configured": bool(config.gemini_api_key),
                "model": config.models.gemini_model
            },
            "moonshot": {
                "configured": bool(config.moonshot_api_key),
                "model": config.models.moonshot_model
            }
        },
        "execution_config": {
            "max_verification_cycles": config.auto_fix.max_verification_cycles if hasattr(config, 'auto_fix') else 10,
            "fix_confidence_threshold": config.auto_fix.fix_confidence_threshold if hasattr(config, 'auto_fix') else 0.7,
        },
        "total_available": len(available),
        "env_file_path": str(Path(__file__).parent.parent / ".env")
    }
    
    return [TextContent(
        type="text",
        text=json.dumps(status, indent=2)
    )]


async def handle_route_to_model(arguments: dict[str, Any]) -> list[TextContent]:
    """Handle the route_to_model tool call."""
    task = arguments.get("task")
    model = arguments.get("model")
    
    if not task:
        return [TextContent(
            type="text",
            text=json.dumps({"error": "Missing required parameter: task"}, indent=2)
        )]
    
    if not model:
        return [TextContent(
            type="text",
            text=json.dumps({"error": "Missing required parameter: model"}, indent=2)
        )]
    
    # Validate model
    valid_models = ["openai", "anthropic", "gemini", "moonshot"]
    if model not in valid_models:
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": f"Invalid model: {model}. Must be one of: {valid_models}"
            }, indent=2)
        )]
    
    config = get_config()
    orchestrator = get_orchestrator()
    
    # Check if model is available
    if model not in config.get_available_models():
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": f"Model '{model}' is not available. API key not configured.",
                "available_models": config.get_available_models()
            }, indent=2)
        )]
    
    # Get the client and execute
    provider = ModelProvider(model)
    client = orchestrator.clients.get(provider)
    
    if not client:
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": f"Could not get client for model: {model}"
            }, indent=2)
        )]
    
    # Execute the task
    loop = asyncio.get_event_loop()
    response = await loop.run_in_executor(
        None,
        lambda: client.complete_sync(task, None)
    )
    
    result = {
        "success": response.success,
        "model_name": response.model_name,
        "model_provider": response.model_provider,
        "content": response.content,
        "error": response.error,
        "tokens_used": response.tokens_used
    }
    
    return [TextContent(
        type="text",
        text=json.dumps(result, indent=2)
    )]


async def handle_get_available_models() -> list[TextContent]:
    """Handle the get_available_models tool call."""
    config = get_config()
    
    models = []
    for provider in ModelProvider:
        models.append(format_model_info(provider, config))
    
    response = {
        "models": models,
        "available_count": len(config.get_available_models()),
        "total_count": len(ModelProvider)
    }
    
    return [TextContent(
        type="text",
        text=json.dumps(response, indent=2)
    )]


# ============================================================================
# New Execution Tool Handlers
# ============================================================================

async def handle_run_project(arguments: dict[str, Any]) -> list[TextContent]:
    """Handle the run_project tool call."""
    project_path = arguments.get("project_path")
    if not project_path:
        return [TextContent(
            type="text",
            text=json.dumps({"error": "Missing required parameter: project_path"}, indent=2)
        )]
    
    project_path = Path(project_path)
    if not project_path.exists():
        return [TextContent(
            type="text",
            text=json.dumps({"error": f"Project path does not exist: {project_path}"}, indent=2)
        )]
    
    setup = arguments.get("setup_dependencies", True)
    command = arguments.get("command")
    timeout = arguments.get("timeout", 300)
    
    config = get_config()
    runner = ProjectRunner(
        timeout=timeout,
        setup_timeout=config.execution.setup_timeout,
        max_retries=config.execution.max_retry_attempts,
    )
    
    # Run in thread pool to avoid blocking
    loop = asyncio.get_event_loop()
    
    try:
        result = await loop.run_in_executor(
            None,
            lambda: runner.run_project(
                project_path,
                setup=setup,
                command=command,
            )
        )
        
        formatted_result = format_execution_result(result)
        formatted_result["tool"] = "run_project"
        
        return [TextContent(
            type="text",
            text=json.dumps(formatted_result, indent=2)
        )]
    except Exception as e:
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": str(e),
                "error_type": type(e).__name__,
                "project_path": str(project_path)
            }, indent=2)
        )]


async def handle_test_project(arguments: dict[str, Any]) -> list[TextContent]:
    """Handle the test_project tool call."""
    project_path = arguments.get("project_path")
    if not project_path:
        return [TextContent(
            type="text",
            text=json.dumps({"error": "Missing required parameter: project_path"}, indent=2)
        )]
    
    project_path = Path(project_path)
    if not project_path.exists():
        return [TextContent(
            type="text",
            text=json.dumps({"error": f"Project path does not exist: {project_path}"}, indent=2)
        )]
    
    test_command = arguments.get("test_command")
    timeout = arguments.get("timeout", 180)
    
    config = get_config()
    test_executor = TestExecutor(timeout=timeout)
    
    # Run in thread pool
    loop = asyncio.get_event_loop()
    
    try:
        result = await loop.run_in_executor(
            None,
            lambda: test_executor.run_tests(project_path, command=test_command)
        )
        
        formatted_result = format_test_result(result)
        formatted_result["tool"] = "test_project"
        formatted_result["project_path"] = str(project_path)
        
        return [TextContent(
            type="text",
            text=json.dumps(formatted_result, indent=2)
        )]
    except Exception as e:
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": str(e),
                "error_type": type(e).__name__,
                "project_path": str(project_path)
            }, indent=2)
        )]


async def handle_analyze_errors(arguments: dict[str, Any]) -> list[TextContent]:
    """Handle the analyze_errors tool call."""
    project_path = arguments.get("project_path")
    if not project_path:
        return [TextContent(
            type="text",
            text=json.dumps({"error": "Missing required parameter: project_path"}, indent=2)
        )]
    
    project_path = Path(project_path)
    if not project_path.exists():
        return [TextContent(
            type="text",
            text=json.dumps({"error": f"Project path does not exist: {project_path}"}, indent=2)
        )]
    
    error_logs = arguments.get("error_logs")
    use_ai = arguments.get("use_ai", True)
    
    config = get_config()
    error_detector = ErrorDetector()
    
    loop = asyncio.get_event_loop()
    
    try:
        # If no error logs provided, run the project to get them
        if not error_logs:
            runner = ProjectRunner(timeout=60)
            exec_result = await loop.run_in_executor(
                None,
                lambda: runner.run_project(project_path, setup=False)
            )
            error_logs = exec_result.stderr + "\n" + exec_result.stdout
            detected_errors = exec_result.errors
        else:
            # Parse provided error logs
            detected_errors = await loop.run_in_executor(
                None,
                lambda: error_detector.parse_error_logs(error_logs, str(project_path))
            )
        
        # Format basic error detection
        response = {
            "tool": "analyze_errors",
            "project_path": str(project_path),
            "errors_detected": len(detected_errors),
            "errors": [format_detected_error(e) for e in detected_errors],
            "categories": {},
            "ai_analysis": None
        }
        
        # Categorize errors
        for error in detected_errors:
            cat = error.category.value if hasattr(error.category, 'value') else str(error.category)
            if cat not in response["categories"]:
                response["categories"][cat] = 0
            response["categories"][cat] += 1
        
        # AI analysis if requested and available
        if use_ai and detected_errors:
            auto_fixer = AutoFixer(
                config=config,
                max_attempts=1,
                confidence_threshold=0.5,
            )
            
            ai_analyses = []
            for error in detected_errors[:5]:  # Limit to first 5 errors
                try:
                    analysis = await loop.run_in_executor(
                        None,
                        lambda e=error: auto_fixer.analyze_error(e, str(project_path))
                    )
                    if analysis:
                        ai_analyses.append(format_error_analysis(analysis))
                except Exception as e:
                    ai_analyses.append({"error": str(e)})
            
            response["ai_analysis"] = ai_analyses
        
        return [TextContent(
            type="text",
            text=json.dumps(response, indent=2)
        )]
    except Exception as e:
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": str(e),
                "error_type": type(e).__name__,
                "project_path": str(project_path)
            }, indent=2)
        )]


async def handle_fix_issues(arguments: dict[str, Any]) -> list[TextContent]:
    """Handle the fix_issues tool call."""
    project_path = arguments.get("project_path")
    if not project_path:
        return [TextContent(
            type="text",
            text=json.dumps({"error": "Missing required parameter: project_path"}, indent=2)
        )]
    
    project_path = Path(project_path)
    if not project_path.exists():
        return [TextContent(
            type="text",
            text=json.dumps({"error": f"Project path does not exist: {project_path}"}, indent=2)
        )]
    
    error_messages = arguments.get("errors", [])
    auto_apply = arguments.get("auto_apply", False)
    max_attempts = arguments.get("max_attempts", 3)
    
    config = get_config()
    error_detector = ErrorDetector()
    auto_fixer = AutoFixer(
        config=config,
        backup_dir=project_path / ".auto_fixer_backups",
        max_attempts=max_attempts,
        confidence_threshold=config.auto_fix.fix_confidence_threshold if hasattr(config, 'auto_fix') else 0.7,
        enable_backup=True,
        validate_fixes=True,
    )
    
    loop = asyncio.get_event_loop()
    
    try:
        # Get errors - either from provided messages or by running the project
        if error_messages:
            detected_errors = []
            for msg in error_messages:
                errors = await loop.run_in_executor(
                    None,
                    lambda m=msg: error_detector.parse_error_logs(m, str(project_path))
                )
                detected_errors.extend(errors)
        else:
            runner = ProjectRunner(timeout=60)
            exec_result = await loop.run_in_executor(
                None,
                lambda: runner.run_project(project_path, setup=False)
            )
            detected_errors = exec_result.errors
        
        if not detected_errors:
            return [TextContent(
                type="text",
                text=json.dumps({
                    "tool": "fix_issues",
                    "project_path": str(project_path),
                    "message": "No errors detected - project appears to be working",
                    "fixes_generated": 0,
                    "fixes_applied": 0
                }, indent=2)
            )]
        
        # Generate and optionally apply fixes
        fixes_generated = []
        fixes_applied = []
        
        for error in detected_errors[:5]:  # Limit to first 5 errors
            try:
                # Generate fix
                fix = await loop.run_in_executor(
                    None,
                    lambda e=error: auto_fixer.generate_fix(e, str(project_path))
                )
                
                if fix:
                    fix_info = format_generated_fix(fix)
                    fix_info["error_message"] = error.message
                    fixes_generated.append(fix_info)
                    
                    # Apply fix if requested
                    if auto_apply and fix.confidence >= auto_fixer.confidence_threshold:
                        attempt = await loop.run_in_executor(
                            None,
                            lambda f=fix: auto_fixer.apply_fix(f, str(project_path))
                        )
                        if attempt and attempt.result and attempt.result.success:
                            fixes_applied.append(format_fix_attempt(attempt))
            except Exception as e:
                fixes_generated.append({
                    "error": str(e),
                    "error_message": error.message
                })
        
        response = {
            "tool": "fix_issues",
            "project_path": str(project_path),
            "errors_found": len(detected_errors),
            "fixes_generated": len(fixes_generated),
            "fixes_applied": len(fixes_applied),
            "auto_apply_enabled": auto_apply,
            "generated_fixes": fixes_generated,
            "applied_fixes": fixes_applied if auto_apply else None,
            "recommendation": "Review generated fixes and apply manually" if not auto_apply else "Fixes have been applied - run project to verify"
        }
        
        return [TextContent(
            type="text",
            text=json.dumps(response, indent=2)
        )]
    except Exception as e:
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": str(e),
                "error_type": type(e).__name__,
                "project_path": str(project_path)
            }, indent=2)
        )]


async def handle_verify_project(arguments: dict[str, Any]) -> list[TextContent]:
    """Handle the verify_project tool call."""
    project_path = arguments.get("project_path")
    if not project_path:
        return [TextContent(
            type="text",
            text=json.dumps({"error": "Missing required parameter: project_path"}, indent=2)
        )]
    
    project_path = Path(project_path)
    if not project_path.exists():
        return [TextContent(
            type="text",
            text=json.dumps({"error": f"Project path does not exist: {project_path}"}, indent=2)
        )]
    
    max_cycles = arguments.get("max_cycles", 10)
    run_tests = arguments.get("run_tests", True)
    auto_fix = arguments.get("auto_fix", True)
    setup_first = arguments.get("setup_first", True)
    
    config = get_config()
    
    verification_loop = VerificationLoop(
        config=config,
        project_path=project_path,
        max_cycles=max_cycles,
        max_same_error_attempts=config.auto_fix.max_same_error_attempts if hasattr(config, 'auto_fix') else 3,
        run_tests=run_tests,
        auto_fix=auto_fix,
        confidence_threshold=config.auto_fix.fix_confidence_threshold if hasattr(config, 'auto_fix') else 0.7,
    )
    
    loop = asyncio.get_event_loop()
    
    try:
        report = await loop.run_in_executor(
            None,
            lambda: verification_loop.run_development_cycle(setup=setup_first)
        )
        
        formatted_report = format_loop_report(report)
        formatted_report["tool"] = "verify_project"
        formatted_report["project_path"] = str(project_path)
        
        return [TextContent(
            type="text",
            text=json.dumps(formatted_report, indent=2)
        )]
    except Exception as e:
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": str(e),
                "error_type": type(e).__name__,
                "project_path": str(project_path)
            }, indent=2)
        )]


async def handle_orchestrate_full_development(arguments: dict[str, Any]) -> list[TextContent]:
    """Handle the orchestrate_full_development tool call."""
    project_path = arguments.get("project_path")
    project_description = arguments.get("project_description")
    
    if not project_path:
        return [TextContent(
            type="text",
            text=json.dumps({"error": "Missing required parameter: project_path"}, indent=2)
        )]
    
    if not project_description:
        return [TextContent(
            type="text",
            text=json.dumps({"error": "Missing required parameter: project_description"}, indent=2)
        )]
    
    project_path = Path(project_path)
    
    # Create project directory if it doesn't exist
    project_path.mkdir(parents=True, exist_ok=True)
    
    requirements = arguments.get("requirements", [])
    run_project = arguments.get("run_project", True)
    run_tests = arguments.get("run_tests", True)
    auto_fix = arguments.get("auto_fix", True)
    
    # Build full task description
    full_description = project_description
    if requirements:
        full_description += "\n\nRequirements:\n" + "\n".join(f"- {r}" for r in requirements)
    
    orchestrator = get_orchestrator()
    loop = asyncio.get_event_loop()
    
    try:
        result = await loop.run_in_executor(
            None,
            lambda: orchestrator.orchestrate_project_development(
                project_path=str(project_path),
                task_description=full_description,
                run_project=run_project,
                run_tests=run_tests,
                auto_fix=auto_fix,
                verbose=False,
            )
        )
        
        formatted_result = format_development_result(result)
        formatted_result["tool"] = "orchestrate_full_development"
        
        return [TextContent(
            type="text",
            text=json.dumps(formatted_result, indent=2)
        )]
    except Exception as e:
        import traceback
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": str(e),
                "error_type": type(e).__name__,
                "project_path": str(project_path),
                "traceback": traceback.format_exc()
            }, indent=2)
        )]


# ============================================================================
# iOS Tool Handlers
# ============================================================================

async def handle_list_ios_simulators(arguments: dict[str, Any]) -> list[TextContent]:
    """Handle the list_ios_simulators tool call."""
    available_only = arguments.get("available_only", True)
    
    loop = asyncio.get_event_loop()
    
    try:
        config = get_config()
        sim_manager = iOSSimulatorManager(
            default_device=config.ios.ios_simulator_device,
            default_os=config.ios.ios_simulator_os,
        )
        
        simulators = await loop.run_in_executor(
            None,
            lambda: sim_manager.list_simulators(available_only=available_only)
        )
        
        response = {
            "tool": "list_ios_simulators",
            "total_simulators": len(simulators),
            "simulators": [
                {
                    "name": sim.name,
                    "udid": sim.udid,
                    "state": sim.state.value,
                    "os_version": sim.os_version,
                    "is_booted": sim.is_booted,
                }
                for sim in simulators
            ]
        }
        
        return [TextContent(
            type="text",
            text=json.dumps(response, indent=2)
        )]
    except Exception as e:
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": str(e),
                "error_type": type(e).__name__,
                "message": "Failed to list simulators. Is Xcode installed?"
            }, indent=2)
        )]


async def handle_boot_ios_simulator(arguments: dict[str, Any]) -> list[TextContent]:
    """Handle the boot_ios_simulator tool call."""
    device_name = arguments.get("device_name", "iPhone 15")
    
    loop = asyncio.get_event_loop()
    
    try:
        config = get_config()
        sim_manager = iOSSimulatorManager(
            default_device=config.ios.ios_simulator_device,
            default_os=config.ios.ios_simulator_os,
        )
        
        result = await loop.run_in_executor(
            None,
            lambda: sim_manager.boot_simulator(device_name=device_name)
        )
        
        response = {
            "tool": "boot_ios_simulator",
            "success": result.success,
            "message": result.message,
            "device_name": device_name,
            "simulator": {
                "name": result.simulator.name,
                "udid": result.simulator.udid,
                "state": result.simulator.state.value,
            } if result.simulator else None,
        }
        
        return [TextContent(
            type="text",
            text=json.dumps(response, indent=2)
        )]
    except Exception as e:
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": str(e),
                "error_type": type(e).__name__,
                "device_name": device_name,
            }, indent=2)
        )]


async def handle_build_ios_project(arguments: dict[str, Any]) -> list[TextContent]:
    """Handle the build_ios_project tool call."""
    project_path = arguments.get("project_path")
    if not project_path:
        return [TextContent(
            type="text",
            text=json.dumps({"error": "Missing required parameter: project_path"}, indent=2)
        )]
    
    project_path = Path(project_path)
    if not project_path.exists():
        return [TextContent(
            type="text",
            text=json.dumps({"error": f"Project path does not exist: {project_path}"}, indent=2)
        )]
    
    scheme = arguments.get("scheme")
    configuration = arguments.get("configuration", "Debug")
    simulator_device = arguments.get("simulator_device", "iPhone 15")
    
    loop = asyncio.get_event_loop()
    
    try:
        config = get_config()
        sim_manager = iOSSimulatorManager(
            default_device=simulator_device,
            default_os=config.ios.ios_simulator_os,
        )
        builder = iOSProjectBuilder(
            simulator_manager=sim_manager,
            build_timeout=config.ios.xcode_build_timeout,
        )
        
        # Find simulator
        simulator = await loop.run_in_executor(
            None,
            lambda: sim_manager.find_simulator(device_name=simulator_device)
        )
        
        # Build
        result = await loop.run_in_executor(
            None,
            lambda: builder.build_for_simulator(
                project_path=project_path,
                scheme=scheme,
                simulator=simulator,
                configuration=configuration,
            )
        )
        
        response = {
            "tool": "build_ios_project",
            "success": result.success,
            "project_path": str(project_path),
            "message": result.message,
            "duration_seconds": round(result.duration, 2),
            "app_path": result.app_path,
            "build_dir": result.build_dir,
            "output": truncate_output(result.output, 5000) if result.output else None,
            "error": truncate_output(result.error, 3000) if result.error else None,
        }
        
        return [TextContent(
            type="text",
            text=json.dumps(response, indent=2)
        )]
    except Exception as e:
        import traceback
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": str(e),
                "error_type": type(e).__name__,
                "project_path": str(project_path),
                "traceback": traceback.format_exc(),
            }, indent=2)
        )]


async def handle_run_ios_app(arguments: dict[str, Any]) -> list[TextContent]:
    """Handle the run_ios_app tool call."""
    project_path = arguments.get("project_path")
    if not project_path:
        return [TextContent(
            type="text",
            text=json.dumps({"error": "Missing required parameter: project_path"}, indent=2)
        )]
    
    project_path = Path(project_path)
    if not project_path.exists():
        return [TextContent(
            type="text",
            text=json.dumps({"error": f"Project path does not exist: {project_path}"}, indent=2)
        )]
    
    scheme = arguments.get("scheme")
    simulator_device = arguments.get("simulator_device", "iPhone 15")
    should_boot_simulator = arguments.get("boot_simulator", True)
    
    loop = asyncio.get_event_loop()
    
    try:
        config = get_config()
        sim_manager = iOSSimulatorManager(
            default_device=simulator_device,
            default_os=config.ios.ios_simulator_os,
        )
        builder = iOSProjectBuilder(
            simulator_manager=sim_manager,
            build_timeout=config.ios.xcode_build_timeout,
        )
        
        # Boot simulator if needed
        if should_boot_simulator:
            boot_result = await loop.run_in_executor(
                None,
                lambda: sim_manager.boot_simulator(device_name=simulator_device)
            )
            if not boot_result.success:
                return [TextContent(
                    type="text",
                    text=json.dumps({
                        "error": f"Failed to boot simulator: {boot_result.message}",
                        "tool": "run_ios_app",
                    }, indent=2)
                )]
        
        # Find simulator
        simulator = await loop.run_in_executor(
            None,
            lambda: sim_manager.find_simulator(device_name=simulator_device)
        )
        
        # Build
        build_result = await loop.run_in_executor(
            None,
            lambda: builder.build_for_simulator(
                project_path=project_path,
                scheme=scheme,
                simulator=simulator,
            )
        )
        
        if not build_result.success:
            return [TextContent(
                type="text",
                text=json.dumps({
                    "tool": "run_ios_app",
                    "success": False,
                    "phase": "build",
                    "message": build_result.message,
                    "error": truncate_output(build_result.error, 3000) if build_result.error else None,
                }, indent=2)
            )]
        
        # Install and launch
        if build_result.app_path:
            install_result = await loop.run_in_executor(
                None,
                lambda: sim_manager.install_app(build_result.app_path, simulator)
            )
            
            if install_result.success and install_result.bundle_id:
                launch_result = await loop.run_in_executor(
                    None,
                    lambda: sim_manager.launch_app(install_result.bundle_id, simulator)
                )
                
                return [TextContent(
                    type="text",
                    text=json.dumps({
                        "tool": "run_ios_app",
                        "success": launch_result.success,
                        "project_path": str(project_path),
                        "app_path": build_result.app_path,
                        "bundle_id": install_result.bundle_id,
                        "simulator": {
                            "name": simulator.name if simulator else None,
                            "udid": simulator.udid if simulator else None,
                        },
                        "message": launch_result.message,
                    }, indent=2)
                )]
        
        return [TextContent(
            type="text",
            text=json.dumps({
                "tool": "run_ios_app",
                "success": True,
                "message": "Build succeeded but could not find app bundle to install",
                "build_result": build_result.message,
            }, indent=2)
        )]
    except Exception as e:
        import traceback
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": str(e),
                "error_type": type(e).__name__,
                "project_path": str(project_path),
                "traceback": traceback.format_exc(),
            }, indent=2)
        )]


async def handle_test_ios_project(arguments: dict[str, Any]) -> list[TextContent]:
    """Handle the test_ios_project tool call."""
    project_path = arguments.get("project_path")
    if not project_path:
        return [TextContent(
            type="text",
            text=json.dumps({"error": "Missing required parameter: project_path"}, indent=2)
        )]
    
    project_path = Path(project_path)
    if not project_path.exists():
        return [TextContent(
            type="text",
            text=json.dumps({"error": f"Project path does not exist: {project_path}"}, indent=2)
        )]
    
    scheme = arguments.get("scheme")
    simulator_device = arguments.get("simulator_device", "iPhone 15")
    
    loop = asyncio.get_event_loop()
    
    try:
        config = get_config()
        sim_manager = iOSSimulatorManager(
            default_device=simulator_device,
            default_os=config.ios.ios_simulator_os,
        )
        builder = iOSProjectBuilder(
            simulator_manager=sim_manager,
            build_timeout=config.ios.xcode_test_timeout,
        )
        
        # Find simulator
        simulator = await loop.run_in_executor(
            None,
            lambda: sim_manager.find_simulator(device_name=simulator_device)
        )
        
        # Run tests
        result = await loop.run_in_executor(
            None,
            lambda: builder.run_tests(
                project_path=project_path,
                scheme=scheme,
                simulator=simulator,
            )
        )
        
        response = {
            "tool": "test_ios_project",
            "success": result.success,
            "project_path": str(project_path),
            "message": result.message,
            "duration_seconds": round(result.duration, 2),
            "output": truncate_output(result.output, 5000) if result.output else None,
            "error": truncate_output(result.error, 3000) if result.error else None,
        }
        
        return [TextContent(
            type="text",
            text=json.dumps(response, indent=2)
        )]
    except Exception as e:
        import traceback
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": str(e),
                "error_type": type(e).__name__,
                "project_path": str(project_path),
                "traceback": traceback.format_exc(),
            }, indent=2)
        )]


async def handle_take_simulator_screenshot(arguments: dict[str, Any]) -> list[TextContent]:
    """Handle the take_simulator_screenshot tool call."""
    output_path = arguments.get("output_path", "./screenshot.png")
    
    loop = asyncio.get_event_loop()
    
    try:
        config = get_config()
        sim_manager = iOSSimulatorManager(
            default_device=config.ios.ios_simulator_device,
            default_os=config.ios.ios_simulator_os,
        )
        
        result = await loop.run_in_executor(
            None,
            lambda: sim_manager.take_screenshot(output_path)
        )
        
        response = {
            "tool": "take_simulator_screenshot",
            "success": result.success,
            "message": result.message,
            "screenshot_path": result.data.get("screenshot_path") if result.success else None,
            "simulator": {
                "name": result.simulator.name,
                "udid": result.simulator.udid,
            } if result.simulator else None,
        }
        
        return [TextContent(
            type="text",
            text=json.dumps(response, indent=2)
        )]
    except Exception as e:
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": str(e),
                "error_type": type(e).__name__,
            }, indent=2)
        )]


async def handle_reset_ios_simulator(arguments: dict[str, Any]) -> list[TextContent]:
    """Handle the reset_ios_simulator tool call."""
    device_name = arguments.get("device_name")
    
    loop = asyncio.get_event_loop()
    
    try:
        config = get_config()
        sim_manager = iOSSimulatorManager(
            default_device=config.ios.ios_simulator_device,
            default_os=config.ios.ios_simulator_os,
        )
        
        # Find simulator
        simulator = None
        if device_name:
            simulator = await loop.run_in_executor(
                None,
                lambda: sim_manager.find_simulator(device_name=device_name)
            )
        else:
            simulator = await loop.run_in_executor(
                None,
                sim_manager.get_booted_simulator
            )
        
        if not simulator:
            return [TextContent(
                type="text",
                text=json.dumps({
                    "tool": "reset_ios_simulator",
                    "success": False,
                    "message": "No simulator found to reset",
                }, indent=2)
            )]
        
        result = await loop.run_in_executor(
            None,
            lambda: sim_manager.erase_simulator(simulator)
        )
        
        response = {
            "tool": "reset_ios_simulator",
            "success": result.success,
            "message": result.message,
            "simulator": {
                "name": simulator.name,
                "udid": simulator.udid,
            },
        }
        
        return [TextContent(
            type="text",
            text=json.dumps(response, indent=2)
        )]
    except Exception as e:
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": str(e),
                "error_type": type(e).__name__,
            }, indent=2)
        )]


# ============================================================================
# Main Entry Point
# ============================================================================

async def main():
    """Main entry point for the MCP server."""
    logger.info("Starting MCP stdio server...")
    
    try:
        # Log environment info
        env_path = Path(__file__).parent.parent / ".env"
        logger.info(f".env file exists: {env_path.exists()}")
        
        config = get_config()
        available_models = config.get_available_models()
        logger.info(f"Available models: {available_models}")
        logger.info(f"Total tools registered: {len(await list_tools())}")
        
        async with stdio_server() as (read_stream, write_stream):
            logger.info("MCP server running - waiting for connections...")
            await app.run(
                read_stream,
                write_stream,
                app.create_initialization_options()
            )
    except Exception as e:
        logger.exception(f"Fatal error in MCP server: {e}")
        raise
    finally:
        logger.info("MCP server shutting down")


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("MCP server interrupted by user")
    except Exception as e:
        logger.exception(f"MCP server crashed: {e}")
        sys.exit(1)
