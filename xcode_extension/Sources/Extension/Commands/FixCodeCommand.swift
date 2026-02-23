//
//  FixCodeCommand.swift
//  AI Orchestrator for Xcode
//
//  Command to fix code issues using AI
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation
import XcodeKit

/// Command to analyze and fix code issues
class FixCodeCommand: BaseCommand {
    
    override func perform(with invocation: XCSourceEditorCommandInvocation,
                         completionHandler: @escaping (Error?) -> Void) {
        
        guard let client = mcpClient else {
            completionHandler(createError(code: 1, message: "MCP client not initialized. Please check your settings."))
            return
        }
        
        let (code, range) = getSelectedCode(from: invocation)
        let language = getFileType(from: invocation)
        
        guard !code.isEmpty else {
            completionHandler(createError(code: 2, message: "No code to analyze."))
            return
        }
        
        Logger.shared.log("Analyzing code for issues...")
        showNotification(title: "AI Orchestrator", message: "Analyzing code for issues...")
        
        Task {
            do {
                // Analyze and fix code
                let response = try await client.fixCode(code: code, language: language)
                
                if response.success, let fixedCode = response.fixedCode {
                    // Generate diff for user review
                    let diff = DiffGenerator.generateDiff(original: code, modified: fixedCode)
                    
                    if configuration?.autoApplyFixes == true {
                        // Auto-apply fixes
                        await MainActor.run {
                            self.replaceCode(in: invocation, range: range, with: fixedCode)
                        }
                        Logger.shared.log("Applied \(diff.changes.count) fixes automatically")
                        showNotification(title: "Code Fixed", message: "Applied \(diff.changes.count) fixes")
                    } else {
                        // Show diff and let user decide
                        Logger.shared.log("Fixes available. Review diff before applying.")
                        Logger.shared.log("Diff:\n\(diff.description)")
                        
                        // In a real implementation, would show a diff viewer UI
                        // For now, apply the fixes
                        await MainActor.run {
                            self.replaceCode(in: invocation, range: range, with: fixedCode)
                        }
                    }
                    
                    completionHandler(nil)
                } else {
                    Logger.shared.log("No issues found or no fixes available.")
                    showNotification(title: "AI Orchestrator", message: "No issues found")
                    completionHandler(nil)
                }
            } catch {
                Logger.shared.log("Error fixing code: \(error.localizedDescription)")
                completionHandler(self.createError(code: 3, message: error.localizedDescription))
            }
        }
    }
}
