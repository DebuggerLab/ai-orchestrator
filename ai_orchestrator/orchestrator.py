"""Main orchestrator for AI task distribution."""

from typing import Optional
from dataclasses import dataclass, field
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.table import Table
from rich.markdown import Markdown

from .config import Config
from .router import TaskRouter, SubTask, ModelProvider
from .models import (
    OpenAIClient,
    AnthropicClient,
    GeminiClient,
    MoonshotClient,
    ModelResponse,
)


@dataclass
class OrchestrationResult:
    """Result of orchestrated task execution."""
    original_task: str
    subtask_results: list[tuple[SubTask, ModelResponse]] = field(default_factory=list)
    consolidated_output: str = ""
    success: bool = True
    errors: list[str] = field(default_factory=list)


class Orchestrator:
    """Main orchestrator that coordinates AI models."""
    
    def __init__(self, config: Config):
        self.config = config
        self.console = Console()
        self.clients = {}
        self._initialize_clients()
        self.router = TaskRouter(config.get_available_models())
    
    def _initialize_clients(self):
        """Initialize available AI clients."""
        if self.config.openai_api_key:
            try:
                self.clients[ModelProvider.OPENAI] = OpenAIClient(
                    self.config.openai_api_key,
                    self.config.models.openai_model
                )
            except Exception as e:
                self.console.print(f"[yellow]Warning: Could not initialize OpenAI client: {e}[/yellow]")
        
        if self.config.anthropic_api_key:
            try:
                self.clients[ModelProvider.ANTHROPIC] = AnthropicClient(
                    self.config.anthropic_api_key,
                    self.config.models.anthropic_model
                )
            except Exception as e:
                self.console.print(f"[yellow]Warning: Could not initialize Anthropic client: {e}[/yellow]")
        
        if self.config.gemini_api_key:
            try:
                self.clients[ModelProvider.GEMINI] = GeminiClient(
                    self.config.gemini_api_key,
                    self.config.models.gemini_model
                )
            except Exception as e:
                self.console.print(f"[yellow]Warning: Could not initialize Gemini client: {e}[/yellow]")
        
        if self.config.moonshot_api_key:
            try:
                self.clients[ModelProvider.MOONSHOT] = MoonshotClient(
                    self.config.moonshot_api_key,
                    self.config.models.moonshot_model
                )
            except Exception as e:
                self.console.print(f"[yellow]Warning: Could not initialize Moonshot client: {e}[/yellow]")
    
    def execute(self, task_description: str, verbose: bool = True) -> OrchestrationResult:
        """Execute a task by routing to appropriate AI models."""
        result = OrchestrationResult(original_task=task_description)
        
        if not self.clients:
            result.success = False
            result.errors.append("No AI models available. Please configure at least one API key in .env file.")
            return result
        
        # Analyze and route the task
        if verbose:
            self.console.print(Panel("[bold blue]AI Orchestrator[/bold blue] - Analyzing task...", border_style="blue"))
        
        try:
            subtasks = self.router.analyze_and_route(task_description)
        except ValueError as e:
            result.success = False
            result.errors.append(str(e))
            return result
        
        if verbose:
            self._display_routing_plan(subtasks)
        
        # Execute each subtask
        with Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=self.console,
            disable=not verbose
        ) as progress:
            for subtask in subtasks:
                task_progress = progress.add_task(
                    f"Processing: {subtask.description} ({subtask.target_model.value})...",
                    total=None
                )
                
                response = self._execute_subtask(subtask)
                result.subtask_results.append((subtask, response))
                
                if not response.success:
                    result.errors.append(f"[{subtask.target_model.value}] {response.error}")
                
                progress.remove_task(task_progress)
        
        # Consolidate results
        result.consolidated_output = self._consolidate_results(result.subtask_results)
        result.success = len(result.errors) == 0 or any(r[1].success for r in result.subtask_results)
        
        return result
    
    def _execute_subtask(self, subtask: SubTask) -> ModelResponse:
        """Execute a single subtask."""
        client = self.clients.get(subtask.target_model)
        
        if not client:
            # Try fallback to any available client
            if self.clients:
                client = list(self.clients.values())[0]
            else:
                return ModelResponse(
                    model_name="none",
                    model_provider="none",
                    task_type=subtask.task_type.value,
                    content="",
                    success=False,
                    error=f"No client available for {subtask.target_model.value}"
                )
        
        return client.complete_sync(subtask.prompt, subtask.system_prompt)
    
    def _consolidate_results(self, subtask_results: list[tuple[SubTask, ModelResponse]]) -> str:
        """Consolidate multiple subtask results into a unified output."""
        if not subtask_results:
            return "No results to consolidate."
        
        if len(subtask_results) == 1:
            return subtask_results[0][1].content
        
        # Multiple results - create structured output
        parts = []
        for subtask, response in subtask_results:
            if response.success and response.content:
                parts.append(f"## {subtask.task_type.value.replace('_', ' ').title()} ({response.model_provider})\n\n{response.content}")
        
        return "\n\n---\n\n".join(parts)
    
    def _display_routing_plan(self, subtasks: list[SubTask]):
        """Display the routing plan for subtasks."""
        table = Table(title="Task Routing Plan", border_style="cyan")
        table.add_column("#", style="dim", width=4)
        table.add_column("Task Type", style="cyan")
        table.add_column("Model", style="green")
        table.add_column("Description", style="white")
        
        for subtask in subtasks:
            table.add_row(
                str(subtask.id),
                subtask.task_type.value,
                subtask.target_model.value,
                subtask.description[:50] + "..." if len(subtask.description) > 50 else subtask.description
            )
        
        self.console.print(table)
        self.console.print()
    
    def display_result(self, result: OrchestrationResult):
        """Display the orchestration result in a formatted way."""
        self.console.print()
        
        # Show individual model responses
        if len(result.subtask_results) > 1:
            self.console.print(Panel("[bold]Individual Model Responses[/bold]", border_style="blue"))
            
            for subtask, response in result.subtask_results:
                status = "[green]✓[/green]" if response.success else "[red]✗[/red]"
                title = f"{status} {response.model_provider} ({response.model_name}) - {subtask.task_type.value}"
                
                if response.success:
                    self.console.print(Panel(
                        Markdown(response.content[:2000] + ("..." if len(response.content) > 2000 else "")),
                        title=title,
                        border_style="green" if response.success else "red"
                    ))
                else:
                    self.console.print(Panel(
                        f"[red]Error: {response.error}[/red]",
                        title=title,
                        border_style="red"
                    ))
        
        # Show consolidated output
        self.console.print(Panel(
            "[bold green]Consolidated Output[/bold green]",
            border_style="green"
        ))
        self.console.print(Markdown(result.consolidated_output))
        
        # Show errors if any
        if result.errors:
            self.console.print()
            self.console.print(Panel(
                "\n".join([f"[red]• {e}[/red]" for e in result.errors]),
                title="[bold red]Errors[/bold red]",
                border_style="red"
            ))
        
        # Show summary
        self.console.print()
        success_count = sum(1 for _, r in result.subtask_results if r.success)
        total_count = len(result.subtask_results)
        self.console.print(f"[bold]Summary:[/bold] {success_count}/{total_count} tasks completed successfully")
