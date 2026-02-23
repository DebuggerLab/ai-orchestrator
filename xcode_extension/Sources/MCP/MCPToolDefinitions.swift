//
//  MCPToolDefinitions.swift
//  AI Orchestrator for Xcode
//
//  Definitions for available MCP tools
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation

/// Available MCP tools for AI Orchestrator
enum MCPTool: String, CaseIterable {
    case routeTask = "route_task"
    case analyzeErrors = "analyze_errors"
    case fixIssues = "fix_issues"
    case runProject = "run_project"
    case testProject = "test_project"
    case verifyProject = "verify_project"
    case orchestrateDevelopment = "orchestrate_full_development"
    
    var description: String {
        switch self {
        case .routeTask:
            return "Route a task to the appropriate AI model"
        case .analyzeErrors:
            return "Analyze errors and suggest fixes"
        case .fixIssues:
            return "Apply AI-generated fixes to code"
        case .runProject:
            return "Run a project and capture output"
        case .testProject:
            return "Run project tests"
        case .verifyProject:
            return "Run verification loop (run-test-fix)"
        case .orchestrateDevelopment:
            return "Full development workflow orchestration"
        }
    }
    
    var requiredParameters: [String] {
        switch self {
        case .routeTask:
            return ["task"]
        case .analyzeErrors:
            return ["errors"]
        case .fixIssues:
            return ["project_path", "errors"]
        case .runProject:
            return ["project_path"]
        case .testProject:
            return ["project_path"]
        case .verifyProject:
            return ["project_path"]
        case .orchestrateDevelopment:
            return ["project_path", "task"]
        }
    }
}

/// Tool input schema for validation
struct MCPToolInput {
    let tool: MCPTool
    let parameters: [String: Any]
    
    func validate() -> Bool {
        for param in tool.requiredParameters {
            if parameters[param] == nil {
                return false
            }
        }
        return true
    }
}
