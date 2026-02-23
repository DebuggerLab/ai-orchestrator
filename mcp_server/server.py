#!/usr/bin/env python3
"""
MCP Server for AI Orchestrator

This server exposes the AI Orchestrator functionality via the Model Context Protocol (MCP),
allowing integration with Cursor IDE and other MCP-compatible tools.
"""

import asyncio
import json
import sys
import os
from pathlib import Path
from typing import Any, Optional

# Add parent directory to path for importing ai_orchestrator modules
sys.path.insert(0, str(Path(__file__).parent.parent))

from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import (
    Tool,
    TextContent,
    INVALID_PARAMS,
    INTERNAL_ERROR,
)

from ai_orchestrator.config import Config
from ai_orchestrator.orchestrator import Orchestrator, OrchestrationResult
from ai_orchestrator.router import TaskRouter, ModelProvider, SubTask
from ai_orchestrator.models.base import TaskType


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


@app.list_tools()
async def list_tools() -> list[Tool]:
    """List available tools for the MCP server."""
    return [
        Tool(
            name="orchestrate_task",
            description="Orchestrate a task across multiple AI models. The orchestrator will analyze the task, route it to the most appropriate model(s), and return consolidated results.",
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
            description="Analyze how a task would be routed without actually executing it. Returns the routing plan with target models and subtasks.",
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
            description="Check the configuration status and model availability of the AI orchestrator.",
            inputSchema={
                "type": "object",
                "properties": {},
                "required": []
            }
        ),
        Tool(
            name="route_to_model",
            description="Route a specific task directly to a specific AI model, bypassing automatic routing.",
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
        )
    ]


@app.call_tool()
async def call_tool(name: str, arguments: dict[str, Any]) -> list[TextContent]:
    """Handle tool calls from MCP clients."""
    
    try:
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
        else:
            return [TextContent(
                type="text",
                text=json.dumps({"error": f"Unknown tool: {name}"}, indent=2)
            )]
    except Exception as e:
        return [TextContent(
            type="text",
            text=json.dumps({
                "error": str(e),
                "error_type": type(e).__name__
            }, indent=2)
        )]


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


async def main():
    """Main entry point for the MCP server."""
    async with stdio_server() as (read_stream, write_stream):
        await app.run(
            read_stream,
            write_stream,
            app.create_initialization_options()
        )


if __name__ == "__main__":
    asyncio.run(main())
