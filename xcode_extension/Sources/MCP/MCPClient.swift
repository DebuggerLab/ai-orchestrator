//
//  MCPClient.swift
//  AI Orchestrator for Xcode
//
//  MCP Client for communicating with the AI Orchestrator server
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation

/// MCP Client for communicating with the AI Orchestrator server
class MCPClient {
    
    // MARK: - Types
    
    enum MCPError: LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case serverError(String)
        case timeout
        case notConnected
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid MCP server URL"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .invalidResponse:
                return "Invalid response from server"
            case .serverError(let message):
                return "Server error: \(message)"
            case .timeout:
                return "Request timed out"
            case .notConnected:
                return "Not connected to MCP server"
            }
        }
    }
    
    struct MCPRequest: Codable {
        let jsonrpc: String
        let id: String
        let method: String
        let params: [String: AnyCodable]
        
        init(method: String, params: [String: Any]) {
            self.jsonrpc = "2.0"
            self.id = UUID().uuidString
            self.method = method
            self.params = params.mapValues { AnyCodable($0) }
        }
    }
    
    struct MCPResponse: Codable {
        let jsonrpc: String
        let id: String?
        let result: AnyCodable?
        let error: MCPErrorResponse?
    }
    
    struct MCPErrorResponse: Codable {
        let code: Int
        let message: String
        let data: AnyCodable?
    }
    
    struct ToolCallParams: Codable {
        let name: String
        let arguments: [String: AnyCodable]
    }
    
    // MARK: - Properties
    
    private let serverURL: URL
    private let session: URLSession
    private let timeout: TimeInterval
    private let maxRetries: Int
    
    private var isConnected: Bool = false
    
    // MARK: - Initialization
    
    init(serverURL: String, timeout: TimeInterval = 30.0, maxRetries: Int = 3) {
        self.serverURL = URL(string: serverURL) ?? URL(string: "http://localhost:3000")!
        self.timeout = timeout
        self.maxRetries = maxRetries
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout * 2
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Connection Management
    
    func connect() async throws {
        // Test connection by sending initialize request
        let response = try await sendRequest(method: "initialize", params: [
            "protocolVersion": "2024-11-05",
            "capabilities": [
                "tools": [:]
            ],
            "clientInfo": [
                "name": "AI Orchestrator for Xcode",
                "version": "1.0.0"
            ]
        ])
        
        if response.error == nil {
            isConnected = true
            Logger.shared.log("Connected to MCP server at \(serverURL)")
        } else {
            throw MCPError.serverError(response.error?.message ?? "Unknown error")
        }
    }
    
    func disconnect() {
        isConnected = false
        Logger.shared.log("Disconnected from MCP server")
    }
    
    // MARK: - Tool Calls
    
    /// Call a tool on the MCP server
    func callTool(name: String, arguments: [String: Any]) async throws -> [String: Any] {
        let response = try await sendRequest(
            method: "tools/call",
            params: [
                "name": name,
                "arguments": arguments
            ]
        )
        
        if let error = response.error {
            throw MCPError.serverError(error.message)
        }
        
        guard let result = response.result?.value as? [String: Any] else {
            throw MCPError.invalidResponse
        }
        
        return result
    }
    
    /// List available tools on the MCP server
    func listTools() async throws -> [[String: Any]] {
        let response = try await sendRequest(method: "tools/list", params: [:])
        
        if let error = response.error {
            throw MCPError.serverError(error.message)
        }
        
        guard let result = response.result?.value as? [String: Any],
              let tools = result["tools"] as? [[String: Any]] else {
            throw MCPError.invalidResponse
        }
        
        return tools
    }
    
    // MARK: - AI Orchestrator Specific Tools
    
    /// Fix code issues using AI
    func fixCode(code: String, language: String, errorMessage: String? = nil) async throws -> AIResponse {
        let arguments: [String: Any] = [
            "code": code,
            "language": language,
            "error_message": errorMessage ?? "",
            "action": "fix"
        ]
        
        let result = try await callTool(name: "analyze_errors", arguments: arguments)
        return AIResponse(from: result)
    }
    
    /// Explain code using AI
    func explainCode(code: String, language: String) async throws -> AIResponse {
        let arguments: [String: Any] = [
            "code": code,
            "language": language,
            "task": "Explain this code in detail, including its purpose, how it works, and any important patterns or concepts."
        ]
        
        let result = try await callTool(name: "route_task", arguments: arguments)
        return AIResponse(from: result)
    }
    
    /// Generate unit tests for code
    func generateTests(code: String, language: String, testFramework: String = "XCTest") async throws -> AIResponse {
        let arguments: [String: Any] = [
            "code": code,
            "language": language,
            "task": "Generate comprehensive unit tests for this code using \(testFramework). Include edge cases and error scenarios.",
            "test_framework": testFramework
        ]
        
        let result = try await callTool(name: "route_task", arguments: arguments)
        return AIResponse(from: result)
    }
    
    /// Refactor code using AI
    func refactorCode(code: String, language: String, instructions: String? = nil) async throws -> AIResponse {
        let task = instructions ?? "Refactor this code to improve readability, performance, and maintainability. Apply best practices and design patterns."
        
        let arguments: [String: Any] = [
            "code": code,
            "language": language,
            "task": task,
            "action": "refactor"
        ]
        
        let result = try await callTool(name: "route_task", arguments: arguments)
        return AIResponse(from: result)
    }
    
    /// Generate documentation for code
    func generateDocumentation(code: String, language: String, style: String = "swift-doc") async throws -> AIResponse {
        let arguments: [String: Any] = [
            "code": code,
            "language": language,
            "task": "Generate comprehensive documentation comments for this code in \(style) format. Include parameter descriptions, return values, throws, and examples.",
            "doc_style": style
        ]
        
        let result = try await callTool(name: "route_task", arguments: arguments)
        return AIResponse(from: result)
    }
    
    /// Run project and fix build errors
    func buildAndFix(projectPath: String, buildErrors: String) async throws -> AIResponse {
        let arguments: [String: Any] = [
            "project_path": projectPath,
            "errors": buildErrors,
            "action": "fix"
        ]
        
        let result = try await callTool(name: "fix_issues", arguments: arguments)
        return AIResponse(from: result)
    }
    
    /// Verify project (run-test-fix loop)
    func verifyProject(projectPath: String) async throws -> AIResponse {
        let arguments: [String: Any] = [
            "project_path": projectPath,
            "auto_fix": true
        ]
        
        let result = try await callTool(name: "verify_project", arguments: arguments)
        return AIResponse(from: result)
    }
    
    // MARK: - Private Methods
    
    private func sendRequest(method: String, params: [String: Any]) async throws -> MCPResponse {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await performRequest(method: method, params: params)
            } catch {
                lastError = error
                Logger.shared.log("Request attempt \(attempt) failed: \(error.localizedDescription)")
                
                if attempt < maxRetries {
                    // Exponential backoff
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
                }
            }
        }
        
        throw lastError ?? MCPError.networkError(NSError(domain: "Unknown", code: -1))
    }
    
    private func performRequest(method: String, params: [String: Any]) async throws -> MCPResponse {
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let mcpRequest = MCPRequest(method: method, params: params)
        request.httpBody = try JSONEncoder().encode(mcpRequest)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MCPError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw MCPError.serverError(message)
        }
        
        let mcpResponse = try JSONDecoder().decode(MCPResponse.self, from: data)
        return mcpResponse
    }
}

// MARK: - AI Response

struct AIResponse {
    let success: Bool
    let content: String
    let fixedCode: String?
    let explanation: String?
    let suggestions: [String]
    let confidence: Double
    let metadata: [String: Any]
    
    init(from dict: [String: Any]) {
        self.success = dict["success"] as? Bool ?? true
        self.content = dict["content"] as? String ?? dict["response"] as? String ?? ""
        self.fixedCode = dict["fixed_code"] as? String ?? dict["code"] as? String
        self.explanation = dict["explanation"] as? String
        self.suggestions = dict["suggestions"] as? [String] ?? []
        self.confidence = dict["confidence"] as? Double ?? 1.0
        self.metadata = dict["metadata"] as? [String: Any] ?? [:]
    }
}

// MARK: - AnyCodable Helper

struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unable to decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "Unable to encode value")
            throw EncodingError.invalidValue(value, context)
        }
    }
}
