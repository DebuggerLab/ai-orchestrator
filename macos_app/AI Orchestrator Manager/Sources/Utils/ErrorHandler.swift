//
//  ErrorHandler.swift
//  AI Orchestrator Manager
//
//  Centralized error handling with user-friendly messages
//

import Foundation
import AppKit

enum AppError: Error {
    case networkError(String)
    case installationError(String)
    case serverError(String)
    case configurationError(String)
    case fileSystemError(String)
    case pythonError(String)
    case keychainError(String)
    case unknown(String)
    
    var title: String {
        switch self {
        case .networkError: return "Network Error"
        case .installationError: return "Installation Error"
        case .serverError: return "Server Error"
        case .configurationError: return "Configuration Error"
        case .fileSystemError: return "File System Error"
        case .pythonError: return "Python Error"
        case .keychainError: return "Keychain Error"
        case .unknown: return "Error"
        }
    }
    
    var message: String {
        switch self {
        case .networkError(let msg): return msg
        case .installationError(let msg): return msg
        case .serverError(let msg): return msg
        case .configurationError(let msg): return msg
        case .fileSystemError(let msg): return msg
        case .pythonError(let msg): return msg
        case .keychainError(let msg): return msg
        case .unknown(let msg): return msg
        }
    }
    
    var recoveryInstructions: String {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .installationError:
            return "Try reinstalling or check the system requirements."
        case .serverError:
            return "Try restarting the server or check the logs for details."
        case .configurationError:
            return "Please verify your configuration settings."
        case .fileSystemError:
            return "Check file permissions and disk space."
        case .pythonError:
            return "Ensure Python 3.9+ is installed correctly."
        case .keychainError:
            return "Check Keychain Access permissions for this app."
        case .unknown:
            return "Please try again or contact support."
        }
    }
}

class ErrorHandler {
    static let shared = ErrorHandler()
    
    private init() {}
    
    func handle(_ error: Error, context: String = "") {
        let appError = categorize(error, context: context)
        log(appError)
        showAlert(appError)
    }
    
    func handle(_ error: AppError) {
        log(error)
        showAlert(error)
    }
    
    private func categorize(_ error: Error, context: String) -> AppError {
        let description = error.localizedDescription.lowercased()
        
        if description.contains("network") || description.contains("connection") || description.contains("internet") {
            return .networkError(error.localizedDescription)
        } else if description.contains("permission") || description.contains("access") || description.contains("denied") {
            return .fileSystemError(error.localizedDescription)
        } else if description.contains("python") {
            return .pythonError(error.localizedDescription)
        } else if description.contains("keychain") || description.contains("security") {
            return .keychainError(error.localizedDescription)
        } else {
            return .unknown("\(context): \(error.localizedDescription)")
        }
    }
    
    private func log(_ error: AppError) {
        print("[ERROR] \(error.title): \(error.message)")
        
        // Also log to file
        let logPath = FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Logs/AIOrchestatorManager.log"
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] [ERROR] \(error.title): \(error.message)\n"
        
        if let data = logEntry.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logPath) {
                if let fileHandle = FileHandle(forWritingAtPath: logPath) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                FileManager.default.createFile(atPath: logPath, contents: data)
            }
        }
    }
    
    private func showAlert(_ error: AppError) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = error.title
            alert.informativeText = "\(error.message)\n\n\(error.recoveryInstructions)"
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "View Logs")
            
            let response = alert.runModal()
            if response == .alertSecondButtonReturn {
                self.openLogs()
            }
        }
    }
    
    private func openLogs() {
        let logPath = FileManager.default.homeDirectoryForCurrentUser.path + "/Library/Logs/AIOrchestatorManager.log"
        NSWorkspace.shared.open(URL(fileURLWithPath: logPath))
    }
}

// MARK: - Extension for easy error handling

extension Result {
    func handleError(context: String = "") {
        if case .failure(let error) = self {
            ErrorHandler.shared.handle(error, context: context)
        }
    }
}
