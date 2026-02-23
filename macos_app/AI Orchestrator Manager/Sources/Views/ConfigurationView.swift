//
//  ConfigurationView.swift
//  AI Orchestrator Manager
//
//  API Keys and model configuration screen
//

import SwiftUI

struct ConfigurationView: View {
    @EnvironmentObject var configManager: ConfigurationManager
    @EnvironmentObject var appState: AppState
    
    @State private var openAIKey = ""
    @State private var anthropicKey = ""
    @State private var geminiKey = ""
    @State private var moonshotKey = ""
    
    @State private var openAIModel = "gpt-4o-mini"
    @State private var anthropicModel = "claude-3-5-sonnet-20241022"
    @State private var geminiModel = "gemini-2.5-flash"
    @State private var moonshotModel = "moonshot-v1-8k"
    
    @State private var showOpenAIKey = false
    @State private var showAnthropicKey = false
    @State private var showGeminiKey = false
    @State private var showMoonshotKey = false
    
    @State private var isSaving = false
    @State private var testingAPI: String?
    
    let openAIModels = ["gpt-4o", "gpt-4o-mini", "gpt-4-turbo", "gpt-4", "gpt-3.5-turbo"]
    let anthropicModels = ["claude-3-5-sonnet-20241022", "claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307"]
    let geminiModels = ["gemini-2.5-flash", "gemini-2.5-pro", "gemini-1.5-pro", "gemini-1.5-flash"]
    let moonshotModels = ["moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("API Configuration")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Configure your API keys and model preferences")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // OpenAI Configuration
                APIConfigSection(
                    title: "OpenAI",
                    icon: "brain.head.profile",
                    iconColor: .green,
                    apiKey: $openAIKey,
                    showKey: $showOpenAIKey,
                    selectedModel: $openAIModel,
                    models: openAIModels,
                    status: appState.openAIStatus,
                    isTesting: testingAPI == "openai",
                    onTest: { testOpenAI() }
                )
                
                // Anthropic Configuration
                APIConfigSection(
                    title: "Anthropic",
                    icon: "sparkles",
                    iconColor: .orange,
                    apiKey: $anthropicKey,
                    showKey: $showAnthropicKey,
                    selectedModel: $anthropicModel,
                    models: anthropicModels,
                    status: appState.anthropicStatus,
                    isTesting: testingAPI == "anthropic",
                    onTest: { testAnthropic() }
                )
                
                // Google Gemini Configuration
                APIConfigSection(
                    title: "Google Gemini",
                    icon: "diamond",
                    iconColor: .blue,
                    apiKey: $geminiKey,
                    showKey: $showGeminiKey,
                    selectedModel: $geminiModel,
                    models: geminiModels,
                    status: appState.geminiStatus,
                    isTesting: testingAPI == "gemini",
                    onTest: { testGemini() }
                )
                
                // Moonshot Configuration
                APIConfigSection(
                    title: "Moonshot (Kimi)",
                    icon: "moon.stars",
                    iconColor: .purple,
                    apiKey: $moonshotKey,
                    showKey: $showMoonshotKey,
                    selectedModel: $moonshotModel,
                    models: moonshotModels,
                    status: appState.moonshotStatus,
                    isTesting: testingAPI == "moonshot",
                    onTest: { testMoonshot() }
                )
                
                Divider()
                    .padding(.horizontal, 20)
                
                // Save Button
                HStack(spacing: 16) {
                    Button("Test All Connections") {
                        testAllConnections()
                    }
                    .buttonStyle(.bordered)
                    .disabled(testingAPI != nil)
                    
                    Button(action: saveConfiguration) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text(isSaving ? "Saving..." : "Save Configuration")
                        }
                        .frame(width: 180)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isSaving)
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            loadConfiguration()
        }
    }
    
    private func loadConfiguration() {
        let config = configManager.loadAPIConfiguration()
        openAIKey = config.openAIKey
        anthropicKey = config.anthropicKey
        geminiKey = config.geminiKey
        moonshotKey = config.moonshotKey
        openAIModel = config.openAIModel
        anthropicModel = config.anthropicModel
        geminiModel = config.geminiModel
        moonshotModel = config.moonshotModel
    }
    
    private func saveConfiguration() {
        isSaving = true
        
        let config = APIConfiguration(
            openAIKey: openAIKey,
            anthropicKey: anthropicKey,
            geminiKey: geminiKey,
            moonshotKey: moonshotKey,
            openAIModel: openAIModel,
            anthropicModel: anthropicModel,
            geminiModel: geminiModel,
            moonshotModel: moonshotModel
        )
        
        configManager.saveAPIConfiguration(config) { success in
            DispatchQueue.main.async {
                isSaving = false
                if success {
                    appState.showAlert(title: "Success", message: "Configuration saved successfully.")
                    appState.updateActivity("Configuration saved")
                } else {
                    appState.showAlert(title: "Error", message: "Failed to save configuration.")
                }
            }
        }
    }
    
    private func testOpenAI() {
        testingAPI = "openai"
        configManager.testAPIConnection(provider: "openai", key: openAIKey) { status in
            DispatchQueue.main.async {
                appState.openAIStatus = status
                testingAPI = nil
            }
        }
    }
    
    private func testAnthropic() {
        testingAPI = "anthropic"
        configManager.testAPIConnection(provider: "anthropic", key: anthropicKey) { status in
            DispatchQueue.main.async {
                appState.anthropicStatus = status
                testingAPI = nil
            }
        }
    }
    
    private func testGemini() {
        testingAPI = "gemini"
        configManager.testAPIConnection(provider: "gemini", key: geminiKey) { status in
            DispatchQueue.main.async {
                appState.geminiStatus = status
                testingAPI = nil
            }
        }
    }
    
    private func testMoonshot() {
        testingAPI = "moonshot"
        configManager.testAPIConnection(provider: "moonshot", key: moonshotKey) { status in
            DispatchQueue.main.async {
                appState.moonshotStatus = status
                testingAPI = nil
            }
        }
    }
    
    private func testAllConnections() {
        testOpenAI()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { testAnthropic() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { testGemini() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { testMoonshot() }
    }
}

struct APIConfigSection: View {
    let title: String
    let icon: String
    let iconColor: Color
    @Binding var apiKey: String
    @Binding var showKey: Bool
    @Binding var selectedModel: String
    let models: [String]
    let status: APIConnectionStatus
    let isTesting: Bool
    let onTest: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title2)
                Text(title)
                    .font(.headline)
                Spacer()
                StatusBadge(status: status)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("API Key")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    if showKey {
                        TextField("Enter API key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("Enter API key", text: $apiKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Button(action: { showKey.toggle() }) {
                        Image(systemName: showKey ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: onTest) {
                        if isTesting {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Text("Test")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(apiKey.isEmpty || isTesting)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Model")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $selectedModel) {
                    ForEach(models, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct StatusBadge: View {
    let status: APIConnectionStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.2))
        .cornerRadius(8)
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
        case .error(let msg): return msg.prefix(20) + (msg.count > 20 ? "..." : "")
        }
    }
}

#Preview {
    ConfigurationView()
        .environmentObject(ConfigurationManager.shared)
        .environmentObject(AppState.shared)
        .frame(width: 800, height: 700)
}
