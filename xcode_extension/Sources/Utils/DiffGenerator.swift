//
//  DiffGenerator.swift
//  AI Orchestrator for Xcode
//
//  Diff generator for comparing code changes
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation

/// Represents a single diff change
struct DiffChange {
    enum ChangeType {
        case addition
        case deletion
        case modification
        case unchanged
    }
    
    let type: ChangeType
    let originalLine: Int?
    let modifiedLine: Int?
    let originalContent: String?
    let modifiedContent: String?
}

/// Represents a complete diff result
struct DiffResult {
    let original: String
    let modified: String
    let changes: [DiffChange]
    let statistics: DiffStatistics
    
    var description: String {
        var result = "Diff: \(statistics.additions) additions, \(statistics.deletions) deletions, \(statistics.modifications) modifications\n"
        result += String(repeating: "-", count: 60) + "\n"
        
        for change in changes {
            switch change.type {
            case .addition:
                result += "+ \(change.modifiedContent ?? "")\n"
            case .deletion:
                result += "- \(change.originalContent ?? "")\n"
            case .modification:
                result += "- \(change.originalContent ?? "")\n"
                result += "+ \(change.modifiedContent ?? "")\n"
            case .unchanged:
                continue
            }
        }
        
        return result
    }
}

/// Statistics about the diff
struct DiffStatistics {
    let additions: Int
    let deletions: Int
    let modifications: Int
    let unchanged: Int
    
    var totalChanges: Int {
        return additions + deletions + modifications
    }
}

/// Diff generator using Myers algorithm (simplified)
class DiffGenerator {
    
    // MARK: - Public Methods
    
    /// Generate diff between two strings
    static func generateDiff(original: String, modified: String) -> DiffResult {
        let originalLines = original.components(separatedBy: "\n")
        let modifiedLines = modified.components(separatedBy: "\n")
        
        let changes = computeDiff(original: originalLines, modified: modifiedLines)
        let statistics = computeStatistics(changes: changes)
        
        return DiffResult(
            original: original,
            modified: modified,
            changes: changes,
            statistics: statistics
        )
    }
    
    /// Generate unified diff format
    static func generateUnifiedDiff(original: String, modified: String, context: Int = 3) -> String {
        let result = generateDiff(original: original, modified: modified)
        return formatAsUnifiedDiff(result, context: context)
    }
    
    /// Generate HTML diff for display
    static func generateHTMLDiff(original: String, modified: String) -> String {
        let result = generateDiff(original: original, modified: modified)
        return formatAsHTML(result)
    }
    
    // MARK: - Private Methods
    
    /// Compute diff using simplified LCS algorithm
    private static func computeDiff(original: [String], modified: [String]) -> [DiffChange] {
        var changes: [DiffChange] = []
        
        // Build LCS matrix
        let m = original.count
        let n = modified.count
        var lcs = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 1...m {
            for j in 1...n {
                if original[i - 1] == modified[j - 1] {
                    lcs[i][j] = lcs[i - 1][j - 1] + 1
                } else {
                    lcs[i][j] = max(lcs[i - 1][j], lcs[i][j - 1])
                }
            }
        }
        
        // Backtrack to find changes
        var i = m
        var j = n
        var tempChanges: [DiffChange] = []
        
        while i > 0 || j > 0 {
            if i > 0 && j > 0 && original[i - 1] == modified[j - 1] {
                tempChanges.insert(DiffChange(
                    type: .unchanged,
                    originalLine: i,
                    modifiedLine: j,
                    originalContent: original[i - 1],
                    modifiedContent: modified[j - 1]
                ), at: 0)
                i -= 1
                j -= 1
            } else if j > 0 && (i == 0 || lcs[i][j - 1] >= lcs[i - 1][j]) {
                tempChanges.insert(DiffChange(
                    type: .addition,
                    originalLine: nil,
                    modifiedLine: j,
                    originalContent: nil,
                    modifiedContent: modified[j - 1]
                ), at: 0)
                j -= 1
            } else if i > 0 && (j == 0 || lcs[i][j - 1] < lcs[i - 1][j]) {
                tempChanges.insert(DiffChange(
                    type: .deletion,
                    originalLine: i,
                    modifiedLine: nil,
                    originalContent: original[i - 1],
                    modifiedContent: nil
                ), at: 0)
                i -= 1
            }
        }
        
        // Merge consecutive deletion+addition into modification
        var index = 0
        while index < tempChanges.count {
            if index + 1 < tempChanges.count {
                let current = tempChanges[index]
                let next = tempChanges[index + 1]
                
                if current.type == .deletion && next.type == .addition {
                    changes.append(DiffChange(
                        type: .modification,
                        originalLine: current.originalLine,
                        modifiedLine: next.modifiedLine,
                        originalContent: current.originalContent,
                        modifiedContent: next.modifiedContent
                    ))
                    index += 2
                    continue
                }
            }
            
            if tempChanges[index].type != .unchanged {
                changes.append(tempChanges[index])
            }
            index += 1
        }
        
        return changes
    }
    
    /// Compute statistics from changes
    private static func computeStatistics(changes: [DiffChange]) -> DiffStatistics {
        var additions = 0
        var deletions = 0
        var modifications = 0
        var unchanged = 0
        
        for change in changes {
            switch change.type {
            case .addition: additions += 1
            case .deletion: deletions += 1
            case .modification: modifications += 1
            case .unchanged: unchanged += 1
            }
        }
        
        return DiffStatistics(
            additions: additions,
            deletions: deletions,
            modifications: modifications,
            unchanged: unchanged
        )
    }
    
    /// Format diff as unified diff
    private static func formatAsUnifiedDiff(_ diff: DiffResult, context: Int) -> String {
        var result = "--- original\n+++ modified\n"
        
        for change in diff.changes {
            switch change.type {
            case .addition:
                result += "+\(change.modifiedContent ?? "")\n"
            case .deletion:
                result += "-\(change.originalContent ?? "")\n"
            case .modification:
                result += "-\(change.originalContent ?? "")\n"
                result += "+\(change.modifiedContent ?? "")\n"
            case .unchanged:
                result += " \(change.originalContent ?? "")\n"
            }
        }
        
        return result
    }
    
    /// Format diff as HTML
    private static func formatAsHTML(_ diff: DiffResult) -> String {
        var html = "<div class='diff'>\n"
        html += "<style>\n"
        html += ".diff-add { background-color: #e6ffed; }\n"
        html += ".diff-del { background-color: #ffeef0; }\n"
        html += ".diff-mod { background-color: #fff5b1; }\n"
        html += "</style>\n"
        
        for change in diff.changes {
            switch change.type {
            case .addition:
                html += "<div class='diff-add'>+ \(escapeHTML(change.modifiedContent ?? ""))</div>\n"
            case .deletion:
                html += "<div class='diff-del'>- \(escapeHTML(change.originalContent ?? ""))</div>\n"
            case .modification:
                html += "<div class='diff-del'>- \(escapeHTML(change.originalContent ?? ""))</div>\n"
                html += "<div class='diff-add'>+ \(escapeHTML(change.modifiedContent ?? ""))</div>\n"
            case .unchanged:
                html += "<div>  \(escapeHTML(change.originalContent ?? ""))</div>\n"
            }
        }
        
        html += "</div>\n"
        return html
    }
    
    /// Escape HTML special characters
    private static func escapeHTML(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
