"""Google Gemini client for reasoning tasks."""

from typing import Optional
import google.generativeai as genai
from .base import BaseModelClient, ModelResponse, TaskType


class GeminiClient(BaseModelClient):
    """Google Gemini client specialized in reasoning and logic."""
    
    provider_name = "Google"
    specialties = [TaskType.REASONING, TaskType.LOGIC, TaskType.GENERAL]
    
    def __init__(self, api_key: str, model_name: str = "gemini-pro"):
        super().__init__(api_key, model_name)
        genai.configure(api_key=api_key)
        self.model = genai.GenerativeModel(model_name)
    
    async def complete(self, prompt: str, system_prompt: Optional[str] = None) -> ModelResponse:
        """Async completion - uses sync under the hood for simplicity."""
        return self.complete_sync(prompt, system_prompt)
    
    def complete_sync(self, prompt: str, system_prompt: Optional[str] = None) -> ModelResponse:
        """Send completion request to Google Gemini."""
        try:
            # Combine system prompt with user prompt if provided
            full_prompt = prompt
            if system_prompt:
                full_prompt = f"{system_prompt}\n\n{prompt}"
            
            response = self.model.generate_content(
                full_prompt,
                generation_config=genai.types.GenerationConfig(
                    temperature=0.7,
                    max_output_tokens=4096
                )
            )
            
            return ModelResponse(
                model_name=self.model_name,
                model_provider=self.provider_name,
                task_type="reasoning",
                content=response.text,
                success=True,
                metadata={"prompt_feedback": str(response.prompt_feedback) if hasattr(response, 'prompt_feedback') else None}
            )
        except Exception as e:
            return ModelResponse(
                model_name=self.model_name,
                model_provider=self.provider_name,
                task_type="reasoning",
                content="",
                success=False,
                error=str(e)
            )
