//
//  SourceEditorExtension.swift
//  AI Orchestrator for Xcode
//
//  Main entry point for the Xcode Source Editor Extension
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation
import XcodeKit

/// Main extension class that Xcode loads
class SourceEditorExtension: NSObject, XCSourceEditorExtension {
    
    // MARK: - Properties
    
    private static var configuration: ExtensionConfiguration?
    private static var mcpClient: MCPClient?
    
    // MARK: - Extension Lifecycle
    
    func extensionDidFinishLaunching() {
        // Initialize configuration from user defaults and keychain
        Self.configuration = ExtensionConfiguration.load()
        
        // Initialize MCP client
        if let config = Self.configuration {
            Self.mcpClient = MCPClient(serverURL: config.mcpServerURL)
        }
        
        // Log extension startup
        Logger.shared.log("AI Orchestrator for Xcode extension loaded successfully")
    }
    
    // MARK: - Command Definitions
    
    var commandDefinitions: [[XCSourceEditorCommandDefinitionKey: Any]] {
        return [
            // Fix Code Issues (Cmd+Shift+F)
            [
                .identifierKey: "com.debuggerlab.ai-orchestrator-xcode.fix-code",
                .classNameKey: "FixCodeCommand",
                .nameKey: "Fix Code Issues"
            ],
            // Explain Code (Cmd+Shift+E)
            [
                .identifierKey: "com.debuggerlab.ai-orchestrator-xcode.explain-code",
                .classNameKey: "ExplainCodeCommand",
                .nameKey: "Explain Code"
            ],
            // Generate Tests (Cmd+Shift+T)
            [
                .identifierKey: "com.debuggerlab.ai-orchestrator-xcode.generate-tests",
                .classNameKey: "GenerateTestsCommand",
                .nameKey: "Generate Tests"
            ],
            // Refactor Code (Cmd+Shift+R)
            [
                .identifierKey: "com.debuggerlab.ai-orchestrator-xcode.refactor-code",
                .classNameKey: "RefactorCodeCommand",
                .nameKey: "Refactor Code"
            ],
            // Generate Documentation (Cmd+Shift+D)
            [
                .identifierKey: "com.debuggerlab.ai-orchestrator-xcode.generate-docs",
                .classNameKey: "GenerateDocsCommand",
                .nameKey: "Generate Documentation"
            ],
            // Build and Fix (Cmd+Shift+B)
            [
                .identifierKey: "com.debuggerlab.ai-orchestrator-xcode.build-and-fix",
                .classNameKey: "BuildAndFixCommand",
                .nameKey: "Build and Fix"
            ],
            // Settings
            [
                .identifierKey: "com.debuggerlab.ai-orchestrator-xcode.settings",
                .classNameKey: "SettingsCommand",
                .nameKey: "Settings"
            ]
        ]
    }
    
    // MARK: - Shared Resources
    
    static var sharedConfiguration: ExtensionConfiguration? {
        return configuration
    }
    
    static var sharedMCPClient: MCPClient? {
        return mcpClient
    }
    
    static func reloadConfiguration() {
        configuration = ExtensionConfiguration.load()
        if let config = configuration {
            mcpClient = MCPClient(serverURL: config.mcpServerURL)
        }
    }
}
