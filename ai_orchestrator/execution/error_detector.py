"""Error detection and analysis for project execution."""

import re
from typing import List, Dict, Optional, Any
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path


class ErrorCategory(Enum):
    """Categories of errors."""
    SYNTAX = "syntax"
    RUNTIME = "runtime"
    DEPENDENCY = "dependency"
    IMPORT = "import"
    TYPE = "type"
    PERMISSION = "permission"
    NETWORK = "network"
    FILE_NOT_FOUND = "file_not_found"
    CONFIGURATION = "configuration"
    TIMEOUT = "timeout"
    MEMORY = "memory"
    PORT_IN_USE = "port_in_use"
    TEST_FAILURE = "test_failure"
    # iOS-specific categories
    SWIFT_COMPILATION = "swift_compilation"
    CODE_SIGNING = "code_signing"
    SIMULATOR = "simulator"
    XCODE_BUILD = "xcode_build"
    SWIFTUI_PREVIEW = "swiftui_preview"
    UNKNOWN = "unknown"


@dataclass
class DetectedError:
    """Represents a detected error with context."""
    category: ErrorCategory
    message: str
    line_number: Optional[int] = None
    file_path: Optional[str] = None
    stack_trace: Optional[str] = None
    raw_output: Optional[str] = None
    severity: str = "error"  # error, warning, info
    suggested_fixes: List[str] = field(default_factory=list)
    context_lines: List[str] = field(default_factory=list)


class ErrorDetector:
    """Parse and analyze runtime errors from project execution."""
    
    # Error pattern mapping to categories
    ERROR_PATTERNS: Dict[ErrorCategory, List[str]] = {
        ErrorCategory.SYNTAX: [
            r"SyntaxError:",
            r"IndentationError:",
            r"TabError:",
            r"Unexpected token",
            r"Parsing error",
            r"Invalid syntax",
        ],
        ErrorCategory.RUNTIME: [
            r"RuntimeError:",
            r"UnhandledPromiseRejection",
            r"Uncaught Error:",
            r"at Object\.<anonymous>",
            r"RangeError:",
        ],
        ErrorCategory.DEPENDENCY: [
            r"npm ERR! missing:",
            r"npm ERR! peer dep",
            r"Could not resolve dependencies",
            r"ERESOLVE unable to resolve",
            r"Package .* not found",
            r"No matching distribution found",
            r"pip install",
        ],
        ErrorCategory.IMPORT: [
            r"ModuleNotFoundError:",
            r"ImportError:",
            r"Cannot find module",
            r"Module not found:",
            r"No module named",
        ],
        ErrorCategory.TYPE: [
            r"TypeError:",
            r"Expected .* but got",
            r"Type '.*' is not assignable",
            r"is not a function",
        ],
        ErrorCategory.PERMISSION: [
            r"Permission denied",
            r"EACCES:",
            r"PermissionError:",
            r"Access denied",
        ],
        ErrorCategory.NETWORK: [
            r"ECONNREFUSED",
            r"ETIMEDOUT",
            r"ENOTFOUND",
            r"Network error",
            r"Connection refused",
            r"ConnectionError:",
        ],
        ErrorCategory.FILE_NOT_FOUND: [
            r"ENOENT:",
            r"FileNotFoundError:",
            r"No such file or directory",
            r"Cannot find path",
        ],
        ErrorCategory.CONFIGURATION: [
            r"Configuration error",
            r"Invalid configuration",
            r"Missing required",
            r"\.env.*not found",
            r"Environment variable .* not set",
        ],
        ErrorCategory.TIMEOUT: [
            r"Timeout",
            r"ETIMEDOUT",
            r"TimeoutError:",
            r"Task timed out",
        ],
        ErrorCategory.MEMORY: [
            r"OutOfMemory",
            r"MemoryError:",
            r"heap out of memory",
            r"JavaScript heap",
            r"ENOMEM",
        ],
        ErrorCategory.PORT_IN_USE: [
            r"EADDRINUSE:",
            r"Address already in use",
            r"port.*already in use",
            r"bind.*address already in use",
        ],
        ErrorCategory.TEST_FAILURE: [
            r"FAILED",
            r"AssertionError:",
            r"test.*failed",
            r"\d+ failing",
            r"pytest.*failed",
        ],
        # iOS/Swift specific patterns
        ErrorCategory.SWIFT_COMPILATION: [
            r"error:.*\.swift:\d+:\d+:",
            r"cannot find .* in scope",
            r"type .* has no member",
            r"missing argument for parameter",
            r"cannot convert value of type",
            r"ambiguous use of",
            r"value of type .* has no member",
            r"expected .* in .* declaration",
            r"consecutive declarations on a line",
            r"use of undeclared type",
            r"cannot assign to property",
            r"initializer .* cannot be used",
            r"invalid redeclaration of",
            r"use of unresolved identifier",
            r"No such module",
            r"could not find module",
            r"Missing package product",
        ],
        ErrorCategory.CODE_SIGNING: [
            r"Code Signing Error:",
            r"Signing for .* requires a development team",
            r"No signing certificate",
            r"Provisioning profile .* doesn't match",
            r"No profiles for .* were found",
            r"Code signing is required",
            r"Xcode couldn't find any iOS App Development",
            r"requires a provisioning profile",
            r"CSSMERR_TP_NOT_TRUSTED",
        ],
        ErrorCategory.SIMULATOR: [
            r"Unable to boot device",
            r"Simulator .* not available",
            r"Failed to boot simulator",
            r"Device is not available",
            r"The requested device could not be found",
            r"xcrun: error: unable to find",
            r"simctl: error:",
            r"CoreSimulator.*error",
            r"No simulator runtime paired",
            r"Simulator service did not respond",
        ],
        ErrorCategory.XCODE_BUILD: [
            r"xcodebuild: error:",
            r"Build Failed",
            r"Compiling .* failed",
            r"Linking .* failed",
            r"Command .* failed with exit code",
            r"target .* not found",
            r"scheme .* not found",
            r"workspace .* not found",
            r"project .* not found",
            r"The file .* couldn't be opened",
            r"clang: error:",
            r"ld: error:",
            r"Swift Compiler Error",
            r"\*\* BUILD FAILED \*\*",
        ],
        ErrorCategory.SWIFTUI_PREVIEW: [
            r"Preview Crashed",
            r"Cannot preview in this file",
            r"PreviewProvider .* not found",
            r"Previews are limited to 15 seconds",
            r"Preview provider timed out",
            r"Failed to build .* for previewing",
            r"Remote preview service.*terminated",
        ],
    }
    
    # Fix suggestions for each category
    FIX_SUGGESTIONS: Dict[ErrorCategory, List[str]] = {
        ErrorCategory.SYNTAX: [
            "Check the indicated line for syntax errors",
            "Verify proper indentation and bracket matching",
            "Look for missing colons, commas, or parentheses",
        ],
        ErrorCategory.DEPENDENCY: [
            "Run 'npm install' or 'pip install -r requirements.txt'",
            "Check if the package name is correct",
            "Try clearing node_modules and reinstalling",
            "Check for version conflicts in dependencies",
        ],
        ErrorCategory.IMPORT: [
            "Verify the module is installed",
            "Check the import path is correct",
            "Ensure the file exists at the expected location",
        ],
        ErrorCategory.TYPE: [
            "Check the types of variables being used",
            "Verify function arguments match expected types",
            "Look for undefined or null values",
        ],
        ErrorCategory.PERMISSION: [
            "Check file/directory permissions",
            "Run with appropriate privileges if needed",
            "Ensure the user has write access",
        ],
        ErrorCategory.NETWORK: [
            "Check if the server/service is running",
            "Verify the URL and port are correct",
            "Check network connectivity",
        ],
        ErrorCategory.FILE_NOT_FOUND: [
            "Verify the file path is correct",
            "Check if the file exists",
            "Ensure the working directory is correct",
        ],
        ErrorCategory.CONFIGURATION: [
            "Check if .env file exists with required variables",
            "Verify all configuration files are present",
            "Review configuration documentation",
        ],
        ErrorCategory.PORT_IN_USE: [
            "Kill the process using the port",
            "Use a different port",
            "Check for existing instances of the application",
        ],
        ErrorCategory.MEMORY: [
            "Increase memory allocation",
            "Optimize code to use less memory",
            "Check for memory leaks",
        ],
        ErrorCategory.TEST_FAILURE: [
            "Review the failing test assertions",
            "Check if test fixtures are set up correctly",
            "Verify expected vs actual values",
        ],
        # iOS-specific fix suggestions
        ErrorCategory.SWIFT_COMPILATION: [
            "Check the Swift syntax at the indicated file and line",
            "Verify all imports are correctly declared",
            "Check that type names and property names are spelled correctly",
            "Ensure proper use of optionals and unwrapping",
            "Run 'swift package resolve' to update dependencies",
        ],
        ErrorCategory.CODE_SIGNING: [
            "For simulator builds, add CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO to build command",
            "Open Xcode and set signing to 'Automatically manage signing'",
            "Add a development team in Xcode project settings",
            "For CI/CD, ensure certificates are installed in the keychain",
        ],
        ErrorCategory.SIMULATOR: [
            "List available simulators: xcrun simctl list devices",
            "Boot a different simulator version",
            "Reset simulator: xcrun simctl erase <device-udid>",
            "Restart Simulator.app: killall Simulator && open -a Simulator",
            "Update Xcode to get newer simulator runtimes",
        ],
        ErrorCategory.XCODE_BUILD: [
            "Clean build folder: xcodebuild clean",
            "Delete DerivedData: rm -rf ~/Library/Developer/Xcode/DerivedData",
            "Verify scheme exists: xcodebuild -list",
            "Check if project file is corrupted",
            "Ensure Xcode command line tools are installed: xcode-select --install",
        ],
        ErrorCategory.SWIFTUI_PREVIEW: [
            "Restart Xcode to refresh previews",
            "Check that PreviewProvider conforms correctly",
            "Simplify the preview code to identify issues",
            "Clean build folder and rebuild",
            "Ensure the preview device is available in Xcode",
        ],
    }
    
    def __init__(self, max_context_lines: int = 5):
        """Initialize the error detector.
        
        Args:
            max_context_lines: Maximum number of context lines to capture around errors
        """
        self.max_context_lines = max_context_lines
    
    def parse_error_logs(self, output: str, stderr: str = "") -> List[DetectedError]:
        """Extract errors from execution logs.
        
        Args:
            output: Standard output from execution
            stderr: Standard error from execution
            
        Returns:
            List of detected errors
        """
        combined_output = f"{output}\n{stderr}"
        errors: List[DetectedError] = []
        
        lines = combined_output.split("\n")
        
        for i, line in enumerate(lines):
            category = self._categorize_line(line)
            if category != ErrorCategory.UNKNOWN:
                # Get context lines
                start = max(0, i - self.max_context_lines)
                end = min(len(lines), i + self.max_context_lines + 1)
                context = lines[start:end]
                
                # Extract file path and line number if present
                file_path, line_number = self._extract_location(line, lines, i)
                
                # Get stack trace if available
                stack_trace = self._extract_stack_trace(lines, i)
                
                error = DetectedError(
                    category=category,
                    message=line.strip(),
                    line_number=line_number,
                    file_path=file_path,
                    stack_trace=stack_trace,
                    raw_output=combined_output,
                    suggested_fixes=self.FIX_SUGGESTIONS.get(category, []),
                    context_lines=context,
                )
                errors.append(error)
        
        # Deduplicate errors
        return self._deduplicate_errors(errors)
    
    def categorize_errors(self, errors: List[DetectedError]) -> Dict[ErrorCategory, List[DetectedError]]:
        """Classify errors by type.
        
        Args:
            errors: List of detected errors
            
        Returns:
            Dictionary mapping categories to lists of errors
        """
        categorized: Dict[ErrorCategory, List[DetectedError]] = {}
        for error in errors:
            if error.category not in categorized:
                categorized[error.category] = []
            categorized[error.category].append(error)
        return categorized
    
    def extract_stack_trace(self, output: str) -> Optional[str]:
        """Get detailed error context from stack trace.
        
        Args:
            output: Raw output containing potential stack trace
            
        Returns:
            Extracted stack trace or None
        """
        lines = output.split("\n")
        for i, line in enumerate(lines):
            stack_trace = self._extract_stack_trace(lines, i)
            if stack_trace:
                return stack_trace
        return None
    
    def suggest_fixes(self, error: DetectedError) -> List[str]:
        """Generate fix suggestions based on error type.
        
        Args:
            error: The detected error
            
        Returns:
            List of suggested fixes
        """
        suggestions = list(self.FIX_SUGGESTIONS.get(error.category, []))
        
        # Add specific suggestions based on error message
        message_lower = error.message.lower()
        
        if "npm" in message_lower or "node_modules" in message_lower:
            suggestions.append("Try: rm -rf node_modules && npm install")
        
        if "pip" in message_lower or "python" in message_lower:
            suggestions.append("Try creating a fresh virtual environment")
        
        if "enoent" in message_lower and ".env" in message_lower:
            suggestions.append("Create a .env file from .env.example if available")
        
        if "cannot find module" in message_lower:
            # Try to extract module name
            match = re.search(r"Cannot find module ['\"](.+?)['\"]", error.message)
            if match:
                module = match.group(1)
                if not module.startswith("."):
                    suggestions.insert(0, f"Install missing module: npm install {module}")
        
        if "no module named" in message_lower:
            match = re.search(r"No module named ['\"]?([\w\.]+)['\"]?", error.message)
            if match:
                module = match.group(1).split(".")[0]
                suggestions.insert(0, f"Install missing module: pip install {module}")
        
        return suggestions
    
    def _categorize_line(self, line: str) -> ErrorCategory:
        """Categorize a single line of output."""
        for category, patterns in self.ERROR_PATTERNS.items():
            for pattern in patterns:
                if re.search(pattern, line, re.IGNORECASE):
                    return category
        return ErrorCategory.UNKNOWN
    
    def _extract_location(self, line: str, lines: List[str], index: int) -> tuple:
        """Extract file path and line number from error."""
        file_path = None
        line_number = None
        
        # Python traceback pattern: File "path", line X
        py_match = re.search(r'File "([^"]+)", line (\d+)', line)
        if py_match:
            return py_match.group(1), int(py_match.group(2))
        
        # JavaScript/Node pattern: at path:line:column
        js_match = re.search(r'at (?:[^\s]+\s+)?\(?([\/\w\._-]+\.\w+):(\d+)(?::\d+)?\)?', line)
        if js_match:
            return js_match.group(1), int(js_match.group(2))
        
        # Generic pattern: path:line
        generic_match = re.search(r'([\w\.\/\\-]+\.[\w]+):(\d+)', line)
        if generic_match:
            return generic_match.group(1), int(generic_match.group(2))
        
        # Look in nearby lines for location info
        for nearby in lines[max(0, index-3):min(len(lines), index+3)]:
            py_match = re.search(r'File "([^"]+)", line (\d+)', nearby)
            if py_match:
                return py_match.group(1), int(py_match.group(2))
        
        return file_path, line_number
    
    def _extract_stack_trace(self, lines: List[str], start_index: int) -> Optional[str]:
        """Extract stack trace starting from an error line."""
        # Python traceback
        if start_index > 0:
            # Look backwards for "Traceback"
            for i in range(start_index, max(0, start_index - 50), -1):
                if "Traceback (most recent call last)" in lines[i]:
                    # Find the end of traceback
                    end = start_index + 1
                    for j in range(start_index + 1, min(len(lines), start_index + 20)):
                        if lines[j].strip() and not lines[j].startswith(" ") and "Error" not in lines[j]:
                            break
                        end = j + 1
                    return "\n".join(lines[i:end])
        
        # Node.js stack trace (starts with "Error:" or contains "at ")
        if "at " in lines[start_index] or lines[start_index].strip().startswith(("Error:", "TypeError:", "ReferenceError:")):
            stack_lines = [lines[start_index]]
            for j in range(start_index + 1, min(len(lines), start_index + 20)):
                if lines[j].strip().startswith("at "):
                    stack_lines.append(lines[j])
                elif not lines[j].strip():
                    continue
                else:
                    break
            if len(stack_lines) > 1:
                return "\n".join(stack_lines)
        
        return None
    
    def _deduplicate_errors(self, errors: List[DetectedError]) -> List[DetectedError]:
        """Remove duplicate errors based on message similarity."""
        seen_messages = set()
        unique_errors = []
        
        for error in errors:
            # Normalize message for comparison
            normalized = re.sub(r'\d+', 'N', error.message.strip())
            if normalized not in seen_messages:
                seen_messages.add(normalized)
                unique_errors.append(error)
        
        return unique_errors
    
    def generate_error_report(self, errors: List[DetectedError]) -> str:
        """Generate a human-readable error report.
        
        Args:
            errors: List of detected errors
            
        Returns:
            Formatted error report string
        """
        if not errors:
            return "No errors detected."
        
        report_lines = [f"Found {len(errors)} error(s):\n"]
        categorized = self.categorize_errors(errors)
        
        for category, category_errors in categorized.items():
            report_lines.append(f"\n## {category.value.upper()} Errors ({len(category_errors)})\n")
            
            for i, error in enumerate(category_errors, 1):
                report_lines.append(f"### Error {i}")
                report_lines.append(f"**Message:** {error.message}")
                
                if error.file_path:
                    location = f"**Location:** {error.file_path}"
                    if error.line_number:
                        location += f":{error.line_number}"
                    report_lines.append(location)
                
                if error.stack_trace:
                    report_lines.append("**Stack Trace:**")
                    report_lines.append(f"```\n{error.stack_trace}\n```")
                
                if error.suggested_fixes:
                    report_lines.append("**Suggested Fixes:**")
                    for fix in error.suggested_fixes:
                        report_lines.append(f"- {fix}")
                
                report_lines.append("")
        
        return "\n".join(report_lines)
