//
//  SwiftCodeParser.swift
//  AI Orchestrator for Xcode
//
//  Swift code parser for analyzing code structure
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation

/// Parsed code element
struct CodeElement {
    enum ElementType {
        case `class`
        case `struct`
        case `enum`
        case `protocol`
        case function
        case property
        case `extension`
        case `import`
    }
    
    let type: ElementType
    let name: String
    let lineNumber: Int
    let parameters: [String]?
    let returnType: String?
    let accessLevel: String?
    let body: String?
}

/// Swift code parser
class SwiftCodeParser {
    
    // MARK: - Patterns
    
    private let patterns: [CodeElement.ElementType: String] = [
        .class: "(?:public|private|internal|open|fileprivate)?\\s*(?:final\\s+)?class\\s+(\\w+)",
        .struct: "(?:public|private|internal|fileprivate)?\\s*struct\\s+(\\w+)",
        .enum: "(?:public|private|internal|fileprivate)?\\s*enum\\s+(\\w+)",
        .protocol: "(?:public|private|internal|fileprivate)?\\s*protocol\\s+(\\w+)",
        .function: "(?:public|private|internal|open|fileprivate)?\\s*(?:static\\s+)?(?:override\\s+)?func\\s+(\\w+)\\s*\\(([^)]*)\\)(?:\\s*(?:throws\\s*)?->\\s*(\\S+))?",
        .property: "(?:public|private|internal|fileprivate)?\\s*(?:static\\s+)?(?:let|var)\\s+(\\w+)",
        .extension: "extension\\s+(\\w+)",
        .import: "import\\s+(\\w+)"
    ]
    
    // MARK: - Parsing
    
    /// Parse Swift code and extract code elements
    func parse(_ code: String) -> [CodeElement] {
        var elements: [CodeElement] = []
        let lines = code.components(separatedBy: "\n")
        
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1
            
            // Check each pattern
            for (type, pattern) in patterns {
                if let element = parseElement(type: type, pattern: pattern, line: line, lineNumber: lineNumber) {
                    elements.append(element)
                }
            }
        }
        
        return elements
    }
    
    /// Parse a single element from a line
    private func parseElement(type: CodeElement.ElementType, pattern: String, line: String, lineNumber: Int) -> CodeElement? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let range = NSRange(line.startIndex..., in: line)
        guard let match = regex.firstMatch(in: line, options: [], range: range) else {
            return nil
        }
        
        // Extract name (first capture group)
        guard let nameRange = Range(match.range(at: 1), in: line) else {
            return nil
        }
        let name = String(line[nameRange])
        
        // Extract access level
        let accessLevel = extractAccessLevel(from: line)
        
        // For functions, extract parameters and return type
        var parameters: [String]? = nil
        var returnType: String? = nil
        
        if type == .function {
            if match.numberOfRanges > 2,
               let paramsRange = Range(match.range(at: 2), in: line) {
                let paramsStr = String(line[paramsRange])
                parameters = paramsStr.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }
            
            if match.numberOfRanges > 3,
               let returnRange = Range(match.range(at: 3), in: line) {
                returnType = String(line[returnRange])
            }
        }
        
        return CodeElement(
            type: type,
            name: name,
            lineNumber: lineNumber,
            parameters: parameters,
            returnType: returnType,
            accessLevel: accessLevel,
            body: nil
        )
    }
    
    /// Extract access level from a line
    private func extractAccessLevel(from line: String) -> String? {
        let accessLevels = ["public", "private", "internal", "open", "fileprivate"]
        for level in accessLevels {
            if line.contains(level) {
                return level
            }
        }
        return nil
    }
    
    // MARK: - Analysis
    
    /// Get all function signatures
    func getFunctions(from code: String) -> [CodeElement] {
        return parse(code).filter { $0.type == .function }
    }
    
    /// Get all type definitions (class, struct, enum, protocol)
    func getTypes(from code: String) -> [CodeElement] {
        return parse(code).filter {
            [.class, .struct, .enum, .protocol].contains($0.type)
        }
    }
    
    /// Get imports
    func getImports(from code: String) -> [String] {
        return parse(code).filter { $0.type == .import }.map { $0.name }
    }
    
    /// Check if code has syntax errors (basic check)
    func hasSyntaxErrors(_ code: String) -> Bool {
        var braceCount = 0
        var parenCount = 0
        var bracketCount = 0
        var inString = false
        var inComment = false
        var previousChar: Character = " "
        
        for char in code {
            // Handle strings
            if char == "\"" && previousChar != "\\" {
                inString.toggle()
            }
            
            // Handle comments
            if !inString {
                if previousChar == "/" && char == "/" {
                    // Single line comment - skip to end of line
                    continue
                }
                if previousChar == "/" && char == "*" {
                    inComment = true
                }
                if previousChar == "*" && char == "/" {
                    inComment = false
                }
            }
            
            if !inString && !inComment {
                switch char {
                case "{": braceCount += 1
                case "}": braceCount -= 1
                case "(": parenCount += 1
                case ")": parenCount -= 1
                case "[": bracketCount += 1
                case "]": bracketCount -= 1
                default: break
                }
            }
            
            previousChar = char
        }
        
        return braceCount != 0 || parenCount != 0 || bracketCount != 0
    }
}
