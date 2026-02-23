//
//  ContentView.swift
//  AI Orchestrator Manager
//
//  Main content view with sidebar navigation
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var installManager: InstallationManager
    
    var body: some View {
        Group {
            if !installManager.isInstalled {
                WelcomeView()
            } else {
                MainNavigationView()
            }
        }
        .onAppear {
            installManager.checkInstallation()
        }
    }
}

struct MainNavigationView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
                .frame(minWidth: 200)
        } detail: {
            switch appState.selectedTab {
            case .dashboard:
                DashboardView()
            case .configuration:
                ConfigurationView()
            case .server:
                ServerManagementView()
            case .logs:
                LogsViewerView()
            case .setup:
                WelcomeView()
            }
        }
        .navigationTitle("")
    }
}

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var serverManager: ServerManager
    
    var body: some View {
        List(selection: $appState.selectedTab) {
            Section("Overview") {
                Label("Dashboard", systemImage: "gauge.with.dots.needle.bottom.50percent")
                    .tag(AppTab.dashboard)
            }
            
            Section("Management") {
                Label("Configuration", systemImage: "gearshape.2")
                    .tag(AppTab.configuration)
                
                HStack {
                    Label("Server", systemImage: "server.rack")
                    Spacer()
                    Circle()
                        .fill(serverManager.isRunning ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                }
                .tag(AppTab.server)
            }
            
            Section("Tools") {
                Label("Logs", systemImage: "doc.text.magnifyingglass")
                    .tag(AppTab.logs)
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 250)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
        .environmentObject(ServerManager.shared)
        .environmentObject(ConfigurationManager.shared)
        .environmentObject(InstallationManager.shared)
}
