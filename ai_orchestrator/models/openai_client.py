"""OpenAI (ChatGPT) client for architecture and roadmap tasks."""

from typing import Optional
from openai import OpenAI
from .base import BaseModelClient, ModelResponse, TaskType


class OpenAIClient(BaseModelClient):
    """OpenAI client specialized in architecture and roadmap planning."""
    
    provider_name = "OpenAI"
    specialties = [TaskType.ARCHITECTURE, TaskType.ROADMAP, TaskType.DOCUMENTATION, TaskType.GENERAL]
    
    def __init__(self, api_key: str, model_name: str = "gpt-4"):
        super().__init__(api_key, model_name)
        self.client = OpenAI(api_key=api_key)
    
    async def complete(self, prompt: str, system_prompt: Optional[str] = None) -> ModelResponse:
        """Async completion - uses sync under the hood for simplicity."""
        return self.complete_sync(prompt, system_prompt)
    
    def complete_sync(self, prompt: str, system_prompt: Optional[str] = None) -> ModelResponse:
        """Send completion request to OpenAI."""
        try:
            messages = []
            if system_prompt:
                messages.append({"role": "system", "content": system_prompt})
            messages.append({"role": "user", "content": prompt})
            
            response = self.client.chat.completions.create(
                model=self.model_name,
                messages=messages,
                temperature=0.7,
                max_tokens=4096
            )
            
            return ModelResponse(
                model_name=self.model_name,
                model_provider=self.provider_name,
                task_type="architecture/roadmap",
                content=response.choices[0].message.content,
                success=True,
                tokens_used=response.usage.total_tokens if response.usage else None,
                metadata={"finish_reason": response.choices[0].finish_reason}
            )
        except Exception as e:
            return ModelResponse(
                model_name=self.model_name,
                model_provider=self.provider_name,
                task_type="architecture/roadmap",
                content="",
                success=False,
                error=str(e)
            )
