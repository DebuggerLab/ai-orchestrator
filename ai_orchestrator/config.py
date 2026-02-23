"""Configuration management for AI Orchestrator."""

import os
from pathlib import Path
from typing import Optional
from pydantic import BaseModel, Field
from dotenv import load_dotenv


class ModelConfig(BaseModel):
    """Configuration for individual AI models.
    
    Default models are chosen for accessibility and cost-effectiveness:
    - gpt-4o-mini: Fast, affordable, widely accessible OpenAI model
    - claude-3-5-sonnet: Best balance of capability and availability
    - gemini-2.5-flash: Latest stable flash model with excellent performance
    - moonshot-v1-8k: Standard Moonshot model
    
    Note: Model availability varies by region/account. Use `ai-orchestrator list-models gemini`
    to check available models for your API key.
    
    Tip: Use "gemini-flash-latest" or "gemini-pro-latest" as aliases that always point to
    the latest version of the respective model family.
    """
    openai_model: str = Field(default="gpt-4o-mini")
    anthropic_model: str = Field(default="claude-3-5-sonnet-20241022")
    gemini_model: str = Field(default="gemini-2.5-flash")
    moonshot_model: str = Field(default="moonshot-v1-8k")


class ExecutionConfig(BaseModel):
    """Configuration for project execution and testing.
    
    Controls timeouts, retries, and resource limits for running projects.
    """
    # Execution timeouts (in seconds)
    execution_timeout: int = Field(
        default=300,
        description="Maximum time to wait for project execution"
    )
    setup_timeout: int = Field(
        default=600,
        description="Maximum time to wait for dependency installation"
    )
    test_timeout: int = Field(
        default=300,
        description="Maximum time to wait for test execution"
    )
    
    # Retry configuration
    max_retry_attempts: int = Field(
        default=3,
        description="Maximum number of retry attempts on failure"
    )
    retry_delay: float = Field(
        default=1.0,
        description="Delay between retry attempts in seconds"
    )
    
    # Output limits
    max_output_size: int = Field(
        default=500000,
        description="Maximum captured output size in characters"
    )
    error_log_size_limit: int = Field(
        default=100000,
        description="Maximum error log size for analysis"
    )
    
    # Process control
    graceful_shutdown_timeout: int = Field(
        default=5,
        description="Time to wait for graceful process termination"
    )
    
    # Development server settings
    auto_detect_ports: bool = Field(
        default=True,
        description="Automatically detect and use project-defined ports"
    )
    default_port: int = Field(
        default=3000,
        description="Default port for development servers"
    )


class Config(BaseModel):
    """Main configuration class."""
    openai_api_key: Optional[str] = None
    anthropic_api_key: Optional[str] = None
    gemini_api_key: Optional[str] = None
    moonshot_api_key: Optional[str] = None
    models: ModelConfig = Field(default_factory=ModelConfig)
    execution: ExecutionConfig = Field(default_factory=ExecutionConfig)
    
    @classmethod
    def load(cls, env_path: Optional[Path] = None) -> "Config":
        """Load configuration from environment variables."""
        if env_path:
            load_dotenv(env_path)
        else:
            # Try loading from current directory or home directory
            load_dotenv(Path.cwd() / ".env")
            load_dotenv(Path.home() / ".ai-orchestrator" / ".env")
        
        # Helper to get int from env with default
        def get_int(key: str, default: int) -> int:
            val = os.getenv(key)
            return int(val) if val else default
        
        def get_float(key: str, default: float) -> float:
            val = os.getenv(key)
            return float(val) if val else default
        
        def get_bool(key: str, default: bool) -> bool:
            val = os.getenv(key)
            if val is None:
                return default
            return val.lower() in ('true', '1', 'yes')
        
        return cls(
            openai_api_key=os.getenv("OPENAI_API_KEY"),
            anthropic_api_key=os.getenv("ANTHROPIC_API_KEY"),
            gemini_api_key=os.getenv("GEMINI_API_KEY"),
            moonshot_api_key=os.getenv("MOONSHOT_API_KEY"),
            models=ModelConfig(
                openai_model=os.getenv("OPENAI_MODEL", os.getenv("DEFAULT_ARCHITECTURE_MODEL", "gpt-4o-mini")),
                anthropic_model=os.getenv("ANTHROPIC_MODEL", os.getenv("DEFAULT_CODING_MODEL", "claude-3-5-sonnet-20241022")),
                gemini_model=os.getenv("GEMINI_MODEL", os.getenv("DEFAULT_REASONING_MODEL", "gemini-2.5-flash")),
                moonshot_model=os.getenv("MOONSHOT_MODEL", os.getenv("DEFAULT_REVIEW_MODEL", "moonshot-v1-8k")),
            ),
            execution=ExecutionConfig(
                execution_timeout=get_int("EXECUTION_TIMEOUT", 300),
                setup_timeout=get_int("SETUP_TIMEOUT", 600),
                test_timeout=get_int("TEST_TIMEOUT", 300),
                max_retry_attempts=get_int("MAX_RETRY_ATTEMPTS", 3),
                retry_delay=get_float("RETRY_DELAY", 1.0),
                max_output_size=get_int("MAX_OUTPUT_SIZE", 500000),
                error_log_size_limit=get_int("ERROR_LOG_SIZE_LIMIT", 100000),
                graceful_shutdown_timeout=get_int("GRACEFUL_SHUTDOWN_TIMEOUT", 5),
                auto_detect_ports=get_bool("AUTO_DETECT_PORTS", True),
                default_port=get_int("DEFAULT_PORT", 3000),
            ),
        )
    
    def get_available_models(self) -> list[str]:
        """Return list of models that have API keys configured."""
        available = []
        if self.openai_api_key:
            available.append("openai")
        if self.anthropic_api_key:
            available.append("anthropic")
        if self.gemini_api_key:
            available.append("gemini")
        if self.moonshot_api_key:
            available.append("moonshot")
        return available
