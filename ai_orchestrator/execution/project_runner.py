"""Main project runner for executing projects safely."""

import os
import signal
import subprocess
import threading
import time
from pathlib import Path
from typing import Optional, Dict, List, Callable, Any
from dataclasses import dataclass, field
from enum import Enum
import queue

from .project_types import (
    detect_project_type,
    BaseProjectHandler,
    ProjectConfig,
    PROJECT_HANDLERS,
)
from .error_detector import ErrorDetector, DetectedError
from .test_executor import TestExecutor, TestResult


class ExecutionStatus(Enum):
    """Status of project execution."""
    PENDING = "pending"
    SETTING_UP = "setting_up"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    TIMEOUT = "timeout"
    CANCELLED = "cancelled"


@dataclass
class ExecutionResult:
    """Result of project execution."""
    status: ExecutionStatus
    project_type: str
    stdout: str = ""
    stderr: str = ""
    exit_code: Optional[int] = None
    duration: float = 0.0
    errors: List[DetectedError] = field(default_factory=list)
    test_results: Optional[TestResult] = None
    setup_output: str = ""
    config: Optional[ProjectConfig] = None
    message: str = ""


class OutputCapture:
    """Thread-safe output capture for subprocess streams."""
    
    def __init__(self, max_size: int = 500000):
        self.max_size = max_size
        self._stdout: List[str] = []
        self._stderr: List[str] = []
        self._lock = threading.Lock()
        self._current_size = 0
    
    def add_stdout(self, line: str) -> None:
        with self._lock:
            if self._current_size < self.max_size:
                self._stdout.append(line)
                self._current_size += len(line)
    
    def add_stderr(self, line: str) -> None:
        with self._lock:
            if self._current_size < self.max_size:
                self._stderr.append(line)
                self._current_size += len(line)
    
    @property
    def stdout(self) -> str:
        with self._lock:
            return "".join(self._stdout)
    
    @property
    def stderr(self) -> str:
        with self._lock:
            return "".join(self._stderr)


class ProjectRunner:
    """Main class for running projects with error detection."""
    
    def __init__(
        self,
        timeout: int = 300,
        setup_timeout: int = 600,
        max_retries: int = 3,
        max_output_size: int = 500000,
        error_log_size_limit: int = 100000,
    ):
        """Initialize the project runner.
        
        Args:
            timeout: Maximum execution time in seconds
            setup_timeout: Maximum setup/install time in seconds
            max_retries: Maximum retry attempts on failure
            max_output_size: Maximum captured output size in characters
            error_log_size_limit: Maximum error log size for analysis
        """
        self.timeout = timeout
        self.setup_timeout = setup_timeout
        self.max_retries = max_retries
        self.max_output_size = max_output_size
        self.error_log_size_limit = error_log_size_limit
        
        self.error_detector = ErrorDetector()
        self.test_executor = TestExecutor(timeout=timeout)
        
        self._current_process: Optional[subprocess.Popen] = None
        self._cancelled = False
    
    def detect_project_type(self, project_path: Path) -> BaseProjectHandler:
        """Auto-detect project type.
        
        Args:
            project_path: Path to the project root
            
        Returns:
            Appropriate project handler
        """
        return detect_project_type(project_path)
    
    def setup_environment(
        self,
        project_path: Path,
        config: Optional[ProjectConfig] = None,
        env: Optional[Dict[str, str]] = None,
    ) -> tuple[bool, str]:
        """Install dependencies and set up the project.
        
        Args:
            project_path: Path to the project root
            config: Project configuration (auto-detected if not provided)
            env: Additional environment variables
            
        Returns:
            Tuple of (success, output)
        """
        if config is None:
            handler = self.detect_project_type(project_path)
            config = handler.get_config(project_path)
        
        if not config.install_command:
            return True, "No installation required"
        
        # Prepare environment
        run_env = os.environ.copy()
        if config.environment:
            run_env.update(config.environment)
        if env:
            run_env.update(env)
        
        try:
            result = subprocess.run(
                config.install_command,
                shell=True,
                cwd=str(project_path),
                capture_output=True,
                text=True,
                timeout=self.setup_timeout,
                env=run_env,
            )
            
            output = result.stdout + "\n" + result.stderr
            
            if result.returncode != 0:
                return False, f"Setup failed (exit code {result.returncode}):\n{output}"
            
            return True, output
            
        except subprocess.TimeoutExpired:
            return False, f"Setup timed out after {self.setup_timeout} seconds"
        except Exception as e:
            return False, f"Setup error: {str(e)}"
    
    def run_project(
        self,
        project_path: Path,
        command: Optional[str] = None,
        config: Optional[ProjectConfig] = None,
        env: Optional[Dict[str, str]] = None,
        setup: bool = True,
        stream_output: bool = False,
        output_callback: Optional[Callable[[str, str], None]] = None,
    ) -> ExecutionResult:
        """Execute the project.
        
        Args:
            project_path: Path to the project root
            command: Custom run command (optional)
            config: Project configuration (auto-detected if not provided)
            env: Additional environment variables
            setup: Whether to run setup before execution
            stream_output: Whether to stream output in real-time
            output_callback: Callback for streaming output (line, stream_type)
            
        Returns:
            ExecutionResult with execution details
        """
        self._cancelled = False
        project_path = Path(project_path)
        
        # Detect project type
        handler = self.detect_project_type(project_path)
        if config is None:
            config = handler.get_config(project_path)
        
        result = ExecutionResult(
            status=ExecutionStatus.PENDING,
            project_type=handler.name,
            config=config,
        )
        
        # Setup environment if requested
        if setup and config.install_command:
            result.status = ExecutionStatus.SETTING_UP
            success, setup_output = self.setup_environment(project_path, config, env)
            result.setup_output = setup_output
            
            if not success:
                result.status = ExecutionStatus.FAILED
                result.message = "Setup failed"
                result.errors = self.error_detector.parse_error_logs(setup_output)
                return result
        
        # Determine run command
        run_command = command or config.run_command or config.dev_command
        if not run_command:
            result.status = ExecutionStatus.FAILED
            result.message = "No run command available"
            return result
        
        # Prepare environment
        run_env = os.environ.copy()
        if config.environment:
            run_env.update(config.environment)
        if env:
            run_env.update(env)
        
        # Execute with retry support
        for attempt in range(self.max_retries):
            if self._cancelled:
                result.status = ExecutionStatus.CANCELLED
                result.message = "Execution cancelled"
                return result
            
            exec_result = self._execute_command(
                run_command,
                project_path,
                run_env,
                stream_output,
                output_callback,
            )
            
            result.stdout = exec_result["stdout"]
            result.stderr = exec_result["stderr"]
            result.exit_code = exec_result["exit_code"]
            result.duration = exec_result["duration"]
            result.status = exec_result["status"]
            
            if result.status == ExecutionStatus.SUCCESS:
                break
            
            # Don't retry on certain conditions
            if result.status in (ExecutionStatus.TIMEOUT, ExecutionStatus.CANCELLED):
                break
        
        # Detect errors
        result.errors = self.detect_errors(result.stdout, result.stderr)
        
        if result.errors and result.status == ExecutionStatus.SUCCESS:
            # Check if errors are actually critical
            critical_errors = [e for e in result.errors if e.severity == "error"]
            if critical_errors:
                result.status = ExecutionStatus.FAILED
        
        return result
    
    def capture_output(
        self,
        process: subprocess.Popen,
        capture: OutputCapture,
        stream_output: bool = False,
        callback: Optional[Callable[[str, str], None]] = None,
    ) -> None:
        """Capture stdout/stderr from a running process.
        
        Args:
            process: Running subprocess
            capture: OutputCapture instance
            stream_output: Whether to print output in real-time
            callback: Optional callback for each line
        """
        def read_stream(stream, add_func, stream_name):
            try:
                for line in iter(stream.readline, ''):
                    if line:
                        add_func(line)
                        if stream_output:
                            print(line, end='')
                        if callback:
                            callback(line, stream_name)
            except Exception:
                pass
        
        stdout_thread = threading.Thread(
            target=read_stream,
            args=(process.stdout, capture.add_stdout, "stdout")
        )
        stderr_thread = threading.Thread(
            target=read_stream,
            args=(process.stderr, capture.add_stderr, "stderr")
        )
        
        stdout_thread.daemon = True
        stderr_thread.daemon = True
        stdout_thread.start()
        stderr_thread.start()
        
        # Wait for threads to finish or timeout
        stdout_thread.join(timeout=self.timeout)
        stderr_thread.join(timeout=1)
    
    def detect_errors(self, stdout: str, stderr: str) -> List[DetectedError]:
        """Identify runtime errors from output.
        
        Args:
            stdout: Standard output
            stderr: Standard error
            
        Returns:
            List of detected errors
        """
        # Truncate logs if necessary
        if len(stdout) > self.error_log_size_limit:
            stdout = stdout[-self.error_log_size_limit:]
        if len(stderr) > self.error_log_size_limit:
            stderr = stderr[-self.error_log_size_limit:]
        
        return self.error_detector.parse_error_logs(stdout, stderr)
    
    def run_tests(
        self,
        project_path: Path,
        command: Optional[str] = None,
        setup: bool = True,
    ) -> TestResult:
        """Run tests for the project.
        
        Args:
            project_path: Path to the project root
            command: Custom test command
            setup: Whether to setup before testing
            
        Returns:
            TestResult with test execution details
        """
        project_path = Path(project_path)
        
        # Setup if needed
        if setup:
            handler = self.detect_project_type(project_path)
            config = handler.get_config(project_path)
            success, _ = self.setup_environment(project_path, config)
            if not success:
                return TestResult(
                    framework=self.test_executor.detect_test_framework(project_path),
                    success=False,
                    raw_output="Setup failed before tests",
                    exit_code=-1,
                )
        
        return self.test_executor.run_tests(project_path, command)
    
    def cancel(self) -> None:
        """Cancel the current execution."""
        self._cancelled = True
        if self._current_process:
            try:
                # Try graceful termination first
                self._current_process.terminate()
                try:
                    self._current_process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    # Force kill
                    self._current_process.kill()
            except Exception:
                pass
    
    def _execute_command(
        self,
        command: str,
        cwd: Path,
        env: Dict[str, str],
        stream_output: bool,
        callback: Optional[Callable[[str, str], None]],
    ) -> Dict[str, Any]:
        """Execute a command with output capture and timeout."""
        capture = OutputCapture(max_size=self.max_output_size)
        start_time = time.time()
        
        try:
            self._current_process = subprocess.Popen(
                command,
                shell=True,
                cwd=str(cwd),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                env=env,
                preexec_fn=os.setsid if os.name != 'nt' else None,
            )
            
            # Capture output in background threads
            self.capture_output(
                self._current_process,
                capture,
                stream_output,
                callback,
            )
            
            # Wait for process with timeout
            try:
                exit_code = self._current_process.wait(timeout=self.timeout)
            except subprocess.TimeoutExpired:
                # Kill process group
                if os.name != 'nt':
                    try:
                        os.killpg(os.getpgid(self._current_process.pid), signal.SIGTERM)
                    except Exception:
                        self._current_process.kill()
                else:
                    self._current_process.kill()
                
                return {
                    "stdout": capture.stdout,
                    "stderr": capture.stderr + f"\nProcess timed out after {self.timeout}s",
                    "exit_code": -1,
                    "duration": self.timeout,
                    "status": ExecutionStatus.TIMEOUT,
                }
            
            duration = time.time() - start_time
            status = ExecutionStatus.SUCCESS if exit_code == 0 else ExecutionStatus.FAILED
            
            return {
                "stdout": capture.stdout,
                "stderr": capture.stderr,
                "exit_code": exit_code,
                "duration": duration,
                "status": status,
            }
            
        except Exception as e:
            return {
                "stdout": capture.stdout,
                "stderr": capture.stderr + f"\nExecution error: {str(e)}",
                "exit_code": -1,
                "duration": time.time() - start_time,
                "status": ExecutionStatus.FAILED,
            }
        finally:
            self._current_process = None
    
    def get_execution_summary(self, result: ExecutionResult) -> str:
        """Generate a summary of the execution result.
        
        Args:
            result: ExecutionResult to summarize
            
        Returns:
            Formatted summary string
        """
        lines = []
        lines.append("# Project Execution Summary\n")
        lines.append(f"**Project Type:** {result.project_type}")
        lines.append(f"**Status:** {result.status.value}")
        lines.append(f"**Duration:** {result.duration:.2f}s")
        
        if result.exit_code is not None:
            lines.append(f"**Exit Code:** {result.exit_code}")
        
        if result.message:
            lines.append(f"**Message:** {result.message}")
        
        lines.append("")
        
        if result.errors:
            lines.append("## Errors Detected\n")
            lines.append(self.error_detector.generate_error_report(result.errors))
        
        if result.test_results:
            lines.append("## Test Results\n")
            lines.append(self.test_executor.generate_test_report(result.test_results))
        
        # Output snippets
        if result.stdout:
            lines.append("## Standard Output (Last 50 lines)\n")
            stdout_lines = result.stdout.strip().split("\n")[-50:]
            lines.append(f"```\n{chr(10).join(stdout_lines)}\n```")
        
        if result.stderr and result.status != ExecutionStatus.SUCCESS:
            lines.append("## Standard Error (Last 50 lines)\n")
            stderr_lines = result.stderr.strip().split("\n")[-50:]
            lines.append(f"```\n{chr(10).join(stderr_lines)}\n```")
        
        return "\n".join(lines)
