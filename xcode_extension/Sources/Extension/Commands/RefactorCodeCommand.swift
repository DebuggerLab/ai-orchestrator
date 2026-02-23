//
//  RefactorCodeCommand.swift
//  AI Orchestrator for Xcode
//
//  Command to refactor code using AI
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation
import XcodeKit

/// Command to refactor selected code
class RefactorCodeCommand: BaseCommand {
    
    override func perform(with invocation: XCSourceEditorCommandInvocation,
                         completionHandler: @escaping (Error?) -> Void) {
        
        guard let client = mcpClient else {
            completionHandler(createError(code: 1, message: "MCP client not initialized. Please check your settings."))
            return
        }
        
        let (code, range) = getSelectedCode(from: invocation)
        let language = getFileType(from: invocation)
        
        guard !code.isEmpty else {
            completionHandler(createError(code: 2, message: "No code to refactor."))
            return
        }
        
        Logger.shared.log("Refactoring code...")
        showNotification(title: "AI Orchestrator", message: "Analyzing code for refactoring...")
        
        Task {
            do {
                let response = try await client.refactorCode(code: code, language: language)
                
                if response.success, let refactoredCode = response.fixedCode ?? extractCodeBlock(from: response.content) {
                    // Generate diff for review
                    let diff = DiffGenerator.generateDiff(original: code, modified: refactoredCode)
                    
                    // Log refactoring suggestions
                    if !response.suggestions.isEmpty {
                        Logger.shared.log("Refactoring suggestions:")
                        for suggestion in response.suggestions {
                            Logger.shared.log("  - \(suggestion)")
                        }
                    }
                    
                    // Apply refactored code
                    await MainActor.run {
                        self.replaceCode(in: invocation, range: range, with: refactoredCode)
                    }
                    
                    Logger.shared.log("Code refactored successfully (\(diff.changes.count) changes)")
                    showNotification(title: "Code Refactored", message: "Applied \(diff.changes.count) improvements")
                    completionHandler(nil)
                } else {
                    // No refactoring needed or suggestions only
                    if !response.suggestions.isEmpty {
                        Logger.shared.log("Refactoring suggestions (no code changes):")
                        for suggestion in response.suggestions {
                            Logger.shared.log("  - \(suggestion)")
                        }
                        showNotification(title: "Suggestions Available", message: "\(response.suggestions.count) suggestions logged")
                    } else {
                        showNotification(title: "AI Orchestrator", message: "Code looks good, no refactoring needed")
                    }
                    completionHandler(nil)
                }
            } catch {
                Logger.shared.log("Error refactoring code: \(error.localizedDescription)")
                completionHandler(self.createError(code: 3, message: error.localizedDescription))
            }
        }
    }
    
    /// Extract code block from markdown response
    private func extractCodeBlock(from content: String) -> String? {
        let pattern = "```(?:swift|objc|cpp)?\\n([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let range = NSRange(content.startIndex..., in: content)
        guard let match = regex.firstMatch(in: content, options: [], range: range),
              let codeRange = Range(match.range(at: 1), in: content) else {
            return nil
        }
        
        return String(content[codeRange])
    }
}
