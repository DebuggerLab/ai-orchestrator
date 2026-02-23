"""Main orchestrator for AI task distribution."""

from typing import Optional, Dict, Any, List
from dataclasses import dataclass, field
from pathlib import Path
from datetime import datetime
from rich.console import Console
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from rich.table import Table
from rich.markdown import Markdown

from .config import Config
from .router import TaskRouter, SubTask, ModelProvider, TaskType
from .models import (
    OpenAIClient,
    AnthropicClient,
    GeminiClient,
    MoonshotClient,
    ModelResponse,
)
from .execution.project_runner import ProjectRunner, ExecutionResult, ExecutionStatus
from .execution.verification_loop import VerificationLoop, LoopReport, LoopStatus
from .execution.auto_fixer import AutoFixer
from .execution.test_executor import TestResult


@dataclass
class OrchestrationResult:
    """Result of orchestrated task execution."""
    original_task: str
    subtask_results: list[tuple[SubTask, ModelResponse]] = field(default_factory=list)
    consolidated_output: str = ""
    success: bool = True
    errors: list[str] = field(default_factory=list)


@dataclass
class DevelopmentPhase:
    """Represents a phase in the development workflow."""
    name: str
    model_provider: str
    task_type: TaskType
    prompt: str
    response: Optional[ModelResponse] = None
    duration: float = 0.0
    success: bool = False


@dataclass
class ProjectDevelopmentResult:
    """Result of complete project development orchestration."""
    project_path: str
    phases: List[DevelopmentPhase] = field(default_factory=list)
    execution_result: Optional[ExecutionResult] = None
    verification_report: Optional[LoopReport] = None
    test_result: Optional[TestResult] = None
    final_review: Optional[ModelResponse] = None
    total_duration: float = 0.0
    success: bool = False
    status: str = "pending"
    errors: List[str] = field(default_factory=list)
    summary: str = ""


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
    
    def orchestrate_project_development(
        self,
        project_path: str,
        task_description: str,
        run_project: bool = True,
        run_tests: bool = True,
        auto_fix: bool = True,
        verbose: bool = True,
    ) -> ProjectDevelopmentResult:
        """Orchestrate complete project development with verification loop.
        
        Workflow:
        1. Use ChatGPT for architecture planning
        2. Use Claude for implementation
        3. Run the project
        4. If errors: enter verification loop
        5. Use Gemini for test design
        6. Use Kimi for final review
        7. Return complete project status
        
        Args:
            project_path: Path to the project directory
            task_description: Description of what to build/fix
            run_project: Whether to run the project after implementation
            run_tests: Whether to run tests
            auto_fix: Whether to auto-fix errors
            verbose: Whether to print progress
            
        Returns:
            ProjectDevelopmentResult with complete development status
        """
        import time
        start_time = time.time()
        
        project_path = Path(project_path)
        result = ProjectDevelopmentResult(
            project_path=str(project_path),
            status="in_progress",
        )
        
        if verbose:
            self.console.print(Panel(
                f"[bold blue]AI Orchestrator[/bold blue] - Project Development\n"
                f"Project: {project_path}\n"
                f"Task: {task_description[:100]}...",
                border_style="blue"
            ))
        
        try:
            # Phase 1: Architecture Planning (ChatGPT)
            if verbose:
                self.console.print("\n[bold cyan]Phase 1:[/bold cyan] Architecture Planning (ChatGPT)")
            
            arch_phase = self._execute_phase(
                name="Architecture Planning",
                model_provider="openai",
                task_type=TaskType.ARCHITECTURE,
                prompt=self._build_architecture_prompt(task_description, project_path),
            )
            result.phases.append(arch_phase)
            
            if not arch_phase.success:
                result.errors.append(f"Architecture planning failed: {arch_phase.response.error if arch_phase.response else 'No response'}")
            
            # Phase 2: Implementation (Claude)
            if verbose:
                self.console.print("\n[bold cyan]Phase 2:[/bold cyan] Implementation (Claude)")
            
            impl_context = arch_phase.response.content if arch_phase.response and arch_phase.success else ""
            impl_phase = self._execute_phase(
                name="Implementation",
                model_provider="anthropic",
                task_type=TaskType.CODING,
                prompt=self._build_implementation_prompt(task_description, project_path, impl_context),
            )
            result.phases.append(impl_phase)
            
            if not impl_phase.success:
                result.errors.append(f"Implementation failed: {impl_phase.response.error if impl_phase.response else 'No response'}")
            
            # Phase 3: Run Project
            if run_project:
                if verbose:
                    self.console.print("\n[bold cyan]Phase 3:[/bold cyan] Running Project")
                
                runner = ProjectRunner(
                    timeout=self.config.execution.execution_timeout,
                    setup_timeout=self.config.execution.setup_timeout,
                )
                
                exec_result = runner.run_project(project_path, setup=True)
                result.execution_result = exec_result
                
                if verbose:
                    status_color = "green" if exec_result.status == ExecutionStatus.SUCCESS else "red"
                    self.console.print(f"  Status: [{status_color}]{exec_result.status.value}[/{status_color}]")
                
                # Phase 4: Verification Loop (if errors and auto_fix enabled)
                if exec_result.status != ExecutionStatus.SUCCESS and auto_fix:
                    if verbose:
                        self.console.print("\n[bold cyan]Phase 4:[/bold cyan] Verification Loop (Auto-Fix)")
                    
                    verification_loop = VerificationLoop(
                        config=self.config,
                        project_path=project_path,
                        max_cycles=self.config.auto_fix.max_verification_cycles,
                        max_same_error_attempts=self.config.auto_fix.max_same_error_attempts,
                        run_tests=run_tests,
                        auto_fix=True,
                        confidence_threshold=self.config.auto_fix.fix_confidence_threshold,
                    )
                    
                    loop_report = verification_loop.run_development_cycle(setup=False)
                    result.verification_report = loop_report
                    
                    if verbose:
                        self.console.print(f"  Loop Status: {loop_report.status.value}")
                        self.console.print(f"  Cycles: {loop_report.progress.total_cycles}")
                        self.console.print(f"  Errors Fixed: {loop_report.progress.total_errors_fixed}")
                    
                    # Update execution result from loop
                    if loop_report.final_execution_result:
                        result.execution_result = loop_report.final_execution_result
            
            # Phase 5: Test Design (Gemini)
            if run_tests:
                if verbose:
                    self.console.print("\n[bold cyan]Phase 5:[/bold cyan] Test Design (Gemini)")
                
                test_phase = self._execute_phase(
                    name="Test Design",
                    model_provider="gemini",
                    task_type=TaskType.TESTING,
                    prompt=self._build_test_prompt(task_description, project_path),
                )
                result.phases.append(test_phase)
            
            # Phase 6: Final Review (Kimi/Moonshot)
            if verbose:
                self.console.print("\n[bold cyan]Phase 6:[/bold cyan] Final Review (Kimi)")
            
            review_phase = self._execute_phase(
                name="Final Review",
                model_provider="moonshot",
                task_type=TaskType.REVIEW,
                prompt=self._build_review_prompt(task_description, project_path, result),
            )
            result.phases.append(review_phase)
            result.final_review = review_phase.response
            
            # Determine overall success
            execution_success = (
                result.execution_result is None or 
                result.execution_result.status == ExecutionStatus.SUCCESS
            )
            verification_success = (
                result.verification_report is None or
                result.verification_report.status == LoopStatus.SUCCESS
            )
            
            result.success = execution_success or verification_success
            result.status = "success" if result.success else "failed"
            
        except Exception as e:
            result.status = "error"
            result.errors.append(f"Orchestration error: {str(e)}")
        
        result.total_duration = time.time() - start_time
        result.summary = self._generate_development_summary(result)
        
        if verbose:
            self.display_development_result(result)
        
        return result
    
    def _execute_phase(
        self,
        name: str,
        model_provider: str,
        task_type: TaskType,
        prompt: str,
    ) -> DevelopmentPhase:
        """Execute a single development phase."""
        import time
        start_time = time.time()
        
        phase = DevelopmentPhase(
            name=name,
            model_provider=model_provider,
            task_type=task_type,
            prompt=prompt,
        )
        
        # Get the appropriate client
        provider_map = {
            "openai": ModelProvider.OPENAI,
            "anthropic": ModelProvider.ANTHROPIC,
            "gemini": ModelProvider.GEMINI,
            "moonshot": ModelProvider.MOONSHOT,
        }
        
        client = self.clients.get(provider_map.get(model_provider))
        
        if not client:
            # Try fallback
            if self.clients:
                client = list(self.clients.values())[0]
                phase.model_provider = list(self.clients.keys())[0].value
        
        if client:
            try:
                response = client.complete_sync(prompt)
                phase.response = response
                phase.success = response.success
            except Exception as e:
                phase.response = ModelResponse(
                    model_name="unknown",
                    model_provider=model_provider,
                    task_type=task_type.value,
                    content="",
                    success=False,
                    error=str(e),
                )
                phase.success = False
        else:
            phase.response = ModelResponse(
                model_name="none",
                model_provider=model_provider,
                task_type=task_type.value,
                content="",
                success=False,
                error="No AI client available",
            )
            phase.success = False
        
        phase.duration = time.time() - start_time
        return phase
    
    def _build_architecture_prompt(self, task: str, project_path: Path) -> str:
        """Build prompt for architecture planning."""
        # Try to read existing project structure
        structure = self._get_project_structure(project_path)
        
        return f"""You are an expert software architect. Plan the architecture for the following task:

## Task
{task}

## Current Project Structure
{structure}

Please provide:
1. High-level architecture overview
2. Key components and their responsibilities
3. Data flow and interactions
4. Technology recommendations
5. Potential challenges and solutions

Format your response as a clear, structured plan."""
    
    def _build_implementation_prompt(self, task: str, project_path: Path, architecture: str) -> str:
        """Build prompt for implementation."""
        structure = self._get_project_structure(project_path)
        
        return f"""You are an expert software developer. Implement the following based on the architecture plan:

## Task
{task}

## Architecture Plan
{architecture[:2000] if architecture else "No specific architecture provided."}

## Current Project Structure
{structure}

Please provide:
1. Implementation strategy
2. Key code changes needed
3. File-by-file modifications (if applicable)
4. Configuration updates
5. Any dependencies to add

Be specific and provide actual code where appropriate."""
    
    def _build_test_prompt(self, task: str, project_path: Path) -> str:
        """Build prompt for test design."""
        structure = self._get_project_structure(project_path)
        
        return f"""You are an expert in software testing. Design tests for the following:

## Task/Feature
{task}

## Project Structure
{structure}

Please provide:
1. Test strategy overview
2. Unit test cases
3. Integration test cases
4. Edge cases to consider
5. Test data requirements

Include actual test code examples where appropriate."""
    
    def _build_review_prompt(self, task: str, project_path: Path, result: ProjectDevelopmentResult) -> str:
        """Build prompt for final review."""
        phases_summary = "\n".join([
            f"- {p.name}: {'✓' if p.success else '✗'}"
            for p in result.phases
        ])
        
        execution_status = "Not run"
        if result.execution_result:
            execution_status = result.execution_result.status.value
        
        verification_status = "Not run"
        if result.verification_report:
            verification_status = result.verification_report.status.value
        
        return f"""You are a senior code reviewer. Review the following development effort:

## Original Task
{task}

## Development Phases
{phases_summary}

## Execution Status
{execution_status}

## Verification Status
{verification_status}

## Errors Encountered
{chr(10).join(result.errors) if result.errors else "None"}

Please provide:
1. Overall assessment
2. Code quality observations
3. Security considerations
4. Performance considerations
5. Recommendations for improvement
6. Next steps

Be constructive and specific in your feedback."""
    
    def _get_project_structure(self, project_path: Path, max_depth: int = 3) -> str:
        """Get a string representation of project structure."""
        if not project_path.exists():
            return "Project directory does not exist."
        
        lines = []
        
        def walk_dir(path: Path, prefix: str = "", depth: int = 0):
            if depth > max_depth:
                return
            
            # Skip hidden and common non-essential directories
            skip_dirs = {'.git', 'node_modules', '__pycache__', '.venv', 'venv', '.auto_fixer_backups'}
            
            try:
                items = sorted(path.iterdir(), key=lambda x: (x.is_file(), x.name))
                for i, item in enumerate(items):
                    if item.name.startswith('.') and item.name not in ['.env.example', '.gitignore']:
                        continue
                    if item.name in skip_dirs:
                        continue
                    
                    is_last = i == len(items) - 1
                    connector = "└── " if is_last else "├── "
                    lines.append(f"{prefix}{connector}{item.name}")
                    
                    if item.is_dir():
                        extension = "    " if is_last else "│   "
                        walk_dir(item, prefix + extension, depth + 1)
            except PermissionError:
                pass
        
        lines.append(str(project_path.name) + "/")
        walk_dir(project_path)
        
        return "\n".join(lines[:100])  # Limit output
    
    def _generate_development_summary(self, result: ProjectDevelopmentResult) -> str:
        """Generate a summary of the development process."""
        lines = ["# Project Development Summary\n"]
        
        # Status
        status_emoji = "✅" if result.success else "❌"
        lines.append(f"## Status: {status_emoji} {result.status}\n")
        
        # Timing
        lines.append(f"**Total Duration:** {result.total_duration:.2f}s\n")
        
        # Phases
        lines.append("## Development Phases\n")
        for phase in result.phases:
            emoji = "✓" if phase.success else "✗"
            lines.append(f"- [{emoji}] **{phase.name}** ({phase.model_provider}) - {phase.duration:.2f}s")
        
        # Execution
        if result.execution_result:
            lines.append(f"\n## Execution: {result.execution_result.status.value}")
            if result.execution_result.errors:
                lines.append(f"  - Errors found: {len(result.execution_result.errors)}")
        
        # Verification
        if result.verification_report:
            lines.append(f"\n## Verification Loop: {result.verification_report.status.value}")
            lines.append(f"  - Cycles: {result.verification_report.progress.total_cycles}")
            lines.append(f"  - Errors fixed: {result.verification_report.progress.total_errors_fixed}")
        
        # Errors
        if result.errors:
            lines.append("\n## Errors")
            for error in result.errors:
                lines.append(f"- {error}")
        
        return "\n".join(lines)
    
    def display_development_result(self, result: ProjectDevelopmentResult):
        """Display the project development result."""
        self.console.print()
        self.console.print(Panel(
            Markdown(result.summary),
            title="[bold]Project Development Complete[/bold]",
            border_style="green" if result.success else "red"
        ))
        
        # Show final review if available
        if result.final_review and result.final_review.success:
            self.console.print()
            self.console.print(Panel(
                Markdown(result.final_review.content[:3000] + ("..." if len(result.final_review.content) > 3000 else "")),
                title="[bold]Final Review[/bold]",
                border_style="cyan"
            ))
        
        # Show recommendations from verification if available
        if result.verification_report and result.verification_report.recommendations:
            self.console.print()
            self.console.print(Panel(
                "\n".join([f"• {r}" for r in result.verification_report.recommendations]),
                title="[bold]Recommendations[/bold]",
                border_style="yellow"
            ))
