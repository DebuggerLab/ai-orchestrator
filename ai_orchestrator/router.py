"""Intelligent task router for AI Orchestrator."""

import re
from dataclasses import dataclass, field
from typing import Optional
from enum import Enum

from .models.base import TaskType


class ModelProvider(Enum):
    """Available AI model providers."""
    OPENAI = "openai"      # ChatGPT - Architecture & Roadmap
    ANTHROPIC = "anthropic"  # Claude - Coding
    GEMINI = "gemini"        # Gemini - Reasoning
    MOONSHOT = "moonshot"    # Kimi - Code Review


@dataclass
class SubTask:
    """A sub-task to be routed to a specific model."""
    id: int
    description: str
    task_type: TaskType
    target_model: ModelProvider
    prompt: str
    system_prompt: Optional[str] = None
    dependencies: list[int] = field(default_factory=list)


class TaskRouter:
    """Intelligent router that analyzes tasks and routes to appropriate models."""
    
    # Keywords for task type detection
    TASK_PATTERNS = {
        TaskType.ARCHITECTURE: [
            r'architect', r'design', r'structure', r'system design',
            r'high.?level', r'overview', r'blueprint', r'schema',
            r'database design', r'api design', r'microservice'
        ],
        TaskType.ROADMAP: [
            r'roadmap', r'plan', r'strategy', r'milestone', r'timeline',
            r'phase', r'sprint', r'project plan', r'release plan'
        ],
        TaskType.CODING: [
            r'implement', r'code', r'write', r'function', r'class',
            r'script', r'program', r'develop', r'build', r'create.*function',
            r'api endpoint', r'module', r'library'
        ],
        TaskType.DEBUGGING: [
            r'debug', r'fix', r'error', r'bug', r'issue', r'problem',
            r'not working', r'fails', r'crash', r'exception'
        ],
        TaskType.REASONING: [
            r'reason', r'logic', r'explain', r'why', r'analyze',
            r'think', r'evaluate', r'compare', r'pros.?cons',
            r'trade.?off', r'decision', r'choose', r'best approach'
        ],
        TaskType.LOGIC: [
            r'algorithm', r'optimize', r'complexity', r'efficient',
            r'performance', r'mathematical', r'formula', r'calculate'
        ],
        TaskType.CODE_REVIEW: [
            r'review', r'check', r'audit', r'inspect', r'feedback',
            r'improve', r'refactor', r'quality', r'best practice',
            r'security', r'vulnerability'
        ],
        TaskType.DOCUMENTATION: [
            r'document', r'readme', r'comment', r'docstring',
            r'specification', r'wiki', r'guide', r'tutorial'
        ],
    }
    
    # Model specialization mapping
    MODEL_SPECIALIZATIONS = {
        TaskType.ARCHITECTURE: ModelProvider.OPENAI,
        TaskType.ROADMAP: ModelProvider.OPENAI,
        TaskType.CODING: ModelProvider.ANTHROPIC,
        TaskType.DEBUGGING: ModelProvider.ANTHROPIC,
        TaskType.REASONING: ModelProvider.GEMINI,
        TaskType.LOGIC: ModelProvider.GEMINI,
        TaskType.CODE_REVIEW: ModelProvider.MOONSHOT,
        TaskType.DOCUMENTATION: ModelProvider.OPENAI,
        TaskType.GENERAL: ModelProvider.OPENAI,
    }
    
    def __init__(self, available_models: list[str]):
        """Initialize router with available models."""
        self.available_models = [ModelProvider(m) for m in available_models if m in [e.value for e in ModelProvider]]
    
    def detect_task_type(self, text: str) -> TaskType:
        """Detect the primary task type from text."""
        text_lower = text.lower()
        scores = {task_type: 0 for task_type in TaskType}
        
        for task_type, patterns in self.TASK_PATTERNS.items():
            for pattern in patterns:
                matches = re.findall(pattern, text_lower)
                scores[task_type] += len(matches)
        
        # Return the task type with the highest score
        max_score = max(scores.values())
        if max_score > 0:
            for task_type, score in scores.items():
                if score == max_score:
                    return task_type
        
        return TaskType.GENERAL
    
    def get_target_model(self, task_type: TaskType) -> ModelProvider:
        """Get the target model for a task type, considering availability."""
        preferred = self.MODEL_SPECIALIZATIONS.get(task_type, ModelProvider.OPENAI)
        
        if preferred in self.available_models:
            return preferred
        
        # Fallback to any available model
        if self.available_models:
            return self.available_models[0]
        
        raise ValueError("No AI models available. Please configure at least one API key.")
    
    def analyze_and_route(self, task_description: str) -> list[SubTask]:
        """Analyze a task and break it into routed sub-tasks."""
        subtasks = []
        
        # Detect if this is a complex task that needs multiple models
        detected_types = self._detect_all_task_types(task_description)
        
        if len(detected_types) <= 1:
            # Simple task - route to single model
            task_type = detected_types[0] if detected_types else TaskType.GENERAL
            target = self.get_target_model(task_type)
            
            subtasks.append(SubTask(
                id=1,
                description=task_description,
                task_type=task_type,
                target_model=target,
                prompt=task_description,
                system_prompt=self._get_system_prompt(task_type)
            ))
        else:
            # Complex task - break down and route to multiple models
            subtasks = self._create_multi_model_workflow(task_description, detected_types)
        
        return subtasks
    
    def _detect_all_task_types(self, text: str) -> list[TaskType]:
        """Detect all task types present in the text."""
        text_lower = text.lower()
        detected = []
        
        for task_type, patterns in self.TASK_PATTERNS.items():
            for pattern in patterns:
                if re.search(pattern, text_lower):
                    if task_type not in detected:
                        detected.append(task_type)
                    break
        
        return detected if detected else [TaskType.GENERAL]
    
    def _create_multi_model_workflow(self, task_description: str, task_types: list[TaskType]) -> list[SubTask]:
        """Create a workflow with multiple models for complex tasks."""
        subtasks = []
        task_id = 1
        
        # Priority order for task types
        priority_order = [
            TaskType.ARCHITECTURE, TaskType.ROADMAP,  # Planning first
            TaskType.REASONING, TaskType.LOGIC,        # Analysis
            TaskType.CODING, TaskType.DEBUGGING,       # Implementation
            TaskType.CODE_REVIEW,                      # Review last
            TaskType.DOCUMENTATION,
        ]
        
        # Sort detected types by priority
        sorted_types = sorted(
            task_types,
            key=lambda t: priority_order.index(t) if t in priority_order else 999
        )
        
        previous_id = None
        for task_type in sorted_types:
            target = self.get_target_model(task_type)
            
            # Create contextual prompt
            prompt = self._create_contextual_prompt(task_description, task_type)
            
            subtask = SubTask(
                id=task_id,
                description=f"{task_type.value.replace('_', ' ').title()} phase",
                task_type=task_type,
                target_model=target,
                prompt=prompt,
                system_prompt=self._get_system_prompt(task_type),
                dependencies=[previous_id] if previous_id else []
            )
            subtasks.append(subtask)
            previous_id = task_id
            task_id += 1
        
        return subtasks
    
    def _create_contextual_prompt(self, original_task: str, task_type: TaskType) -> str:
        """Create a focused prompt for a specific task type."""
        prefixes = {
            TaskType.ARCHITECTURE: "Focus on the architecture and system design aspects of this task:\n\n",
            TaskType.ROADMAP: "Create a roadmap and project plan for:\n\n",
            TaskType.CODING: "Implement the code for the following requirement:\n\n",
            TaskType.DEBUGGING: "Debug and fix issues in the following:\n\n",
            TaskType.REASONING: "Analyze and reason about the following:\n\n",
            TaskType.LOGIC: "Provide algorithmic and logical analysis for:\n\n",
            TaskType.CODE_REVIEW: "Review and provide feedback on:\n\n",
            TaskType.DOCUMENTATION: "Write documentation for:\n\n",
            TaskType.GENERAL: "",
        }
        return prefixes.get(task_type, "") + original_task
    
    def _get_system_prompt(self, task_type: TaskType) -> str:
        """Get appropriate system prompt for task type."""
        prompts = {
            TaskType.ARCHITECTURE: "You are a senior software architect. Focus on system design, scalability, and best practices. Provide clear architectural diagrams in text format when helpful.",
            TaskType.ROADMAP: "You are a technical project manager. Create detailed, actionable roadmaps with clear milestones and timelines.",
            TaskType.CODING: "You are an expert software engineer. Write clean, well-documented, production-ready code. Include error handling and follow best practices.",
            TaskType.DEBUGGING: "You are a debugging expert. Analyze issues methodically, identify root causes, and provide clear solutions with explanations.",
            TaskType.REASONING: "You are an analytical thinker. Break down complex problems, evaluate trade-offs, and provide well-reasoned conclusions.",
            TaskType.LOGIC: "You are an algorithms expert. Focus on efficiency, complexity analysis, and optimal solutions.",
            TaskType.CODE_REVIEW: "You are a code review specialist. Identify issues, suggest improvements, check for security vulnerabilities, and ensure code quality.",
            TaskType.DOCUMENTATION: "You are a technical writer. Create clear, comprehensive documentation that is easy to understand.",
            TaskType.GENERAL: "You are a helpful AI assistant. Provide clear, accurate, and helpful responses.",
        }
        return prompts.get(task_type, prompts[TaskType.GENERAL])
