"""Google Gemini client for reasoning tasks."""

from typing import Optional, List, Dict, Any
import google.generativeai as genai
from .base import BaseModelClient, ModelResponse, TaskType


def list_available_gemini_models(api_key: str) -> List[Dict[str, Any]]:
    """List all available Gemini models for the given API key.
    
    Args:
        api_key: Google AI API key
        
    Returns:
        List of dictionaries containing model info (name, display_name, description, etc.)
    """
    genai.configure(api_key=api_key)
    models = []
    for model in genai.list_models():
        if 'generateContent' in model.supported_generation_methods:
            models.append({
                'name': model.name.replace('models/', ''),  # Remove 'models/' prefix
                'display_name': model.display_name,
                'description': model.description,
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
    """
    
    provider_name = "Google"
    specialties = [TaskType.REASONING, TaskType.LOGIC, TaskType.GENERAL]
    
    def __init__(self, api_key: str, model_name: str = "gemini-2.5-flash"):
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
