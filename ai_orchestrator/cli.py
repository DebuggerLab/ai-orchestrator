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
@click.option("--debug", "-d", is_flag=True, help="Show debug information")
def run(task: tuple, env: Optional[str], quiet: bool, model: Optional[str], output: Optional[str], debug: bool):
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
    
    # If specific model requested, use direct query
    if model:
        if model not in available:
            console.print(f"[bold red]Error:[/bold red] Model '{model}' is not configured.")
            console.print(f"Available models: {', '.join(available)}")
            sys.exit(1)
        
        response = _call_model_directly(config, model, task_description, quiet, debug=debug)
        
        # Check if we got a response at all
        if response is None:
            console.print("[bold red]Error:[/bold red] Failed to get response (no response object).")
            console.print("\n[yellow]Troubleshooting tips:[/yellow]")
            console.print("  1. Check your API key is valid")
            console.print("  2. Check your network connection")
            console.print(f"  3. Run with --debug flag for more info")
            sys.exit(1)
        
        # Check if the response was successful
        if not response.success:
            console.print(f"[bold red]Error:[/bold red] API call failed")
            if response.error:
                console.print(f"[red]Details: {response.error}[/red]")
            console.print("\n[yellow]Troubleshooting tips:[/yellow]")
            console.print("  1. Verify your API key is correct and active")
            console.print("  2. Check if you have API credits/quota remaining")
            console.print("  3. The model name might not be available")
            console.print(f"  4. Current model: {getattr(config.models, f'{model}_model', 'unknown')}")
            sys.exit(1)
        
        # Check for empty content
        if not response.content or response.content.strip() == "":
            console.print("[bold yellow]Warning:[/bold yellow] Received empty response from API")
            if debug:
                console.print(f"[dim]Debug: Full response metadata: {response.metadata}[/dim]")
            sys.exit(1)
        
        # Success - display the response
        if not quiet:
            console.print(Panel(response.content, title=f"[bold green]{model.upper()} Response[/bold green]", border_style="green"))
            if response.tokens_used:
                console.print(f"[dim]Tokens used: {response.tokens_used}[/dim]")
        else:
            console.print(response.content)
        
        if output:
            output_path = Path(output)
            output_path.write_text(response.content)
            console.print(f"\n[green]Output saved to: {output_path}[/green]")
        return
    
    # Initialize orchestrator for automatic routing
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


def _call_model_directly(config: Config, model: str, prompt: str, quiet: bool = False, debug: bool = False):
    """Call a specific model directly without routing."""
    from .models import OpenAIClient, AnthropicClient, GeminiClient, MoonshotClient
    
    client = None
    
    if debug:
        console.print(f"[dim]Debug: Creating {model} client...[/dim]")
        console.print(f"[dim]Debug: Model name: {getattr(config.models, f'{model}_model', 'unknown')}[/dim]")
    
    try:
        if model == "openai":
            client = OpenAIClient(config.openai_api_key, config.models.openai_model)
        elif model == "anthropic":
            client = AnthropicClient(config.anthropic_api_key, config.models.anthropic_model)
        elif model == "gemini":
            client = GeminiClient(config.gemini_api_key, config.models.gemini_model)
        elif model == "moonshot":
            client = MoonshotClient(config.moonshot_api_key, config.models.moonshot_model)
    except Exception as e:
        console.print(f"[bold red]Error creating {model} client:[/bold red] {e}")
        return None
    
    if not client:
        console.print(f"[bold red]Error:[/bold red] Unknown model '{model}'")
        return None
    
    try:
        if not quiet:
            console.print(f"[dim]Calling {model}...[/dim]")
        
        if debug:
            console.print(f"[dim]Debug: Sending request to {model}...[/dim]")
        
        response = client.complete_sync(prompt)
        
        if debug:
            console.print(f"[dim]Debug: Response received[/dim]")
            console.print(f"[dim]Debug: Success: {response.success}[/dim]")
            console.print(f"[dim]Debug: Content length: {len(response.content) if response.content else 0}[/dim]")
            if response.error:
                console.print(f"[dim]Debug: Error: {response.error}[/dim]")
            if response.tokens_used:
                console.print(f"[dim]Debug: Tokens used: {response.tokens_used}[/dim]")
        
        return response
    except Exception as e:
        console.print(f"[bold red]Error calling {model}:[/bold red] {e}")
        import traceback
        if debug:
            console.print(f"[dim]{traceback.format_exc()}[/dim]")
        return None


@main.command()
@click.argument("prompt", nargs=-1, required=True)
@click.option("--model", "-m", type=click.Choice(["openai", "anthropic", "gemini", "moonshot"]), 
              required=True, help="Model to use")
@click.option("--env", "-e", type=click.Path(exists=True), help="Path to .env file")
@click.option("--quiet", "-q", is_flag=True, help="Output only the response")
@click.option("--debug", "-d", is_flag=True, help="Show debug information")
def ask(prompt: tuple, model: str, env: Optional[str], quiet: bool, debug: bool):
    """Quick query to a specific model.
    
    Simple command for direct model interaction without task routing.
    
    Examples:
    
    \b
    ai-orchestrator ask -m openai "Write hello world in Python"
    ai-orchestrator ask -m anthropic "Explain recursion"
    ai-orchestrator ask -m gemini "What is 2+2?"
    ai-orchestrator ask -m moonshot "Review this code snippet"
    ai-orchestrator ask -m anthropic -d "Test with debug"
    """
    prompt_text = " ".join(prompt)
    
    # Load configuration
    env_path = Path(env) if env else None
    config = Config.load(env_path)
    
    if debug:
        console.print(f"[dim]Debug: Config loaded from {env_path or 'default locations'}[/dim]")
        console.print(f"[dim]Debug: Prompt: {prompt_text[:100]}{'...' if len(prompt_text) > 100 else ''}[/dim]")
    
    # Check model availability
    available = config.get_available_models()
    if model not in available:
        console.print(f"[bold red]Error:[/bold red] Model '{model}' is not configured.")
        console.print(f"Available models: {', '.join(available) if available else 'none'}")
        console.print("\nPlease add the API key to your .env file.")
        sys.exit(1)
    
    if not quiet:
        console.print(f"[cyan]Querying {model}...[/cyan]\n")
    
    response = _call_model_directly(config, model, prompt_text, quiet=True, debug=debug)
    
    # Check if we got a response at all
    if response is None:
        console.print("[bold red]Error:[/bold red] Failed to get response (no response object).")
        console.print("\n[yellow]Troubleshooting tips:[/yellow]")
        console.print("  1. Check your API key is valid")
        console.print("  2. Check your network connection")
        console.print(f"  3. Run with --debug flag for more info")
        sys.exit(1)
    
    # Check if the response was successful
    if not response.success:
        console.print(f"[bold red]Error:[/bold red] API call failed")
        if response.error:
            console.print(f"[red]Details: {response.error}[/red]")
        console.print("\n[yellow]Troubleshooting tips:[/yellow]")
        console.print("  1. Verify your API key is correct and active")
        console.print("  2. Check if you have API credits/quota remaining")
        console.print("  3. The model name might not be available in your region")
        console.print(f"  4. Current model: {getattr(config.models, f'{model}_model', 'unknown')}")
        sys.exit(1)
    
    # Check for empty content
    if not response.content or response.content.strip() == "":
        console.print("[bold yellow]Warning:[/bold yellow] Received empty response from API")
        if debug:
            console.print(f"[dim]Debug: Full response metadata: {response.metadata}[/dim]")
        console.print("\n[yellow]This might indicate:[/yellow]")
        console.print("  • The model had nothing to say")
        console.print("  • Content was filtered")
        console.print("  • API issue")
        sys.exit(1)
    
    # Success - display the response
    if not quiet:
        console.print(Panel(response.content, title=f"[bold green]{model.upper()}[/bold green]", border_style="green"))
        if response.tokens_used:
            console.print(f"[dim]Tokens used: {response.tokens_used}[/dim]")
    else:
        print(response.content)


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


@main.command("list-models")
@click.argument("provider", type=click.Choice(["gemini", "all"]), default="gemini")
@click.option("--env", "-e", type=click.Path(exists=True), help="Path to .env file")
def list_models(provider: str, env: Optional[str]):
    """List available models for a provider.
    
    Currently supports listing Gemini models dynamically from the API.
    This is useful to check which models are available for your API key,
    as model availability varies by region and account type.
    
    Examples:
    
    \b
    ai-orchestrator list-models gemini
    ai-orchestrator list-models all
    """
    print_banner()
    
    env_path = Path(env) if env else None
    config = Config.load(env_path)
    
    if provider in ["gemini", "all"]:
        if not config.gemini_api_key:
            console.print("[bold red]Error:[/bold red] GEMINI_API_KEY not configured.")
            console.print("Please add your Gemini API key to .env file.")
            sys.exit(1)
        
        console.print("[bold cyan]Fetching available Gemini models...[/bold cyan]\n")
        
        try:
            from .models.gemini_client import list_available_gemini_models
            
            models = list_available_gemini_models(config.gemini_api_key)
            
            if not models:
                console.print("[yellow]No text generation models found.[/yellow]")
                return
            
            table = Table(title="Available Gemini Models", border_style="cyan")
            table.add_column("Model Name", style="green")
            table.add_column("Display Name", style="white")
            table.add_column("Input Tokens", style="cyan", justify="right")
            table.add_column("Output Tokens", style="cyan", justify="right")
            
            for model in models:
                input_tokens = str(model.get('input_token_limit', 'N/A'))
                output_tokens = str(model.get('output_token_limit', 'N/A'))
                table.add_row(
                    model['name'],
                    model.get('display_name', 'N/A'),
                    input_tokens,
                    output_tokens
                )
            
            console.print(table)
            console.print(f"\n[green]✓ Found {len(models)} model(s) available for your API key[/green]")
            console.print(f"\n[dim]Current configured model: {config.models.gemini_model}[/dim]")
            console.print("\n[bold]To use a different model:[/bold]")
            console.print("  Add to your .env file: GEMINI_MODEL=<model-name>")
            
        except Exception as e:
            console.print(f"[bold red]Error fetching models:[/bold red] {e}")
            console.print("\nTips:")
            console.print("  • Verify your GEMINI_API_KEY is valid")
            console.print("  • Get a key from: https://aistudio.google.com/apikey")
            sys.exit(1)


@main.command("test-api")
@click.option("--model", "-m", type=click.Choice(["openai", "anthropic", "gemini", "moonshot", "all"]), 
              default="all", help="Model to test (default: all)")
@click.option("--env", "-e", type=click.Path(exists=True), help="Path to .env file")
def test_api(model: str, env: Optional[str]):
    """Test API connections for configured models.
    
    Sends a simple test request to verify your API keys are working.
    
    Examples:
    
    \b
    ai-orchestrator test-api
    ai-orchestrator test-api -m anthropic
    ai-orchestrator test-api -m openai
    """
    print_banner()
    
    env_path = Path(env) if env else None
    config = Config.load(env_path)
    
    models_to_test = ["openai", "anthropic", "gemini", "moonshot"] if model == "all" else [model]
    
    results = []
    
    for m in models_to_test:
        available = config.get_available_models()
        if m not in available:
            console.print(f"[yellow]⏭️  {m.upper()}:[/yellow] Skipped (no API key configured)")
            results.append((m, None))
            continue
        
        console.print(f"[cyan]Testing {m.upper()}...[/cyan]")
        
        response = _call_model_directly(config, m, "Say 'OK' and nothing else.", quiet=True)
        
        if response is None:
            console.print(f"  [red]❌ FAILED - No response object[/red]")
            results.append((m, False))
        elif not response.success:
            console.print(f"  [red]❌ FAILED - {response.error}[/red]")
            results.append((m, False))
        elif not response.content or not response.content.strip():
            console.print(f"  [red]❌ FAILED - Empty response[/red]")
            results.append((m, False))
        else:
            console.print(f"  [green]✅ SUCCESS - Response: {response.content[:50]}{'...' if len(response.content) > 50 else ''}[/green]")
            results.append((m, True))
    
    # Summary
    console.print()
    passed = sum(1 for _, s in results if s is True)
    failed = sum(1 for _, s in results if s is False)
    skipped = sum(1 for _, s in results if s is None)
    
    console.print(f"[bold]Summary:[/bold] {passed} passed, {failed} failed, {skipped} skipped")
    
    if failed > 0:
        console.print("\n[yellow]Troubleshooting tips:[/yellow]")
        console.print("  1. Verify your API keys are correct in ~/.config/ai-orchestrator/config.env")
        console.print("  2. Check that your API keys have not expired")
        console.print("  3. Verify you have credits/quota remaining")
        console.print("  4. Run 'ai-orchestrator status' to see configuration")
        sys.exit(1)


if __name__ == "__main__":
    main()
