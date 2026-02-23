"""Verification loop for iterative project development and fixing."""

import hashlib
import json
import time
from datetime import datetime
from typing import Optional, Dict, List, Any, Set
from dataclasses import dataclass, field
from pathlib import Path
from enum import Enum

from ..config import Config
from .project_runner import ProjectRunner, ExecutionResult, ExecutionStatus
from .error_detector import ErrorDetector, DetectedError, ErrorCategory
from .test_executor import TestExecutor, TestResult
from .auto_fixer import AutoFixer, GeneratedFix, FixAttempt, AnalysisResult
from .fix_strategies import FixResult


class LoopStatus(Enum):
    """Status of the verification loop."""
    NOT_STARTED = "not_started"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    MAX_RETRIES_REACHED = "max_retries_reached"
    STUCK_IN_LOOP = "stuck_in_loop"
    NEEDS_HUMAN_HELP = "needs_human_help"
    CANCELLED = "cancelled"


class ProgressTrend(Enum):
    """Trend of progress in the loop."""
    IMPROVING = "improving"
    REGRESSING = "regressing"
    STALLED = "stalled"
    UNKNOWN = "unknown"


@dataclass
class CycleResult:
    """Result of a single development cycle."""
    cycle_number: int
    execution_result: Optional[ExecutionResult] = None
    test_result: Optional[TestResult] = None
    errors_found: List[DetectedError] = field(default_factory=list)
    fixes_attempted: List[FixAttempt] = field(default_factory=list)
    fixes_successful: int = 0
    fixes_failed: int = 0
    duration: float = 0.0
    status: str = "pending"


@dataclass
class LoopProgress:
    """Tracks progress across cycles."""
    total_cycles: int = 0
    total_errors_found: int = 0
    total_errors_fixed: int = 0
    unique_errors_seen: int = 0
    repeated_errors: int = 0
    trend: ProgressTrend = ProgressTrend.UNKNOWN
    error_count_history: List[int] = field(default_factory=list)


@dataclass
class LoopReport:
    """Comprehensive report of the verification loop."""
    status: LoopStatus
    progress: LoopProgress
    cycles: List[CycleResult]
    total_duration: float
    start_time: datetime
    end_time: datetime
    final_execution_result: Optional[ExecutionResult] = None
    final_test_result: Optional[TestResult] = None
    summary: str = ""
    recommendations: List[str] = field(default_factory=list)


class VerificationLoop:
    """Main loop: run → test → fix → repeat until success or max retries."""
    
    def __init__(
        self,
        config: Config,
        project_path: Path,
        max_cycles: int = 10,
        max_same_error_attempts: int = 3,
        run_tests: bool = True,
        auto_fix: bool = True,
        confidence_threshold: float = 0.7,
    ):
        """Initialize the verification loop.
        
        Args:
            config: Configuration with API keys and settings
            project_path: Path to the project root
            max_cycles: Maximum number of run-fix cycles
            max_same_error_attempts: Max attempts to fix the same error
            run_tests: Whether to run tests after successful execution
            auto_fix: Whether to attempt automatic fixes
            confidence_threshold: Minimum confidence to apply fixes
        """
        self.config = config
        self.project_path = Path(project_path)
        self.max_cycles = max_cycles
        self.max_same_error_attempts = max_same_error_attempts
        self.run_tests = run_tests
        self.auto_fix = auto_fix
        self.confidence_threshold = confidence_threshold
        
        # Initialize components
        self.runner = ProjectRunner(
            timeout=config.execution.execution_timeout,
            setup_timeout=config.execution.setup_timeout,
            max_retries=config.execution.max_retry_attempts,
        )
        self.error_detector = ErrorDetector()
        self.test_executor = TestExecutor(timeout=config.execution.test_timeout)
        self.auto_fixer = AutoFixer(
            config=config,
            max_attempts=max_same_error_attempts,
            confidence_threshold=confidence_threshold,
        )
        
        # Track state
        self.status = LoopStatus.NOT_STARTED
        self.progress = LoopProgress()
        self.cycles: List[CycleResult] = []
        self._error_hash_counts: Dict[str, int] = {}  # Track error occurrences
        self._seen_error_hashes: Set[str] = set()
        self._cancelled = False
        
        # Timing
        self._start_time: Optional[datetime] = None
        self._end_time: Optional[datetime] = None
    
    def run_development_cycle(
        self,
        setup: bool = True,
        command: Optional[str] = None,
        test_command: Optional[str] = None,
        env: Optional[Dict[str, str]] = None,
    ) -> LoopReport:
        """Main loop: run → test → fix → repeat.
        
        Args:
            setup: Whether to run setup on first cycle
            command: Custom run command
            test_command: Custom test command
            env: Additional environment variables
            
        Returns:
            LoopReport with complete execution history
        """
        self._start_time = datetime.now()
        self.status = LoopStatus.RUNNING
        self._cancelled = False
        
        final_execution_result = None
        final_test_result = None
        
        try:
            for cycle_num in range(1, self.max_cycles + 1):
                if self._cancelled:
                    self.status = LoopStatus.CANCELLED
                    break
                
                cycle_result = self._run_single_cycle(
                    cycle_num,
                    setup=(setup and cycle_num == 1),
                    command=command,
                    test_command=test_command,
                    env=env,
                )
                self.cycles.append(cycle_result)
                
                # Update final results
                if cycle_result.execution_result:
                    final_execution_result = cycle_result.execution_result
                if cycle_result.test_result:
                    final_test_result = cycle_result.test_result
                
                # Track progress
                self._update_progress(cycle_result)
                
                # Check if we should stop
                should_stop, reason = self.should_continue(cycle_result)
                
                if not should_stop:
                    if reason == "success":
                        self.status = LoopStatus.SUCCESS
                    elif reason == "stuck":
                        self.status = LoopStatus.STUCK_IN_LOOP
                    elif reason == "needs_help":
                        self.status = LoopStatus.NEEDS_HUMAN_HELP
                    break
            
            # Check if we exhausted max cycles
            if len(self.cycles) >= self.max_cycles and self.status == LoopStatus.RUNNING:
                self.status = LoopStatus.MAX_RETRIES_REACHED
            
        except Exception as e:
            self.status = LoopStatus.FAILED
        
        self._end_time = datetime.now()
        
        return self.generate_report(final_execution_result, final_test_result)
    
    def _run_single_cycle(
        self,
        cycle_num: int,
        setup: bool,
        command: Optional[str],
        test_command: Optional[str],
        env: Optional[Dict[str, str]],
    ) -> CycleResult:
        """Run a single cycle of the verification loop."""
        cycle_start = time.time()
        cycle = CycleResult(cycle_number=cycle_num)
        
        # Step 1: Run the project
        execution_result = self.runner.run_project(
            self.project_path,
            command=command,
            env=env,
            setup=setup,
        )
        cycle.execution_result = execution_result
        
        # Step 2: Handle execution errors
        if execution_result.status not in (ExecutionStatus.SUCCESS, ExecutionStatus.TIMEOUT):
            cycle.errors_found = execution_result.errors
            
            if self.auto_fix and cycle.errors_found:
                # Attempt to fix errors
                for error in cycle.errors_found:
                    fix_result = self._attempt_fix(error)
                    if fix_result:
                        cycle.fixes_attempted.append(fix_result)
                        if fix_result.result.success:
                            cycle.fixes_successful += 1
                        else:
                            cycle.fixes_failed += 1
            
            cycle.status = "errors_found"
            cycle.duration = time.time() - cycle_start
            return cycle
        
        # Step 3: Run tests if execution succeeded
        if self.run_tests and execution_result.status == ExecutionStatus.SUCCESS:
            test_result = self.test_executor.run_tests(
                self.project_path,
                command=test_command,
            )
            cycle.test_result = test_result
            
            # Handle test failures
            if not test_result.success:
                # Parse test errors
                test_errors = self.error_detector.parse_error_logs(
                    test_result.raw_output,
                    test_result.error_output or "",
                )
                cycle.errors_found.extend(test_errors)
                
                if self.auto_fix and test_errors:
                    for error in test_errors:
                        fix_result = self._attempt_fix(error)
                        if fix_result:
                            cycle.fixes_attempted.append(fix_result)
                            if fix_result.result.success:
                                cycle.fixes_successful += 1
                            else:
                                cycle.fixes_failed += 1
                
                cycle.status = "tests_failed"
            else:
                cycle.status = "success"
        else:
            cycle.status = "success" if execution_result.status == ExecutionStatus.SUCCESS else "execution_completed"
        
        cycle.duration = time.time() - cycle_start
        return cycle
    
    def _attempt_fix(self, error: DetectedError) -> Optional[FixAttempt]:
        """Attempt to fix a single error."""
        # Check if we've tried this error too many times
        error_hash = self._get_error_hash(error)
        
        if self._error_hash_counts.get(error_hash, 0) >= self.max_same_error_attempts:
            return None  # Skip this error
        
        self._error_hash_counts[error_hash] = self._error_hash_counts.get(error_hash, 0) + 1
        self._seen_error_hashes.add(error_hash)
        
        # Analyze the error
        analysis = self.auto_fixer.analyze_error(
            error,
            self.project_path,
            context={"cycle": len(self.cycles) + 1},
        )
        
        # Generate a fix
        fix = self.auto_fixer.generate_fix(error, analysis, self.project_path)
        
        if not fix:
            return None
        
        # Check confidence threshold
        if fix.confidence < self.confidence_threshold:
            return FixAttempt(
                timestamp=datetime.now(),
                error=error,
                fix=fix,
                result=FixResult(
                    success=False,
                    strategy=None,
                    message=f"Confidence too low: {fix.confidence:.2f} < {self.confidence_threshold}",
                ),
            )
        
        # Apply the fix
        result = self.auto_fixer.apply_fix(fix, self.project_path)
        
        return FixAttempt(
            timestamp=datetime.now(),
            error=error,
            fix=fix,
            result=result,
        )
    
    def track_progress(self) -> LoopProgress:
        """Monitor improvements/regressions.
        
        Returns:
            Current progress state
        """
        return self.progress
    
    def _update_progress(self, cycle: CycleResult):
        """Update progress tracking after a cycle."""
        self.progress.total_cycles += 1
        
        # Count errors
        error_count = len(cycle.errors_found)
        self.progress.total_errors_found += error_count
        self.progress.error_count_history.append(error_count)
        
        # Track fixes
        self.progress.total_errors_fixed += cycle.fixes_successful
        
        # Count unique vs repeated errors
        for error in cycle.errors_found:
            error_hash = self._get_error_hash(error)
            if error_hash in self._seen_error_hashes:
                self.progress.repeated_errors += 1
            else:
                self.progress.unique_errors_seen += 1
        
        # Determine trend
        self.progress.trend = self._calculate_trend()
    
    def _calculate_trend(self) -> ProgressTrend:
        """Calculate the progress trend based on error history."""
        history = self.progress.error_count_history
        
        if len(history) < 2:
            return ProgressTrend.UNKNOWN
        
        # Compare last 3 cycles (or available)
        recent = history[-3:]
        
        if all(count == recent[0] for count in recent):
            return ProgressTrend.STALLED
        
        # Check if generally decreasing
        if len(recent) >= 2:
            if recent[-1] < recent[0]:
                return ProgressTrend.IMPROVING
            elif recent[-1] > recent[0]:
                return ProgressTrend.REGRESSING
        
        return ProgressTrend.STALLED
    
    def detect_infinite_loop(self) -> bool:
        """Prevent getting stuck on same error.
        
        Returns:
            True if stuck in an infinite loop
        """
        if len(self.cycles) < 3:
            return False
        
        # Check if last 3 cycles have same errors
        last_3_errors = [
            self._get_cycle_error_signature(cycle)
            for cycle in self.cycles[-3:]
        ]
        
        if len(set(last_3_errors)) == 1 and last_3_errors[0]:
            return True
        
        # Check if error count hasn't changed
        if self.progress.trend == ProgressTrend.STALLED:
            history = self.progress.error_count_history
            if len(history) >= 3 and all(h > 0 for h in history[-3:]):
                return True
        
        return False
    
    def _get_cycle_error_signature(self, cycle: CycleResult) -> str:
        """Get a signature for all errors in a cycle."""
        if not cycle.errors_found:
            return ""
        
        hashes = sorted(self._get_error_hash(e) for e in cycle.errors_found)
        return "|".join(hashes)
    
    def _get_error_hash(self, error: DetectedError) -> str:
        """Generate a hash for an error to track duplicates."""
        # Normalize the error for comparison
        key_parts = [
            error.category.value,
            error.file_path or "",
            str(error.line_number or 0),
            # Normalize message (remove line numbers, paths)
            error.message[:100] if error.message else "",
        ]
        key = "|".join(key_parts)
        return hashlib.md5(key.encode()).hexdigest()[:16]
    
    def should_continue(self, cycle: CycleResult) -> tuple[bool, str]:
        """Decide if loop should continue.
        
        Args:
            cycle: The most recent cycle result
            
        Returns:
            Tuple of (should_continue, reason)
        """
        # Success - stop
        if cycle.status == "success":
            return False, "success"
        
        # Check for infinite loop
        if self.detect_infinite_loop():
            return False, "stuck"
        
        # Check if progress is regressing
        if self.progress.trend == ProgressTrend.REGRESSING:
            if len(self.cycles) >= 3:
                return False, "regressing"
        
        # Check if we've exhausted fix attempts for all errors
        all_errors_exhausted = True
        for error in cycle.errors_found:
            error_hash = self._get_error_hash(error)
            if self._error_hash_counts.get(error_hash, 0) < self.max_same_error_attempts:
                all_errors_exhausted = False
                break
        
        if all_errors_exhausted and cycle.errors_found:
            return False, "needs_help"
        
        # Continue if there are errors and we haven't hit max cycles
        if cycle.errors_found and len(self.cycles) < self.max_cycles:
            return True, "errors_remaining"
        
        # No errors found
        if not cycle.errors_found:
            return False, "success"
        
        return True, "continue"
    
    def generate_report(
        self,
        final_execution: Optional[ExecutionResult] = None,
        final_tests: Optional[TestResult] = None,
    ) -> LoopReport:
        """Create detailed report of the entire process.
        
        Args:
            final_execution: The last execution result
            final_tests: The last test result
            
        Returns:
            Comprehensive LoopReport
        """
        end_time = self._end_time or datetime.now()
        start_time = self._start_time or datetime.now()
        total_duration = (end_time - start_time).total_seconds()
        
        # Generate summary
        summary = self._generate_summary()
        
        # Generate recommendations
        recommendations = self._generate_recommendations()
        
        return LoopReport(
            status=self.status,
            progress=self.progress,
            cycles=self.cycles,
            total_duration=total_duration,
            start_time=start_time,
            end_time=end_time,
            final_execution_result=final_execution,
            final_test_result=final_tests,
            summary=summary,
            recommendations=recommendations,
        )
    
    def _generate_summary(self) -> str:
        """Generate a human-readable summary."""
        lines = ["# Verification Loop Summary\n"]
        
        # Status
        status_emoji = {
            LoopStatus.SUCCESS: "✅",
            LoopStatus.FAILED: "❌",
            LoopStatus.MAX_RETRIES_REACHED: "⚠️",
            LoopStatus.STUCK_IN_LOOP: "🔄",
            LoopStatus.NEEDS_HUMAN_HELP: "🆘",
            LoopStatus.CANCELLED: "🛑",
        }
        
        emoji = status_emoji.get(self.status, "❓")
        lines.append(f"## Status: {emoji} {self.status.value}\n")
        
        # Overview
        lines.append("## Overview\n")
        lines.append(f"- **Total Cycles:** {self.progress.total_cycles}")
        lines.append(f"- **Total Errors Found:** {self.progress.total_errors_found}")
        lines.append(f"- **Errors Fixed:** {self.progress.total_errors_fixed}")
        lines.append(f"- **Unique Errors:** {self.progress.unique_errors_seen}")
        lines.append(f"- **Repeated Errors:** {self.progress.repeated_errors}")
        lines.append(f"- **Progress Trend:** {self.progress.trend.value}")
        
        # Cycle details
        if self.cycles:
            lines.append("\n## Cycle History\n")
            for cycle in self.cycles:
                lines.append(f"### Cycle {cycle.cycle_number}")
                lines.append(f"- Status: {cycle.status}")
                lines.append(f"- Errors: {len(cycle.errors_found)}")
                lines.append(f"- Fixes Attempted: {len(cycle.fixes_attempted)}")
                lines.append(f"- Fixes Successful: {cycle.fixes_successful}")
                lines.append(f"- Duration: {cycle.duration:.2f}s\n")
        
        return "\n".join(lines)
    
    def _generate_recommendations(self) -> List[str]:
        """Generate recommendations based on the loop results."""
        recommendations = []
        
        if self.status == LoopStatus.SUCCESS:
            recommendations.append("✅ Project is working! Consider adding more tests.")
            return recommendations
        
        if self.status == LoopStatus.STUCK_IN_LOOP:
            recommendations.append(
                "🔄 Loop detected the same errors repeatedly. "
                "These errors may require manual intervention or architecture changes."
            )
        
        if self.status == LoopStatus.NEEDS_HUMAN_HELP:
            recommendations.append(
                "🆘 Some errors could not be auto-fixed. "
                "Review the error logs and consider manual fixes."
            )
        
        if self.status == LoopStatus.MAX_RETRIES_REACHED:
            recommendations.append(
                "⚠️ Maximum retries reached. Consider:\n"
                "  - Reviewing the error patterns\n"
                "  - Increasing max_cycles if progress was being made\n"
                "  - Manual debugging for persistent issues"
            )
        
        # Analyze error patterns
        error_categories: Dict[ErrorCategory, int] = {}
        for cycle in self.cycles:
            for error in cycle.errors_found:
                error_categories[error.category] = error_categories.get(error.category, 0) + 1
        
        if error_categories:
            most_common = max(error_categories.items(), key=lambda x: x[1])
            recommendations.append(
                f"📊 Most common error type: {most_common[0].value} ({most_common[1]} occurrences)"
            )
            
            # Category-specific recommendations
            if ErrorCategory.DEPENDENCY in error_categories:
                recommendations.append(
                    "📦 Dependency issues detected. Try:\n"
                    "  - Clearing node_modules or venv\n"
                    "  - Checking package.json or requirements.txt\n"
                    "  - Running a fresh install"
                )
            
            if ErrorCategory.SYNTAX in error_categories:
                recommendations.append(
                    "⚠️ Syntax errors detected. Consider:\n"
                    "  - Using a linter (ESLint, Pylint)\n"
                    "  - IDE with syntax checking\n"
                    "  - Reviewing recent code changes"
                )
            
            if ErrorCategory.TYPE in error_categories:
                recommendations.append(
                    "🔤 Type errors detected. Consider:\n"
                    "  - Adding TypeScript or type hints\n"
                    "  - Reviewing function signatures\n"
                    "  - Adding runtime type checking"
                )
        
        # Progress-based recommendations
        if self.progress.trend == ProgressTrend.REGRESSING:
            recommendations.append(
                "📉 Error count is increasing. Recent fixes may have introduced new issues. "
                "Consider rolling back to a previous working state."
            )
        
        return recommendations
    
    def cancel(self):
        """Cancel the verification loop."""
        self._cancelled = True
        self.runner.cancel()
    
    def get_fix_history(self) -> List[FixAttempt]:
        """Get all fix attempts from all cycles."""
        all_fixes = []
        for cycle in self.cycles:
            all_fixes.extend(cycle.fixes_attempted)
        return all_fixes
    
    def export_report(self, output_path: Path) -> bool:
        """Export the report to a file.
        
        Args:
            output_path: Path to save the report
            
        Returns:
            True if export successful
        """
        try:
            report = self.generate_report()
            
            # Create markdown report
            content = report.summary + "\n\n"
            
            if report.recommendations:
                content += "## Recommendations\n\n"
                for rec in report.recommendations:
                    content += f"- {rec}\n"
            
            content += f"\n---\n*Generated at {report.end_time.isoformat()}*"
            
            output_path.write_text(content)
            return True
        except Exception as e:
            return False
