//
//  SettingsCommand.swift
//  AI Orchestrator for Xcode
//
//  Command to open settings panel
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation
import XcodeKit

/// Command to open the settings panel
class SettingsCommand: BaseCommand {
    
    override func perform(with invocation: XCSourceEditorCommandInvocation,
                         completionHandler: @escaping (Error?) -> Void) {
        
        Logger.shared.log("Opening settings...")
        
        // In a real implementation, this would:
        // 1. Open a settings window/panel
        // 2. Allow configuration of MCP server, API keys, preferences
        
        // For now, log current configuration
        if let config = configuration {
            Logger.shared.log("Current Configuration:")
            Logger.shared.log("  MCP Server URL: \(config.mcpServerURL)")
            Logger.shared.log("  Auto Apply Fixes: \(config.autoApplyFixes)")
            Logger.shared.log("  Verify After Build: \(config.verifyFixesAfterBuild)")
            Logger.shared.log("  Preferred Model: \(config.preferredModel)")
        } else {
            Logger.shared.log("No configuration loaded. Using defaults.")
        }
        
        // Launch settings app or show notification
        showNotification(title: "AI Orchestrator Settings", message: "Configure via preferences or .ai-orchestrator.json")
        
        // Open settings file location
        let settingsPath = getSettingsFilePath()
        Logger.shared.log("Settings file: \(settingsPath)")
        
        completionHandler(nil)
    }
    
    /// Get path to settings file
    private func getSettingsFilePath() -> String {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        return homeDir.appendingPathComponent(".config/ai-orchestrator/settings.json").path
    }
}
