"""Moonshot AI (Kimi) client for code review tasks."""

from typing import Optional
import requests
from .base import BaseModelClient, ModelResponse, TaskType


class MoonshotClient(BaseModelClient):
    """Moonshot AI (Kimi) client specialized in code review."""
    
    provider_name = "Moonshot"
    specialties = [TaskType.CODE_REVIEW, TaskType.DEBUGGING]
    base_url = "https://api.moonshot.cn/v1/chat/completions"
    
    def __init__(self, api_key: str, model_name: str = "moonshot-v1-8k"):
        super().__init__(api_key, model_name)
    
    async def complete(self, prompt: str, system_prompt: Optional[str] = None) -> ModelResponse:
        """Async completion - uses sync under the hood for simplicity."""
        return self.complete_sync(prompt, system_prompt)
    
    def complete_sync(self, prompt: str, system_prompt: Optional[str] = None) -> ModelResponse:
        """Send completion request to Moonshot AI (Kimi)."""
        try:
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {self.api_key}"
            }
            
            messages = []
            if system_prompt:
                messages.append({"role": "system", "content": system_prompt})
            messages.append({"role": "user", "content": prompt})
            
            payload = {
                "model": self.model_name,
                "messages": messages,
                "temperature": 0.7,
                "max_tokens": 4096
            }
            
            response = requests.post(
                self.base_url,
                headers=headers,
                json=payload,
                timeout=120
            )
            response.raise_for_status()
            
            data = response.json()
            content = data["choices"][0]["message"]["content"]
            tokens = data.get("usage", {}).get("total_tokens")
            
            return ModelResponse(
                model_name=self.model_name,
                model_provider=self.provider_name,
                task_type="code_review",
                content=content,
                success=True,
                tokens_used=tokens,
                metadata={"finish_reason": data["choices"][0].get("finish_reason")}
            )
        except Exception as e:
            return ModelResponse(
                model_name=self.model_name,
                model_provider=self.provider_name,
                task_type="code_review",
                content="",
                success=False,
                error=str(e)
            )
