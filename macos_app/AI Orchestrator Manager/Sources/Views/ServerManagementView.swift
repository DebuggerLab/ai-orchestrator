//
//  ServerManagementView.swift
//  AI Orchestrator Manager
//
//  Server start/stop and configuration management
//

import SwiftUI

struct ServerManagementView: View {
    @EnvironmentObject var serverManager: ServerManager
    @EnvironmentObject var appState: AppState
    
    @State private var port: String = "3000"
    @State private var autoStartOnLogin = false
    @State private var showingLogs = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Server Management")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Control and configure the MCP server")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // Server Status Card
                ServerStatusCard()
                
                // Server Controls
                VStack(alignment: .leading, spacing: 16) {
                    Text("Server Controls")
                        .font(.headline)
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            if serverManager.isRunning {
                                serverManager.stopServer()
                            } else {
                                serverManager.startServer()
                            }
                        }) {
                            HStack {
                                if serverManager.status == .starting || serverManager.status == .stopping {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: serverManager.isRunning ? "stop.fill" : "play.fill")
                                }
                                Text(serverButtonTitle)
                            }
                            .frame(width: 150)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(serverManager.isRunning ? .red : .green)
                        .disabled(serverManager.status == .starting || serverManager.status == .stopping)
                        
                        Button(action: {
                            serverManager.restartServer()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Restart")
                            }
                            .frame(width: 100)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!serverManager.isRunning || serverManager.status == .starting || serverManager.status == .stopping)
                        
                        Spacer()
                        
                        Button(action: {
                            appState.selectedTab = .logs
                        }) {
                            HStack {
                                Image(systemName: "doc.text.magnifyingglass")
                                Text("View Logs")
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal, 40)
                
                // Server Configuration
                VStack(alignment: .leading, spacing: 16) {
                    Text("Configuration")
                        .font(.headline)
                    
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                        GridRow {
                            Text("Port:")
                                .foregroundColor(.secondary)
                            TextField("Port", text: $port)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                            Text("Default: 3000")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        GridRow {
                            Text("Auto-start:")
                                .foregroundColor(.secondary)
                            Toggle("", isOn: $autoStartOnLogin)
                                .labelsHidden()
                            Text("Start server when you log in")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Spacer()
                        Button("Apply Changes") {
                            applyConfiguration()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(serverManager.isRunning)
                    }
                    
                    if serverManager.isRunning {
                        Text("⚠️ Stop the server to change configuration")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
                .padding(.horizontal, 40)
                
                // Server Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Server Information")
                        .font(.headline)
                    
                    Grid(alignment: .leading, horizontalSpacing: 40, verticalSpacing: 8) {
                        GridRow {
                            Text("Process ID:")
                                .foregroundColor(.secondary)
                            Text(serverManager.processId.map { String($0) } ?? "N/A")
                                .fontWeight(.medium)
                        }
                        
                        GridRow {
                            Text("Uptime:")
                                .foregroundColor(.secondary)
                            Text(serverManager.uptimeString)
                                .fontWeight(.medium)
                        }
                        
                        GridRow {
                            Text("Memory Usage:")
                                .foregroundColor(.secondary)
                            Text(serverManager.memoryUsage)
                                .fontWeight(.medium)
                        }
                        
                        GridRow {
                            Text("Last Started:")
                                .foregroundColor(.secondary)
                            Text(serverManager.lastStarted.map { formatDate($0) } ?? "Never")
                                .fontWeight(.medium)
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
        .onAppear {
            loadConfiguration()
        }
    }
    
    private var serverButtonTitle: String {
        switch serverManager.status {
        case .starting: return "Starting..."
        case .stopping: return "Stopping..."
        case .running: return "Stop Server"
        default: return "Start Server"
        }
    }
    
    private func loadConfiguration() {
        let config = serverManager.loadConfiguration()
        port = String(config.port)
        autoStartOnLogin = config.autoStartOnLogin
    }
    
    private func applyConfiguration() {
        guard let portInt = Int(port), portInt > 0, portInt < 65536 else {
            appState.showAlert(title: "Invalid Port", message: "Please enter a valid port number (1-65535).")
            return
        }
        
        let config = ServerConfiguration(
            port: portInt,
            autoStartOnLogin: autoStartOnLogin,
            logLevel: .info,
            maxLogSizeMB: 50
        )
        
        serverManager.saveConfiguration(config)
        appState.showAlert(title: "Success", message: "Configuration saved.")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ServerStatusCard: View {
    @EnvironmentObject var serverManager: ServerManager
    
    var body: some View {
        HStack(spacing: 20) {
            // Status Icon
            ZStack {
                Circle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: statusIcon)
                    .font(.system(size: 36))
                    .foregroundColor(statusColor)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("MCP Server")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(serverManager.status.rawValue)
                        .font(.headline)
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .cornerRadius(8)
                }
                
                if serverManager.isRunning {
                    Text("Listening on port \(serverManager.port)")
                        .foregroundColor(.secondary)
                } else {
                    Text("Server is not running")
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(20)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .padding(.horizontal, 40)
    }
    
    private var statusColor: Color {
        switch serverManager.status {
        case .running: return .green
        case .stopped: return .gray
        case .starting, .stopping: return .orange
        case .error: return .red
        }
    }
    
    private var statusIcon: String {
        switch serverManager.status {
        case .running: return "checkmark.circle.fill"
        case .stopped: return "stop.circle.fill"
        case .starting, .stopping: return "hourglass.circle.fill"
        case .error: return "exclamationmark.triangle.fill"
        }
    }
}

#Preview {
    ServerManagementView()
        .environmentObject(ServerManager.shared)
        .environmentObject(AppState.shared)
        .frame(width: 800, height: 700)
}
