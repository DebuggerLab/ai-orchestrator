//
//  WelcomeView.swift
//  AI Orchestrator Manager
//
//  Welcome and setup screen for first-time installation
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var installManager: InstallationManager
    @EnvironmentObject var appState: AppState
    
    @State private var installationPath = FileManager.default.homeDirectoryForCurrentUser.path + "/ai_orchestrator"
    @State private var showingFolderPicker = false
    @State private var requirements: [SystemRequirement] = SystemRequirement.requirements
    @State private var isCheckingRequirements = false
    @State private var allRequirementsMet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Text("AI Orchestrator Manager")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Multi-model AI orchestration for intelligent task routing")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                Divider()
                    .padding(.horizontal, 40)
                
                // System Requirements
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("System Requirements")
                            .font(.headline)
                        Spacer()
                        Button("Check All") {
                            checkRequirements()
                        }
                        .buttonStyle(.bordered)
                        .disabled(isCheckingRequirements)
                    }
                    
                    VStack(spacing: 12) {
                        ForEach(requirements) { req in
                            RequirementRow(requirement: req)
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }
                .padding(.horizontal, 40)
                
                // Installation Location
                VStack(alignment: .leading, spacing: 12) {
                    Text("Installation Location")
                        .font(.headline)
                    
                    HStack {
                        TextField("Installation path", text: $installationPath)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Browse...") {
                            selectFolder()
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text("The AI Orchestrator will be installed at this location.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 40)
                
                // Installation Progress
                if installManager.isInstalling {
                    InstallationProgressView()
                        .padding(.horizontal, 40)
                }
                
                // Install Button
                VStack(spacing: 12) {
                    Button(action: {
                        startInstallation()
                    }) {
                        HStack {
                            if installManager.isInstalling {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(.circular)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                            }
                            Text(installManager.isInstalling ? "Installing..." : "Install AI Orchestrator")
                        }
                        .frame(maxWidth: 300)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!allRequirementsMet || installManager.isInstalling)
                    
                    if !allRequirementsMet && !isCheckingRequirements {
                        Text("Please ensure all system requirements are met before installation.")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            checkRequirements()
        }
    }
    
    private func checkRequirements() {
        isCheckingRequirements = true
        installManager.checkSystemRequirements { results in
            DispatchQueue.main.async {
                self.requirements = results
                self.allRequirementsMet = results.allSatisfy { $0.isMet }
                self.isCheckingRequirements = false
            }
        }
    }
    
    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Select"
        panel.message = "Choose installation location for AI Orchestrator"
        
        if panel.runModal() == .OK, let url = panel.url {
            installationPath = url.path + "/ai_orchestrator"
        }
    }
    
    private func startInstallation() {
        installManager.installOrchestrator(at: installationPath)
    }
}

struct RequirementRow: View {
    let requirement: SystemRequirement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: requirement.isMet ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(requirement.isMet ? .green : .red)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(requirement.name)
                    .fontWeight(.medium)
                Text(requirement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(requirement.statusMessage)
                .font(.caption)
                .foregroundColor(requirement.isMet ? .green : .orange)
        }
    }
}

struct InstallationProgressView: View {
    @EnvironmentObject var installManager: InstallationManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Installation Progress")
                .font(.headline)
            
            VStack(spacing: 8) {
                ForEach(InstallationStep.allCases, id: \.self) { step in
                    HStack(spacing: 12) {
                        Image(systemName: stepIcon(for: step))
                            .foregroundColor(stepColor(for: step))
                            .frame(width: 20)
                        
                        Text(step.rawValue)
                            .foregroundColor(stepColor(for: step))
                        
                        Spacer()
                        
                        if step == installManager.currentStep && installManager.isInstalling {
                            ProgressView()
                                .scaleEffect(0.6)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            ProgressView(value: installManager.installationProgress)
                .progressViewStyle(.linear)
            
            if !installManager.installationLog.isEmpty {
                Text(installManager.installationLog)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func stepIcon(for step: InstallationStep) -> String {
        let stepIndex = InstallationStep.allCases.firstIndex(of: step) ?? 0
        let currentIndex = InstallationStep.allCases.firstIndex(of: installManager.currentStep) ?? 0
        
        if stepIndex < currentIndex {
            return "checkmark.circle.fill"
        } else if stepIndex == currentIndex {
            return step.icon
        } else {
            return "circle"
        }
    }
    
    private func stepColor(for step: InstallationStep) -> Color {
        let stepIndex = InstallationStep.allCases.firstIndex(of: step) ?? 0
        let currentIndex = InstallationStep.allCases.firstIndex(of: installManager.currentStep) ?? 0
        
        if stepIndex < currentIndex {
            return .green
        } else if stepIndex == currentIndex {
            return .blue
        } else {
            return .secondary
        }
    }
}

#Preview {
    WelcomeView()
        .environmentObject(InstallationManager.shared)
        .environmentObject(AppState.shared)
        .frame(width: 800, height: 700)
}
