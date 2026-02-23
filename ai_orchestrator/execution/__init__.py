"""Execution module for running projects and detecting errors."""

from .project_runner import ProjectRunner, ExecutionResult, ExecutionStatus
from .error_detector import ErrorDetector, DetectedError, ErrorCategory
from .test_executor import TestExecutor, TestResult, TestFramework, TestStatus
from .project_types import (
    BaseProjectHandler,
    ProjectConfig,
    NodeJSProject,
    PythonProject,
    ReactProject,
    NextJSProject,
    FlaskProject,
    DjangoProject,
    GenericProject,
    detect_project_type,
)

__all__ = [
    # Main classes
    "ProjectRunner",
    "ErrorDetector",
    "TestExecutor",
    # Result types
    "ExecutionResult",
    "ExecutionStatus",
    "DetectedError",
    "ErrorCategory",
    "TestResult",
    "TestFramework",
    "TestStatus",
    "ProjectConfig",
    # Project handlers
    "BaseProjectHandler",
    "NodeJSProject",
    "PythonProject",
    "ReactProject",
    "NextJSProject",
    "FlaskProject",
    "DjangoProject",
    "GenericProject",
    # Utility functions
    "detect_project_type",
]
