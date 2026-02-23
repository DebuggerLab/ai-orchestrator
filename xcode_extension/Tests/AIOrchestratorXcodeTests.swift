//
//  AIOrchestratorXcodeTests.swift
//  AI Orchestrator for Xcode
//
//  Unit tests for the extension
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import XCTest
@testable import AIOrchestratorXcode

final class AIOrchestratorXcodeTests: XCTestCase {
    
    // MARK: - Configuration Tests
    
    func testDefaultConfiguration() {
        let config = ExtensionConfiguration.default
        XCTAssertEqual(config.mcpServerURL, "http://localhost:3000")
        XCTAssertEqual(config.connectionTimeout, 30.0)
        XCTAssertEqual(config.maxRetries, 3)
        XCTAssertFalse(config.autoApplyFixes)
        XCTAssertTrue(config.verifyFixesAfterBuild)
    }
    
    func testConfigurationCodable() throws {
        let config = ExtensionConfiguration.default
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ExtensionConfiguration.self, from: data)
        
        XCTAssertEqual(decoded.mcpServerURL, config.mcpServerURL)
        XCTAssertEqual(decoded.preferredModel, config.preferredModel)
    }
    
    // MARK: - Code Parser Tests
    
    func testSwiftCodeParserFunctions() {
        let parser = SwiftCodeParser()
        let code = """
        func hello() {
            print("Hello")
        }
        
        public func add(a: Int, b: Int) -> Int {
            return a + b
        }
        """
        
        let functions = parser.getFunctions(from: code)
        XCTAssertEqual(functions.count, 2)
        XCTAssertEqual(functions[0].name, "hello")
        XCTAssertEqual(functions[1].name, "add")
    }
    
    func testSwiftCodeParserTypes() {
        let parser = SwiftCodeParser()
        let code = """
        class MyClass {
            var property: String = ""
        }
        
        struct MyStruct {
            let value: Int
        }
        
        enum MyEnum {
            case one
            case two
        }
        """
        
        let types = parser.getTypes(from: code)
        XCTAssertEqual(types.count, 3)
    }
    
    func testSyntaxErrorDetection() {
        let parser = SwiftCodeParser()
        
        let validCode = """
        func test() {
            if true {
                print("ok")
            }
        }
        """
        XCTAssertFalse(parser.hasSyntaxErrors(validCode))
        
        let invalidCode = """
        func test() {
            if true {
                print("ok")
        }
        """
        XCTAssertTrue(parser.hasSyntaxErrors(invalidCode))
    }
    
    // MARK: - Diff Generator Tests
    
    func testDiffGeneratorAddition() {
        let original = "line1\nline2"
        let modified = "line1\nline2\nline3"
        
        let diff = DiffGenerator.generateDiff(original: original, modified: modified)
        
        XCTAssertEqual(diff.statistics.additions, 1)
        XCTAssertEqual(diff.statistics.deletions, 0)
    }
    
    func testDiffGeneratorDeletion() {
        let original = "line1\nline2\nline3"
        let modified = "line1\nline3"
        
        let diff = DiffGenerator.generateDiff(original: original, modified: modified)
        
        XCTAssertEqual(diff.statistics.deletions, 1)
    }
    
    func testDiffGeneratorModification() {
        let original = "line1\nline2\nline3"
        let modified = "line1\nmodified\nline3"
        
        let diff = DiffGenerator.generateDiff(original: original, modified: modified)
        
        XCTAssertTrue(diff.statistics.totalChanges > 0)
    }
    
    // MARK: - Code Formatter Tests
    
    func testCodeFormatterNormalization() {
        let code = "line1\r\nline2\rline3\n"
        let normalized = CodeFormatter.normalizeLineEndings(code)
        
        XCTAssertFalse(normalized.contains("\r"))
        XCTAssertTrue(normalized.contains("\n"))
    }
    
    func testCodeFormatterTrailingWhitespace() {
        let code = "line1   \nline2\t\nline3"
        let cleaned = CodeFormatter.removeTrailingWhitespace(code)
        
        XCTAssertFalse(cleaned.contains("   \n"))
        XCTAssertFalse(cleaned.contains("\t\n"))
    }
    
    func testLinesOfCodeCount() {
        let code = """
        // Comment
        func test() {
            print("hello")
        }
        
        // Another comment
        """
        
        let count = CodeFormatter.countLinesOfCode(code)
        XCTAssertEqual(count, 3) // func, print, closing brace
    }
    
    // MARK: - Logger Tests
    
    func testLoggerSingleton() {
        let logger1 = Logger.shared
        let logger2 = Logger.shared
        XCTAssertTrue(logger1 === logger2)
    }
}
