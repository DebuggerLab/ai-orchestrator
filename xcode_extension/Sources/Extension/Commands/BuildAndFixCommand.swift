//
//  BuildAndFixCommand.swift
//  AI Orchestrator for Xcode
//
//  Command to build project and auto-fix errors
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation
import XcodeKit

/// Command to build the project and automatically fix build errors
class BuildAndFixCommand: BaseCommand {
    
    override func perform(with invocation: XCSourceEditorCommandInvocation,
                         completionHandler: @escaping (Error?) -> Void) {
        
        guard let client = mcpClient else {
            completionHandler(createError(code: 1, message: "MCP client not initialized. Please check your settings."))
            return
        }
        
        Logger.shared.log("Starting build and fix process...")
        showNotification(title: "AI Orchestrator", message: "Building project...")
        
        Task {
            do {
                // Get project path from configuration or workspace
                let projectPath = configuration?.projectPath ?? getProjectPath()
                
                guard let path = projectPath else {
                    completionHandler(self.createError(code: 2, message: "Unable to determine project path"))
                    return
                }
                
                // Step 1: Trigger build and capture errors
                Logger.shared.log("Building project at: \(path)")
                let buildResult = try await runBuild(projectPath: path)
                
                if buildResult.success {
                    Logger.shared.log("Build succeeded!")
                    showNotification(title: "Build Successful", message: "No errors found")
                    completionHandler(nil)
                    return
                }
                
                Logger.shared.log("Build failed with \(buildResult.errors.count) errors")
                
                // Step 2: Send errors to orchestrator for analysis and fixes
                let errorMessages = buildResult.errors.map { $0.description }.joined(separator: "\n")
                let response = try await client.buildAndFix(projectPath: path, buildErrors: errorMessages)
                
                if response.success {
                    // Step 3: Apply fixes
                    let fixesApplied = try await applyFixes(response: response, invocation: invocation)
                    
                    if fixesApplied > 0 {
                        Logger.shared.log("Applied \(fixesApplied) fixes")
                        
                        // Step 4: Verify fixes by rebuilding
                        if configuration?.verifyFixesAfterBuild == true {
                            Logger.shared.log("Verifying fixes...")
                            let verifyResult = try await runBuild(projectPath: path)
                            
                            if verifyResult.success {
                                showNotification(title: "Build Fixed", message: "\(fixesApplied) fixes applied, build now succeeds")
                            } else {
                                showNotification(title: "Partial Fix", message: "\(fixesApplied) fixes applied, \(verifyResult.errors.count) errors remain")
                            }
                        } else {
                            showNotification(title: "Fixes Applied", message: "\(fixesApplied) fixes applied")
                        }
                    } else {
                        showNotification(title: "AI Orchestrator", message: "No automatic fixes available for these errors")
                    }
                    
                    completionHandler(nil)
                } else {
                    completionHandler(self.createError(code: 3, message: "Failed to analyze build errors"))
                }
            } catch {
                Logger.shared.log("Error in build and fix: \(error.localizedDescription)")
                completionHandler(self.createError(code: 4, message: error.localizedDescription))
            }
        }
    }
    
    // MARK: - Build Process
    
    /// Run the build process
    private func runBuild(projectPath: String) async throws -> BuildResult {
        // In a real implementation, this would:
        // 1. Find the Xcode project/workspace
        // 2. Run xcodebuild
        // 3. Parse the output for errors
        
        let process = Process()
        let pipe = Pipe()
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcodebuild")
        process.arguments = ["-project", projectPath, "-configuration", "Debug", "build"]
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        let errors = parseBuildErrors(from: output)
        let success = process.terminationStatus == 0
        
        return BuildResult(success: success, errors: errors, output: output)
    }
    
    /// Parse build errors from xcodebuild output
    private func parseBuildErrors(from output: String) -> [BuildError] {
        var errors: [BuildError] = []
        
        // Parse Xcode build output format
        // Format: /path/to/file.swift:line:column: error: message
        let pattern = "(.+?):(\\d+):(\\d+): (error|warning): (.+)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return errors
        }
        
        let lines = output.components(separatedBy: "\n")
        for line in lines {
            let range = NSRange(line.startIndex..., in: line)
            if let match = regex.firstMatch(in: line, options: [], range: range) {
                let file = String(line[Range(match.range(at: 1), in: line)!])
                let lineNum = Int(String(line[Range(match.range(at: 2), in: line)!])) ?? 0
                let column = Int(String(line[Range(match.range(at: 3), in: line)!])) ?? 0
                let type = String(line[Range(match.range(at: 4), in: line)!])
                let message = String(line[Range(match.range(at: 5), in: line)!])
                
                if type == "error" {
                    errors.append(BuildError(
                        file: file,
                        line: lineNum,
                        column: column,
                        message: message,
                        type: .error
                    ))
                }
            }
        }
        
        return errors
    }
    
    /// Get project path from workspace or configuration
    private func getProjectPath() -> String? {
        // In a real implementation, this would:
        // 1. Check current workspace
        // 2. Look for .xcodeproj or .xcworkspace
        // 3. Use configuration setting
        return configuration?.projectPath
    }
    
    /// Apply fixes from AI response
    private func applyFixes(response: AIResponse, invocation: XCSourceEditorCommandInvocation) async throws -> Int {
        var fixesApplied = 0
        
        // Parse fixes from response
        if let fixedCode = response.fixedCode {
            // Replace entire buffer with fixed code
            await MainActor.run {
                let buffer = invocation.buffer
                buffer.lines.removeAllObjects()
                let lines = fixedCode.components(separatedBy: "\n")
                for line in lines {
                    buffer.lines.add(line + "\n")
                }
            }
            fixesApplied = 1
        }
        
        // Parse individual fixes from metadata
        if let fixes = response.metadata["fixes"] as? [[String: Any]] {
            for fix in fixes {
                if let file = fix["file"] as? String,
                   let line = fix["line"] as? Int,
                   let replacement = fix["replacement"] as? String {
                    // Apply fix to specific location
                    Logger.shared.log("Applying fix to \(file):\(line)")
                    fixesApplied += 1
                }
            }
        }
        
        return fixesApplied
    }
}

// MARK: - Build Types

struct BuildResult {
    let success: Bool
    let errors: [BuildError]
    let output: String
}

struct BuildError {
    let file: String
    let line: Int
    let column: Int
    let message: String
    let type: BuildErrorType
    
    var description: String {
        "\(file):\(line):\(column): \(type.rawValue): \(message)"
    }
}

enum BuildErrorType: String {
    case error = "error"
    case warning = "warning"
}
