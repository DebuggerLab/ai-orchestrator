"""Common fix strategies for different error types."""

import re
import os
import subprocess
from typing import Optional, Dict, List, Any, Callable
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path

from .error_detector import ErrorCategory, DetectedError


class FixType(Enum):
    """Types of fixes that can be applied."""
    DEPENDENCY = "dependency"
    IMPORT = "import"
    SYNTAX = "syntax"
    CONFIGURATION = "configuration"
    PORT = "port"
    PERMISSION = "permission"
    FILE_CREATION = "file_creation"
    CODE_MODIFICATION = "code_modification"
    COMMAND = "command"


@dataclass
class FixStrategy:
    """A strategy for fixing a specific type of error."""
    name: str
    description: str
    fix_type: FixType
    error_categories: List[ErrorCategory]
    confidence: float  # 0.0 to 1.0
    apply_func: Optional[Callable] = None
    command: Optional[str] = None
    file_changes: Dict[str, str] = field(default_factory=dict)
    requires_restart: bool = False
    is_safe: bool = True  # Safe fixes don't require backup


@dataclass
class FixResult:
    """Result of applying a fix."""
    success: bool
    strategy: FixStrategy
    message: str
    changes_made: List[str] = field(default_factory=list)
    rollback_info: Dict[str, Any] = field(default_factory=dict)


class FixStrategyRegistry:
    """Registry of available fix strategies."""
    
    def __init__(self):
        self.strategies: List[FixStrategy] = []
        self._register_default_strategies()
    
    def _register_default_strategies(self):
        """Register built-in fix strategies."""
        # Dependency fixes
        self.register(FixStrategy(
            name="npm_install",
            description="Install missing npm packages",
            fix_type=FixType.DEPENDENCY,
            error_categories=[ErrorCategory.DEPENDENCY, ErrorCategory.IMPORT],
            confidence=0.9,
            command="npm install",
            requires_restart=True,
        ))
        
        self.register(FixStrategy(
            name="npm_clean_install",
            description="Clean install npm packages",
            fix_type=FixType.DEPENDENCY,
            error_categories=[ErrorCategory.DEPENDENCY],
            confidence=0.8,
            command="rm -rf node_modules package-lock.json && npm install",
            requires_restart=True,
        ))
        
        self.register(FixStrategy(
            name="pip_install_requirements",
            description="Install Python requirements",
            fix_type=FixType.DEPENDENCY,
            error_categories=[ErrorCategory.DEPENDENCY, ErrorCategory.IMPORT],
            confidence=0.9,
            command="pip install -r requirements.txt",
            requires_restart=True,
        ))
        
        self.register(FixStrategy(
            name="pip_install_module",
            description="Install specific Python module",
            fix_type=FixType.DEPENDENCY,
            error_categories=[ErrorCategory.IMPORT],
            confidence=0.85,
            requires_restart=True,
        ))
        
        self.register(FixStrategy(
            name="npm_install_module",
            description="Install specific npm package",
            fix_type=FixType.DEPENDENCY,
            error_categories=[ErrorCategory.IMPORT],
            confidence=0.85,
            requires_restart=True,
        ))
        
        # Port fixes
        self.register(FixStrategy(
            name="kill_port_process",
            description="Kill process using the port",
            fix_type=FixType.PORT,
            error_categories=[ErrorCategory.PORT_IN_USE],
            confidence=0.9,
            requires_restart=True,
        ))
        
        self.register(FixStrategy(
            name="change_port",
            description="Change application port",
            fix_type=FixType.PORT,
            error_categories=[ErrorCategory.PORT_IN_USE],
            confidence=0.7,
            requires_restart=True,
        ))
        
        # Permission fixes
        self.register(FixStrategy(
            name="fix_file_permissions",
            description="Fix file permissions",
            fix_type=FixType.PERMISSION,
            error_categories=[ErrorCategory.PERMISSION],
            confidence=0.8,
        ))
        
        self.register(FixStrategy(
            name="fix_directory_permissions",
            description="Fix directory permissions",
            fix_type=FixType.PERMISSION,
            error_categories=[ErrorCategory.PERMISSION],
            confidence=0.8,
        ))
        
        # Configuration fixes
        self.register(FixStrategy(
            name="create_env_file",
            description="Create .env file from template",
            fix_type=FixType.CONFIGURATION,
            error_categories=[ErrorCategory.CONFIGURATION, ErrorCategory.FILE_NOT_FOUND],
            confidence=0.9,
        ))
        
        self.register(FixStrategy(
            name="fix_config_syntax",
            description="Fix configuration file syntax",
            fix_type=FixType.CONFIGURATION,
            error_categories=[ErrorCategory.CONFIGURATION, ErrorCategory.SYNTAX],
            confidence=0.6,
        ))
        
        # Import fixes
        self.register(FixStrategy(
            name="fix_relative_import",
            description="Fix relative import path",
            fix_type=FixType.IMPORT,
            error_categories=[ErrorCategory.IMPORT],
            confidence=0.7,
        ))
        
        self.register(FixStrategy(
            name="add_missing_import",
            description="Add missing import statement",
            fix_type=FixType.IMPORT,
            error_categories=[ErrorCategory.IMPORT],
            confidence=0.75,
        ))
        
        # Syntax fixes
        self.register(FixStrategy(
            name="fix_indentation",
            description="Fix Python indentation",
            fix_type=FixType.SYNTAX,
            error_categories=[ErrorCategory.SYNTAX],
            confidence=0.7,
        ))
        
        self.register(FixStrategy(
            name="fix_bracket_mismatch",
            description="Fix bracket/parenthesis mismatch",
            fix_type=FixType.SYNTAX,
            error_categories=[ErrorCategory.SYNTAX],
            confidence=0.6,
        ))
        
        self.register(FixStrategy(
            name="fix_missing_semicolon",
            description="Add missing semicolons",
            fix_type=FixType.SYNTAX,
            error_categories=[ErrorCategory.SYNTAX],
            confidence=0.8,
        ))
    
    def register(self, strategy: FixStrategy):
        """Register a new fix strategy."""
        self.strategies.append(strategy)
    
    def get_strategies_for_error(
        self,
        error: DetectedError,
        min_confidence: float = 0.5,
    ) -> List[FixStrategy]:
        """Get applicable fix strategies for an error."""
        applicable = [
            s for s in self.strategies
            if error.category in s.error_categories and s.confidence >= min_confidence
        ]
        return sorted(applicable, key=lambda s: s.confidence, reverse=True)
    
    def get_strategies_by_type(self, fix_type: FixType) -> List[FixStrategy]:
        """Get all strategies of a specific type."""
        return [s for s in self.strategies if s.fix_type == fix_type]


class DependencyFixer:
    """Handles dependency-related fixes."""
    
    @staticmethod
    def extract_missing_npm_package(error: DetectedError) -> Optional[str]:
        """Extract missing package name from npm/node error."""
        patterns = [
            r"Cannot find module ['\"]([^'\"]+)['\"]",
            r"Module not found: ['\"]([^'\"]+)['\"]",
            r"Cannot find package ['\"]([^'\"]+)['\"]",
            r"npm ERR! missing: ([^,@]+)",
        ]
        for pattern in patterns:
            match = re.search(pattern, error.message)
            if match:
                module = match.group(1)
                # Skip relative imports
                if not module.startswith("."):
                    # Handle scoped packages
                    if module.startswith("@"):
                        return module.split("/")[0] + "/" + module.split("/")[1] if "/" in module else module
                    return module.split("/")[0]
        return None
    
    @staticmethod
    def extract_missing_python_module(error: DetectedError) -> Optional[str]:
        """Extract missing module name from Python error."""
        patterns = [
            r"No module named ['\"]?([^'\"]+)['\"]?",
            r"ModuleNotFoundError: No module named ['\"]?([^'\"]+)['\"]?",
            r"ImportError: cannot import name ['\"]?(\w+)['\"]?",
        ]
        for pattern in patterns:
            match = re.search(pattern, error.message)
            if match:
                module = match.group(1)
                # Return the top-level module
                return module.split(".")[0]
        return None
    
    @staticmethod
    def install_npm_package(project_path: Path, package: str) -> FixResult:
        """Install an npm package."""
        strategy = FixStrategy(
            name="npm_install_module",
            description=f"Install npm package: {package}",
            fix_type=FixType.DEPENDENCY,
            error_categories=[ErrorCategory.IMPORT, ErrorCategory.DEPENDENCY],
            confidence=0.85,
            command=f"npm install {package}",
        )
        
        try:
            result = subprocess.run(
                f"npm install {package}",
                shell=True,
                cwd=str(project_path),
                capture_output=True,
                text=True,
                timeout=120,
            )
            
            if result.returncode == 0:
                return FixResult(
                    success=True,
                    strategy=strategy,
                    message=f"Successfully installed {package}",
                    changes_made=[f"Installed npm package: {package}"],
                    rollback_info={"package": package, "command": f"npm uninstall {package}"},
                )
            else:
                return FixResult(
                    success=False,
                    strategy=strategy,
                    message=f"Failed to install {package}: {result.stderr}",
                )
        except Exception as e:
            return FixResult(
                success=False,
                strategy=strategy,
                message=f"Error installing {package}: {str(e)}",
            )
    
    @staticmethod
    def install_python_package(project_path: Path, package: str) -> FixResult:
        """Install a Python package."""
        strategy = FixStrategy(
            name="pip_install_module",
            description=f"Install Python package: {package}",
            fix_type=FixType.DEPENDENCY,
            error_categories=[ErrorCategory.IMPORT, ErrorCategory.DEPENDENCY],
            confidence=0.85,
            command=f"pip install {package}",
        )
        
        try:
            result = subprocess.run(
                f"pip install {package}",
                shell=True,
                cwd=str(project_path),
                capture_output=True,
                text=True,
                timeout=120,
            )
            
            if result.returncode == 0:
                return FixResult(
                    success=True,
                    strategy=strategy,
                    message=f"Successfully installed {package}",
                    changes_made=[f"Installed Python package: {package}"],
                    rollback_info={"package": package, "command": f"pip uninstall -y {package}"},
                )
            else:
                return FixResult(
                    success=False,
                    strategy=strategy,
                    message=f"Failed to install {package}: {result.stderr}",
                )
        except Exception as e:
            return FixResult(
                success=False,
                strategy=strategy,
                message=f"Error installing {package}: {str(e)}",
            )


class PortFixer:
    """Handles port conflict fixes."""
    
    @staticmethod
    def extract_port(error: DetectedError) -> Optional[int]:
        """Extract port number from error message."""
        patterns = [
            r"EADDRINUSE.*:(\d+)",
            r"address already in use.*:(\d+)",
            r"port (\d+).*already in use",
            r"bind.*:(\d+)",
        ]
        for pattern in patterns:
            match = re.search(pattern, error.message, re.IGNORECASE)
            if match:
                return int(match.group(1))
        return None
    
    @staticmethod
    def kill_port_process(port: int) -> FixResult:
        """Kill process using a specific port."""
        strategy = FixStrategy(
            name="kill_port_process",
            description=f"Kill process using port {port}",
            fix_type=FixType.PORT,
            error_categories=[ErrorCategory.PORT_IN_USE],
            confidence=0.9,
        )
        
        try:
            # Find PID using the port (Linux/macOS)
            if os.name != 'nt':
                result = subprocess.run(
                    f"lsof -ti :{port}",
                    shell=True,
                    capture_output=True,
                    text=True,
                )
                pids = result.stdout.strip().split("\n")
                
                for pid in pids:
                    if pid:
                        subprocess.run(f"kill -9 {pid}", shell=True)
                
                if pids and pids[0]:
                    return FixResult(
                        success=True,
                        strategy=strategy,
                        message=f"Killed process(es) using port {port}",
                        changes_made=[f"Killed PID(s): {', '.join(pids)}"],
                        rollback_info={"port": port, "note": "Process termination cannot be rolled back"},
                    )
            else:
                # Windows
                result = subprocess.run(
                    f"netstat -ano | findstr :{port}",
                    shell=True,
                    capture_output=True,
                    text=True,
                )
                if result.stdout:
                    # Extract PID from netstat output
                    lines = result.stdout.strip().split("\n")
                    for line in lines:
                        parts = line.split()
                        if len(parts) >= 5:
                            pid = parts[-1]
                            subprocess.run(f"taskkill /PID {pid} /F", shell=True)
                    
                    return FixResult(
                        success=True,
                        strategy=strategy,
                        message=f"Killed process using port {port}",
                        changes_made=[f"Terminated processes on port {port}"],
                    )
            
            return FixResult(
                success=False,
                strategy=strategy,
                message=f"No process found using port {port}",
            )
            
        except Exception as e:
            return FixResult(
                success=False,
                strategy=strategy,
                message=f"Error killing process on port {port}: {str(e)}",
            )
    
    @staticmethod
    def find_available_port(start_port: int = 3000) -> int:
        """Find an available port starting from a given port."""
        import socket
        
        for port in range(start_port, start_port + 100):
            try:
                with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                    s.bind(("localhost", port))
                    return port
            except OSError:
                continue
        return start_port + 100


class PermissionFixer:
    """Handles permission-related fixes."""
    
    @staticmethod
    def extract_path(error: DetectedError) -> Optional[str]:
        """Extract file path from permission error."""
        patterns = [
            r"EACCES:.*['\"]([^'\"]+)['\"]",
            r"Permission denied: ['\"]?([^'\"]+)['\"]?",
            r"PermissionError:.*['\"]([^'\"]+)['\"]",
        ]
        for pattern in patterns:
            match = re.search(pattern, error.message)
            if match:
                return match.group(1)
        return None
    
    @staticmethod
    def fix_file_permissions(path: str, mode: int = 0o644) -> FixResult:
        """Fix permissions on a file."""
        strategy = FixStrategy(
            name="fix_file_permissions",
            description=f"Fix permissions on {path}",
            fix_type=FixType.PERMISSION,
            error_categories=[ErrorCategory.PERMISSION],
            confidence=0.8,
        )
        
        try:
            file_path = Path(path)
            if file_path.exists():
                old_mode = file_path.stat().st_mode
                os.chmod(path, mode)
                return FixResult(
                    success=True,
                    strategy=strategy,
                    message=f"Changed permissions on {path}",
                    changes_made=[f"chmod {oct(mode)} {path}"],
                    rollback_info={"path": path, "old_mode": old_mode},
                )
            else:
                return FixResult(
                    success=False,
                    strategy=strategy,
                    message=f"File not found: {path}",
                )
        except Exception as e:
            return FixResult(
                success=False,
                strategy=strategy,
                message=f"Error fixing permissions: {str(e)}",
            )
    
    @staticmethod
    def fix_directory_permissions(path: str, mode: int = 0o755) -> FixResult:
        """Fix permissions on a directory."""
        strategy = FixStrategy(
            name="fix_directory_permissions",
            description=f"Fix permissions on directory {path}",
            fix_type=FixType.PERMISSION,
            error_categories=[ErrorCategory.PERMISSION],
            confidence=0.8,
        )
        
        try:
            dir_path = Path(path)
            if dir_path.exists() and dir_path.is_dir():
                old_mode = dir_path.stat().st_mode
                os.chmod(path, mode)
                return FixResult(
                    success=True,
                    strategy=strategy,
                    message=f"Changed permissions on directory {path}",
                    changes_made=[f"chmod {oct(mode)} {path}"],
                    rollback_info={"path": path, "old_mode": old_mode},
                )
            else:
                return FixResult(
                    success=False,
                    strategy=strategy,
                    message=f"Directory not found: {path}",
                )
        except Exception as e:
            return FixResult(
                success=False,
                strategy=strategy,
                message=f"Error fixing directory permissions: {str(e)}",
            )


class ConfigurationFixer:
    """Handles configuration-related fixes."""
    
    @staticmethod
    def create_env_from_example(project_path: Path) -> FixResult:
        """Create .env file from .env.example."""
        strategy = FixStrategy(
            name="create_env_file",
            description="Create .env file from .env.example",
            fix_type=FixType.CONFIGURATION,
            error_categories=[ErrorCategory.CONFIGURATION, ErrorCategory.FILE_NOT_FOUND],
            confidence=0.9,
        )
        
        env_file = project_path / ".env"
        example_file = project_path / ".env.example"
        
        if env_file.exists():
            return FixResult(
                success=False,
                strategy=strategy,
                message=".env file already exists",
            )
        
        if example_file.exists():
            try:
                import shutil
                shutil.copy(example_file, env_file)
                return FixResult(
                    success=True,
                    strategy=strategy,
                    message="Created .env from .env.example",
                    changes_made=["Copied .env.example to .env"],
                    rollback_info={"created_file": str(env_file)},
                )
            except Exception as e:
                return FixResult(
                    success=False,
                    strategy=strategy,
                    message=f"Error copying file: {str(e)}",
                )
        else:
            # Try other common templates
            for template in [".env.sample", ".env.template", "env.example"]:
                template_file = project_path / template
                if template_file.exists():
                    try:
                        import shutil
                        shutil.copy(template_file, env_file)
                        return FixResult(
                            success=True,
                            strategy=strategy,
                            message=f"Created .env from {template}",
                            changes_made=[f"Copied {template} to .env"],
                            rollback_info={"created_file": str(env_file)},
                        )
                    except Exception as e:
                        continue
            
            return FixResult(
                success=False,
                strategy=strategy,
                message="No .env template file found",
            )
    
    @staticmethod
    def extract_missing_env_var(error: DetectedError) -> Optional[str]:
        """Extract missing environment variable name."""
        patterns = [
            r"Environment variable ['\"]?(\w+)['\"]? not set",
            r"Missing required.*['\"]?(\w+)['\"]?",
            r"(\w+_\w+) is not defined",
            r"process\.env\.(\w+)",
        ]
        for pattern in patterns:
            match = re.search(pattern, error.message)
            if match:
                return match.group(1)
        return None


class SyntaxFixer:
    """Handles syntax-related fixes (limited capability, relies on AI for complex fixes)."""
    
    @staticmethod
    def detect_fix_type(error: DetectedError) -> Optional[str]:
        """Detect the type of syntax fix needed."""
        message = error.message.lower()
        
        if "indentation" in message or "indent" in message:
            return "indentation"
        elif "unexpected token" in message:
            return "unexpected_token"
        elif "unterminated" in message:
            return "unterminated"
        elif "missing" in message and any(c in message for c in [")", "]", "}", ":", ";"]):
            return "missing_bracket"
        
        return None
    
    @staticmethod
    def get_syntax_fix_prompt(error: DetectedError, file_content: str) -> str:
        """Generate a prompt for AI to fix syntax errors."""
        return f"""Fix the following syntax error in this code:

Error: {error.message}
File: {error.file_path or 'unknown'}
Line: {error.line_number or 'unknown'}

Code:
```
{file_content}
```

Please provide only the corrected code, no explanations."""


class SwiftSyntaxFixer:
    """Handles Swift/SwiftUI syntax error fixes."""
    
    @staticmethod
    def detect_fix_type(error: DetectedError) -> Optional[str]:
        """Detect the type of Swift fix needed."""
        message = error.message.lower()
        
        if "cannot find" in message and "in scope" in message:
            return "missing_import_or_declaration"
        elif "no such module" in message:
            return "missing_module"
        elif "type" in message and "has no member" in message:
            return "invalid_member"
        elif "cannot convert" in message:
            return "type_conversion"
        elif "missing argument" in message:
            return "missing_argument"
        elif "use of unresolved identifier" in message:
            return "unresolved_identifier"
        
        return None
    
    @staticmethod
    def extract_missing_module(error: DetectedError) -> Optional[str]:
        """Extract missing module name from Swift error."""
        patterns = [
            r"No such module ['\"]?([^'\"]+)['\"]?",
            r"could not find module ['\"]?([^'\"]+)['\"]?",
            r"Missing package product ['\"]?([^'\"]+)['\"]?",
        ]
        for pattern in patterns:
            match = re.search(pattern, error.message, re.IGNORECASE)
            if match:
                return match.group(1)
        return None
    
    @staticmethod
    def get_swift_fix_prompt(error: DetectedError, file_content: str) -> str:
        """Generate a prompt for AI to fix Swift errors."""
        return f"""Fix the following Swift/SwiftUI error in this code:

Error: {error.message}
File: {error.file_path or 'unknown'}
Line: {error.line_number or 'unknown'}

Code:
```swift
{file_content}
```

Please provide only the corrected Swift code, no explanations."""


class SimulatorFixer:
    """Handles iOS Simulator-related fixes."""
    
    @staticmethod
    def reset_simulator(udid: Optional[str] = None) -> FixResult:
        """Reset/erase a simulator."""
        strategy = FixStrategy(
            name="reset_simulator",
            description="Reset simulator to clean state",
            fix_type=FixType.COMMAND,
            error_categories=[ErrorCategory.SIMULATOR],
            confidence=0.8,
        )
        
        try:
            if udid:
                cmd = f"xcrun simctl erase {udid}"
            else:
                # Erase all simulators
                cmd = "xcrun simctl erase all"
            
            result = subprocess.run(
                cmd,
                shell=True,
                capture_output=True,
                text=True,
                timeout=60,
            )
            
            if result.returncode == 0:
                return FixResult(
                    success=True,
                    strategy=strategy,
                    message="Simulator reset successfully",
                    changes_made=[f"Executed: {cmd}"],
                )
            else:
                return FixResult(
                    success=False,
                    strategy=strategy,
                    message=f"Failed to reset simulator: {result.stderr}",
                )
        except Exception as e:
            return FixResult(
                success=False,
                strategy=strategy,
                message=f"Error resetting simulator: {str(e)}",
            )
    
    @staticmethod
    def boot_simulator(device_name: str = "iPhone 15") -> FixResult:
        """Boot a simulator by device name."""
        strategy = FixStrategy(
            name="boot_simulator",
            description=f"Boot iOS simulator: {device_name}",
            fix_type=FixType.COMMAND,
            error_categories=[ErrorCategory.SIMULATOR],
            confidence=0.9,
        )
        
        try:
            # First try to find the device UDID
            list_result = subprocess.run(
                "xcrun simctl list devices -j",
                shell=True,
                capture_output=True,
                text=True,
                timeout=30,
            )
            
            if list_result.returncode != 0:
                return FixResult(
                    success=False,
                    strategy=strategy,
                    message="Failed to list simulators",
                )
            
            import json
            devices_data = json.loads(list_result.stdout)
            
            # Find matching device
            device_udid = None
            for runtime, devices in devices_data.get("devices", {}).items():
                for device in devices:
                    if device.get("isAvailable", False) and device_name.lower() in device.get("name", "").lower():
                        device_udid = device.get("udid")
                        break
                if device_udid:
                    break
            
            if not device_udid:
                return FixResult(
                    success=False,
                    strategy=strategy,
                    message=f"No simulator found matching: {device_name}",
                )
            
            # Boot the simulator
            boot_result = subprocess.run(
                f"xcrun simctl boot {device_udid}",
                shell=True,
                capture_output=True,
                text=True,
                timeout=60,
            )
            
            # Open Simulator app
            subprocess.run("open -a Simulator", shell=True, capture_output=True)
            
            if boot_result.returncode == 0 or "current state: Booted" in boot_result.stderr:
                return FixResult(
                    success=True,
                    strategy=strategy,
                    message=f"Successfully booted simulator: {device_name}",
                    changes_made=[f"Booted simulator with UDID: {device_udid}"],
                )
            else:
                return FixResult(
                    success=False,
                    strategy=strategy,
                    message=f"Failed to boot simulator: {boot_result.stderr}",
                )
        except Exception as e:
            return FixResult(
                success=False,
                strategy=strategy,
                message=f"Error booting simulator: {str(e)}",
            )
    
    @staticmethod
    def list_available_simulators() -> List[Dict[str, Any]]:
        """List all available iOS simulators."""
        try:
            import json
            result = subprocess.run(
                "xcrun simctl list devices -j",
                shell=True,
                capture_output=True,
                text=True,
                timeout=30,
            )
            
            if result.returncode != 0:
                return []
            
            data = json.loads(result.stdout)
            simulators = []
            
            for runtime, devices in data.get("devices", {}).items():
                for device in devices:
                    if device.get("isAvailable", False):
                        simulators.append({
                            "name": device.get("name"),
                            "udid": device.get("udid"),
                            "state": device.get("state"),
                            "runtime": runtime,
                        })
            
            return simulators
        except Exception:
            return []


class SwiftPackageFixer:
    """Handles Swift Package Manager dependency fixes."""
    
    @staticmethod
    def resolve_packages(project_path: Path) -> FixResult:
        """Resolve Swift Package Manager dependencies."""
        strategy = FixStrategy(
            name="swift_package_resolve",
            description="Resolve Swift Package Manager dependencies",
            fix_type=FixType.DEPENDENCY,
            error_categories=[ErrorCategory.DEPENDENCY, ErrorCategory.SWIFT_COMPILATION],
            confidence=0.9,
            command="swift package resolve",
            requires_restart=True,
        )
        
        try:
            result = subprocess.run(
                "swift package resolve",
                shell=True,
                cwd=str(project_path),
                capture_output=True,
                text=True,
                timeout=300,
            )
            
            if result.returncode == 0:
                return FixResult(
                    success=True,
                    strategy=strategy,
                    message="Successfully resolved Swift packages",
                    changes_made=["Resolved Swift Package Manager dependencies"],
                )
            else:
                return FixResult(
                    success=False,
                    strategy=strategy,
                    message=f"Failed to resolve packages: {result.stderr}",
                )
        except Exception as e:
            return FixResult(
                success=False,
                strategy=strategy,
                message=f"Error resolving packages: {str(e)}",
            )
    
    @staticmethod
    def update_packages(project_path: Path) -> FixResult:
        """Update Swift Package Manager dependencies."""
        strategy = FixStrategy(
            name="swift_package_update",
            description="Update Swift Package Manager dependencies",
            fix_type=FixType.DEPENDENCY,
            error_categories=[ErrorCategory.DEPENDENCY],
            confidence=0.8,
            command="swift package update",
            requires_restart=True,
        )
        
        try:
            result = subprocess.run(
                "swift package update",
                shell=True,
                cwd=str(project_path),
                capture_output=True,
                text=True,
                timeout=300,
            )
            
            if result.returncode == 0:
                return FixResult(
                    success=True,
                    strategy=strategy,
                    message="Successfully updated Swift packages",
                    changes_made=["Updated Swift Package Manager dependencies"],
                )
            else:
                return FixResult(
                    success=False,
                    strategy=strategy,
                    message=f"Failed to update packages: {result.stderr}",
                )
        except Exception as e:
            return FixResult(
                success=False,
                strategy=strategy,
                message=f"Error updating packages: {str(e)}",
            )
    
    @staticmethod
    def clean_build(project_path: Path) -> FixResult:
        """Clean Swift build artifacts."""
        strategy = FixStrategy(
            name="swift_clean_build",
            description="Clean Swift build artifacts",
            fix_type=FixType.COMMAND,
            error_categories=[ErrorCategory.XCODE_BUILD, ErrorCategory.SWIFT_COMPILATION],
            confidence=0.7,
        )
        
        try:
            # Clean .build directory
            build_dir = project_path / ".build"
            if build_dir.exists():
                import shutil
                shutil.rmtree(build_dir)
            
            # Clean DerivedData
            derived_data = project_path / "build" / "DerivedData"
            if derived_data.exists():
                import shutil
                shutil.rmtree(derived_data)
            
            return FixResult(
                success=True,
                strategy=strategy,
                message="Successfully cleaned build artifacts",
                changes_made=["Removed .build directory", "Removed DerivedData"],
            )
        except Exception as e:
            return FixResult(
                success=False,
                strategy=strategy,
                message=f"Error cleaning build: {str(e)}",
            )


class SigningFixer:
    """Handles code signing issues for iOS projects."""
    
    @staticmethod
    def get_signing_fix_suggestion() -> str:
        """Get suggestion for fixing code signing issues."""
        return """To fix code signing issues:

1. For simulator builds, add these flags to xcodebuild:
   CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO

2. For device builds, open Xcode and:
   - Go to project settings > Signing & Capabilities
   - Enable "Automatically manage signing"
   - Select your development team

3. For CI/CD:
   - Ensure certificates are in the keychain
   - Use fastlane match for signing management
"""
    
    @staticmethod
    def generate_xcode_build_command(
        project_path: Path,
        scheme: Optional[str] = None,
        skip_signing: bool = True,
    ) -> str:
        """Generate xcodebuild command with proper signing settings."""
        xcworkspaces = list(project_path.glob("*.xcworkspace"))
        xcodeprojs = list(project_path.glob("*.xcodeproj"))
        
        cmd_parts = ["xcodebuild"]
        
        if xcworkspaces:
            cmd_parts.extend(["-workspace", xcworkspaces[0].name])
        elif xcodeprojs:
            cmd_parts.extend(["-project", xcodeprojs[0].name])
        
        if scheme:
            cmd_parts.extend(["-scheme", scheme])
        
        cmd_parts.extend([
            "-sdk", "iphonesimulator",
            "-configuration", "Debug",
        ])
        
        if skip_signing:
            cmd_parts.extend([
                "CODE_SIGN_IDENTITY=-",
                "CODE_SIGNING_REQUIRED=NO",
                "CODE_SIGNING_ALLOWED=NO",
            ])
        
        cmd_parts.append("build")
        
        return " ".join(cmd_parts)


# Convenience class for accessing all fixers
class FixerCollection:
    """Collection of all available fixers."""
    
    def __init__(self):
        self.registry = FixStrategyRegistry()
        self.dependency = DependencyFixer()
        self.port = PortFixer()
        self.permission = PermissionFixer()
        self.configuration = ConfigurationFixer()
        self.syntax = SyntaxFixer()
        # iOS-specific fixers
        self.swift_syntax = SwiftSyntaxFixer()
        self.simulator = SimulatorFixer()
        self.swift_package = SwiftPackageFixer()
        self.signing = SigningFixer()
    
    def get_fixer_for_error(self, error: DetectedError) -> Optional[Any]:
        """Get the appropriate fixer for an error category."""
        fixer_map = {
            ErrorCategory.DEPENDENCY: self.dependency,
            ErrorCategory.IMPORT: self.dependency,
            ErrorCategory.PORT_IN_USE: self.port,
            ErrorCategory.PERMISSION: self.permission,
            ErrorCategory.CONFIGURATION: self.configuration,
            ErrorCategory.SYNTAX: self.syntax,
            # iOS-specific mappings
            ErrorCategory.SWIFT_COMPILATION: self.swift_syntax,
            ErrorCategory.CODE_SIGNING: self.signing,
            ErrorCategory.SIMULATOR: self.simulator,
            ErrorCategory.XCODE_BUILD: self.swift_package,
            ErrorCategory.SWIFTUI_PREVIEW: self.swift_syntax,
        }
        return fixer_map.get(error.category)
    
    def can_auto_fix(self, error: DetectedError) -> bool:
        """Check if an error can be automatically fixed without AI."""
        auto_fixable = {
            ErrorCategory.DEPENDENCY,
            ErrorCategory.IMPORT,
            ErrorCategory.PORT_IN_USE,
            ErrorCategory.PERMISSION,
            # iOS auto-fixable categories
            ErrorCategory.SIMULATOR,
            ErrorCategory.XCODE_BUILD,  # Clean/rebuild often fixes
        }
        return error.category in auto_fixable
    
    def requires_ai_fix(self, error: DetectedError) -> bool:
        """Check if an error requires AI assistance to fix."""
        ai_required = {
            ErrorCategory.SYNTAX,
            ErrorCategory.RUNTIME,
            ErrorCategory.TYPE,
            ErrorCategory.TEST_FAILURE,
            # iOS AI-required categories
            ErrorCategory.SWIFT_COMPILATION,
            ErrorCategory.SWIFTUI_PREVIEW,
        }
        return error.category in ai_required
    
    def is_ios_error(self, error: DetectedError) -> bool:
        """Check if an error is iOS-specific."""
        ios_categories = {
            ErrorCategory.SWIFT_COMPILATION,
            ErrorCategory.CODE_SIGNING,
            ErrorCategory.SIMULATOR,
            ErrorCategory.XCODE_BUILD,
            ErrorCategory.SWIFTUI_PREVIEW,
        }
        return error.category in ios_categories
