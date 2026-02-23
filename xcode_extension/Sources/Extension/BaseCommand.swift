//
//  BaseCommand.swift
//  AI Orchestrator for Xcode
//
//  Base class for all extension commands with common functionality
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation
import XcodeKit

/// Base class for all AI Orchestrator commands
class BaseCommand: NSObject, XCSourceEditorCommand {
    
    // MARK: - Properties
    
    var mcpClient: MCPClient? {
        return SourceEditorExtension.sharedMCPClient
    }
    
    var configuration: ExtensionConfiguration? {
        return SourceEditorExtension.sharedConfiguration
    }
    
    // MARK: - XCSourceEditorCommand
    
    func perform(with invocation: XCSourceEditorCommandInvocation,
                 completionHandler: @escaping (Error?) -> Void) {
        // Subclasses must override this method
        fatalError("Subclasses must implement perform(with:completionHandler:)")
    }
    
    // MARK: - Helper Methods
    
    /// Get selected text from the buffer, or entire file if nothing selected
    func getSelectedCode(from invocation: XCSourceEditorCommandInvocation) -> (code: String, range: XCSourceTextRange?) {
        let buffer = invocation.buffer
        let selections = buffer.selections as! [XCSourceTextRange]
        
        guard let selection = selections.first else {
            // No selection, return entire file
            let allLines = buffer.lines as! [String]
            return (allLines.joined(), nil)
        }
        
        // Check if selection is just cursor position (no actual selection)
        if selection.start.line == selection.end.line &&
           selection.start.column == selection.end.column {
            let allLines = buffer.lines as! [String]
            return (allLines.joined(), nil)
        }
        
        // Extract selected lines
        var selectedCode = ""
        let lines = buffer.lines as! [String]
        
        for lineIndex in selection.start.line...selection.end.line {
            guard lineIndex < lines.count else { continue }
            let line = lines[lineIndex]
            
            if lineIndex == selection.start.line && lineIndex == selection.end.line {
                // Single line selection
                let startIdx = line.index(line.startIndex, offsetBy: min(selection.start.column, line.count))
                let endIdx = line.index(line.startIndex, offsetBy: min(selection.end.column, line.count))
                selectedCode += String(line[startIdx..<endIdx])
            } else if lineIndex == selection.start.line {
                // First line of multi-line selection
                let startIdx = line.index(line.startIndex, offsetBy: min(selection.start.column, line.count))
                selectedCode += String(line[startIdx...])
            } else if lineIndex == selection.end.line {
                // Last line of multi-line selection
                let endIdx = line.index(line.startIndex, offsetBy: min(selection.end.column, line.count))
                selectedCode += String(line[..<endIdx])
            } else {
                // Middle lines
                selectedCode += line
            }
        }
        
        return (selectedCode, selection)
    }
    
    /// Replace selected text or entire file with new code
    func replaceCode(in invocation: XCSourceEditorCommandInvocation,
                     range: XCSourceTextRange?,
                     with newCode: String) {
        let buffer = invocation.buffer
        
        if let range = range {
            // Replace selected range
            let lines = newCode.components(separatedBy: "\n")
            
            // Remove old lines
            let linesToRemove = range.end.line - range.start.line + 1
            for _ in 0..<linesToRemove {
                if range.start.line < buffer.lines.count {
                    buffer.lines.removeObject(at: range.start.line)
                }
            }
            
            // Insert new lines
            for (index, line) in lines.enumerated() {
                let insertIndex = range.start.line + index
                if insertIndex <= buffer.lines.count {
                    buffer.lines.insert(line + "\n", at: insertIndex)
                }
            }
        } else {
            // Replace entire file
            buffer.lines.removeAllObjects()
            let lines = newCode.components(separatedBy: "\n")
            for line in lines {
                buffer.lines.add(line + "\n")
            }
        }
    }
    
    /// Insert code at a specific position
    func insertCode(in invocation: XCSourceEditorCommandInvocation,
                    at line: Int,
                    code: String) {
        let buffer = invocation.buffer
        let lines = code.components(separatedBy: "\n")
        
        for (index, insertLine) in lines.enumerated() {
            let insertIndex = line + index
            if insertIndex <= buffer.lines.count {
                buffer.lines.insert(insertLine + "\n", at: insertIndex)
            }
        }
    }
    
    /// Get file type from the buffer's content UTI
    func getFileType(from invocation: XCSourceEditorCommandInvocation) -> String {
        let uti = invocation.buffer.contentUTI
        
        switch uti {
        case "public.swift-source":
            return "swift"
        case "public.objective-c-source":
            return "objc"
        case "public.objective-c-plus-plus-source":
            return "objcpp"
        case "public.c-source":
            return "c"
        case "public.c-plus-plus-source":
            return "cpp"
        case "public.c-header":
            return "header"
        default:
            return "unknown"
        }
    }
    
    /// Create an error for the command
    func createError(code: Int, message: String) -> NSError {
        return NSError(
            domain: "com.debuggerlab.ai-orchestrator-xcode",
            code: code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
    
    /// Show notification to user (logged for now, would integrate with Notification Center)
    func showNotification(title: String, message: String) {
        Logger.shared.log("[\(title)] \(message)")
        // In a real implementation, this would post to NotificationCenter
    }
}
