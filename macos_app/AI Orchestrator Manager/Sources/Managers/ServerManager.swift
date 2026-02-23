//
//  ServerManager.swift
//  AI Orchestrator Manager
//
//  Manages the MCP server process
//

import Foundation
import Combine

class ServerManager: ObservableObject {
    static let shared = ServerManager()
    
    @Published var status: ServerStatus = .stopped
    @Published var isRunning = false
    @Published var port = 3000
    @Published var processId: Int32?
    @Published var logs: [LogEntry] = []
    @Published var lastStarted: Date?
    @Published var memoryUsage = "N/A"
    
    private var serverProcess: Process?
    private var logTimer: Timer?
    private var healthCheckTimer: Timer?
    private var startTime: Date?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    
    var uptimeString: String {
        guard let start = startTime, isRunning else { return "N/A" }
        let interval = Date().timeIntervalSince(start)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%dh %dm %ds", hours, minutes, seconds)
        } else if minutes > 0 {
            return String(format: "%dm %ds", minutes, seconds)
        } else {
            return String(format: "%ds", seconds)
        }
    }
    
    var recentLogs: [LogEntry] {
        Array(logs.suffix(10))
    }
    
    private init() {
        setupHealthCheck()
    }
    
    // MARK: - Public Methods
    
    func loadConfiguration() -> ServerConfiguration {
        if let data = UserDefaults.standard.data(forKey: "serverConfiguration"),
           let config = try? JSONDecoder().decode(ServerConfiguration.self, from: data) {
            return config
        }
        return .default
    }
    
    func saveConfiguration(_ config: ServerConfiguration) {
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "serverConfiguration")
        }
        
        port = config.port
        
        // Setup auto-start if enabled
        if config.autoStartOnLogin {
            setupLaunchAgent()
        } else {
            removeLaunchAgent()
        }
    }
    
    func startServer() {
        guard !isRunning else { return }
        
        DispatchQueue.main.async {
            self.status = .starting
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.performStartServer()
        }
    }
    
    func stopServer() {
        guard isRunning else { return }
        
        DispatchQueue.main.async {
            self.status = .stopping
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.performStopServer()
        }
    }
    
    func restartServer() {
        stopServer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.startServer()
        }
    }
    
    func clearLogs() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
    
    func refreshLogs() {
        // Read logs from file if available
        let installPath = UserDefaults.standard.string(forKey: "installationPath") ?? ""
        let logPath = "\(installPath)/mcp_server/server.log"
        
        if FileManager.default.fileExists(atPath: logPath),
           let content = try? String(contentsOfFile: logPath, encoding: .utf8) {
            parseLogFile(content)
        }
    }
    
    // MARK: - Private Methods
    
    private func performStartServer() {
        let installPath = UserDefaults.standard.string(forKey: "installationPath") ?? FileManager.default.homeDirectoryForCurrentUser.path + "/ai_orchestrator"
        let serverPath = "\(installPath)/mcp_server"
        let pythonPath = "\(installPath)/venv/bin/python"
        let serverScript = "\(serverPath)/server.py"
        
        // Check if server script exists
        guard FileManager.default.fileExists(atPath: serverScript) else {
            DispatchQueue.main.async {
                self.status = .error
                self.addLog(.error, "Server script not found at \(serverScript)")
            }
            return
        }
        
        let process = Process()
        
        // Use virtual environment Python if available
        if FileManager.default.fileExists(atPath: pythonPath) {
            process.executableURL = URL(fileURLWithPath: pythonPath)
            process.arguments = [serverScript]
        } else {
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = ["python3", serverScript]
        }
        
        process.currentDirectoryURL = URL(fileURLWithPath: serverPath)
        
        // Set environment
        var env = ProcessInfo.processInfo.environment
        env["PYTHONPATH"] = installPath
        env["MCP_SERVER_PORT"] = String(port)
        process.environment = env
        
        // Setup pipes for output
        outputPipe = Pipe()
        errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Handle output
        outputPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                self?.handleServerOutput(output)
            }
        }
        
        errorPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                self?.handleServerError(output)
            }
        }
        
        // Handle termination
        process.terminationHandler = { [weak self] process in
            DispatchQueue.main.async {
                self?.handleServerTermination(process.terminationStatus)
            }
        }
        
        do {
            try process.run()
            serverProcess = process
            
            DispatchQueue.main.async {
                self.processId = process.processIdentifier
                self.status = .running
                self.isRunning = true
                self.startTime = Date()
                self.lastStarted = Date()
                self.addLog(.info, "Server started on port \(self.port)")
            }
        } catch {
            DispatchQueue.main.async {
                self.status = .error
                self.addLog(.error, "Failed to start server: \(error.localizedDescription)")
            }
        }
    }
    
    private func performStopServer() {
        if let process = serverProcess, process.isRunning {
            process.terminate()
        }
        
        // Also try to kill any process on the port
        let killResult = runCommand("lsof", arguments: ["-ti", ":\(port)"])
        if let pids = killResult.output?.trimmingCharacters(in: .whitespacesAndNewlines), !pids.isEmpty {
            for pid in pids.split(separator: "\n") {
                _ = runCommand("kill", arguments: ["-9", String(pid)])
            }
        }
        
        DispatchQueue.main.async {
            self.serverProcess = nil
            self.processId = nil
            self.status = .stopped
            self.isRunning = false
            self.startTime = nil
            self.addLog(.info, "Server stopped")
        }
    }
    
    private func handleServerOutput(_ output: String) {
        for line in output.split(separator: "\n") {
            let message = String(line)
            DispatchQueue.main.async {
                self.addLog(.info, message)
            }
        }
    }
    
    private func handleServerError(_ output: String) {
        for line in output.split(separator: "\n") {
            let message = String(line)
            let level: LogLevel = message.lowercased().contains("error") ? .error : 
                                  message.lowercased().contains("warning") ? .warning : .info
            DispatchQueue.main.async {
                self.addLog(level, message)
            }
        }
    }
    
    private func handleServerTermination(_ status: Int32) {
        isRunning = false
        serverProcess = nil
        processId = nil
        startTime = nil
        
        if status != 0 {
            self.status = .error
            addLog(.error, "Server exited with status \(status)")
        } else {
            self.status = .stopped
            addLog(.info, "Server stopped gracefully")
        }
    }
    
    private func addLog(_ level: LogLevel, _ message: String) {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            message: message,
            source: "MCP Server"
        )
        logs.append(entry)
        
        // Keep only last 1000 logs
        if logs.count > 1000 {
            logs.removeFirst(logs.count - 1000)
        }
    }
    
    private func parseLogFile(_ content: String) {
        // Parse log file format: [TIMESTAMP] [LEVEL] MESSAGE
        let lines = content.split(separator: "\n")
        for line in lines.suffix(100) {
            // Simple parsing - adjust based on actual log format
            let level: LogLevel
            if line.contains("ERROR") {
                level = .error
            } else if line.contains("WARNING") {
                level = .warning
            } else if line.contains("DEBUG") {
                level = .debug
            } else {
                level = .info
            }
            
            DispatchQueue.main.async {
                self.addLog(level, String(line))
            }
        }
    }
    
    private func setupHealthCheck() {
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.performHealthCheck()
        }
    }
    
    private func performHealthCheck() {
        guard isRunning, let process = serverProcess else { return }
        
        if !process.isRunning {
            DispatchQueue.main.async {
                self.handleServerTermination(process.terminationStatus)
            }
        }
        
        // Update memory usage
        if let pid = processId {
            let result = runCommand("ps", arguments: ["-o", "rss=", "-p", String(pid)])
            if let memory = result.output?.trimmingCharacters(in: .whitespacesAndNewlines),
               let kb = Int(memory) {
                DispatchQueue.main.async {
                    self.memoryUsage = self.formatMemory(kb)
                }
            }
        }
    }
    
    private func formatMemory(_ kilobytes: Int) -> String {
        if kilobytes > 1024 * 1024 {
            return String(format: "%.1f GB", Double(kilobytes) / 1024 / 1024)
        } else if kilobytes > 1024 {
            return String(format: "%.1f MB", Double(kilobytes) / 1024)
        } else {
            return "\(kilobytes) KB"
        }
    }
    
    private func setupLaunchAgent() {
        let launchAgentPath = FileManager.default.homeDirectoryForCurrentUser.path + "/Library/LaunchAgents/com.debuggerlab.ai-orchestrator-manager.plist"
        let installPath = UserDefaults.standard.string(forKey: "installationPath") ?? ""
        
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.debuggerlab.ai-orchestrator-manager</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(installPath)/venv/bin/python</string>
                <string>\(installPath)/mcp_server/server.py</string>
            </array>
            <key>RunAtLoad</key>
            <true/>
            <key>KeepAlive</key>
            <true/>
            <key>WorkingDirectory</key>
            <string>\(installPath)/mcp_server</string>
            <key>StandardOutPath</key>
            <string>\(installPath)/mcp_server/server.log</string>
            <key>StandardErrorPath</key>
            <string>\(installPath)/mcp_server/server_error.log</string>
            <key>EnvironmentVariables</key>
            <dict>
                <key>PYTHONPATH</key>
                <string>\(installPath)</string>
            </dict>
        </dict>
        </plist>
        """
        
        try? plist.write(toFile: launchAgentPath, atomically: true, encoding: .utf8)
        _ = runCommand("launchctl", arguments: ["load", launchAgentPath])
    }
    
    private func removeLaunchAgent() {
        let launchAgentPath = FileManager.default.homeDirectoryForCurrentUser.path + "/Library/LaunchAgents/com.debuggerlab.ai-orchestrator-manager.plist"
        
        if FileManager.default.fileExists(atPath: launchAgentPath) {
            _ = runCommand("launchctl", arguments: ["unload", launchAgentPath])
            try? FileManager.default.removeItem(atPath: launchAgentPath)
        }
    }
    
    private func runCommand(_ command: String, arguments: [String]) -> (output: String?, error: String?, exitCode: Int32) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = [command] + arguments
        
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
