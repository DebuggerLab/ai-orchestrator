//
//  GenerateDocsCommand.swift
//  AI Orchestrator for Xcode
//
//  Command to generate documentation using AI
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation
import XcodeKit

/// Command to generate documentation comments for code
class GenerateDocsCommand: BaseCommand {
    
    override func perform(with invocation: XCSourceEditorCommandInvocation,
                         completionHandler: @escaping (Error?) -> Void) {
        
        guard let client = mcpClient else {
            completionHandler(createError(code: 1, message: "MCP client not initialized. Please check your settings."))
            return
        }
        
        let (code, range) = getSelectedCode(from: invocation)
        let language = getFileType(from: invocation)
        
        guard !code.isEmpty else {
            completionHandler(createError(code: 2, message: "No code to document."))
            return
        }
        
        // Determine documentation style
        let docStyle = getDocStyle(for: language)
        
        Logger.shared.log("Generating documentation...")
        showNotification(title: "AI Orchestrator", message: "Generating documentation...")
        
        Task {
            do {
                let response = try await client.generateDocumentation(
                    code: code,
                    language: language,
                    style: docStyle
                )
                
                if response.success {
                    let documentedCode = response.fixedCode ?? insertDocumentation(into: code, docs: response.content, language: language)
                    
                    // Replace original code with documented version
                    await MainActor.run {
                        self.replaceCode(in: invocation, range: range, with: documentedCode)
                    }
                    
                    Logger.shared.log("Documentation generated successfully")
                    showNotification(title: "Documentation Added", message: "Code documented")
                    completionHandler(nil)
                } else {
                    completionHandler(self.createError(code: 3, message: "Failed to generate documentation"))
                }
            } catch {
                Logger.shared.log("Error generating documentation: \(error.localizedDescription)")
                completionHandler(self.createError(code: 4, message: error.localizedDescription))
            }
        }
    }
    
    /// Get documentation style for language
    private func getDocStyle(for language: String) -> String {
        switch language {
        case "swift":
            return "swift-doc"  // /// style documentation
        case "objc", "objcpp":
            return "headerdoc"  // HeaderDoc style
        case "c", "cpp":
            return "doxygen"    // Doxygen style
        default:
            return "swift-doc"
        }
    }
    
    /// Insert documentation comments into code
    private func insertDocumentation(into code: String, docs: String, language: String) -> String {
        // Parse code to find functions/classes
        let parser = SwiftCodeParser()
        let elements = parser.parse(code)
        
        var result = code
        var offset = 0
        
        // Parse documentation response
        let docBlocks = parseDocBlocks(from: docs)
        
        // Match doc blocks to code elements and insert
        for element in elements {
            if let docBlock = findMatchingDocBlock(for: element, in: docBlocks) {
                let formattedDoc = formatDocBlock(docBlock, style: getDocStyle(for: language))
                let insertPosition = findInsertPosition(for: element, in: result, offset: offset)
                
                result.insert(contentsOf: formattedDoc + "\n", at: insertPosition)
                offset += formattedDoc.count + 1
            }
        }
        
        return result
    }
    
    /// Parse documentation blocks from AI response
    private func parseDocBlocks(from docs: String) -> [DocumentationBlock] {
        var blocks: [DocumentationBlock] = []
        
        // Simple parsing - look for function/class names followed by descriptions
        let lines = docs.components(separatedBy: "\n")
        var currentBlock: DocumentationBlock?
        
        for line in lines {
            if line.hasPrefix("## ") || line.hasPrefix("### ") {
                if let block = currentBlock {
                    blocks.append(block)
                }
                let name = line.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespaces)
                currentBlock = DocumentationBlock(name: name, description: "", parameters: [], returns: nil, throws: nil)
            } else if let block = currentBlock {
                if line.lowercased().hasPrefix("- parameter") || line.lowercased().hasPrefix("- param") {
                    let param = line.replacingOccurrences(of: "- [Pp]arameter\\s*", with: "", options: .regularExpression)
                    currentBlock?.parameters.append(param)
                } else if line.lowercased().hasPrefix("- returns:") {
                    currentBlock?.returns = line.replacingOccurrences(of: "- [Rr]eturns:\\s*", with: "", options: .regularExpression)
                } else if line.lowercased().hasPrefix("- throws:") {
                    currentBlock?.throws = line.replacingOccurrences(of: "- [Tt]hrows:\\s*", with: "", options: .regularExpression)
                } else if !line.trimmingCharacters(in: .whitespaces).isEmpty {
                    currentBlock?.description += (currentBlock?.description.isEmpty ?? true ? "" : " ") + line.trimmingCharacters(in: .whitespaces)
                }
            }
        }
        
        if let block = currentBlock {
            blocks.append(block)
        }
        
        return blocks
    }
    
    /// Find matching documentation block for a code element
    private func findMatchingDocBlock(for element: CodeElement, in blocks: [DocumentationBlock]) -> DocumentationBlock? {
        return blocks.first { $0.name.lowercased().contains(element.name.lowercased()) }
    }
    
    /// Find insert position for documentation
    private func findInsertPosition(for element: CodeElement, in code: String, offset: Int) -> String.Index {
        // Find the line where the element starts
        let lines = code.components(separatedBy: "\n")
        var currentPosition = 0
        
        for (index, line) in lines.enumerated() {
            if line.contains(element.name) && index >= element.lineNumber - 1 {
                return code.index(code.startIndex, offsetBy: currentPosition)
            }
            currentPosition += line.count + 1 // +1 for newline
        }
        
        return code.startIndex
    }
    
    /// Format documentation block for the specified style
    private func formatDocBlock(_ block: DocumentationBlock, style: String) -> String {
        var result = ""
        
        switch style {
        case "swift-doc":
            result += "/// \(block.description)\n"
            for param in block.parameters {
                result += "/// - Parameter \(param)\n"
            }
            if let returns = block.returns {
                result += "/// - Returns: \(returns)\n"
            }
            if let throwsDoc = block.throws {
                result += "/// - Throws: \(throwsDoc)\n"
            }
            
        case "headerdoc":
            result += "/**\n"
            result += " * @brief \(block.description)\n"
            for param in block.parameters {
                result += " * @param \(param)\n"
            }
            if let returns = block.returns {
                result += " * @return \(returns)\n"
            }
            result += " */\n"
            
        case "doxygen":
            result += "/**\n"
            result += " * \\brief \(block.description)\n"
            for param in block.parameters {
                result += " * \\param \(param)\n"
            }
            if let returns = block.returns {
                result += " * \\return \(returns)\n"
            }
            result += " */\n"
            
        default:
            result += "/// \(block.description)\n"
        }
        
        return result
    }
}

/// Documentation block structure
struct DocumentationBlock {
    var name: String
    var description: String
    var parameters: [String]
    var returns: String?
    var `throws`: String?
}
