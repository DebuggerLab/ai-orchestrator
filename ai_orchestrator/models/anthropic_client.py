"""Anthropic (Claude) client for coding tasks."""

from typing import Optional
import anthropic
from .base import BaseModelClient, ModelResponse, TaskType


class AnthropicClient(BaseModelClient):
    """Anthropic Claude client specialized in coding implementation."""
    
    provider_name = "Anthropic"
    specialties = [TaskType.CODING, TaskType.DEBUGGING, TaskType.DOCUMENTATION]
    
    def __init__(self, api_key: str, model_name: str = "claude-3-5-sonnet-20241022"):
        super().__init__(api_key, model_name)
        self.client = anthropic.Anthropic(api_key=api_key)
    
    async def complete(self, prompt: str, system_prompt: Optional[str] = None) -> ModelResponse:
        """Async completion - uses sync under the hood for simplicity."""
        return self.complete_sync(prompt, system_prompt)
    
    def complete_sync(self, prompt: str, system_prompt: Optional[str] = None) -> ModelResponse:
        """Send completion request to Anthropic Claude."""
        try:
            kwargs = {
                "model": self.model_name,
                "max_tokens": 4096,
                "messages": [{"role": "user", "content": prompt}]
            }
            if system_prompt:
                kwargs["system"] = system_prompt
            
            response = self.client.messages.create(**kwargs)
            
            content = ""
            if response.content:
                content = response.content[0].text
            
            return ModelResponse(
                model_name=self.model_name,
                model_provider=self.provider_name,
                task_type="coding",
                content=content,
                success=True,
                tokens_used=response.usage.input_tokens + response.usage.output_tokens if response.usage else None,
                metadata={"stop_reason": response.stop_reason}
            )
        except Exception as e:
            return ModelResponse(
                model_name=self.model_name,
                model_provider=self.provider_name,
                task_type="coding",
                content="",
                success=False,
                error=str(e)
            )
