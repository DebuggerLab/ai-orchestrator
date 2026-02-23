"""Google Gemini client for reasoning tasks.

Migrated to google-genai SDK (replaces deprecated google-generativeai).
See: https://github.com/googleapis/python-genai
"""

from typing import Optional, List, Dict, Any
from google import genai
from google.genai import types
from .base import BaseModelClient, ModelResponse, TaskType


def list_available_gemini_models(api_key: str) -> List[Dict[str, Any]]:
    """List all available Gemini models for the given API key.
    
    Args:
        api_key: Google AI API key
        
    Returns:
        List of dictionaries containing model info (name, display_name, description, etc.)
    """
    client = genai.Client(api_key=api_key)
    models = []
    for model in client.models.list():
        # Check if model supports content generation
        supported_methods = getattr(model, 'supported_generation_methods', [])
        if 'generateContent' in supported_methods:
            models.append({
                'name': model.name.replace('models/', ''),  # Remove 'models/' prefix
                'display_name': getattr(model, 'display_name', model.name),
                'description': getattr(model, 'description', ''),
                'input_token_limit': getattr(model, 'input_token_limit', None),
                'output_token_limit': getattr(model, 'output_token_limit', None),
            })
    return models


class GeminiClient(BaseModelClient):
    """Google Gemini client specialized in reasoning and logic.
    
    Default model: gemini-2.5-flash (latest stable flash model)
    
    Note: Model availability varies by region and account type. 
    Use list_available_gemini_models() to check available models for your API key.
    
    Tip: You can use "gemini-flash-latest" or "gemini-pro-latest" as aliases that
    always point to the latest version of the respective model family.
    
    Migration Note: This client uses the new google-genai SDK (replacing deprecated
    google-generativeai). The new SDK uses a Client-based API pattern.
    """
    
    provider_name = "Google"
    specialties = [TaskType.REASONING, TaskType.LOGIC, TaskType.GENERAL]
    
    def __init__(self, api_key: str, model_name: str = "gemini-2.5-flash"):
        super().__init__(api_key, model_name)
        self.client = genai.Client(api_key=api_key)
    
    async def complete(self, prompt: str, system_prompt: Optional[str] = None) -> ModelResponse:
        """Async completion - uses sync under the hood for simplicity."""
        return self.complete_sync(prompt, system_prompt)
    
    def complete_sync(self, prompt: str, system_prompt: Optional[str] = None) -> ModelResponse:
        """Send completion request to Google Gemini."""
        try:
            # Build generation config
            config = types.GenerateContentConfig(
                temperature=0.7,
                max_output_tokens=4096
            )
            
            # Add system instruction if provided
            if system_prompt:
                config.system_instruction = system_prompt
            
            response = self.client.models.generate_content(
                model=self.model_name,
                contents=prompt,
                config=config
            )
            
            return ModelResponse(
                model_name=self.model_name,
                model_provider=self.provider_name,
                task_type="reasoning",
                content=response.text,
                success=True,
                metadata={"prompt_feedback": str(getattr(response, 'prompt_feedback', None))}
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
