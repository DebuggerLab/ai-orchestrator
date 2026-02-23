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


class Config(BaseModel):
    """Main configuration class."""
    openai_api_key: Optional[str] = None
    anthropic_api_key: Optional[str] = None
    gemini_api_key: Optional[str] = None
    moonshot_api_key: Optional[str] = None
    models: ModelConfig = Field(default_factory=ModelConfig)
    
    @classmethod
    def load(cls, env_path: Optional[Path] = None) -> "Config":
        """Load configuration from environment variables."""
        if env_path:
            load_dotenv(env_path)
        else:
            # Try loading from current directory or home directory
            load_dotenv(Path.cwd() / ".env")
            load_dotenv(Path.home() / ".ai-orchestrator" / ".env")
        
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
            )
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
