//
//  CodeFormatter.swift
//  AI Orchestrator for Xcode
//
//  Code formatting utilities
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation

/// Code formatting utilities
class CodeFormatter {
    
    // MARK: - Types
    
    enum Language {
        case swift
        case objectiveC
        case cpp
        case c
        
        var indentString: String {
            return "    " // 4 spaces
        }
    }
    
    // MARK: - Formatting
    
    /// Format Swift code
    static func formatSwift(_ code: String) -> String {
        var result = ""
        var indentLevel = 0
        let lines = code.components(separatedBy: "\n")
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines
            if trimmed.isEmpty {
                result += "\n"
                continue
            }
            
            // Decrease indent for closing braces
            if trimmed.hasPrefix("}") || trimmed.hasPrefix(")") || trimmed.hasPrefix("]") {
                indentLevel = max(0, indentLevel - 1)
            }
            
            // Also decrease for case/default in switch
            if trimmed.hasPrefix("case ") || trimmed.hasPrefix("default:") {
                // Keep same level as switch
            }
            
            // Add indentation
            let indent = String(repeating: Language.swift.indentString, count: indentLevel)
            result += indent + trimmed + "\n"
            
            // Increase indent for opening braces
            if trimmed.hasSuffix("{") || trimmed.hasSuffix("(") || trimmed.hasSuffix("[") {
                indentLevel += 1
            }
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Normalize line endings
    static func normalizeLineEndings(_ code: String) -> String {
        return code
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
    }
    
    /// Remove trailing whitespace
    static func removeTrailingWhitespace(_ code: String) -> String {
        let lines = code.components(separatedBy: "\n")
        let trimmedLines = lines.map { $0.replacingOccurrences(of: "\\s+$", with: "", options: .regularExpression) }
        return trimmedLines.joined(separator: "\n")
    }
    
    /// Add newline at end of file if missing
    static func ensureTrailingNewline(_ code: String) -> String {
        if code.hasSuffix("\n") {
            return code
        }
        return code + "\n"
    }
    
    /// Convert tabs to spaces
    static func tabsToSpaces(_ code: String, tabWidth: Int = 4) -> String {
        let spaces = String(repeating: " ", count: tabWidth)
        return code.replacingOccurrences(of: "\t", with: spaces)
    }
    
    // MARK: - Code Manipulation
    
    /// Insert MARK comment
    static func insertMARK(_ name: String, at line: Int, in code: String) -> String {
        var lines = code.components(separatedBy: "\n")
        let markComment = "\n// MARK: - \(name)\n"
        
        if line < lines.count {
            lines.insert(markComment, at: line)
        } else {
            lines.append(markComment)
        }
        
        return lines.joined(separator: "\n")
    }
    
    /// Wrap code in a function
    static func wrapInFunction(_ code: String, name: String, parameters: String = "", returnType: String? = nil) -> String {
        var result = "func \(name)(\(parameters))"
        
        if let returnType = returnType {
            result += " -> \(returnType)"
        }
        
        result += " {\n"
        
        // Indent the code
        let lines = code.components(separatedBy: "\n")
        for line in lines {
            result += Language.swift.indentString + line + "\n"
        }
        
        result += "}\n"
        return result
    }
    
    /// Extract function body
    static func extractFunctionBody(_ code: String) -> String? {
        guard let openBrace = code.firstIndex(of: "{"),
              let closeBrace = code.lastIndex(of: "}") else {
            return nil
        }
        
        let startIndex = code.index(after: openBrace)
        let body = String(code[startIndex..<closeBrace])
        
        // Remove leading/trailing whitespace and dedent
        let lines = body.components(separatedBy: "\n")
        let trimmedLines = lines.map { $0.hasPrefix(Language.swift.indentString) ? String($0.dropFirst(4)) : $0 }
        
        return trimmedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Validation
    
    /// Check if code is valid Swift syntax (basic check)
    static func isValidSwiftSyntax(_ code: String) -> Bool {
        let parser = SwiftCodeParser()
        return !parser.hasSyntaxErrors(code)
    }
    
    /// Count lines of code (excluding comments and blank lines)
    static func countLinesOfCode(_ code: String) -> Int {
        let lines = code.components(separatedBy: "\n")
        var count = 0
        var inBlockComment = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines
            if trimmed.isEmpty {
                continue
            }
            
            // Handle block comments
            if trimmed.contains("/*") {
                inBlockComment = true
            }
            if trimmed.contains("*/") {
                inBlockComment = false
                continue
            }
            if inBlockComment {
                continue
            }
            
            // Skip single line comments
            if trimmed.hasPrefix("//") {
                continue
            }
            
            count += 1
        }
        
        return count
    }
}
