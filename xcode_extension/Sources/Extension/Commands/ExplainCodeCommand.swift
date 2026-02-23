//
//  ExplainCodeCommand.swift
//  AI Orchestrator for Xcode
//
//  Command to explain code using AI
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation
import XcodeKit

/// Command to get AI-generated explanations for code
class ExplainCodeCommand: BaseCommand {
    
    override func perform(with invocation: XCSourceEditorCommandInvocation,
                         completionHandler: @escaping (Error?) -> Void) {
        
        guard let client = mcpClient else {
            completionHandler(createError(code: 1, message: "MCP client not initialized. Please check your settings."))
            return
        }
        
        let (code, range) = getSelectedCode(from: invocation)
        let language = getFileType(from: invocation)
        
        guard !code.isEmpty else {
            completionHandler(createError(code: 2, message: "No code to explain."))
            return
        }
        
        Logger.shared.log("Getting code explanation...")
        showNotification(title: "AI Orchestrator", message: "Analyzing code...")
        
        Task {
            do {
                let response = try await client.explainCode(code: code, language: language)
                
                if response.success {
                    let explanation = response.explanation ?? response.content
                    
                    // Format explanation as comments
                    let commentedExplanation = formatAsComment(explanation, language: language)
                    
                    // Insert explanation above the selected code
                    if let selectionRange = range {
                        await MainActor.run {
                            self.insertCode(in: invocation, at: selectionRange.start.line, code: commentedExplanation)
                        }
                    } else {
                        // Insert at the beginning of the file
                        await MainActor.run {
                            self.insertCode(in: invocation, at: 0, code: commentedExplanation)
                        }
                    }
                    
                    Logger.shared.log("Code explanation inserted")
                    showNotification(title: "Explanation Added", message: "Code explanation inserted as comments")
                    completionHandler(nil)
                } else {
                    completionHandler(self.createError(code: 3, message: "Failed to get explanation"))
                }
            } catch {
                Logger.shared.log("Error explaining code: \(error.localizedDescription)")
                completionHandler(self.createError(code: 4, message: error.localizedDescription))
            }
        }
    }
    
    /// Format explanation text as code comments
    private func formatAsComment(_ text: String, language: String) -> String {
        let lines = text.components(separatedBy: "\n")
        var result = ""
        
        switch language {
        case "swift", "objc", "objcpp", "c", "cpp":
            result = "/*\n"
            result += " * AI Orchestrator Code Explanation\n"
            result += " * " + String(repeating: "=", count: 40) + "\n"
            for line in lines {
                result += " * \(line)\n"
            }
            result += " */\n"
        default:
            result = "// AI Orchestrator Code Explanation\n"
            result += "// " + String(repeating: "=", count: 40) + "\n"
            for line in lines {
                result += "// \(line)\n"
            }
        }
        
        return result
    }
}
