//
//  SettingsView.swift
//  AI Orchestrator Manager
//
//  Application settings and preferences
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var configManager: ConfigurationManager
    
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showInMenuBar") private var showInMenuBar = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("logRetentionDays") private var logRetentionDays = 7
    
    var body: some View {
        TabView {
            // General Settings
            Form {
                Section {
                    Toggle("Launch at Login", isOn: $launchAtLogin)
                    Toggle("Show in Menu Bar", isOn: $showInMenuBar)
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                }
                
                Section("Logs") {
                    Picker("Log Retention", selection: $logRetentionDays) {
                        Text("3 days").tag(3)
                        Text("7 days").tag(7)
                        Text("14 days").tag(14)
                        Text("30 days").tag(30)
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            // About
            VStack(spacing: 20) {
                Image(systemName: "cpu.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("AI Orchestrator Manager")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .foregroundColor(.secondary)
                
                Text("Multi-model AI orchestration for intelligent task routing")
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                Spacer()
                
                Link("GitHub Repository", destination: URL(string: "https://github.com/debuggerlab/ai-orchestrator")!)
                
                Text("© 2024 DebuggerLab")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(40)
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 450, height: 300)
    }
}

#Preview {
    SettingsView()
        .environmentObject(ConfigurationManager.shared)
}
