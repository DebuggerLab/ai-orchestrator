"""Test execution and result collection for projects."""

import re
import subprocess
import time
from pathlib import Path
from typing import Optional, List, Dict, Any
from dataclasses import dataclass, field
from enum import Enum


class TestFramework(Enum):
    """Supported test frameworks."""
    PYTEST = "pytest"
    UNITTEST = "unittest"
    JEST = "jest"
    MOCHA = "mocha"
    VITEST = "vitest"
    DJANGO = "django"
    UNKNOWN = "unknown"


class TestStatus(Enum):
    """Status of a test."""
    PASSED = "passed"
    FAILED = "failed"
    SKIPPED = "skipped"
    ERROR = "error"
    PENDING = "pending"


@dataclass
class TestCase:
    """Represents a single test case result."""
    name: str
    status: TestStatus
    duration: float = 0.0
    file_path: Optional[str] = None
    error_message: Optional[str] = None
    stack_trace: Optional[str] = None


@dataclass
class TestSuite:
    """Represents a test suite (collection of test cases)."""
    name: str
    tests: List[TestCase] = field(default_factory=list)
    file_path: Optional[str] = None
    
    @property
    def passed(self) -> int:
        return sum(1 for t in self.tests if t.status == TestStatus.PASSED)
    
    @property
    def failed(self) -> int:
        return sum(1 for t in self.tests if t.status in (TestStatus.FAILED, TestStatus.ERROR))
    
    @property
    def skipped(self) -> int:
        return sum(1 for t in self.tests if t.status == TestStatus.SKIPPED)


@dataclass
class TestResult:
    """Overall test execution result."""
    framework: TestFramework
    success: bool
    total_tests: int = 0
    passed: int = 0
    failed: int = 0
    skipped: int = 0
    errors: int = 0
    duration: float = 0.0
    suites: List[TestSuite] = field(default_factory=list)
    raw_output: str = ""
    command: str = ""
    exit_code: int = 0


class TestExecutor:
    """Execute tests and collect results for projects."""
    
    # Framework detection patterns
    FRAMEWORK_INDICATORS: Dict[TestFramework, List[str]] = {
        TestFramework.PYTEST: ["pytest.ini", "pyproject.toml", "conftest.py", "test_*.py"],
        TestFramework.UNITTEST: ["test_*.py"],
        TestFramework.JEST: ["jest.config.js", "jest.config.ts", "jest.config.json"],
        TestFramework.MOCHA: ["mocha.opts", ".mocharc.js", ".mocharc.json"],
        TestFramework.VITEST: ["vitest.config.js", "vitest.config.ts"],
        TestFramework.DJANGO: ["manage.py"],
    }
    
    # Default test commands per framework
    DEFAULT_COMMANDS: Dict[TestFramework, str] = {
        TestFramework.PYTEST: "pytest -v --tb=short",
        TestFramework.UNITTEST: "python -m unittest discover -v",
        TestFramework.JEST: "npm test -- --verbose",
        TestFramework.MOCHA: "npm test",
        TestFramework.VITEST: "npm test",
        TestFramework.DJANGO: "python manage.py test -v 2",
    }
    
    def __init__(self, timeout: int = 300, max_output_size: int = 100000):
        """Initialize the test executor.
        
        Args:
            timeout: Maximum time in seconds to wait for tests to complete
            max_output_size: Maximum size of captured output in characters
        """
        self.timeout = timeout
        self.max_output_size = max_output_size
    
    def detect_test_framework(self, project_path: Path) -> TestFramework:
        """Identify the test framework used in the project.
        
        Args:
            project_path: Path to the project root
            
        Returns:
            Detected TestFramework enum value
        """
        # Check package.json for JS frameworks
        package_json_path = project_path / "package.json"
        if package_json_path.exists():
            try:
                import json
                with open(package_json_path) as f:
                    pkg = json.load(f)
                
                deps = {**pkg.get("dependencies", {}), **pkg.get("devDependencies", {})}
                
                if "vitest" in deps:
                    return TestFramework.VITEST
                if "jest" in deps:
                    return TestFramework.JEST
                if "mocha" in deps:
                    return TestFramework.MOCHA
            except Exception:
                pass
        
        # Check for framework-specific config files
        for framework, indicators in self.FRAMEWORK_INDICATORS.items():
            for indicator in indicators:
                if "*" in indicator:
                    # Glob pattern
                    if list(project_path.glob(indicator)):
                        return framework
                elif (project_path / indicator).exists():
                    # Direct file check
                    if framework == TestFramework.DJANGO:
                        # Verify it's actually Django
                        manage_py = project_path / "manage.py"
                        if manage_py.exists():
                            content = manage_py.read_text()
                            if "django" in content.lower():
                                return TestFramework.DJANGO
                    else:
                        return framework
        
        # Check pyproject.toml for pytest
        pyproject_path = project_path / "pyproject.toml"
        if pyproject_path.exists():
            try:
                content = pyproject_path.read_text()
                if "pytest" in content or "[tool.pytest" in content:
                    return TestFramework.PYTEST
            except Exception:
                pass
        
        # Default to pytest if Python project has test files
        if list(project_path.glob("test_*.py")) or list(project_path.glob("tests/test_*.py")):
            return TestFramework.PYTEST
        
        return TestFramework.UNKNOWN
    
    def run_tests(
        self,
        project_path: Path,
        command: Optional[str] = None,
        framework: Optional[TestFramework] = None,
        env: Optional[Dict[str, str]] = None,
    ) -> TestResult:
        """Execute test suite for the project.
        
        Args:
            project_path: Path to the project root
            command: Custom test command (optional)
            framework: Force a specific framework (optional)
            env: Additional environment variables
            
        Returns:
            TestResult with execution details
        """
        # Detect framework if not specified
        if framework is None:
            framework = self.detect_test_framework(project_path)
        
        # Determine test command
        if command is None:
            command = self.DEFAULT_COMMANDS.get(framework, "")
        
        if not command:
            return TestResult(
                framework=framework,
                success=False,
                raw_output="No test command available for detected framework",
                command="",
                exit_code=-1,
            )
        
        # Prepare environment
        import os
        run_env = os.environ.copy()
        if env:
            run_env.update(env)
        
        # Run tests
        start_time = time.time()
        try:
            result = subprocess.run(
                command,
                shell=True,
                cwd=str(project_path),
                capture_output=True,
                text=True,
                timeout=self.timeout,
                env=run_env,
            )
            
            duration = time.time() - start_time
            output = result.stdout + "\n" + result.stderr
            
            # Truncate output if necessary
            if len(output) > self.max_output_size:
                output = output[:self.max_output_size] + "\n... (output truncated)"
            
            # Parse results based on framework
            parsed = self.parse_test_results(output, framework)
            parsed.duration = duration
            parsed.raw_output = output
            parsed.command = command
            parsed.exit_code = result.returncode
            parsed.success = result.returncode == 0
            
            return parsed
            
        except subprocess.TimeoutExpired:
            return TestResult(
                framework=framework,
                success=False,
                raw_output=f"Test execution timed out after {self.timeout} seconds",
                command=command,
                exit_code=-1,
                duration=self.timeout,
            )
        except Exception as e:
            return TestResult(
                framework=framework,
                success=False,
                raw_output=f"Error executing tests: {str(e)}",
                command=command,
                exit_code=-1,
            )
    
    def parse_test_results(self, output: str, framework: TestFramework) -> TestResult:
        """Extract pass/fail information from test output.
        
        Args:
            output: Raw test output
            framework: The test framework used
            
        Returns:
            TestResult with parsed information
        """
        parsers = {
            TestFramework.PYTEST: self._parse_pytest_output,
            TestFramework.JEST: self._parse_jest_output,
            TestFramework.MOCHA: self._parse_mocha_output,
            TestFramework.VITEST: self._parse_vitest_output,
            TestFramework.UNITTEST: self._parse_unittest_output,
            TestFramework.DJANGO: self._parse_django_output,
        }
        
        parser = parsers.get(framework, self._parse_generic_output)
        return parser(output)
    
    def generate_test_report(self, result: TestResult) -> str:
        """Create summary report from test results.
        
        Args:
            result: TestResult to summarize
            
        Returns:
            Formatted report string
        """
        lines = []
        lines.append("# Test Execution Report\n")
        lines.append(f"**Framework:** {result.framework.value}")
        lines.append(f"**Command:** `{result.command}`")
        lines.append(f"**Duration:** {result.duration:.2f}s")
        lines.append(f"**Exit Code:** {result.exit_code}")
        lines.append("")
        
        # Summary
        lines.append("## Summary\n")
        status = "✅ PASSED" if result.success else "❌ FAILED"
        lines.append(f"**Status:** {status}")
        lines.append(f"")
        lines.append(f"| Metric | Count |")
        lines.append(f"|--------|-------|")
        lines.append(f"| Total  | {result.total_tests} |")
        lines.append(f"| Passed | {result.passed} |")
        lines.append(f"| Failed | {result.failed} |")
        lines.append(f"| Skipped| {result.skipped} |")
        lines.append(f"| Errors | {result.errors} |")
        lines.append("")
        
        # Failed tests details
        if result.suites:
            failed_tests = []
            for suite in result.suites:
                for test in suite.tests:
                    if test.status in (TestStatus.FAILED, TestStatus.ERROR):
                        failed_tests.append((suite.name, test))
            
            if failed_tests:
                lines.append("## Failed Tests\n")
                for suite_name, test in failed_tests:
                    lines.append(f"### {suite_name}::{test.name}")
                    if test.file_path:
                        lines.append(f"**File:** {test.file_path}")
                    if test.error_message:
                        lines.append(f"**Error:** {test.error_message}")
                    if test.stack_trace:
                        lines.append(f"```\n{test.stack_trace}\n```")
                    lines.append("")
        
        return "\n".join(lines)
    
    def _parse_pytest_output(self, output: str) -> TestResult:
        """Parse pytest output."""
        result = TestResult(framework=TestFramework.PYTEST, success=False)
        
        # Parse summary line: "X passed, Y failed, Z skipped"
        summary_match = re.search(
            r'(\d+)\s+passed(?:.*?(\d+)\s+failed)?(?:.*?(\d+)\s+skipped)?(?:.*?(\d+)\s+error)?',
            output
        )
        if summary_match:
            result.passed = int(summary_match.group(1) or 0)
            result.failed = int(summary_match.group(2) or 0)
            result.skipped = int(summary_match.group(3) or 0)
            result.errors = int(summary_match.group(4) or 0)
            result.total_tests = result.passed + result.failed + result.skipped + result.errors
            result.success = result.failed == 0 and result.errors == 0
        
        # Parse individual test results
        suite = TestSuite(name="pytest")
        test_pattern = re.compile(r'^([\w/\.]+::[\w_]+)\s+(PASSED|FAILED|SKIPPED|ERROR)', re.MULTILINE)
        for match in test_pattern.finditer(output):
            test_name = match.group(1)
            status_str = match.group(2)
            status_map = {
                "PASSED": TestStatus.PASSED,
                "FAILED": TestStatus.FAILED,
                "SKIPPED": TestStatus.SKIPPED,
                "ERROR": TestStatus.ERROR,
            }
            suite.tests.append(TestCase(
                name=test_name,
                status=status_map.get(status_str, TestStatus.ERROR)
            ))
        
        if suite.tests:
            result.suites.append(suite)
        
        return result
    
    def _parse_jest_output(self, output: str) -> TestResult:
        """Parse Jest output."""
        result = TestResult(framework=TestFramework.JEST, success=False)
        
        # Parse summary: "Tests: X passed, Y failed, Z total"
        summary_match = re.search(
            r'Tests:\s+(?:(\d+)\s+failed,\s*)?(?:(\d+)\s+skipped,\s*)?(?:(\d+)\s+passed,\s*)?(\d+)\s+total',
            output
        )
        if summary_match:
            result.failed = int(summary_match.group(1) or 0)
            result.skipped = int(summary_match.group(2) or 0)
            result.passed = int(summary_match.group(3) or 0)
            result.total_tests = int(summary_match.group(4) or 0)
            result.success = result.failed == 0
        
        # Parse test suites
        suite_pattern = re.compile(r'(PASS|FAIL)\s+([^\n]+)')
        for match in suite_pattern.finditer(output):
            status = match.group(1)
            suite_name = match.group(2).strip()
            suite = TestSuite(
                name=suite_name,
                file_path=suite_name
            )
            result.suites.append(suite)
        
        return result
    
    def _parse_mocha_output(self, output: str) -> TestResult:
        """Parse Mocha output."""
        result = TestResult(framework=TestFramework.MOCHA, success=False)
        
        # Parse summary: "X passing (Ys)" "Y failing"
        passing_match = re.search(r'(\d+)\s+passing', output)
        failing_match = re.search(r'(\d+)\s+failing', output)
        pending_match = re.search(r'(\d+)\s+pending', output)
        
        result.passed = int(passing_match.group(1)) if passing_match else 0
        result.failed = int(failing_match.group(1)) if failing_match else 0
        result.skipped = int(pending_match.group(1)) if pending_match else 0
        result.total_tests = result.passed + result.failed + result.skipped
        result.success = result.failed == 0
        
        return result
    
    def _parse_vitest_output(self, output: str) -> TestResult:
        """Parse Vitest output."""
        result = TestResult(framework=TestFramework.VITEST, success=False)
        
        # Vitest has similar output to Jest
        summary_match = re.search(
            r'Tests\s+(\d+)\s+failed\s*\|?\s*(\d+)\s+passed',
            output
        )
        if summary_match:
            result.failed = int(summary_match.group(1))
            result.passed = int(summary_match.group(2))
            result.total_tests = result.passed + result.failed
            result.success = result.failed == 0
        else:
            # Try alternate format
            pass_match = re.search(r'(\d+)\s+passed', output)
            fail_match = re.search(r'(\d+)\s+failed', output)
            if pass_match:
                result.passed = int(pass_match.group(1))
            if fail_match:
                result.failed = int(fail_match.group(1))
            result.total_tests = result.passed + result.failed
            result.success = result.failed == 0
        
        return result
    
    def _parse_unittest_output(self, output: str) -> TestResult:
        """Parse Python unittest output."""
        result = TestResult(framework=TestFramework.UNITTEST, success=False)
        
        # Parse "Ran X tests in Ys"
        ran_match = re.search(r'Ran (\d+) tests? in ([\d.]+)s', output)
        if ran_match:
            result.total_tests = int(ran_match.group(1))
            result.duration = float(ran_match.group(2))
        
        # Check for OK or FAILED
        if re.search(r'^OK$', output, re.MULTILINE):
            result.success = True
            result.passed = result.total_tests
        else:
            # Parse failures/errors
            fail_match = re.search(r'FAILED \((?:failures=(\d+))?(?:,?\s*errors=(\d+))?', output)
            if fail_match:
                result.failed = int(fail_match.group(1) or 0)
                result.errors = int(fail_match.group(2) or 0)
                result.passed = result.total_tests - result.failed - result.errors
        
        return result
    
    def _parse_django_output(self, output: str) -> TestResult:
        """Parse Django test output."""
        # Django uses unittest under the hood
        result = self._parse_unittest_output(output)
        result.framework = TestFramework.DJANGO
        return result
    
    def _parse_generic_output(self, output: str) -> TestResult:
        """Parse generic test output."""
        result = TestResult(framework=TestFramework.UNKNOWN, success=False)
        
        # Try to find common patterns
        pass_patterns = [r'(\d+)\s+(?:tests?\s+)?pass(?:ed|ing)?', r'passed:\s*(\d+)']
        fail_patterns = [r'(\d+)\s+(?:tests?\s+)?fail(?:ed|ing)?', r'failed:\s*(\d+)']
        
        for pattern in pass_patterns:
            match = re.search(pattern, output, re.IGNORECASE)
            if match:
                result.passed = int(match.group(1))
                break
        
        for pattern in fail_patterns:
            match = re.search(pattern, output, re.IGNORECASE)
            if match:
                result.failed = int(match.group(1))
                break
        
        result.total_tests = result.passed + result.failed
        result.success = result.failed == 0 and result.passed > 0
        
        return result
