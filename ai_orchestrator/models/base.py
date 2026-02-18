"""Base class for AI model clients."""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Optional
from enum import Enum


class TaskType(Enum):
    """Types of tasks that can be routed to different models."""
    ARCHITECTURE = "architecture"
    ROADMAP = "roadmap"
    CODING = "coding"
    DEBUGGING = "debugging"
    REASONING = "reasoning"
    LOGIC = "logic"
    CODE_REVIEW = "code_review"
    DOCUMENTATION = "documentation"
    GENERAL = "general"


@dataclass
class ModelResponse:
    """Standardized response from any AI model."""
    model_name: str
    model_provider: str
    task_type: str
    content: str
    success: bool = True
    error: Optional[str] = None
    tokens_used: Optional[int] = None
    metadata: dict = field(default_factory=dict)


class BaseModelClient(ABC):
    """Abstract base class for AI model clients."""
    
    provider_name: str = "unknown"
    specialties: list[TaskType] = []
    
    def __init__(self, api_key: str, model_name: str):
        self.api_key = api_key
        self.model_name = model_name
        self._validate_api_key()
    
    def _validate_api_key(self):
        """Validate that API key is provided."""
        if not self.api_key:
            raise ValueError(f"API key required for {self.provider_name}")
    
    @abstractmethod
    async def complete(self, prompt: str, system_prompt: Optional[str] = None) -> ModelResponse:
        """Send a completion request to the model."""
        pass
    
    @abstractmethod
    def complete_sync(self, prompt: str, system_prompt: Optional[str] = None) -> ModelResponse:
        """Synchronous completion request."""
        pass
    
    def can_handle(self, task_type: TaskType) -> bool:
        """Check if this model specializes in the given task type."""
        return task_type in self.specialties
