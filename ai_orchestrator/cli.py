"""Command-line interface for AI Orchestrator."""

import sys
from pathlib import Path
from typing import Optional

import click
from rich.console import Console
from rich.panel import Panel
from rich.table import Table

from .config import Config
from .orchestrator import Orchestrator
from .router import ModelProvider


console = Console()


def print_banner():
    """Print the AI Orchestrator banner."""
    banner = """
    ╔═══════════════════════════════════════════════════════════╗
    ║           🤖 AI ORCHESTRATOR v1.0.0 🤖                    ║
    ║     Multi-Model AI Task Distribution System               ║
    ╚═══════════════════════════════════════════════════════════╝
    """
    console.print(banner, style="bold cyan")


@click.group()
@click.version_option(version="1.0.0", prog_name="ai-orchestrator")
def main():
    """AI Orchestrator - Intelligent multi-model AI task distribution.
    
    Routes tasks to the most appropriate AI model:
    
    \b
    • OpenAI (ChatGPT): Architecture & Roadmap planning
    • Anthropic (Claude): Coding & Implementation
    • Google (Gemini): Reasoning & Logic
    • Moonshot (Kimi): Code Review
    """
    pass


@main.command()
@click.argument("task", nargs=-1, required=True)
@click.option("--env", "-e", type=click.Path(exists=True), help="Path to .env file")
@click.option("--quiet", "-q", is_flag=True, help="Minimal output")
@click.option("--model", "-m", type=click.Choice(["openai", "anthropic", "gemini", "moonshot"]), 
              help="Force use of specific model")
@click.option("--output", "-o", type=click.Path(), help="Save output to file")
def run(task: tuple, env: Optional[str], quiet: bool, model: Optional[str], output: Optional[str]):
    """Execute a task using AI orchestration.
    
    Examples:
    
    \b
    ai-orchestrator run "Design a REST API for a blog"
    ai-orchestrator run "Implement a binary search in Python"
    ai-orchestrator run "Review this code for security issues"
    ai-orchestrator run -m anthropic "Write a sorting algorithm"
    """
    if not quiet:
        print_banner()
    
    task_description = " ".join(task)
    
    # Load configuration
    env_path = Path(env) if env else None
    config = Config.load(env_path)
    
    # Check for available models
    available = config.get_available_models()
    if not available:
        console.print("[bold red]Error:[/bold red] No API keys configured.")
        console.print("Please copy .env.example to .env and add your API keys.")
        sys.exit(1)
    
    if not quiet:
        console.print(f"[dim]Available models: {', '.join(available)}[/dim]\n")
    
    # Initialize orchestrator
    orchestrator = Orchestrator(config)
    
    # Execute task
    result = orchestrator.execute(task_description, verbose=not quiet)
    
    # Display result
    if not quiet:
        orchestrator.display_result(result)
    else:
        console.print(result.consolidated_output)
    
    # Save to file if requested
    if output:
        output_path = Path(output)
        output_path.write_text(result.consolidated_output)
        console.print(f"\n[green]Output saved to: {output_path}[/green]")
    
    # Exit with error code if task failed
    if not result.success:
        sys.exit(1)


@main.command()
@click.option("--env", "-e", type=click.Path(exists=True), help="Path to .env file")
def status(env: Optional[str]):
    """Check configuration and available models."""
    print_banner()
    
    env_path = Path(env) if env else None
    config = Config.load(env_path)
    
    table = Table(title="Model Configuration Status", border_style="cyan")
    table.add_column("Provider", style="cyan")
    table.add_column("Model", style="white")
    table.add_column("Status", style="white")
    table.add_column("Specialization", style="dim")
    
    models_info = [
        ("OpenAI", config.models.openai_model, config.openai_api_key, "Architecture, Roadmap"),
        ("Anthropic", config.models.anthropic_model, config.anthropic_api_key, "Coding, Implementation"),
        ("Gemini", config.models.gemini_model, config.gemini_api_key, "Reasoning, Logic"),
        ("Moonshot", config.models.moonshot_model, config.moonshot_api_key, "Code Review"),
    ]
    
    for provider, model, api_key, spec in models_info:
        status_text = "[green]✓ Configured[/green]" if api_key else "[red]✗ Not configured[/red]"
        table.add_row(provider, model, status_text, spec)
    
    console.print(table)
    
    available = config.get_available_models()
    if available:
        console.print(f"\n[green]✓ {len(available)} model(s) ready for use[/green]")
    else:
        console.print("\n[yellow]⚠ No models configured. Copy .env.example to .env and add API keys.[/yellow]")


@main.command()
def init():
    """Initialize configuration in current directory."""
    print_banner()
    
    env_example = Path(__file__).parent.parent / ".env.example"
    env_target = Path.cwd() / ".env"
    
    if env_target.exists():
        if not click.confirm(".env already exists. Overwrite?"):
            console.print("[yellow]Aborted.[/yellow]")
            return
    
    # Create .env from template
    template = """# AI Orchestrator Configuration
# Fill in your API keys below

# OpenAI API Key (for ChatGPT - Architecture & Roadmap)
OPENAI_API_KEY=

# Anthropic API Key (for Claude - Coding Tasks)
ANTHROPIC_API_KEY=

# Google Gemini API Key (for Reasoning)
GEMINI_API_KEY=

# Moonshot AI API Key (for Kimi - Code Review)
MOONSHOT_API_KEY=
"""
    env_target.write_text(template)
    console.print(f"[green]✓ Created .env file at {env_target}[/green]")
    console.print("\nNext steps:")
    console.print("1. Edit .env and add your API keys")
    console.print("2. Run 'ai-orchestrator status' to verify")
    console.print("3. Run 'ai-orchestrator run \"your task\"' to start")


@main.command()
@click.argument("text", nargs=-1, required=True)
def analyze(text: tuple):
    """Analyze a task to see how it would be routed.
    
    This shows which models would handle the task without executing it.
    """
    print_banner()
    
    from .router import TaskRouter
    
    task_text = " ".join(text)
    
    # Use all models as potentially available for analysis
    router = TaskRouter(["openai", "anthropic", "gemini", "moonshot"])
    subtasks = router.analyze_and_route(task_text)
    
    console.print(Panel(f"[bold]Task:[/bold] {task_text}", border_style="blue"))
    console.print()
    
    table = Table(title="Routing Analysis", border_style="cyan")
    table.add_column("#", style="dim", width=4)
    table.add_column("Task Type", style="cyan")
    table.add_column("Target Model", style="green")
    table.add_column("Provider", style="yellow")
    
    provider_names = {
        ModelProvider.OPENAI: "OpenAI (ChatGPT)",
        ModelProvider.ANTHROPIC: "Anthropic (Claude)",
        ModelProvider.GEMINI: "Google (Gemini)",
        ModelProvider.MOONSHOT: "Moonshot (Kimi)",
    }
    
    for subtask in subtasks:
        table.add_row(
            str(subtask.id),
            subtask.task_type.value,
            subtask.target_model.value,
            provider_names.get(subtask.target_model, "Unknown")
        )
    
    console.print(table)


if __name__ == "__main__":
    main()
