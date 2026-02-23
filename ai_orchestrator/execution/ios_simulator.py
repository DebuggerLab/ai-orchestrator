"""iOS Simulator management utilities for SwiftUI project development."""

import subprocess
import json
import re
import time
from typing import Optional, List, Dict, Any
from dataclasses import dataclass, field
from pathlib import Path
from enum import Enum


class SimulatorState(Enum):
    """State of an iOS simulator."""
    SHUTDOWN = "Shutdown"
    BOOTED = "Booted"
    BOOTING = "Booting"
    SHUTTING_DOWN = "Shutting Down"


@dataclass
class Simulator:
    """Represents an iOS Simulator device."""
    udid: str
    name: str
    state: SimulatorState
    is_available: bool
    device_type: str = ""
    runtime: str = ""
    os_version: str = ""
    
    @property
    def is_booted(self) -> bool:
        return self.state == SimulatorState.BOOTED


@dataclass
class SimulatorResult:
    """Result of a simulator operation."""
    success: bool
    message: str
    simulator: Optional[Simulator] = None
    output: Optional[str] = None
    error: Optional[str] = None
    data: Dict[str, Any] = field(default_factory=dict)


@dataclass
class AppInstallResult:
    """Result of installing an app on simulator."""
    success: bool
    app_path: str
    bundle_id: Optional[str] = None
    message: str = ""
    error: Optional[str] = None


@dataclass
class BuildResult:
    """Result of building an iOS project."""
    success: bool
    project_path: str
    build_dir: Optional[str] = None
    app_path: Optional[str] = None
    message: str = ""
    output: Optional[str] = None
    error: Optional[str] = None
    duration: float = 0.0


class iOSSimulatorManager:
    """Manager for iOS Simulator operations using xcrun simctl."""
    
    def __init__(self, default_device: str = "iPhone 15", default_os: str = "iOS 17.0"):
        """Initialize the iOS Simulator manager.
        
        Args:
            default_device: Default device name (e.g., "iPhone 15")
            default_os: Default iOS version (e.g., "iOS 17.0")
        """
        self.default_device = default_device
        self.default_os = default_os
    
    def _run_simctl(self, args: List[str], timeout: int = 60) -> tuple:
        """Run an xcrun simctl command.
        
        Args:
            args: Arguments to pass to simctl
            timeout: Command timeout in seconds
            
        Returns:
            Tuple of (return_code, stdout, stderr)
        """
        cmd = ["xcrun", "simctl"] + args
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout,
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return -1, "", "Command timed out"
        except FileNotFoundError:
            return -1, "", "xcrun not found. Is Xcode installed?"
        except Exception as e:
            return -1, "", str(e)
    
    def _run_xcodebuild(self, args: List[str], cwd: str, timeout: int = 600) -> tuple:
        """Run an xcodebuild command.
        
        Args:
            args: Arguments to pass to xcodebuild
            cwd: Working directory
            timeout: Command timeout in seconds
            
        Returns:
            Tuple of (return_code, stdout, stderr)
        """
        cmd = ["xcodebuild"] + args
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout,
                cwd=cwd,
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return -1, "", "Build timed out"
        except FileNotFoundError:
            return -1, "", "xcodebuild not found. Is Xcode installed?"
        except Exception as e:
            return -1, "", str(e)
    
    def list_simulators(self, available_only: bool = True) -> List[Simulator]:
        """List available iOS simulators.
        
        Args:
            available_only: Only return available simulators
            
        Returns:
            List of Simulator objects
        """
        retcode, stdout, stderr = self._run_simctl(["list", "devices", "-j"])
        
        if retcode != 0:
            return []
        
        try:
            data = json.loads(stdout)
            simulators = []
            
            for runtime, devices in data.get("devices", {}).items():
                # Extract iOS version from runtime string
                # e.g., "com.apple.CoreSimulator.SimRuntime.iOS-17-0"
                os_version = ""
                ios_match = re.search(r"iOS[.-](\d+[.-]\d+)", runtime)
                if ios_match:
                    os_version = ios_match.group(1).replace("-", ".")
                
                for device in devices:
                    is_available = device.get("isAvailable", True)
                    
                    if available_only and not is_available:
                        continue
                    
                    state_str = device.get("state", "Shutdown")
                    try:
                        state = SimulatorState(state_str)
                    except ValueError:
                        state = SimulatorState.SHUTDOWN
                    
                    sim = Simulator(
                        udid=device.get("udid", ""),
                        name=device.get("name", ""),
                        state=state,
                        is_available=is_available,
                        device_type=device.get("deviceTypeIdentifier", ""),
                        runtime=runtime,
                        os_version=os_version,
                    )
                    simulators.append(sim)
            
            return simulators
        except json.JSONDecodeError:
            return []
    
    def find_simulator(
        self,
        device_name: Optional[str] = None,
        os_version: Optional[str] = None,
    ) -> Optional[Simulator]:
        """Find a simulator matching the given criteria.
        
        Args:
            device_name: Device name to match (e.g., "iPhone 15")
            os_version: iOS version to match (e.g., "17.0")
            
        Returns:
            Matching Simulator or None
        """
        device_name = device_name or self.default_device
        simulators = self.list_simulators()
        
        # First try exact match
        for sim in simulators:
            if sim.name == device_name:
                if os_version is None or os_version in sim.os_version:
                    return sim
        
        # Try partial match
        for sim in simulators:
            if device_name.lower() in sim.name.lower():
                if os_version is None or os_version in sim.os_version:
                    return sim
        
        # Return any available iPhone
        for sim in simulators:
            if "iPhone" in sim.name:
                return sim
        
        return simulators[0] if simulators else None
    
    def get_booted_simulator(self) -> Optional[Simulator]:
        """Get the currently booted simulator.
        
        Returns:
            Booted Simulator or None
        """
        simulators = self.list_simulators()
        for sim in simulators:
            if sim.is_booted:
                return sim
        return None
    
    def boot_simulator(
        self,
        simulator: Optional[Simulator] = None,
        device_name: Optional[str] = None,
        wait: bool = True,
        timeout: int = 120,
    ) -> SimulatorResult:
        """Boot an iOS simulator.
        
        Args:
            simulator: Simulator to boot (optional)
            device_name: Device name if simulator not provided
            wait: Wait for boot to complete
            timeout: Boot timeout in seconds
            
        Returns:
            SimulatorResult indicating success/failure
        """
        if simulator is None:
            simulator = self.find_simulator(device_name)
            if simulator is None:
                return SimulatorResult(
                    success=False,
                    message="No simulator found matching criteria",
                )
        
        if simulator.is_booted:
            return SimulatorResult(
                success=True,
                message=f"Simulator {simulator.name} is already booted",
                simulator=simulator,
            )
        
        retcode, stdout, stderr = self._run_simctl(["boot", simulator.udid])
        
        if retcode != 0 and "current state: Booted" not in stderr:
            return SimulatorResult(
                success=False,
                message=f"Failed to boot simulator: {stderr}",
                simulator=simulator,
                error=stderr,
            )
        
        # Wait for boot to complete
        if wait:
            start_time = time.time()
            while time.time() - start_time < timeout:
                sim = self.find_simulator(simulator.name)
                if sim and sim.is_booted:
                    # Also open Simulator app
                    subprocess.run(
                        ["open", "-a", "Simulator"],
                        capture_output=True,
                    )
                    return SimulatorResult(
                        success=True,
                        message=f"Successfully booted simulator {simulator.name}",
                        simulator=sim,
                    )
                time.sleep(2)
            
            return SimulatorResult(
                success=False,
                message=f"Timeout waiting for simulator {simulator.name} to boot",
                simulator=simulator,
            )
        
        return SimulatorResult(
            success=True,
            message=f"Boot command sent to simulator {simulator.name}",
            simulator=simulator,
        )
    
    def shutdown_simulator(self, simulator: Optional[Simulator] = None) -> SimulatorResult:
        """Shutdown an iOS simulator.
        
        Args:
            simulator: Simulator to shutdown (or booted one if None)
            
        Returns:
            SimulatorResult indicating success/failure
        """
        if simulator is None:
            simulator = self.get_booted_simulator()
            if simulator is None:
                return SimulatorResult(
                    success=True,
                    message="No simulator is currently booted",
                )
        
        retcode, stdout, stderr = self._run_simctl(["shutdown", simulator.udid])
        
        if retcode != 0 and "current state: Shutdown" not in stderr:
            return SimulatorResult(
                success=False,
                message=f"Failed to shutdown simulator: {stderr}",
                simulator=simulator,
                error=stderr,
            )
        
        return SimulatorResult(
            success=True,
            message=f"Successfully shutdown simulator {simulator.name}",
            simulator=simulator,
        )
    
    def erase_simulator(self, simulator: Simulator) -> SimulatorResult:
        """Erase/reset a simulator to clean state.
        
        Args:
            simulator: Simulator to erase
            
        Returns:
            SimulatorResult indicating success/failure
        """
        # Shutdown first if running
        if simulator.is_booted:
            self.shutdown_simulator(simulator)
            time.sleep(2)
        
        retcode, stdout, stderr = self._run_simctl(["erase", simulator.udid])
        
        if retcode != 0:
            return SimulatorResult(
                success=False,
                message=f"Failed to erase simulator: {stderr}",
                simulator=simulator,
                error=stderr,
            )
        
        return SimulatorResult(
            success=True,
            message=f"Successfully erased simulator {simulator.name}",
            simulator=simulator,
        )
    
    def install_app(
        self,
        app_path: str,
        simulator: Optional[Simulator] = None,
        boot_if_needed: bool = True,
    ) -> AppInstallResult:
        """Install an app on the simulator.
        
        Args:
            app_path: Path to the .app bundle
            simulator: Target simulator (or booted one if None)
            boot_if_needed: Boot simulator if not running
            
        Returns:
            AppInstallResult indicating success/failure
        """
        app_path_obj = Path(app_path)
        if not app_path_obj.exists():
            return AppInstallResult(
                success=False,
                app_path=app_path,
                message=f"App not found: {app_path}",
                error="App bundle does not exist",
            )
        
        # Get or boot simulator
        if simulator is None:
            simulator = self.get_booted_simulator()
        
        if simulator is None or not simulator.is_booted:
            if boot_if_needed:
                boot_result = self.boot_simulator(simulator)
                if not boot_result.success:
                    return AppInstallResult(
                        success=False,
                        app_path=app_path,
                        message="Failed to boot simulator for app installation",
                        error=boot_result.error,
                    )
                simulator = boot_result.simulator
            else:
                return AppInstallResult(
                    success=False,
                    app_path=app_path,
                    message="No booted simulator available",
                    error="Simulator not running",
                )
        
        # Extract bundle ID from Info.plist
        bundle_id = self._get_bundle_id(app_path)
        
        # Install the app
        retcode, stdout, stderr = self._run_simctl(
            ["install", simulator.udid, app_path]
        )
        
        if retcode != 0:
            return AppInstallResult(
                success=False,
                app_path=app_path,
                bundle_id=bundle_id,
                message=f"Failed to install app: {stderr}",
                error=stderr,
            )
        
        return AppInstallResult(
            success=True,
            app_path=app_path,
            bundle_id=bundle_id,
            message=f"Successfully installed app on {simulator.name}",
        )
    
    def launch_app(
        self,
        bundle_id: str,
        simulator: Optional[Simulator] = None,
        wait_for_debugger: bool = False,
    ) -> SimulatorResult:
        """Launch an app on the simulator.
        
        Args:
            bundle_id: App bundle identifier
            simulator: Target simulator (or booted one if None)
            wait_for_debugger: Wait for debugger to attach
            
        Returns:
            SimulatorResult indicating success/failure
        """
        if simulator is None:
            simulator = self.get_booted_simulator()
            if simulator is None:
                return SimulatorResult(
                    success=False,
                    message="No booted simulator available",
                )
        
        args = ["launch", simulator.udid, bundle_id]
        if wait_for_debugger:
            args.insert(2, "-w")
        
        retcode, stdout, stderr = self._run_simctl(args)
        
        if retcode != 0:
            return SimulatorResult(
                success=False,
                message=f"Failed to launch app: {stderr}",
                simulator=simulator,
                error=stderr,
            )
        
        return SimulatorResult(
            success=True,
            message=f"Successfully launched {bundle_id} on {simulator.name}",
            simulator=simulator,
            output=stdout,
        )
    
    def terminate_app(
        self,
        bundle_id: str,
        simulator: Optional[Simulator] = None,
    ) -> SimulatorResult:
        """Terminate a running app on the simulator.
        
        Args:
            bundle_id: App bundle identifier
            simulator: Target simulator (or booted one if None)
            
        Returns:
            SimulatorResult indicating success/failure
        """
        if simulator is None:
            simulator = self.get_booted_simulator()
            if simulator is None:
                return SimulatorResult(
                    success=False,
                    message="No booted simulator available",
                )
        
        retcode, stdout, stderr = self._run_simctl(
            ["terminate", simulator.udid, bundle_id]
        )
        
        # It's okay if app wasn't running
        if retcode != 0 and "not running" not in stderr.lower():
            return SimulatorResult(
                success=False,
                message=f"Failed to terminate app: {stderr}",
                simulator=simulator,
                error=stderr,
            )
        
        return SimulatorResult(
            success=True,
            message=f"Successfully terminated {bundle_id}",
            simulator=simulator,
        )
    
    def uninstall_app(
        self,
        bundle_id: str,
        simulator: Optional[Simulator] = None,
    ) -> SimulatorResult:
        """Uninstall an app from the simulator.
        
        Args:
            bundle_id: App bundle identifier
            simulator: Target simulator (or booted one if None)
            
        Returns:
            SimulatorResult indicating success/failure
        """
        if simulator is None:
            simulator = self.get_booted_simulator()
            if simulator is None:
                return SimulatorResult(
                    success=False,
                    message="No booted simulator available",
                )
        
        retcode, stdout, stderr = self._run_simctl(
            ["uninstall", simulator.udid, bundle_id]
        )
        
        if retcode != 0:
            return SimulatorResult(
                success=False,
                message=f"Failed to uninstall app: {stderr}",
                simulator=simulator,
                error=stderr,
            )
        
        return SimulatorResult(
            success=True,
            message=f"Successfully uninstalled {bundle_id}",
            simulator=simulator,
        )
    
    def get_app_container(
        self,
        bundle_id: str,
        container_type: str = "app",
        simulator: Optional[Simulator] = None,
    ) -> Optional[str]:
        """Get the path to an app container on the simulator.
        
        Args:
            bundle_id: App bundle identifier
            container_type: Type of container (app, data, groups)
            simulator: Target simulator (or booted one if None)
            
        Returns:
            Path to container or None
        """
        if simulator is None:
            simulator = self.get_booted_simulator()
            if simulator is None:
                return None
        
        retcode, stdout, stderr = self._run_simctl(
            ["get_app_container", simulator.udid, bundle_id, container_type]
        )
        
        if retcode != 0:
            return None
        
        return stdout.strip()
    
    def take_screenshot(
        self,
        output_path: str,
        simulator: Optional[Simulator] = None,
    ) -> SimulatorResult:
        """Take a screenshot of the simulator.
        
        Args:
            output_path: Path to save the screenshot
            simulator: Target simulator (or booted one if None)
            
        Returns:
            SimulatorResult indicating success/failure
        """
        if simulator is None:
            simulator = self.get_booted_simulator()
            if simulator is None:
                return SimulatorResult(
                    success=False,
                    message="No booted simulator available",
                )
        
        retcode, stdout, stderr = self._run_simctl(
            ["io", simulator.udid, "screenshot", output_path]
        )
        
        if retcode != 0:
            return SimulatorResult(
                success=False,
                message=f"Failed to take screenshot: {stderr}",
                simulator=simulator,
                error=stderr,
            )
        
        return SimulatorResult(
            success=True,
            message=f"Screenshot saved to {output_path}",
            simulator=simulator,
            data={"screenshot_path": output_path},
        )
    
    def get_logs(
        self,
        simulator: Optional[Simulator] = None,
        predicate: Optional[str] = None,
        timeout: int = 5,
    ) -> SimulatorResult:
        """Get recent logs from the simulator.
        
        Args:
            simulator: Target simulator (or booted one if None)
            predicate: Log filter predicate
            timeout: How long to collect logs
            
        Returns:
            SimulatorResult with logs in output
        """
        if simulator is None:
            simulator = self.get_booted_simulator()
            if simulator is None:
                return SimulatorResult(
                    success=False,
                    message="No booted simulator available",
                )
        
        args = ["spawn", simulator.udid, "log", "show", "--last", f"{timeout}s"]
        if predicate:
            args.extend(["--predicate", predicate])
        
        retcode, stdout, stderr = self._run_simctl(args, timeout=timeout + 10)
        
        # Log show command often returns non-zero even when successful
        return SimulatorResult(
            success=True,
            message="Logs retrieved",
            simulator=simulator,
            output=stdout or stderr,
        )
    
    def _get_bundle_id(self, app_path: str) -> Optional[str]:
        """Extract bundle ID from an app bundle.
        
        Args:
            app_path: Path to the .app bundle
            
        Returns:
            Bundle ID or None
        """
        info_plist = Path(app_path) / "Info.plist"
        if not info_plist.exists():
            return None
        
        try:
            result = subprocess.run(
                ["/usr/libexec/PlistBuddy", "-c", "Print :CFBundleIdentifier", str(info_plist)],
                capture_output=True,
                text=True,
            )
            if result.returncode == 0:
                return result.stdout.strip()
        except Exception:
            pass
        
        return None


class iOSProjectBuilder:
    """Builder for iOS/SwiftUI projects using xcodebuild."""
    
    def __init__(
        self,
        simulator_manager: Optional[iOSSimulatorManager] = None,
        build_timeout: int = 600,
    ):
        """Initialize the iOS project builder.
        
        Args:
            simulator_manager: Simulator manager instance
            build_timeout: Build timeout in seconds
        """
        self.simulator_manager = simulator_manager or iOSSimulatorManager()
        self.build_timeout = build_timeout
    
    def detect_project_type(self, project_path: Path) -> Dict[str, Any]:
        """Detect the type of iOS project.
        
        Args:
            project_path: Path to the project
            
        Returns:
            Dictionary with project info
        """
        info = {
            "is_ios_project": False,
            "has_xcodeproj": False,
            "has_xcworkspace": False,
            "has_package_swift": False,
            "has_swiftui": False,
            "xcodeproj_path": None,
            "xcworkspace_path": None,
            "package_swift_path": None,
            "scheme": None,
        }
        
        # Check for .xcodeproj
        xcodeprojs = list(project_path.glob("*.xcodeproj"))
        if xcodeprojs:
            info["has_xcodeproj"] = True
            info["xcodeproj_path"] = str(xcodeprojs[0])
            info["is_ios_project"] = True
        
        # Check for .xcworkspace
        xcworkspaces = list(project_path.glob("*.xcworkspace"))
        if xcworkspaces:
            info["has_xcworkspace"] = True
            info["xcworkspace_path"] = str(xcworkspaces[0])
            info["is_ios_project"] = True
        
        # Check for Package.swift
        package_swift = project_path / "Package.swift"
        if package_swift.exists():
            info["has_package_swift"] = True
            info["package_swift_path"] = str(package_swift)
            info["is_ios_project"] = True
        
        # Check for SwiftUI files
        swift_files = list(project_path.rglob("*.swift"))
        for swift_file in swift_files:
            try:
                content = swift_file.read_text()
                if "import SwiftUI" in content or "SwiftUI." in content:
                    info["has_swiftui"] = True
                    break
            except Exception:
                continue
        
        return info
    
    def get_schemes(self, project_path: Path) -> List[str]:
        """List available schemes in the project.
        
        Args:
            project_path: Path to the project
            
        Returns:
            List of scheme names
        """
        project_info = self.detect_project_type(project_path)
        
        args = ["-list", "-json"]
        
        if project_info["has_xcworkspace"]:
            args.extend(["-workspace", project_info["xcworkspace_path"]])
        elif project_info["has_xcodeproj"]:
            args.extend(["-project", project_info["xcodeproj_path"]])
        else:
            return []
        
        try:
            result = subprocess.run(
                ["xcodebuild"] + args,
                capture_output=True,
                text=True,
                timeout=30,
                cwd=str(project_path),
            )
            
            if result.returncode == 0:
                data = json.loads(result.stdout)
                if "workspace" in data:
                    return data["workspace"].get("schemes", [])
                elif "project" in data:
                    return data["project"].get("schemes", [])
        except (subprocess.TimeoutExpired, json.JSONDecodeError):
            pass
        
        return []
    
    def build_for_simulator(
        self,
        project_path: Path,
        scheme: Optional[str] = None,
        simulator: Optional[Simulator] = None,
        configuration: str = "Debug",
        derived_data_path: Optional[str] = None,
    ) -> BuildResult:
        """Build an iOS project for the simulator.
        
        Args:
            project_path: Path to the project
            scheme: Build scheme (auto-detected if None)
            simulator: Target simulator
            configuration: Build configuration (Debug/Release)
            derived_data_path: Custom derived data path
            
        Returns:
            BuildResult indicating success/failure
        """
        import time
        start_time = time.time()
        
        project_info = self.detect_project_type(project_path)
        
        if not project_info["is_ios_project"]:
            return BuildResult(
                success=False,
                project_path=str(project_path),
                message="Not an iOS project",
                error="No .xcodeproj, .xcworkspace, or Package.swift found",
            )
        
        # Determine scheme
        if scheme is None:
            schemes = self.get_schemes(project_path)
            if schemes:
                scheme = schemes[0]
            else:
                # Try to derive from project name
                if project_info["has_xcodeproj"]:
                    scheme = Path(project_info["xcodeproj_path"]).stem
                elif project_info["has_xcworkspace"]:
                    scheme = Path(project_info["xcworkspace_path"]).stem
        
        # Get or find simulator
        if simulator is None:
            simulator = self.simulator_manager.find_simulator()
        
        # Build arguments
        args = ["build"]
        
        if project_info["has_xcworkspace"]:
            args.extend(["-workspace", project_info["xcworkspace_path"]])
        elif project_info["has_xcodeproj"]:
            args.extend(["-project", project_info["xcodeproj_path"]])
        
        if scheme:
            args.extend(["-scheme", scheme])
        
        args.extend([
            "-configuration", configuration,
            "-sdk", "iphonesimulator",
            "-destination", f"platform=iOS Simulator,id={simulator.udid}" if simulator else "platform=iOS Simulator",
        ])
        
        # Set derived data path
        if derived_data_path is None:
            derived_data_path = str(project_path / "build" / "DerivedData")
        args.extend(["-derivedDataPath", derived_data_path])
        
        # Enable code coverage and other settings
        args.extend([
            "CODE_SIGN_IDENTITY=-",
            "CODE_SIGNING_REQUIRED=NO",
            "CODE_SIGNING_ALLOWED=NO",
        ])
        
        try:
            result = subprocess.run(
                ["xcodebuild"] + args,
                capture_output=True,
                text=True,
                timeout=self.build_timeout,
                cwd=str(project_path),
            )
            
            duration = time.time() - start_time
            
            if result.returncode != 0:
                return BuildResult(
                    success=False,
                    project_path=str(project_path),
                    message="Build failed",
                    output=result.stdout,
                    error=result.stderr,
                    duration=duration,
                )
            
            # Find the built .app
            app_path = self._find_built_app(derived_data_path)
            
            return BuildResult(
                success=True,
                project_path=str(project_path),
                build_dir=derived_data_path,
                app_path=app_path,
                message="Build succeeded",
                output=result.stdout,
                duration=duration,
            )
            
        except subprocess.TimeoutExpired:
            return BuildResult(
                success=False,
                project_path=str(project_path),
                message="Build timed out",
                error=f"Build exceeded timeout of {self.build_timeout} seconds",
                duration=self.build_timeout,
            )
        except FileNotFoundError:
            return BuildResult(
                success=False,
                project_path=str(project_path),
                message="xcodebuild not found",
                error="Xcode command line tools are not installed",
                duration=time.time() - start_time,
            )
        except Exception as e:
            return BuildResult(
                success=False,
                project_path=str(project_path),
                message="Build failed with exception",
                error=str(e),
                duration=time.time() - start_time,
            )
    
    def run_tests(
        self,
        project_path: Path,
        scheme: Optional[str] = None,
        simulator: Optional[Simulator] = None,
        configuration: str = "Debug",
    ) -> BuildResult:
        """Run XCTest tests for an iOS project.
        
        Args:
            project_path: Path to the project
            scheme: Test scheme
            simulator: Target simulator
            configuration: Build configuration
            
        Returns:
            BuildResult with test output
        """
        import time
        start_time = time.time()
        
        project_info = self.detect_project_type(project_path)
        
        if not project_info["is_ios_project"]:
            return BuildResult(
                success=False,
                project_path=str(project_path),
                message="Not an iOS project",
                error="No .xcodeproj, .xcworkspace, or Package.swift found",
            )
        
        # Determine scheme
        if scheme is None:
            schemes = self.get_schemes(project_path)
            if schemes:
                scheme = schemes[0]
        
        # Get or find simulator
        if simulator is None:
            simulator = self.simulator_manager.find_simulator()
        
        # Build test arguments
        args = ["test"]
        
        if project_info["has_xcworkspace"]:
            args.extend(["-workspace", project_info["xcworkspace_path"]])
        elif project_info["has_xcodeproj"]:
            args.extend(["-project", project_info["xcodeproj_path"]])
        
        if scheme:
            args.extend(["-scheme", scheme])
        
        args.extend([
            "-configuration", configuration,
            "-sdk", "iphonesimulator",
            "-destination", f"platform=iOS Simulator,id={simulator.udid}" if simulator else "platform=iOS Simulator",
            "CODE_SIGN_IDENTITY=-",
            "CODE_SIGNING_REQUIRED=NO",
            "CODE_SIGNING_ALLOWED=NO",
        ])
        
        try:
            result = subprocess.run(
                ["xcodebuild"] + args,
                capture_output=True,
                text=True,
                timeout=self.build_timeout,
                cwd=str(project_path),
            )
            
            duration = time.time() - start_time
            
            return BuildResult(
                success=result.returncode == 0,
                project_path=str(project_path),
                message="Tests passed" if result.returncode == 0 else "Tests failed",
                output=result.stdout,
                error=result.stderr if result.returncode != 0 else None,
                duration=duration,
            )
            
        except subprocess.TimeoutExpired:
            return BuildResult(
                success=False,
                project_path=str(project_path),
                message="Tests timed out",
                error=f"Tests exceeded timeout of {self.build_timeout} seconds",
                duration=self.build_timeout,
            )
        except Exception as e:
            return BuildResult(
                success=False,
                project_path=str(project_path),
                message="Test execution failed",
                error=str(e),
                duration=time.time() - start_time,
            )
    
    def clean(self, project_path: Path, scheme: Optional[str] = None) -> BuildResult:
        """Clean the build artifacts.
        
        Args:
            project_path: Path to the project
            scheme: Build scheme
            
        Returns:
            BuildResult indicating success/failure
        """
        import time
        start_time = time.time()
        
        project_info = self.detect_project_type(project_path)
        
        args = ["clean"]
        
        if project_info["has_xcworkspace"]:
            args.extend(["-workspace", project_info["xcworkspace_path"]])
        elif project_info["has_xcodeproj"]:
            args.extend(["-project", project_info["xcodeproj_path"]])
        
        if scheme:
            args.extend(["-scheme", scheme])
        
        try:
            result = subprocess.run(
                ["xcodebuild"] + args,
                capture_output=True,
                text=True,
                timeout=60,
                cwd=str(project_path),
            )
            
            return BuildResult(
                success=result.returncode == 0,
                project_path=str(project_path),
                message="Clean succeeded" if result.returncode == 0 else "Clean failed",
                output=result.stdout,
                error=result.stderr if result.returncode != 0 else None,
                duration=time.time() - start_time,
            )
        except Exception as e:
            return BuildResult(
                success=False,
                project_path=str(project_path),
                message="Clean failed",
                error=str(e),
                duration=time.time() - start_time,
            )
    
    def _find_built_app(self, derived_data_path: str) -> Optional[str]:
        """Find the built .app bundle in derived data.
        
        Args:
            derived_data_path: Path to derived data
            
        Returns:
            Path to .app bundle or None
        """
        derived_path = Path(derived_data_path)
        products_path = derived_path / "Build" / "Products"
        
        # Look in Debug-iphonesimulator first
        for config_dir in ["Debug-iphonesimulator", "Release-iphonesimulator"]:
            config_path = products_path / config_dir
            if config_path.exists():
                apps = list(config_path.glob("*.app"))
                if apps:
                    return str(apps[0])
        
        # Search recursively
        apps = list(products_path.rglob("*.app"))
        if apps:
            return str(apps[0])
        
        return None


# Convenience functions
def list_simulators(available_only: bool = True) -> List[Simulator]:
    """List available iOS simulators."""
    return iOSSimulatorManager().list_simulators(available_only)


def boot_simulator(device_name: Optional[str] = None) -> SimulatorResult:
    """Boot an iOS simulator."""
    return iOSSimulatorManager().boot_simulator(device_name=device_name)


def get_booted_simulator() -> Optional[Simulator]:
    """Get the currently booted simulator."""
    return iOSSimulatorManager().get_booted_simulator()


def build_ios_project(project_path: str, scheme: Optional[str] = None) -> BuildResult:
    """Build an iOS project for the simulator."""
    return iOSProjectBuilder().build_for_simulator(Path(project_path), scheme)


def run_ios_tests(project_path: str, scheme: Optional[str] = None) -> BuildResult:
    """Run tests for an iOS project."""
    return iOSProjectBuilder().run_tests(Path(project_path), scheme)
