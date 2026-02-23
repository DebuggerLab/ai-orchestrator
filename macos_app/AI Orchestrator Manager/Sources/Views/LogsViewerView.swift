//
//  LogsViewerView.swift
//  AI Orchestrator Manager
//
//  Real-time log viewer with filtering capabilities
//

import SwiftUI

struct LogsViewerView: View {
    @EnvironmentObject var serverManager: ServerManager
    @EnvironmentObject var appState: AppState
    
    @State private var searchText = ""
    @State private var selectedLogLevel: LogLevel? = nil
    @State private var autoScroll = true
    @State private var showingExportDialog = false
    
    var filteredLogs: [LogEntry] {
        var logs = serverManager.logs
        
        if let level = selectedLogLevel {
            logs = logs.filter { $0.level == level }
        }
        
        if !searchText.isEmpty {
            logs = logs.filter { $0.message.localizedCaseInsensitiveContains(searchText) }
        }
        
        return logs
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                HStack {
                    Text("Logs")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("\(serverManager.logs.count) entries")
                        .foregroundColor(.secondary)
                }
                
                // Toolbar
                HStack(spacing: 12) {
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search logs...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    .frame(maxWidth: 300)
                    
                    // Filter by level
                    Picker("Level", selection: $selectedLogLevel) {
                        Text("All Levels").tag(nil as LogLevel?)
                        ForEach(LogLevel.allCases, id: \.self) { level in
                            HStack {
                                Circle()
                                    .fill(logLevelColor(level))
                                    .frame(width: 8, height: 8)
                                Text(level.displayName)
                            }
                            .tag(level as LogLevel?)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)
                    
                    Spacer()
                    
                    // Auto-scroll toggle
                    Toggle("Auto-scroll", isOn: $autoScroll)
                        .toggleStyle(.switch)
                    
                    // Action buttons
                    Button(action: clearLogs) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .help("Clear logs")
                    
                    Button(action: exportLogs) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .help("Export logs")
                    
                    Button(action: refreshLogs) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .help("Refresh logs")
                }
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))
            
            Divider()
            
            // Log Content
            if filteredLogs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text(searchText.isEmpty && selectedLogLevel == nil ? "No logs yet" : "No matching logs")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    if !searchText.isEmpty || selectedLogLevel != nil {
                        Button("Clear Filters") {
                            searchText = ""
                            selectedLogLevel = nil
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List {
                        ForEach(filteredLogs) { log in
                            LogEntryRow(log: log)
                                .id(log.id)
                        }
                    }
                    .listStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: serverManager.logs.count) { _, _ in
                        if autoScroll, let lastLog = filteredLogs.last {
                            withAnimation {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
    }
    
    private func logLevelColor(_ level: LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
    
    private func clearLogs() {
        serverManager.clearLogs()
        appState.updateActivity("Logs cleared")
    }
    
    private func exportLogs() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "ai_orchestrator_logs_\(formatDateForFilename()).txt"
        panel.allowedContentTypes = [.plainText]
        
        if panel.runModal() == .OK, let url = panel.url {
            let logContent = serverManager.logs.map { log in
                "[\(log.formattedTime)] [\(log.level.rawValue)] \(log.message)"
            }.joined(separator: "\n")
            
            do {
                try logContent.write(to: url, atomically: true, encoding: .utf8)
                appState.showAlert(title: "Success", message: "Logs exported successfully.")
            } catch {
                appState.showAlert(title: "Error", message: "Failed to export logs: \(error.localizedDescription)")
            }
        }
    }
    
    private func refreshLogs() {
        serverManager.refreshLogs()
    }
    
    private func formatDateForFilename() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return formatter.string(from: Date())
    }
}

struct LogEntryRow: View {
    let log: LogEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timestamp
            Text(log.formattedTime)
                .foregroundColor(.secondary)
                .frame(width: 90, alignment: .leading)
            
            // Level badge
            Text(log.level.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(levelColor)
                .cornerRadius(4)
                .frame(width: 70)
            
            // Message
            Text(log.message)
                .textSelection(.enabled)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var levelColor: Color {
        switch log.level {
        case .debug: return .gray
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}

#Preview {
    LogsViewerView()
        .environmentObject(ServerManager.shared)
        .environmentObject(AppState.shared)
        .frame(width: 900, height: 600)
}
