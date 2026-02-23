//
//  AppState.swift
//  AI Orchestrator Manager
//
//  Central application state management
//

import SwiftUI
import Combine

enum AppTab: String, Hashable, CaseIterable {
    case dashboard = "Dashboard"
    case configuration = "Configuration"
    case server = "Server"
    case logs = "Logs"
    case setup = "Setup"
}

enum ServerStatus: String {
    case running = "Running"
    case stopped = "Stopped"
    case starting = "Starting"
    case stopping = "Stopping"
    case error = "Error"
}

enum APIConnectionStatus {
    case connected
    case disconnected
    case checking
    case error(String)
}

class AppState: ObservableObject {
    static let shared = AppState()
    
    @Published var selectedTab: AppTab = .dashboard
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var isLoading = false
    @Published var loadingMessage = ""
    
    // API Connection Status
    @Published var openAIStatus: APIConnectionStatus = .disconnected
    @Published var anthropicStatus: APIConnectionStatus = .disconnected
    @Published var geminiStatus: APIConnectionStatus = .disconnected
    @Published var moonshotStatus: APIConnectionStatus = .disconnected
    
    // Last activity tracking
    @Published var lastActivity: Date?
    @Published var lastActivityDescription: String = "No recent activity"
    
    private init() {}
    
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    func setLoading(_ loading: Bool, message: String = "") {
        isLoading = loading
        loadingMessage = message
    }
    
    func updateActivity(_ description: String) {
        lastActivity = Date()
        lastActivityDescription = description
    }
}
