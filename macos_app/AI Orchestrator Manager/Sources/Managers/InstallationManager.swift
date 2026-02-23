//
//  InstallationManager.swift
//  AI Orchestrator Manager
//
//  Handles installation of the AI Orchestrator
//

import Foundation
import AppKit

class InstallationManager: ObservableObject {
    static let shared = InstallationManager()
    
    @Published var isInstalled = false
    @Published var isInstalling = false
    @Published var currentStep: InstallationStep = .checkingRequirements
    @Published var installationProgress: Double = 0.0
    @Published var installationLog = ""
    @Published var installationPath = ""
    
    private var installTask: Process?
    
    private init() {}
    
    // MARK: - Public Methods
    
    func checkInstallation() {
        let defaultPath = FileManager.default.homeDirectoryForCurrentUser.path + "/ai_orchestrator"
        let userDefaultsPath = UserDefaults.standard.string(forKey: "installationPath") ?? defaultPath
        
        isInstalled = FileManager.default.fileExists(atPath: userDefaultsPath + "/mcp_server/server.py")
        installationPath = userDefaultsPath
    }
    
    func checkSystemRequirements(completion: @escaping ([SystemRequirement]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var requirements = SystemRequirement.requirements
            
            // Check Python
            let pythonResult = self.runCommand("python3", arguments: ["--version"])
            if let output = pythonResult.output, output.contains("Python 3") {
                let version = output.replacingOccurrences(of: "Python ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                requirements[0].isMet = self.isPythonVersionValid(version)
                requirements[0].statusMessage = requirements[0].isMet ? "v\(version)" : "v\(version) (3.9+ required)"
            } else {
                requirements[0].isMet = false
                requirements[0].statusMessage = "Not installed"
            }
            
            // Check pip
            let pipResult = self.runCommand("pip3", arguments: ["--version"])
            if pipResult.exitCode == 0 {
                requirements[1].isMet = true
                requirements[1].statusMessage = "Installed"
            } else {
                requirements[1].isMet = false
                requirements[1].statusMessage = "Not installed"
            }
            
            // Check Git
            let gitResult = self.runCommand("git", arguments: ["--version"])
            if let output = gitResult.output, output.contains("git version") {
                requirements[2].isMet = true
                requirements[2].statusMessage = "Installed"
            } else {
                requirements[2].isMet = false
                requirements[2].statusMessage = "Not installed"
            }
            
            // Check Xcode CLI Tools
            let xcodeResult = self.runCommand("xcode-select", arguments: ["-p"])
            if xcodeResult.exitCode == 0 {
                requirements[3].isMet = true
                requirements[3].statusMessage = "Installed"
            } else {
                requirements[3].isMet = false
                requirements[3].statusMessage = "Not installed"
            }
            
            completion(requirements)
        }
    }
    
    func installOrchestrator(at path: String) {
        guard !isInstalling else { return }
        
        isInstalling = true
        installationPath = path
        installationProgress = 0.0
        installationLog = ""
        
        UserDefaults.standard.set(path, forKey: "installationPath")
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.performInstallation(at: path)
        }
    }
    
    func cancelInstallation() {
        installTask?.terminate()
        installTask = nil
        DispatchQueue.main.async {
            self.isInstalling = false
            self.updateLog("Installation cancelled by user.")
        }
    }
    
    // MARK: - Private Methods
    
    private func performInstallation(at path: String) {
        // Step 1: Create directory
        updateStep(.checkingRequirements, progress: 0.1)
        updateLog("Creating installation directory...")
        
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        } catch {
            installationFailed("Failed to create directory: \(error.localizedDescription)")
            return
        }
        
        // Step 2: Clone repository
        updateStep(.cloningRepository, progress: 0.2)
        updateLog("Cloning AI Orchestrator repository...")
        
        let cloneResult = runCommand("git", arguments: [
            "clone",
            "https://github.com/debuggerlab/ai-orchestrator.git",
            path
        ], currentDirectory: FileManager.default.homeDirectoryForCurrentUser.path)
        
        if cloneResult.exitCode != 0 {
            // If clone fails, try to use existing files or download
            updateLog("Git clone failed, trying alternative method...")
            if !setupFromTemplate(at: path) {
                installationFailed("Failed to download repository: \(cloneResult.error ?? "Unknown error")")
                return
            }
        }
        
        // Step 3: Create virtual environment
        updateStep(.creatingVenv, progress: 0.4)
        updateLog("Creating Python virtual environment...")
        
        let venvResult = runCommand("python3", arguments: ["-m", "venv", "venv"], currentDirectory: path)
        if venvResult.exitCode != 0 {
            installationFailed("Failed to create virtual environment: \(venvResult.error ?? "Unknown error")")
            return
        }
        
        // Step 4: Install dependencies
        updateStep(.installingDependencies, progress: 0.6)
        updateLog("Installing Python dependencies...")
        
        let pipPath = "\(path)/venv/bin/pip"
        let requirementsPath = "\(path)/requirements.txt"
        
        if FileManager.default.fileExists(atPath: requirementsPath) {
            let pipResult = runCommand(pipPath, arguments: ["install", "-r", requirementsPath], currentDirectory: path)
            if pipResult.exitCode != 0 {
                updateLog("Warning: Some dependencies may have failed to install.")
            }
        }
        
        // Also install MCP server dependencies
        let mcpRequirements = "\(path)/mcp_server/requirements.txt"
        if FileManager.default.fileExists(atPath: mcpRequirements) {
            _ = runCommand(pipPath, arguments: ["install", "-r", mcpRequirements], currentDirectory: path)
        }
        
        // Step 5: Configure environment
        updateStep(.configuringEnvironment, progress: 0.8)
        updateLog("Configuring environment...")
        
        let envExample = "\(path)/.env.example"
        let envFile = "\(path)/.env"
        
        if FileManager.default.fileExists(atPath: envExample) && !FileManager.default.fileExists(atPath: envFile) {
            try? FileManager.default.copyItem(atPath: envExample, toPath: envFile)
        }
        
        // Step 6: Setup server
        updateStep(.settingUpServer, progress: 0.9)
        updateLog("Setting up MCP server...")
        
        let startScript = "\(path)/mcp_server/start.sh"
        if FileManager.default.fileExists(atPath: startScript) {
            _ = runCommand("chmod", arguments: ["+x", startScript])
        }
        
        // Complete
        updateStep(.complete, progress: 1.0)
        updateLog("Installation complete!")
        
        DispatchQueue.main.async {
            self.isInstalling = false
            self.isInstalled = true
        }
    }
    
    private func setupFromTemplate(at path: String) -> Bool {
        // Create basic structure if git clone fails
        let directories = [
            "\(path)/ai_orchestrator",
            "\(path)/mcp_server"
        ]
        
        for dir in directories {
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        }
        
        // Create basic requirements.txt
        let requirements = """
        openai>=1.0.0
        anthropic>=0.18.0
        google-generativeai>=0.5.0
        python-dotenv>=1.0.0
        rich>=13.0.0
        click>=8.0.0
        pydantic>=2.0.0
        requests>=2.31.0
        mcp>=1.0.0
        """
        
        try? requirements.write(toFile: "\(path)/requirements.txt", atomically: true, encoding: .utf8)
        
        // Create basic .env.example
        let envExample = """
        # API Keys
        OPENAI_API_KEY=your_openai_key_here
        ANTHROPIC_API_KEY=your_anthropic_key_here
        GEMINI_API_KEY=your_gemini_key_here
        MOONSHOT_API_KEY=your_moonshot_key_here
        
        # Model Configuration
        OPENAI_MODEL=gpt-4o-mini
        ANTHROPIC_MODEL=claude-3-5-sonnet-20241022
        GEMINI_MODEL=gemini-2.5-flash
        MOONSHOT_MODEL=moonshot-v1-8k
        """
        
        try? envExample.write(toFile: "\(path)/.env.example", atomically: true, encoding: .utf8)
        
        return true
    }
    
    private func updateStep(_ step: InstallationStep, progress: Double) {
        DispatchQueue.main.async {
            self.currentStep = step
            self.installationProgress = progress
        }
    }
    
    private func updateLog(_ message: String) {
        DispatchQueue.main.async {
            self.installationLog = message
        }
    }
    
    private func installationFailed(_ message: String) {
        DispatchQueue.main.async {
            self.isInstalling = false
            self.installationLog = "Error: \(message)"
        }
    }
    
    private func isPythonVersionValid(_ version: String) -> Bool {
        let components = version.split(separator: ".").compactMap { Int($0) }
        guard components.count >= 2 else { return false }
        return components[0] >= 3 && components[1] >= 9
    }
    
    private func runCommand(_ command: String, arguments: [String], currentDirectory: String? = nil) -> (output: String?, error: String?, exitCode: Int32) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments
        
        if let dir = currentDirectory {
            process.currentDirectoryURL = URL(fileURLWithPath: dir)
        }
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return (nil, error.localizedDescription, -1)
        }
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        return (
            String(data: outputData, encoding: .utf8),
            String(data: errorData, encoding: .utf8),
            process.terminationStatus
        )
    }
}
