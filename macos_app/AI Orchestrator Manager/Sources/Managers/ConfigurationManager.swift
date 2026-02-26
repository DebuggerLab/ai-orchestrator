//
//  ConfigurationManager.swift
//  AI Orchestrator Manager
//
//  Manages API keys and configuration
//

import Foundation
import Security

class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()
    
    private let keychainService = "com.debuggerlab.ai-orchestrator-manager"
    
    private init() {}
    
    // MARK: - API Configuration
    
    func loadAPIConfiguration() -> APIConfiguration {
        return APIConfiguration(
            openAIKey: getKeychainItem("openai_api_key") ?? "",
            anthropicKey: getKeychainItem("anthropic_api_key") ?? "",
            geminiKey: getKeychainItem("gemini_api_key") ?? "",
            moonshotKey: getKeychainItem("moonshot_api_key") ?? "",
            openAIModel: UserDefaults.standard.string(forKey: "openai_model") ?? "gpt-4o-mini",
            anthropicModel: UserDefaults.standard.string(forKey: "anthropic_model") ?? "claude-3-5-sonnet-20240620",
            geminiModel: UserDefaults.standard.string(forKey: "gemini_model") ?? "gemini-2.5-flash",
            moonshotModel: UserDefaults.standard.string(forKey: "moonshot_model") ?? "moonshot-v1-8k"
        )
    }
    
    func saveAPIConfiguration(_ config: APIConfiguration, completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            var success = true
            
            // Save API keys to Keychain
            if !config.openAIKey.isEmpty {
                success = success && self.setKeychainItem("openai_api_key", value: config.openAIKey)
            }
            if !config.anthropicKey.isEmpty {
                success = success && self.setKeychainItem("anthropic_api_key", value: config.anthropicKey)
            }
            if !config.geminiKey.isEmpty {
                success = success && self.setKeychainItem("gemini_api_key", value: config.geminiKey)
            }
            if !config.moonshotKey.isEmpty {
                success = success && self.setKeychainItem("moonshot_api_key", value: config.moonshotKey)
            }
            
            // Save model selections to UserDefaults
            UserDefaults.standard.set(config.openAIModel, forKey: "openai_model")
            UserDefaults.standard.set(config.anthropicModel, forKey: "anthropic_model")
            UserDefaults.standard.set(config.geminiModel, forKey: "gemini_model")
            UserDefaults.standard.set(config.moonshotModel, forKey: "moonshot_model")
            
            // Update .env file
            self.updateEnvFile(config)
            
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func testAPIConnection(provider: String, key: String, completion: @escaping (APIConnectionStatus) -> Void) {
        guard !key.isEmpty else {
            completion(.disconnected)
            return
        }
        
        completion(.checking)
        
        DispatchQueue.global(qos: .userInitiated).async {
            let status = self.performAPITest(provider: provider, key: key)
            DispatchQueue.main.async {
                completion(status)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func performAPITest(provider: String, key: String) -> APIConnectionStatus {
        switch provider {
        case "openai":
            return testOpenAI(key: key)
        case "anthropic":
            return testAnthropic(key: key)
        case "gemini":
            return testGemini(key: key)
        case "moonshot":
            return testMoonshot(key: key)
        default:
            return .error("Unknown provider")
        }
    }
    
    private func testOpenAI(key: String) -> APIConnectionStatus {
        let url = URL(string: "https://api.openai.com/v1/models")!
        var request = URLRequest(url: url)
        request.addValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        
        let semaphore = DispatchSemaphore(value: 0)
        var result: APIConnectionStatus = .error("Request failed")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                result = .error(error.localizedDescription)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    result = .connected
                } else if httpResponse.statusCode == 401 {
                    result = .error("Invalid API key")
                } else {
                    result = .error("HTTP \(httpResponse.statusCode)")
                }
            }
            semaphore.signal()
        }.resume()
        
        _ = semaphore.wait(timeout: .now() + 15)
        return result
    }
    
    private func testAnthropic(key: String) -> APIConnectionStatus {
        // Anthropic doesn't have a simple models endpoint, so we'll validate the key format
        if key.hasPrefix("sk-ant-") && key.count > 20 {
            return .connected
        }
        return .error("Invalid key format")
    }
    
    private func testGemini(key: String) -> APIConnectionStatus {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(key)")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        let semaphore = DispatchSemaphore(value: 0)
        var result: APIConnectionStatus = .error("Request failed")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                result = .error(error.localizedDescription)
            } else if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    result = .connected
                } else if httpResponse.statusCode == 400 || httpResponse.statusCode == 403 {
                    result = .error("Invalid API key")
                } else {
                    result = .error("HTTP \(httpResponse.statusCode)")
                }
            }
            semaphore.signal()
        }.resume()
        
        _ = semaphore.wait(timeout: .now() + 15)
        return result
    }
    
    private func testMoonshot(key: String) -> APIConnectionStatus {
        // Basic validation for Moonshot API key
        if key.count > 10 {
            return .connected
        }
        return .error("Invalid key format")
    }
    
    private func updateEnvFile(_ config: APIConfiguration) {
        let installPath = UserDefaults.standard.string(forKey: "installationPath") ?? ""
        let envPath = "\(installPath)/.env"
        
        let envContent = """
        # API Keys
        OPENAI_API_KEY=\(config.openAIKey)
        ANTHROPIC_API_KEY=\(config.anthropicKey)
        GEMINI_API_KEY=\(config.geminiKey)
        MOONSHOT_API_KEY=\(config.moonshotKey)
        
        # Model Configuration
        OPENAI_MODEL=\(config.openAIModel)
        ANTHROPIC_MODEL=\(config.anthropicModel)
        GEMINI_MODEL=\(config.geminiModel)
        MOONSHOT_MODEL=\(config.moonshotModel)
        """
        
        try? envContent.write(toFile: envPath, atomically: true, encoding: .utf8)
    }
    
    // MARK: - Keychain Methods
    
    private func setKeychainItem(_ key: String, value: String) -> Bool {
        let data = value.data(using: .utf8)!
        
        // Delete existing item
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    private func getKeychainItem(_ key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    private func deleteKeychainItem(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }
}
