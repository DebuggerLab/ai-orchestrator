//
//  Logger.swift
//  AI Orchestrator for Xcode
//
//  Logging utility for the extension
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation
import os.log

/// Centralized logging for the extension
class Logger {
    
    // MARK: - Singleton
    
    static let shared = Logger()
    
    // MARK: - Properties
    
    private let osLog: OSLog
    private let logFile: URL?
    private let dateFormatter: DateFormatter
    
    private var isFileLoggingEnabled: Bool = true
    private var logLevel: LogLevel = .info
    
    // MARK: - Types
    
    enum LogLevel: Int, Comparable {
        case debug = 0
        case info = 1
        case warning = 2
        case error = 3
        
        static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
        
        var prefix: String {
            switch self {
            case .debug: return "📝 DEBUG"
            case .info: return "ℹ️ INFO"
            case .warning: return "⚠️ WARNING"
            case .error: return "❌ ERROR"
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        osLog = OSLog(subsystem: "com.debuggerlab.ai-orchestrator-xcode", category: "Extension")
        
        // Setup date formatter
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        
        // Setup log file
        let logsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config/ai-orchestrator/logs")
        
        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        
        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none)
            .replacingOccurrences(of: "/", with: "-")
        logFile = logsDir.appendingPathComponent("xcode-extension-\(dateStr).log")
    }
    
    // MARK: - Public Methods
    
    func log(_ message: String, level: LogLevel = .info, file: String = #file, function: String = #function, line: Int = #line) {
        guard level >= logLevel else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let fileName = (file as NSString).lastPathComponent
        let formattedMessage = "[\(timestamp)] \(level.prefix) [\(fileName):\(line)] \(message)"
        
        // Log to system console
        switch level {
        case .debug:
            os_log("%{public}@", log: osLog, type: .debug, message)
        case .info:
            os_log("%{public}@", log: osLog, type: .info, message)
        case .warning:
            os_log("%{public}@", log: osLog, type: .default, message)
        case .error:
            os_log("%{public}@", log: osLog, type: .error, message)
        }
        
        // Log to file
        if isFileLoggingEnabled, let logFile = logFile {
            appendToFile(formattedMessage + "\n", at: logFile)
        }
        
        // Also print to console for debugging
        #if DEBUG
        print(formattedMessage)
        #endif
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    // MARK: - Configuration
    
    func setLogLevel(_ level: LogLevel) {
        logLevel = level
    }
    
    func setFileLogging(enabled: Bool) {
        isFileLoggingEnabled = enabled
    }
    
    // MARK: - Private Methods
    
    private func appendToFile(_ text: String, at url: URL) {
        if FileManager.default.fileExists(atPath: url.path) {
            if let fileHandle = try? FileHandle(forWritingTo: url) {
                fileHandle.seekToEndOfFile()
                if let data = text.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
        } else {
            try? text.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}
