//
//  DashboardView.swift
//  AI Orchestrator Manager
//
//  Main status dashboard showing overview of the system
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var serverManager: ServerManager
    @EnvironmentObject var configManager: ConfigurationManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("AI Orchestrator system overview")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(formattedDate)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
                
                // Status Cards Row
                HStack(spacing: 16) {
                    StatusCard(
                        title: "Server Status",
                        value: serverManager.status.rawValue,
                        icon: "server.rack",
                        color: serverManager.isRunning ? .green : .gray
                    )
                    
                    StatusCard(
                        title: "Active APIs",
                        value: "\(activeAPICount)/4",
                        icon: "antenna.radiowaves.left.and.right",
                        color: activeAPICount > 0 ? .blue : .orange
                    )
                    
                    StatusCard(
                        title: "Uptime",
                        value: serverManager.uptimeString,
                        icon: "clock",
                        color: .purple
                    )
                }
                .padding(.horizontal, 40)
                
                // API Status Grid
                VStack(alignment: .leading, spacing: 12) {
                    Text("API Connections")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        APIStatusRow(
                            name: "OpenAI",
                            icon: "brain.head.profile",
                            status: appState.openAIStatus,
                            color: .green
                        )
                        APIStatusRow(
                            name: "Anthropic",
                            icon: "sparkles",
                            status: appState.anthropicStatus,
                            color: .orange
                        )
                        APIStatusRow(
                            name: "Google Gemini",
                            icon: "diamond",
                            status: appState.geminiStatus,
                            color: .blue
                        )
                        APIStatusRow(
                            name: "Moonshot",
                            icon: "moon.stars",
                            status: appState.moonshotStatus,
                            color: .purple
                        )
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal, 40)
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        QuickActionButton(
                            title: serverManager.isRunning ? "Stop Server" : "Start Server",
                            icon: serverManager.isRunning ? "stop.fill" : "play.fill",
                            color: serverManager.isRunning ? .red : .green
                        ) {
                            if serverManager.isRunning {
                                serverManager.stopServer()
                            } else {
                                serverManager.startServer()
                            }
                        }
                        
                        QuickActionButton(
                            title: "Restart Server",
                            icon: "arrow.clockwise",
                            color: .orange
                        ) {
                            serverManager.restartServer()
                        }
                        .disabled(!serverManager.isRunning)
                        
                        QuickActionButton(
                            title: "View Logs",
                            icon: "doc.text.magnifyingglass",
                            color: .blue
                        ) {
                            appState.selectedTab = .logs
                        }
                        
                        QuickActionButton(
                            title: "Configure",
                            icon: "gearshape",
                            color: .gray
                        ) {
                            appState.selectedTab = .configuration
                        }
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal, 40)
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Recent Activity")
                            .font(.headline)
                        Spacer()
                        if let lastActivity = appState.lastActivity {
                            Text(formatTime(lastActivity))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if serverManager.recentLogs.isEmpty {
                        Text("No recent activity")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(serverManager.recentLogs.prefix(5)) { log in
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(logLevelColor(log.level))
                                    .frame(width: 8, height: 8)
                                
                                Text(log.formattedTime)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.secondary)
                                
                                Text(log.message)
                                    .font(.system(.caption, design: .monospaced))
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
    
    private var activeAPICount: Int {
        var count = 0
        if case .connected = appState.openAIStatus { count += 1 }
        if case .connected = appState.anthropicStatus { count += 1 }
        if case .connected = appState.geminiStatus { count += 1 }
        if case .connected = appState.moonshotStatus { count += 1 }
        return count
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func logLevelColor(_ level: LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

struct StatusCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct APIStatusRow: View {
    let name: String
    let icon: String
    let status: APIConnectionStatus
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(name)
                .fontWeight(.medium)
            
            Spacer()
            
            HStack(spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    private var statusColor: Color {
        switch status {
        case .connected: return .green
        case .disconnected: return .gray
        case .checking: return .blue
        case .error: return .red
        }
    }
    
    private var statusText: String {
        switch status {
        case .connected: return "Connected"
        case .disconnected: return "Not configured"
        case .checking: return "Checking..."
        case .error: return "Error"
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @Environment(\.isEnabled) private var isEnabled
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
        .tint(color)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState.shared)
        .environmentObject(ServerManager.shared)
        .environmentObject(ConfigurationManager.shared)
        .frame(width: 800, height: 700)
}
