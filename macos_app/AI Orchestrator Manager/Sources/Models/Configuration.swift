//
//  Configuration.swift
//  AI Orchestrator Manager
//
//  Configuration models and structures
//

import Foundation

struct APIConfiguration: Codable {
    var openAIKey: String
    var anthropicKey: String
    var geminiKey: String
    var moonshotKey: String
    
    var openAIModel: String
    var anthropicModel: String
    var geminiModel: String
    var moonshotModel: String
    
    static let `default` = APIConfiguration(
        openAIKey: "",
        anthropicKey: "",
        geminiKey: "",
        moonshotKey: "",
        openAIModel: "gpt-4o-mini",
        anthropicModel: "claude-3-5-sonnet-20240620",
        geminiModel: "gemini-2.5-flash",
        moonshotModel: "moonshot-v1-8k"
    )
}

struct ServerConfiguration: Codable {
    var port: Int
    var autoStartOnLogin: Bool
    var logLevel: LogLevel
    var maxLogSizeMB: Int
    
    static let `default` = ServerConfiguration(
        port: 3000,
        autoStartOnLogin: false,
        logLevel: .info,
        maxLogSizeMB: 50
    )
}

enum LogLevel: String, Codable, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    
    var displayName: String {
        switch self {
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let level: LogLevel
    let message: String
    let source: String
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: timestamp)
    }
}

struct SystemRequirement: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    var isMet: Bool
    var statusMessage: String
    
    static let requirements: [SystemRequirement] = [
        SystemRequirement(
            name: "Python 3.9+",
            description: "Required for running the AI Orchestrator",
            isMet: false,
            statusMessage: "Checking..."
        ),
        SystemRequirement(
            name: "pip",
            description: "Python package manager",
            isMet: false,
            statusMessage: "Checking..."
        ),
        SystemRequirement(
            name: "Git",
            description: "For cloning the repository",
            isMet: false,
            statusMessage: "Checking..."
        ),
        SystemRequirement(
            name: "Xcode CLI Tools",
            description: "Required for some Python packages",
            isMet: false,
            statusMessage: "Checking..."
        )
    ]
}

enum InstallationStep: String, CaseIterable {
    case checkingRequirements = "Checking Requirements"
    case cloningRepository = "Cloning Repository"
    case creatingVenv = "Creating Virtual Environment"
    case installingDependencies = "Installing Dependencies"
    case configuringEnvironment = "Configuring Environment"
    case settingUpServer = "Setting Up Server"
    case complete = "Complete"
    
    var icon: String {
        switch self {
        case .checkingRequirements: return "checklist"
        case .cloningRepository: return "arrow.down.circle"
        case .creatingVenv: return "folder.badge.plus"
        case .installingDependencies: return "shippingbox"
        case .configuringEnvironment: return "gearshape"
        case .settingUpServer: return "server.rack"
        case .complete: return "checkmark.circle.fill"
        }
    }
}
