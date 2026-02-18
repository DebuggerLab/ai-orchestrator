"""Configuration management for AI Orchestrator."""

import os
from pathlib import Path
from typing import Optional
from pydantic import BaseModel, Field
from dotenv import load_dotenv


class ModelConfig(BaseModel):
    """Configuration for individual AI models."""
    openai_model: str = Field(default="gpt-4")
    anthropic_model: str = Field(default="claude-3-opus-20240229")
    gemini_model: str = Field(default="gemini-pro")
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
                openai_model=os.getenv("DEFAULT_ARCHITECTURE_MODEL", "gpt-4"),
                anthropic_model=os.getenv("DEFAULT_CODING_MODEL", "claude-3-opus-20240229"),
                gemini_model=os.getenv("DEFAULT_REASONING_MODEL", "gemini-pro"),
                moonshot_model=os.getenv("DEFAULT_REVIEW_MODEL", "moonshot-v1-8k"),
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
