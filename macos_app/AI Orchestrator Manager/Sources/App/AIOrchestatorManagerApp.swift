//
//  AIOrchestatorManagerApp.swift
//  AI Orchestrator Manager
//
//  Main application entry point for the AI Orchestrator Manager macOS app.
//  Bundle Identifier: com.debuggerlab.ai-orchestrator-manager
//  Minimum macOS: 13.0 (Ventura)
//

import SwiftUI

@main
struct AIOrchestatorManagerApp: App {
    @StateObject private var appState = AppState.shared
    @StateObject private var serverManager = ServerManager.shared
    @StateObject private var configManager = ConfigurationManager.shared
    @StateObject private var installManager = InstallationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(serverManager)
                .environmentObject(configManager)
                .environmentObject(installManager)
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}
            CommandMenu("Server") {
                Button(serverManager.isRunning ? "Stop Server" : "Start Server") {
                    if serverManager.isRunning {
                        serverManager.stopServer()
                    } else {
                        serverManager.startServer()
                    }
                }
                .keyboardShortcut("R", modifiers: [.command, .shift])
                
                Divider()
                
                Button("View Logs") {
                    appState.selectedTab = .logs
                }
                .keyboardShortcut("L", modifiers: [.command])
            }
        }
        
        // Menu Bar Extra
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
                .environmentObject(serverManager)
        } label: {
            Image(systemName: serverManager.isRunning ? "cpu.fill" : "cpu")
        }
        .menuBarExtraStyle(.menu)
        
        Settings {
            SettingsView()
                .environmentObject(configManager)
        }
    }
}
