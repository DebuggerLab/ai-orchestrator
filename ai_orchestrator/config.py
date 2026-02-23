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


class Config(BaseModel):
    """Main configuration class."""
    openai_api_key: Optional[str] = None
    anthropic_api_key: Optional[str] = None
    gemini_api_key: Optional[str] = None
    moonshot_api_key: Optional[str] = None
    models: ModelConfig = Field(default_factory=ModelConfig)
    execution: ExecutionConfig = Field(default_factory=ExecutionConfig)
    auto_fix: AutoFixConfig = Field(default_factory=AutoFixConfig)
    ios: iOSConfig = Field(default_factory=iOSConfig)
    
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
        
        def get_str(key: str, default: str) -> str:
            return os.getenv(key, default)
        
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
            auto_fix=AutoFixConfig(
                max_fix_attempts=get_int("MAX_FIX_ATTEMPTS", 5),
                max_same_error_attempts=get_int("MAX_SAME_ERROR_ATTEMPTS", 3),
                max_verification_cycles=get_int("MAX_VERIFICATION_CYCLES", 10),
                fix_confidence_threshold=get_float("FIX_CONFIDENCE_THRESHOLD", 0.7),
                ai_fix_confidence_threshold=get_float("AI_FIX_CONFIDENCE_THRESHOLD", 0.6),
                enable_auto_backup=get_bool("ENABLE_AUTO_BACKUP", True),
                fix_validation_enabled=get_bool("FIX_VALIDATION_ENABLED", True),
                allow_destructive_fixes=get_bool("ALLOW_DESTRUCTIVE_FIXES", False),
                preferred_fix_model=get_str("PREFERRED_FIX_MODEL", "anthropic"),
                preferred_analysis_model=get_str("PREFERRED_ANALYSIS_MODEL", "openai"),
                run_tests_in_loop=get_bool("RUN_TESTS_IN_LOOP", True),
                stop_on_regression=get_bool("STOP_ON_REGRESSION", True),
                backup_retention_count=get_int("BACKUP_RETENTION_COUNT", 5),
                backup_dir=os.getenv("AUTO_FIX_BACKUP_DIR"),
            ),
            ios=iOSConfig(
                ios_simulator_device=get_str("IOS_SIMULATOR_DEVICE", "iPhone 15"),
                ios_simulator_os=get_str("IOS_SIMULATOR_OS", "iOS 17.0"),
                auto_boot_simulator=get_bool("IOS_AUTO_BOOT_SIMULATOR", True),
                xcode_build_timeout=get_int("XCODE_BUILD_TIMEOUT", 600),
                xcode_test_timeout=get_int("XCODE_TEST_TIMEOUT", 600),
                xcode_configuration=get_str("XCODE_CONFIGURATION", "Debug"),
                skip_code_signing=get_bool("IOS_SKIP_CODE_SIGNING", True),
                use_project_derived_data=get_bool("IOS_USE_PROJECT_DERIVED_DATA", True),
                derived_data_path=os.getenv("IOS_DERIVED_DATA_PATH"),
                clean_before_build=get_bool("IOS_CLEAN_BEFORE_BUILD", False),
                parallel_builds=get_bool("IOS_PARALLEL_BUILDS", True),
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
