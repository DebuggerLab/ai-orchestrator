//
//  MenuBarView.swift
//  AI Orchestrator Manager
//
//  Menu bar dropdown menu
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var serverManager: ServerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Status Header
            HStack {
                Circle()
                    .fill(serverManager.isRunning ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(serverManager.isRunning ? "Server Running" : "Server Stopped")
                    .fontWeight(.medium)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // Server Controls
            Button(action: {
                if serverManager.isRunning {
                    serverManager.stopServer()
                } else {
                    serverManager.startServer()
                }
            }) {
                Label(
                    serverManager.isRunning ? "Stop Server" : "Start Server",
                    systemImage: serverManager.isRunning ? "stop.fill" : "play.fill"
                )
            }
            .keyboardShortcut("R", modifiers: [.command, .shift])
            
            if serverManager.isRunning {
                Button(action: { serverManager.restartServer() }) {
                    Label("Restart Server", systemImage: "arrow.clockwise")
                }
            }
            
            Divider()
            
            // Quick Links
            Button(action: { openMainWindow(.dashboard) }) {
                Label("Open Dashboard", systemImage: "gauge.with.dots.needle.bottom.50percent")
            }
            .keyboardShortcut("D", modifiers: [.command])
            
            Button(action: { openMainWindow(.logs) }) {
                Label("View Logs", systemImage: "doc.text.magnifyingglass")
            }
            .keyboardShortcut("L", modifiers: [.command])
            
            Button(action: { openMainWindow(.configuration) }) {
                Label("Configuration", systemImage: "gearshape")
            }
            .keyboardShortcut(",", modifiers: [.command])
            
            Divider()
            
            // Quit
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Label("Quit AI Orchestrator Manager", systemImage: "power")
            }
            .keyboardShortcut("Q", modifiers: [.command])
        }
        .frame(width: 250)
    }
    
    private func openMainWindow(_ tab: AppTab) {
        appState.selectedTab = tab
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AppState.shared)
        .environmentObject(ServerManager.shared)
}
