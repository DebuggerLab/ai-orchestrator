//
//  ExtensionConfiguration.swift
//  AI Orchestrator for Xcode
//
//  Configuration model for the extension
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation
import Security

/// Extension configuration
struct ExtensionConfiguration: Codable {
    
    // MARK: - Server Settings
    
    /// MCP server URL
    var mcpServerURL: String
    
    /// Connection timeout in seconds
    var connectionTimeout: TimeInterval
    
    /// Maximum retry attempts
    var maxRetries: Int
    
    // MARK: - AI Model Settings
    
    /// Preferred AI model for code tasks
    var preferredModel: String
    
    /// Model for analysis tasks
    var analysisModel: String
    
    /// Model for fix generation
    var fixModel: String
    
    // MARK: - Behavior Settings
    
    /// Automatically apply fixes without confirmation
    var autoApplyFixes: Bool
    
    /// Verify fixes after build
    var verifyFixesAfterBuild: Bool
    
    /// Show diff before applying changes
    var showDiffBeforeApply: Bool
    
    /// Insert explanations as comments
    var insertExplanationsAsComments: Bool
    
    // MARK: - Project Settings
    
    /// Project path (if not auto-detected)
    var projectPath: String?
    
    /// Test framework preference
    var testFramework: String
    
    /// Documentation style preference
    var documentationStyle: String
    
    // MARK: - Defaults
    
    static let `default` = ExtensionConfiguration(
        mcpServerURL: "http://localhost:3000",
        connectionTimeout: 30.0,
        maxRetries: 3,
        preferredModel: "claude-3-5-sonnet",
        analysisModel: "gpt-4o",
        fixModel: "claude-3-5-sonnet",
        autoApplyFixes: false,
        verifyFixesAfterBuild: true,
        showDiffBeforeApply: true,
        insertExplanationsAsComments: true,
        projectPath: nil,
        testFramework: "XCTest",
        documentationStyle: "swift-doc"
    )
    
    // MARK: - Persistence
    
    private static let userDefaultsKey = "com.debuggerlab.ai-orchestrator-xcode.configuration"
    private static let configFileName = "settings.json"
    
    /// Load configuration from user defaults, file, or return defaults
    static func load() -> ExtensionConfiguration {
        // Try loading from UserDefaults first
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let config = try? JSONDecoder().decode(ExtensionConfiguration.self, from: data) {
            return config
        }
        
        // Try loading from config file
        if let config = loadFromFile() {
            return config
        }
        
        // Return defaults
        return .default
    }
    
    /// Save configuration to user defaults
    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
        }
        
        // Also save to file
        saveToFile()
    }
    
    /// Load configuration from file
    private static func loadFromFile() -> ExtensionConfiguration? {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/ai-orchestrator")
        let configFile = configDir.appendingPathComponent(configFileName)
        
        guard FileManager.default.fileExists(atPath: configFile.path),
              let data = try? Data(contentsOf: configFile),
              let config = try? JSONDecoder().decode(ExtensionConfiguration.self, from: data) else {
            return nil
        }
        
        return config
    }
    
    /// Save configuration to file
    private func saveToFile() {
        let configDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/ai-orchestrator")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        
        let configFile = configDir.appendingPathComponent(Self.configFileName)
        
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: configFile)
        }
    }
}

// MARK: - Keychain Helper

extension ExtensionConfiguration {
    
    /// Get API key from keychain
    static func getAPIKey(for service: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.debuggerlab.ai-orchestrator-xcode",
            kSecAttrAccount as String: service,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    /// Save API key to keychain
    static func setAPIKey(_ key: String, for service: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.debuggerlab.ai-orchestrator-xcode",
            kSecAttrAccount as String: service,
            kSecValueData as String: key.data(using: .utf8)!
        ]
        
        // Delete existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}
