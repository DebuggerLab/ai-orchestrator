"""Configuration management for AI Orchestrator."""

import os
import logging
from pathlib import Path
from typing import Optional
from pydantic import BaseModel, Field
from dotenv import load_dotenv

# Configure logger for config module
logger = logging.getLogger(__name__)


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
    anthropic_model: str = Field(default="claude-3-5-sonnet-20240620")
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


class iOSConfig(BaseModel):
    """Configuration for iOS/SwiftUI development.
    
    Controls simulator settings and Xcode build behavior.
    """
    # Simulator settings
    ios_simulator_device: str = Field(
        default="iPhone 15",
        description="Default iOS Simulator device name"
    )
    ios_simulator_os: str = Field(
        default="iOS 17.0",
        description="Preferred iOS version for simulator"
    )
    auto_boot_simulator: bool = Field(
        default=True,
        description="Automatically boot simulator when running iOS projects"
    )
    
    # Build settings
    xcode_build_timeout: int = Field(
        default=600,
        description="Timeout for xcodebuild operations in seconds"
    )
    xcode_test_timeout: int = Field(
        default=600,
        description="Timeout for XCTest execution in seconds"
    )
    xcode_configuration: str = Field(
        default="Debug",
        description="Default Xcode build configuration (Debug/Release)"
    )
    
    # Code signing
    skip_code_signing: bool = Field(
        default=True,
        description="Skip code signing for simulator builds"
    )
    
    # Derived data
    use_project_derived_data: bool = Field(
        default=True,
        description="Use project-local DerivedData instead of global"
    )
    derived_data_path: Optional[str] = Field(
        default=None,
        description="Custom DerivedData path (default: project/build/DerivedData)"
    )
    
    # Build behavior
    clean_before_build: bool = Field(
        default=False,
        description="Clean before building"
    )
    parallel_builds: bool = Field(
        default=True,
        description="Enable parallel builds"
    )


class AutoFixConfig(BaseModel):
    """Configuration for auto-fix and verification loop.
    
    Controls the behavior of the automatic error fixing system.
    """
    # Fix attempt limits
    max_fix_attempts: int = Field(
        default=5,
        description="Maximum number of fix attempts per error"
    )
    max_same_error_attempts: int = Field(
        default=3,
        description="Maximum attempts to fix the same error before giving up"
    )
    max_verification_cycles: int = Field(
        default=10,
        description="Maximum number of run-fix-rerun cycles"
    )
    
    # Confidence thresholds
    fix_confidence_threshold: float = Field(
        default=0.7,
        description="Minimum confidence (0.0-1.0) to apply a fix"
    )
    ai_fix_confidence_threshold: float = Field(
        default=0.6,
        description="Minimum confidence for AI-generated fixes"
    )
    
    # Safety features
    enable_auto_backup: bool = Field(
        default=True,
        description="Create backups before applying fixes"
    )
    fix_validation_enabled: bool = Field(
        default=True,
        description="Validate fixes before applying them"
    )
    allow_destructive_fixes: bool = Field(
        default=False,
        description="Allow fixes that delete files (requires backup)"
    )
    
    # AI model preferences for fixing
    preferred_fix_model: str = Field(
        default="anthropic",
        description="Preferred AI model for code fixes (anthropic/openai/gemini)"
    )
    preferred_analysis_model: str = Field(
        default="openai",
        description="Preferred AI model for error analysis"
    )
    
    # Loop behavior
    run_tests_in_loop: bool = Field(
        default=True,
        description="Run tests as part of verification loop"
    )
    stop_on_regression: bool = Field(
        default=True,
        description="Stop if error count increases"
    )
    
    # Backup settings
    backup_retention_count: int = Field(
        default=5,
        description="Number of recent backups to keep"
    )
    backup_dir: Optional[str] = Field(
        default=None,
        description="Custom backup directory (default: project/.auto_fixer_backups)"
    )


def _load_env_file(env_path: Optional[Path] = None) -> bool:
    """Load environment variables from config file.
    
    Config file search order (first found is used):
    1. Explicit env_path parameter (if provided)
    2. ~/.config/ai-orchestrator/config.env (primary user config)
    3. ~/ai-orchestrator/.env (fallback)
    4. ./.env (current directory fallback)
    
    Returns:
        True if a config file was loaded, False otherwise.
    """
    config_loaded = False
    
    if env_path:
        if env_path.exists():
            load_dotenv(env_path, override=True)
            logger.info(f"Loaded config from: {env_path}")
            config_loaded = True
        else:
            logger.warning(f"Specified config file not found: {env_path}")
    
    if not config_loaded:
        # Define config file search paths in priority order
        config_paths = [
            Path.home() / ".config" / "ai-orchestrator" / "config.env",  # Primary
            Path.home() / "ai-orchestrator" / ".env",  # Fallback
            Path.cwd() / ".env",  # Current directory fallback
        ]
        
        for config_path in config_paths:
            if config_path.exists():
                load_dotenv(config_path, override=True)
                logger.info(f"Loaded config from: {config_path}")
                config_loaded = True
                break
            else:
                logger.debug(f"Config file not found: {config_path}")
        
        if not config_loaded:
            logger.warning(
                "No config file found. Searched locations:\n"
                f"  - {config_paths[0]}\n"
                f"  - {config_paths[1]}\n"
                f"  - {config_paths[2]}\n"
                "Using environment variables or defaults."
            )
    
    return config_loaded


def _get_int(key: str, default: int) -> int:
    """Get integer from environment with default."""
    val = os.getenv(key)
    return int(val) if val else default


def _get_float(key: str, default: float) -> float:
    """Get float from environment with default."""
    val = os.getenv(key)
    return float(val) if val else default


def _get_bool(key: str, default: bool) -> bool:
    """Get boolean from environment with default."""
    val = os.getenv(key)
    if val is None:
        return default
    return val.lower() in ('true', '1', 'yes')


def _get_str(key: str, default: str) -> str:
    """Get string from environment with default."""
    return os.getenv(key, default)


def _build_config_from_env() -> dict:
    """Build configuration dictionary from environment variables."""
    return {
        'openai_api_key': os.getenv("OPENAI_API_KEY"),
        'anthropic_api_key': os.getenv("ANTHROPIC_API_KEY"),
        'gemini_api_key': os.getenv("GEMINI_API_KEY"),
        'moonshot_api_key': os.getenv("MOONSHOT_API_KEY"),
        'models': ModelConfig(
            openai_model=os.getenv("OPENAI_MODEL", os.getenv("DEFAULT_ARCHITECTURE_MODEL", "gpt-4o-mini")),
            anthropic_model=os.getenv("ANTHROPIC_MODEL", os.getenv("DEFAULT_CODING_MODEL", "claude-3-5-sonnet-20240620")),
            gemini_model=os.getenv("GEMINI_MODEL", os.getenv("DEFAULT_REASONING_MODEL", "gemini-2.5-flash")),
            moonshot_model=os.getenv("MOONSHOT_MODEL", os.getenv("DEFAULT_REVIEW_MODEL", "moonshot-v1-8k")),
        ),
        'execution': ExecutionConfig(
            execution_timeout=_get_int("EXECUTION_TIMEOUT", 300),
            setup_timeout=_get_int("SETUP_TIMEOUT", 600),
            test_timeout=_get_int("TEST_TIMEOUT", 300),
            max_retry_attempts=_get_int("MAX_RETRY_ATTEMPTS", 3),
            retry_delay=_get_float("RETRY_DELAY", 1.0),
            max_output_size=_get_int("MAX_OUTPUT_SIZE", 500000),
            error_log_size_limit=_get_int("ERROR_LOG_SIZE_LIMIT", 100000),
            graceful_shutdown_timeout=_get_int("GRACEFUL_SHUTDOWN_TIMEOUT", 5),
            auto_detect_ports=_get_bool("AUTO_DETECT_PORTS", True),
            default_port=_get_int("DEFAULT_PORT", 3000),
        ),
        'auto_fix': AutoFixConfig(
            max_fix_attempts=_get_int("MAX_FIX_ATTEMPTS", 5),
            max_same_error_attempts=_get_int("MAX_SAME_ERROR_ATTEMPTS", 3),
            max_verification_cycles=_get_int("MAX_VERIFICATION_CYCLES", 10),
            fix_confidence_threshold=_get_float("FIX_CONFIDENCE_THRESHOLD", 0.7),
            ai_fix_confidence_threshold=_get_float("AI_FIX_CONFIDENCE_THRESHOLD", 0.6),
            enable_auto_backup=_get_bool("ENABLE_AUTO_BACKUP", True),
            fix_validation_enabled=_get_bool("FIX_VALIDATION_ENABLED", True),
            allow_destructive_fixes=_get_bool("ALLOW_DESTRUCTIVE_FIXES", False),
            preferred_fix_model=_get_str("PREFERRED_FIX_MODEL", "anthropic"),
            preferred_analysis_model=_get_str("PREFERRED_ANALYSIS_MODEL", "openai"),
            run_tests_in_loop=_get_bool("RUN_TESTS_IN_LOOP", True),
            stop_on_regression=_get_bool("STOP_ON_REGRESSION", True),
            backup_retention_count=_get_int("BACKUP_RETENTION_COUNT", 5),
            backup_dir=os.getenv("AUTO_FIX_BACKUP_DIR"),
        ),
        'ios': iOSConfig(
            ios_simulator_device=_get_str("IOS_SIMULATOR_DEVICE", "iPhone 15"),
            ios_simulator_os=_get_str("IOS_SIMULATOR_OS", "iOS 17.0"),
            auto_boot_simulator=_get_bool("IOS_AUTO_BOOT_SIMULATOR", True),
            xcode_build_timeout=_get_int("XCODE_BUILD_TIMEOUT", 600),
            xcode_test_timeout=_get_int("XCODE_TEST_TIMEOUT", 600),
            xcode_configuration=_get_str("XCODE_CONFIGURATION", "Debug"),
            skip_code_signing=_get_bool("IOS_SKIP_CODE_SIGNING", True),
            use_project_derived_data=_get_bool("IOS_USE_PROJECT_DERIVED_DATA", True),
            derived_data_path=os.getenv("IOS_DERIVED_DATA_PATH"),
            clean_before_build=_get_bool("IOS_CLEAN_BEFORE_BUILD", False),
            parallel_builds=_get_bool("IOS_PARALLEL_BUILDS", True),
        ),
    }


class Config(BaseModel):
    """Main configuration class.
    
    IMPORTANT: Both Config() and Config.load() will automatically load
    environment variables from config files. You can use either:
    
        config = Config()      # Loads from default config locations
        config = Config.load() # Same as above
        config = Config.load(Path('/custom/path.env'))  # Custom path
    
    Config file search order:
    1. ~/.config/ai-orchestrator/config.env (primary)
    2. ~/ai-orchestrator/.env (fallback)
    3. ./.env (current directory)
    """
    openai_api_key: Optional[str] = None
    anthropic_api_key: Optional[str] = None
    gemini_api_key: Optional[str] = None
    moonshot_api_key: Optional[str] = None
    models: ModelConfig = Field(default_factory=ModelConfig)
    execution: ExecutionConfig = Field(default_factory=ExecutionConfig)
    auto_fix: AutoFixConfig = Field(default_factory=AutoFixConfig)
    ios: iOSConfig = Field(default_factory=iOSConfig)
    
    def __init__(self, **data):
        """Initialize Config, automatically loading from env files if no data provided.
        
        If called without arguments (Config()), will automatically load from
        environment files and set values from environment variables.
        
        If called with explicit arguments, uses those values directly.
        """
        # Check if this is a "fresh" initialization (no API keys provided)
        # If so, load from env files first
        api_keys_provided = any(
            key in data and data[key] is not None 
            for key in ['openai_api_key', 'anthropic_api_key', 'gemini_api_key', 'moonshot_api_key']
        )
        
        if not api_keys_provided and not data:
            # No data provided - load from env files
            _load_env_file()
            env_config = _build_config_from_env()
            super().__init__(**env_config)
        else:
            # Data provided - use it directly
            super().__init__(**data)
    
    @classmethod
    def load(cls, env_path: Optional[Path] = None) -> "Config":
        """Load configuration from environment variables.
        
        This is the recommended way to create a Config instance.
        
        Config file search order (first found is used):
        1. Explicit env_path parameter (if provided)
        2. ~/.config/ai-orchestrator/config.env (primary user config)
        3. ~/ai-orchestrator/.env (fallback)
        4. ./.env (current directory fallback)
        
        Args:
            env_path: Optional explicit path to config file
            
        Returns:
            Config instance with values loaded from environment
        """
        _load_env_file(env_path)
        return cls(**_build_config_from_env())
    
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
    
    def debug_info(self) -> str:
        """Return debug information about loaded configuration."""
        lines = [
            "=== Config Debug Info ===",
            f"OpenAI API Key: {'SET' if self.openai_api_key else 'NOT SET'} (length: {len(self.openai_api_key) if self.openai_api_key else 0})",
            f"Anthropic API Key: {'SET' if self.anthropic_api_key else 'NOT SET'} (length: {len(self.anthropic_api_key) if self.anthropic_api_key else 0})",
            f"Gemini API Key: {'SET' if self.gemini_api_key else 'NOT SET'} (length: {len(self.gemini_api_key) if self.gemini_api_key else 0})",
            f"Moonshot API Key: {'SET' if self.moonshot_api_key else 'NOT SET'} (length: {len(self.moonshot_api_key) if self.moonshot_api_key else 0})",
            f"Available Models: {self.get_available_models()}",
            "",
            "Model Settings:",
            f"  OpenAI Model: {self.models.openai_model}",
            f"  Anthropic Model: {self.models.anthropic_model}",
            f"  Gemini Model: {self.models.gemini_model}",
            f"  Moonshot Model: {self.models.moonshot_model}",
        ]
        return "\n".join(lines)
