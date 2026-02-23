"""Project type handlers for different frameworks and languages."""

import os
import json
from abc import ABC, abstractmethod
from pathlib import Path
from typing import Optional, List, Dict, Any
from dataclasses import dataclass, field


@dataclass
class ProjectConfig:
    """Configuration for a detected project."""
    project_type: str
    root_path: Path
    install_command: Optional[str] = None
    run_command: Optional[str] = None
    test_command: Optional[str] = None
    build_command: Optional[str] = None
    dev_command: Optional[str] = None
    entry_point: Optional[str] = None
    dependencies_file: Optional[str] = None
    config_files: List[str] = field(default_factory=list)
    environment: Dict[str, str] = field(default_factory=dict)
    ports: List[int] = field(default_factory=list)
    error_patterns: List[str] = field(default_factory=list)


class BaseProjectHandler(ABC):
    """Abstract base class for project type handlers."""
    
    name: str = "base"
    priority: int = 0  # Higher priority handlers are checked first
    
    @abstractmethod
    def detect(self, project_path: Path) -> bool:
        """Detect if the project is of this type."""
        pass
    
    @abstractmethod
    def get_config(self, project_path: Path) -> ProjectConfig:
        """Get the project configuration."""
        pass
    
    @abstractmethod
    def get_error_patterns(self) -> List[str]:
        """Get common error patterns for this project type."""
        pass
    
    def _file_exists(self, project_path: Path, filename: str) -> bool:
        """Check if a file exists in the project."""
        return (project_path / filename).exists()
    
    def _read_json(self, filepath: Path) -> Optional[Dict[str, Any]]:
        """Read and parse a JSON file."""
        try:
            with open(filepath, 'r') as f:
                return json.load(f)
        except (FileNotFoundError, json.JSONDecodeError):
            return None


class NodeJSProject(BaseProjectHandler):
    """Handler for Node.js projects."""
    
    name = "nodejs"
    priority = 10
    
    def detect(self, project_path: Path) -> bool:
        """Detect if this is a Node.js project."""
        return self._file_exists(project_path, "package.json")
    
    def get_config(self, project_path: Path) -> ProjectConfig:
        """Get Node.js project configuration."""
        package_json = self._read_json(project_path / "package.json") or {}
        scripts = package_json.get("scripts", {})
        
        # Determine run command
        run_command = None
        dev_command = None
        if "start" in scripts:
            run_command = "npm start"
        if "dev" in scripts:
            dev_command = "npm run dev"
        if not run_command and "main" in package_json:
            run_command = f"node {package_json['main']}"
        
        # Determine test command
        test_command = None
        if "test" in scripts:
            test_command = "npm test"
        
        # Determine build command
        build_command = None
        if "build" in scripts:
            build_command = "npm run build"
        
        return ProjectConfig(
            project_type=self.name,
            root_path=project_path,
            install_command="npm install",
            run_command=run_command or dev_command,
            test_command=test_command,
            build_command=build_command,
            dev_command=dev_command,
            entry_point=package_json.get("main", "index.js"),
            dependencies_file="package.json",
            config_files=["package.json", "package-lock.json", "tsconfig.json"],
            ports=[3000],
            error_patterns=self.get_error_patterns()
        )
    
    def get_error_patterns(self) -> List[str]:
        """Get Node.js error patterns."""
        return [
            r"Error: Cannot find module",
            r"SyntaxError:",
            r"TypeError:",
            r"ReferenceError:",
            r"ENOENT:",
            r"EADDRINUSE:",
            r"UnhandledPromiseRejection",
            r"npm ERR!",
            r"node:internal",
            r"at Object\.<anonymous>",
        ]


class ReactProject(BaseProjectHandler):
    """Handler for React projects."""
    
    name = "react"
    priority = 20  # Check before generic Node.js
    
    def detect(self, project_path: Path) -> bool:
        """Detect if this is a React project."""
        if not self._file_exists(project_path, "package.json"):
            return False
        
        package_json = self._read_json(project_path / "package.json")
        if not package_json:
            return False
        
        dependencies = package_json.get("dependencies", {})
        dev_dependencies = package_json.get("devDependencies", {})
        all_deps = {**dependencies, **dev_dependencies}
        
        # Check for react in dependencies
        return "react" in all_deps and "next" not in all_deps
    
    def get_config(self, project_path: Path) -> ProjectConfig:
        """Get React project configuration."""
        package_json = self._read_json(project_path / "package.json") or {}
        scripts = package_json.get("scripts", {})
        
        return ProjectConfig(
            project_type=self.name,
            root_path=project_path,
            install_command="npm install",
            run_command="npm start" if "start" in scripts else None,
            test_command="npm test" if "test" in scripts else None,
            build_command="npm run build" if "build" in scripts else None,
            dev_command="npm run dev" if "dev" in scripts else "npm start",
            entry_point="src/index.js",
            dependencies_file="package.json",
            config_files=["package.json", "tsconfig.json", "vite.config.js", "webpack.config.js"],
            environment={"BROWSER": "none"},  # Prevent auto-opening browser
            ports=[3000],
            error_patterns=self.get_error_patterns()
        )
    
    def get_error_patterns(self) -> List[str]:
        """Get React error patterns."""
        return [
            r"Error: Cannot find module",
            r"SyntaxError:",
            r"TypeError:",
            r"Module not found:",
            r"Failed to compile",
            r"Invalid hook call",
            r"React\.createElement:",
            r"Warning: Each child in a list",
            r"Uncaught Error:",
        ]


class NextJSProject(BaseProjectHandler):
    """Handler for Next.js projects."""
    
    name = "nextjs"
    priority = 25  # Check before React
    
    def detect(self, project_path: Path) -> bool:
        """Detect if this is a Next.js project."""
        if not self._file_exists(project_path, "package.json"):
            return False
        
        package_json = self._read_json(project_path / "package.json")
        if not package_json:
            return False
        
        dependencies = package_json.get("dependencies", {})
        return "next" in dependencies
    
    def get_config(self, project_path: Path) -> ProjectConfig:
        """Get Next.js project configuration."""
        package_json = self._read_json(project_path / "package.json") or {}
        scripts = package_json.get("scripts", {})
        
        return ProjectConfig(
            project_type=self.name,
            root_path=project_path,
            install_command="npm install",
            run_command="npm start" if "start" in scripts else None,
            test_command="npm test" if "test" in scripts else None,
            build_command="npm run build" if "build" in scripts else "next build",
            dev_command="npm run dev" if "dev" in scripts else "next dev",
            entry_point="pages/index.js",
            dependencies_file="package.json",
            config_files=["package.json", "next.config.js", "next.config.mjs", "tsconfig.json"],
            ports=[3000],
            error_patterns=self.get_error_patterns()
        )
    
    def get_error_patterns(self) -> List[str]:
        """Get Next.js error patterns."""
        return [
            r"Error: Cannot find module",
            r"SyntaxError:",
            r"TypeError:",
            r"Module not found:",
            r"Failed to compile",
            r"Server Error",
            r"Error occurred prerendering",
            r"getServerSideProps",
            r"getStaticProps",
            r"Unhandled Runtime Error",
        ]


class PythonProject(BaseProjectHandler):
    """Handler for generic Python projects."""
    
    name = "python"
    priority = 5
    
    def detect(self, project_path: Path) -> bool:
        """Detect if this is a Python project."""
        python_indicators = [
            "requirements.txt",
            "setup.py",
            "setup.cfg",
            "pyproject.toml",
            "Pipfile",
            "main.py",
            "app.py",
        ]
        return any(self._file_exists(project_path, f) for f in python_indicators)
    
    def get_config(self, project_path: Path) -> ProjectConfig:
        """Get Python project configuration."""
        # Determine entry point
        entry_point = None
        for candidate in ["main.py", "app.py", "run.py", "__main__.py"]:
            if self._file_exists(project_path, candidate):
                entry_point = candidate
                break
        
        # Determine install command
        install_command = None
        deps_file = None
        if self._file_exists(project_path, "requirements.txt"):
            install_command = "pip install -r requirements.txt"
            deps_file = "requirements.txt"
        elif self._file_exists(project_path, "pyproject.toml"):
            install_command = "pip install -e ."
            deps_file = "pyproject.toml"
        elif self._file_exists(project_path, "Pipfile"):
            install_command = "pipenv install"
            deps_file = "Pipfile"
        
        return ProjectConfig(
            project_type=self.name,
            root_path=project_path,
            install_command=install_command,
            run_command=f"python {entry_point}" if entry_point else None,
            test_command="pytest" if self._file_exists(project_path, "pytest.ini") or self._has_tests(project_path) else None,
            entry_point=entry_point,
            dependencies_file=deps_file,
            config_files=["pyproject.toml", "setup.py", "setup.cfg", "pytest.ini", "tox.ini"],
            error_patterns=self.get_error_patterns()
        )
    
    def _has_tests(self, project_path: Path) -> bool:
        """Check if project has test files."""
        test_dirs = ["tests", "test"]
        for test_dir in test_dirs:
            if (project_path / test_dir).is_dir():
                return True
        # Check for test files in root
        for f in project_path.glob("test_*.py"):
            return True
        return False
    
    def get_error_patterns(self) -> List[str]:
        """Get Python error patterns."""
        return [
            r"Traceback \(most recent call last\)",
            r"SyntaxError:",
            r"IndentationError:",
            r"TypeError:",
            r"ValueError:",
            r"KeyError:",
            r"ImportError:",
            r"ModuleNotFoundError:",
            r"AttributeError:",
            r"NameError:",
            r"FileNotFoundError:",
            r"RuntimeError:",
            r"AssertionError:",
        ]


class FlaskProject(BaseProjectHandler):
    """Handler for Flask projects."""
    
    name = "flask"
    priority = 15  # Check before generic Python
    
    def detect(self, project_path: Path) -> bool:
        """Detect if this is a Flask project."""
        requirements_path = project_path / "requirements.txt"
        if requirements_path.exists():
            try:
                content = requirements_path.read_text().lower()
                if "flask" in content:
                    return True
            except Exception:
                pass
        
        # Check common Flask entry points
        for entry in ["app.py", "application.py", "wsgi.py"]:
            entry_path = project_path / entry
            if entry_path.exists():
                try:
                    content = entry_path.read_text()
                    if "from flask import" in content or "import flask" in content.lower():
                        return True
                except Exception:
                    pass
        
        return False
    
    def get_config(self, project_path: Path) -> ProjectConfig:
        """Get Flask project configuration."""
        # Determine entry point
        entry_point = "app.py"
        for candidate in ["app.py", "application.py", "wsgi.py", "main.py"]:
            if self._file_exists(project_path, candidate):
                entry_point = candidate
                break
        
        return ProjectConfig(
            project_type=self.name,
            root_path=project_path,
            install_command="pip install -r requirements.txt" if self._file_exists(project_path, "requirements.txt") else None,
            run_command="flask run",
            test_command="pytest",
            dev_command="flask run --debug",
            entry_point=entry_point,
            dependencies_file="requirements.txt",
            config_files=["config.py", ".flaskenv", ".env"],
            environment={"FLASK_APP": entry_point},
            ports=[5000],
            error_patterns=self.get_error_patterns()
        )
    
    def get_error_patterns(self) -> List[str]:
        """Get Flask error patterns."""
        return [
            r"Traceback \(most recent call last\)",
            r"werkzeug\.exceptions",
            r"jinja2\.exceptions",
            r"BuildError:",
            r"TemplateNotFound:",
            r"RuntimeError:",
            r"Address already in use",
            r"ModuleNotFoundError:",
            r"ImportError:",
            r"flask\.cli\.NoAppException",
        ]


class DjangoProject(BaseProjectHandler):
    """Handler for Django projects."""
    
    name = "django"
    priority = 15  # Same as Flask
    
    def detect(self, project_path: Path) -> bool:
        """Detect if this is a Django project."""
        # Check for manage.py (Django signature file)
        if self._file_exists(project_path, "manage.py"):
            try:
                content = (project_path / "manage.py").read_text()
                if "django" in content.lower():
                    return True
            except Exception:
                pass
        
        # Check requirements
        requirements_path = project_path / "requirements.txt"
        if requirements_path.exists():
            try:
                content = requirements_path.read_text().lower()
                if "django" in content:
                    return True
            except Exception:
                pass
        
        return False
    
    def get_config(self, project_path: Path) -> ProjectConfig:
        """Get Django project configuration."""
        return ProjectConfig(
            project_type=self.name,
            root_path=project_path,
            install_command="pip install -r requirements.txt" if self._file_exists(project_path, "requirements.txt") else None,
            run_command="python manage.py runserver",
            test_command="python manage.py test",
            entry_point="manage.py",
            dependencies_file="requirements.txt",
            config_files=["manage.py", "settings.py", ".env"],
            ports=[8000],
            error_patterns=self.get_error_patterns()
        )
    
    def get_error_patterns(self) -> List[str]:
        """Get Django error patterns."""
        return [
            r"Traceback \(most recent call last\)",
            r"django\.core\.exceptions",
            r"ImproperlyConfigured:",
            r"TemplateDoesNotExist:",
            r"TemplateSyntaxError:",
            r"OperationalError:",
            r"IntegrityError:",
            r"ModuleNotFoundError:",
            r"ImportError:",
            r"django\.db\.utils",
        ]


class iOSProject(BaseProjectHandler):
    """Handler for iOS/SwiftUI projects."""
    
    name = "ios"
    priority = 18  # Check before generic Python/Node but after specific frameworks
    
    def detect(self, project_path: Path) -> bool:
        """Detect if this is an iOS/SwiftUI project."""
        # Check for .xcodeproj
        if list(project_path.glob("*.xcodeproj")):
            return True
        
        # Check for .xcworkspace
        if list(project_path.glob("*.xcworkspace")):
            return True
        
        # Check for Package.swift (Swift Package Manager)
        if self._file_exists(project_path, "Package.swift"):
            # Verify it's an iOS package by checking content
            try:
                content = (project_path / "Package.swift").read_text()
                if ".iOS" in content or "iOS" in content or "SwiftUI" in content:
                    return True
            except Exception:
                pass
        
        # Check for SwiftUI files
        for swift_file in project_path.rglob("*.swift"):
            try:
                content = swift_file.read_text()
                if "import SwiftUI" in content or "import UIKit" in content:
                    return True
            except Exception:
                continue
        
        return False
    
    def get_config(self, project_path: Path) -> ProjectConfig:
        """Get iOS project configuration."""
        # Find xcodeproj or xcworkspace
        xcworkspaces = list(project_path.glob("*.xcworkspace"))
        xcodeprojs = list(project_path.glob("*.xcodeproj"))
        has_package_swift = self._file_exists(project_path, "Package.swift")
        
        # Determine the project/workspace to use
        workspace_arg = ""
        project_arg = ""
        scheme = None
        
        if xcworkspaces:
            workspace_arg = f"-workspace {xcworkspaces[0].name}"
            scheme = xcworkspaces[0].stem
        elif xcodeprojs:
            project_arg = f"-project {xcodeprojs[0].name}"
            scheme = xcodeprojs[0].stem
        
        # Get scheme from xcodebuild list if possible
        detected_scheme = self._detect_scheme(project_path)
        if detected_scheme:
            scheme = detected_scheme
        
        # Build command
        build_args = workspace_arg or project_arg
        if scheme:
            build_args += f" -scheme {scheme}"
        
        build_command = f"xcodebuild {build_args} -sdk iphonesimulator -configuration Debug build CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO"
        
        # Install command for Swift Package Manager
        install_command = None
        if has_package_swift:
            install_command = "swift package resolve"
        
        # Test command
        test_command = f"xcodebuild {build_args} -sdk iphonesimulator -configuration Debug test CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO"
        
        # Run command - build and launch in simulator
        run_command = f"xcodebuild {build_args} -sdk iphonesimulator -configuration Debug build CODE_SIGN_IDENTITY=- CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO && xcrun simctl boot 'iPhone 15' 2>/dev/null; open -a Simulator"
        
        # Config files
        config_files = ["Package.swift", "Info.plist"]
        if xcodeprojs:
            config_files.append(xcodeprojs[0].name + "/project.pbxproj")
        if xcworkspaces:
            config_files.append(xcworkspaces[0].name)
        
        return ProjectConfig(
            project_type=self.name,
            root_path=project_path,
            install_command=install_command,
            run_command=run_command,
            test_command=test_command,
            build_command=build_command,
            entry_point=scheme,
            dependencies_file="Package.swift" if has_package_swift else None,
            config_files=config_files,
            environment={
                "SDKROOT": "iphonesimulator",
            },
            error_patterns=self.get_error_patterns()
        )
    
    def _detect_scheme(self, project_path: Path) -> Optional[str]:
        """Detect available schemes using xcodebuild."""
        import subprocess
        
        xcworkspaces = list(project_path.glob("*.xcworkspace"))
        xcodeprojs = list(project_path.glob("*.xcodeproj"))
        
        args = ["xcodebuild", "-list", "-json"]
        
        if xcworkspaces:
            args.extend(["-workspace", str(xcworkspaces[0])])
        elif xcodeprojs:
            args.extend(["-project", str(xcodeprojs[0])])
        else:
            return None
        
        try:
            result = subprocess.run(
                args,
                capture_output=True,
                text=True,
                timeout=30,
                cwd=str(project_path),
            )
            
            if result.returncode == 0:
                import json
                data = json.loads(result.stdout)
                if "workspace" in data:
                    schemes = data["workspace"].get("schemes", [])
                elif "project" in data:
                    schemes = data["project"].get("schemes", [])
                else:
                    schemes = []
                
                if schemes:
                    return schemes[0]
        except Exception:
            pass
        
        return None
    
    def get_install_command(self) -> Optional[str]:
        """Get command to install dependencies via Swift Package Manager."""
        return "swift package resolve"
    
    def get_run_command(self, scheme: Optional[str] = None) -> str:
        """Get command to build and run in simulator."""
        scheme_arg = f"-scheme {scheme}" if scheme else ""
        return f"xcodebuild {scheme_arg} -sdk iphonesimulator -configuration Debug build && xcrun simctl boot 'iPhone 15' 2>/dev/null; open -a Simulator"
    
    def get_test_command(self, scheme: Optional[str] = None) -> str:
        """Get command to run XCTest."""
        scheme_arg = f"-scheme {scheme}" if scheme else ""
        return f"xcodebuild {scheme_arg} -sdk iphonesimulator -configuration Debug test"
    
    def get_error_patterns(self) -> List[str]:
        """Get iOS/Swift error patterns."""
        return [
            # Swift compilation errors
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
            
            # Code signing errors
            r"Code Signing Error:",
            r"Signing for .* requires a development team",
            r"No signing certificate",
            r"Provisioning profile .* doesn't match",
            r"No profiles for .* were found",
            
            # Simulator errors
            r"Unable to boot device",
            r"Simulator .* not available",
            r"Failed to boot simulator",
            r"Device is not available",
            r"The requested device could not be found",
            
            # Build errors
            r"xcodebuild: error:",
            r"Build Failed",
            r"Compiling .* failed",
            r"Linking .* failed",
            r"Command .* failed with exit code",
            
            # SwiftUI preview errors
            r"Preview Crashed",
            r"Cannot preview in this file",
            r"PreviewProvider .* not found",
            r"Previews are limited to 15 seconds",
            
            # Dependency errors
            r"Package resolution failed",
            r"could not find module",
            r"No such module",
            r"Missing package product",
            r"dependency .* is not used",
            
            # Runtime errors
            r"fatal error:",
            r"EXC_BAD_ACCESS",
            r"EXC_BREAKPOINT",
            r"Thread \d+: Signal",
            r"Assertion failed",
            
            # Configuration errors
            r"target .* not found",
            r"scheme .* not found",
            r"workspace .* not found",
            r"project .* not found",
            r"The file .* couldn't be opened",
        ]


class GenericProject(BaseProjectHandler):
    """Fallback handler for generic projects."""
    
    name = "generic"
    priority = 0  # Lowest priority, used as fallback
    
    def detect(self, project_path: Path) -> bool:
        """Always returns True as fallback."""
        return True
    
    def get_config(self, project_path: Path) -> ProjectConfig:
        """Get generic project configuration."""
        # Try to find a main entry point
        entry_point = None
        for candidate in ["main.py", "main.js", "index.js", "app.py", "app.js", "run.sh"]:
            if self._file_exists(project_path, candidate):
                entry_point = candidate
                break
        
        # Determine run command based on entry point
        run_command = None
        if entry_point:
            if entry_point.endswith(".py"):
                run_command = f"python {entry_point}"
            elif entry_point.endswith(".js"):
                run_command = f"node {entry_point}"
            elif entry_point.endswith(".sh"):
                run_command = f"bash {entry_point}"
        
        return ProjectConfig(
            project_type=self.name,
            root_path=project_path,
            run_command=run_command,
            entry_point=entry_point,
            error_patterns=self.get_error_patterns()
        )
    
    def get_error_patterns(self) -> List[str]:
        """Get generic error patterns."""
        return [
            r"Error:",
            r"Exception:",
            r"Traceback",
            r"FATAL:",
            r"CRITICAL:",
            r"ERROR:",
            r"failed",
            r"error:",
        ]


# Registry of all handlers sorted by priority
PROJECT_HANDLERS: List[BaseProjectHandler] = sorted(
    [
        NextJSProject(),
        ReactProject(),
        DjangoProject(),
        FlaskProject(),
        iOSProject(),
        NodeJSProject(),
        PythonProject(),
        GenericProject(),
    ],
    key=lambda x: x.priority,
    reverse=True
)


def detect_project_type(project_path: Path) -> BaseProjectHandler:
    """Detect the project type and return the appropriate handler."""
    for handler in PROJECT_HANDLERS:
        if handler.detect(project_path):
            return handler
    # Fallback to generic (should always match)
    return GenericProject()
