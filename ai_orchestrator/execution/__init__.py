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
    iOSProject,
    GenericProject,
    detect_project_type,
)
from .auto_fixer import (
    AutoFixer,
    AnalysisResult,
    GeneratedFix,
    FixAttempt,
    FixConfidence,
)
from .verification_loop import (
    VerificationLoop,
    LoopReport,
    LoopStatus,
    LoopProgress,
    CycleResult,
    ProgressTrend,
)
from .fix_strategies import (
    FixStrategy,
    FixResult,
    FixType,
    FixStrategyRegistry,
    FixerCollection,
    DependencyFixer,
    PortFixer,
    PermissionFixer,
    ConfigurationFixer,
    SyntaxFixer,
    # iOS-specific fixers
    SwiftSyntaxFixer,
    SimulatorFixer,
    SwiftPackageFixer,
    SigningFixer,
)
from .ios_simulator import (
    iOSSimulatorManager,
    iOSProjectBuilder,
    Simulator,
    SimulatorState,
    SimulatorResult,
    AppInstallResult,
    BuildResult,
    # Convenience functions
    list_simulators,
    boot_simulator,
    get_booted_simulator,
    build_ios_project,
    run_ios_tests,
)

__all__ = [
    # Main classes
    "ProjectRunner",
    "ErrorDetector",
    "TestExecutor",
    "AutoFixer",
    "VerificationLoop",
    # Result types
    "ExecutionResult",
    "ExecutionStatus",
    "DetectedError",
    "ErrorCategory",
    "TestResult",
    "TestFramework",
    "TestStatus",
    "ProjectConfig",
    # Auto-fixer types
    "AnalysisResult",
    "GeneratedFix",
    "FixAttempt",
    "FixConfidence",
    # Verification loop types
    "LoopReport",
    "LoopStatus",
    "LoopProgress",
    "CycleResult",
    "ProgressTrend",
    # Fix strategy types
    "FixStrategy",
    "FixResult",
    "FixType",
    "FixStrategyRegistry",
    "FixerCollection",
    "DependencyFixer",
    "PortFixer",
    "PermissionFixer",
    "ConfigurationFixer",
    "SyntaxFixer",
    # iOS-specific fixers
    "SwiftSyntaxFixer",
    "SimulatorFixer",
    "SwiftPackageFixer",
    "SigningFixer",
    # Project handlers
    "BaseProjectHandler",
    "NodeJSProject",
    "PythonProject",
    "ReactProject",
    "NextJSProject",
    "FlaskProject",
    "DjangoProject",
    "iOSProject",
    "GenericProject",
    # iOS Simulator utilities
    "iOSSimulatorManager",
    "iOSProjectBuilder",
    "Simulator",
    "SimulatorState",
    "SimulatorResult",
    "AppInstallResult",
    "BuildResult",
    "list_simulators",
    "boot_simulator",
    "get_booted_simulator",
    "build_ios_project",
    "run_ios_tests",
    # Utility functions
    "detect_project_type",
]
