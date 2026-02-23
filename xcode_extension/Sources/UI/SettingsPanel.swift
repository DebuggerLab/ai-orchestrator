//
//  SettingsPanel.swift
//  AI Orchestrator for Xcode
//
//  Settings panel for configuring the extension
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation
import AppKit

/// Settings panel for extension configuration
class SettingsPanel: NSWindowController {
    
    // MARK: - Properties
    
    private var configuration: ExtensionConfiguration
    private var completionHandler: ((ExtensionConfiguration?) -> Void)?
    
    // Form fields
    private var serverURLField: NSTextField?
    private var autoApplyCheckbox: NSButton?
    private var verifyFixesCheckbox: NSButton?
    private var showDiffCheckbox: NSButton?
    private var preferredModelPopup: NSPopUpButton?
    private var testFrameworkPopup: NSPopUpButton?
    private var docStylePopup: NSPopUpButton?
    
    // MARK: - Initialization
    
    convenience init(configuration: ExtensionConfiguration, completion: @escaping (ExtensionConfiguration?) -> Void) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 450),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        self.init(window: window)
        self.configuration = configuration
        self.completionHandler = completion
        
        setupWindow()
        loadConfiguration()
    }
    
    // MARK: - Setup
    
    private func setupWindow() {
        guard let window = self.window else { return }
        
        window.title = "AI Orchestrator Settings"
        window.center()
        
        let contentView = NSView(frame: window.contentView!.bounds)
        
        var y = 400
        let labelWidth = 150
        let fieldWidth = 300
        let leftMargin = 20
        let rowHeight = 30
        
        // Server Settings Section
        addSectionHeader("Server Settings", y: y, to: contentView)
        y -= rowHeight + 10
        
        // MCP Server URL
        addLabel("MCP Server URL:", x: leftMargin, y: y, width: labelWidth, to: contentView)
        serverURLField = addTextField(x: leftMargin + labelWidth, y: y, width: fieldWidth, to: contentView)
        y -= rowHeight
        
        // AI Model Settings Section
        y -= 20
        addSectionHeader("AI Model Settings", y: y, to: contentView)
        y -= rowHeight + 10
        
        // Preferred Model
        addLabel("Preferred Model:", x: leftMargin, y: y, width: labelWidth, to: contentView)
        preferredModelPopup = addPopUpButton(
            items: ["claude-3-5-sonnet", "gpt-4o", "gemini-2.5-flash", "moonshot-v1"],
            x: leftMargin + labelWidth, y: y, width: fieldWidth, to: contentView
        )
        y -= rowHeight
        
        // Behavior Settings Section
        y -= 20
        addSectionHeader("Behavior Settings", y: y, to: contentView)
        y -= rowHeight + 10
        
        // Auto Apply Fixes
        autoApplyCheckbox = addCheckbox(
            "Automatically apply fixes without confirmation",
            x: leftMargin, y: y, to: contentView
        )
        y -= rowHeight
        
        // Verify Fixes After Build
        verifyFixesCheckbox = addCheckbox(
            "Verify fixes by rebuilding after applying",
            x: leftMargin, y: y, to: contentView
        )
        y -= rowHeight
        
        // Show Diff
        showDiffCheckbox = addCheckbox(
            "Show diff before applying changes",
            x: leftMargin, y: y, to: contentView
        )
        y -= rowHeight
        
        // Code Generation Settings Section
        y -= 20
        addSectionHeader("Code Generation", y: y, to: contentView)
        y -= rowHeight + 10
        
        // Test Framework
        addLabel("Test Framework:", x: leftMargin, y: y, width: labelWidth, to: contentView)
        testFrameworkPopup = addPopUpButton(
            items: ["XCTest", "Quick/Nimble", "SwiftTesting"],
            x: leftMargin + labelWidth, y: y, width: fieldWidth, to: contentView
        )
        y -= rowHeight
        
        // Documentation Style
        addLabel("Doc Style:", x: leftMargin, y: y, width: labelWidth, to: contentView)
        docStylePopup = addPopUpButton(
            items: ["swift-doc", "headerdoc", "doxygen"],
            x: leftMargin + labelWidth, y: y, width: fieldWidth, to: contentView
        )
        y -= rowHeight
        
        // Buttons
        y -= 30
        
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelAction))
        cancelButton.frame = NSRect(x: leftMargin, y: y, width: 100, height: 30)
        contentView.addSubview(cancelButton)
        
        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveAction))
        saveButton.frame = NSRect(x: 380, y: y, width: 100, height: 30)
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        contentView.addSubview(saveButton)
        
        window.contentView = contentView
    }
    
    // MARK: - Helper Methods
    
    private func addSectionHeader(_ title: String, y: Int, to view: NSView) {
        let label = NSTextField(labelWithString: title)
        label.frame = NSRect(x: 20, y: y, width: 460, height: 20)
        label.font = NSFont.boldSystemFont(ofSize: 14)
        view.addSubview(label)
        
        let separator = NSBox(frame: NSRect(x: 20, y: y - 5, width: 460, height: 1))
        separator.boxType = .separator
        view.addSubview(separator)
    }
    
    private func addLabel(_ title: String, x: Int, y: Int, width: Int, to view: NSView) {
        let label = NSTextField(labelWithString: title)
        label.frame = NSRect(x: x, y: y, width: width, height: 22)
        label.alignment = .right
        view.addSubview(label)
    }
    
    private func addTextField(x: Int, y: Int, width: Int, to view: NSView) -> NSTextField {
        let field = NSTextField(frame: NSRect(x: x, y: y, width: width, height: 22))
        view.addSubview(field)
        return field
    }
    
    private func addCheckbox(_ title: String, x: Int, y: Int, to view: NSView) -> NSButton {
        let checkbox = NSButton(checkboxWithTitle: title, target: nil, action: nil)
        checkbox.frame = NSRect(x: x, y: y, width: 460, height: 22)
        view.addSubview(checkbox)
        return checkbox
    }
    
    private func addPopUpButton(items: [String], x: Int, y: Int, width: Int, to view: NSView) -> NSPopUpButton {
        let popup = NSPopUpButton(frame: NSRect(x: x, y: y, width: width, height: 22))
        popup.addItems(withTitles: items)
        view.addSubview(popup)
        return popup
    }
    
    // MARK: - Configuration
    
    private func loadConfiguration() {
        serverURLField?.stringValue = configuration.mcpServerURL
        autoApplyCheckbox?.state = configuration.autoApplyFixes ? .on : .off
        verifyFixesCheckbox?.state = configuration.verifyFixesAfterBuild ? .on : .off
        showDiffCheckbox?.state = configuration.showDiffBeforeApply ? .on : .off
        preferredModelPopup?.selectItem(withTitle: configuration.preferredModel)
        testFrameworkPopup?.selectItem(withTitle: configuration.testFramework)
        docStylePopup?.selectItem(withTitle: configuration.documentationStyle)
    }
    
    private func saveConfiguration() -> ExtensionConfiguration {
        var config = configuration
        config.mcpServerURL = serverURLField?.stringValue ?? configuration.mcpServerURL
        config.autoApplyFixes = autoApplyCheckbox?.state == .on
        config.verifyFixesAfterBuild = verifyFixesCheckbox?.state == .on
        config.showDiffBeforeApply = showDiffCheckbox?.state == .on
        config.preferredModel = preferredModelPopup?.selectedItem?.title ?? configuration.preferredModel
        config.testFramework = testFrameworkPopup?.selectedItem?.title ?? configuration.testFramework
        config.documentationStyle = docStylePopup?.selectedItem?.title ?? configuration.documentationStyle
        return config
    }
    
    // MARK: - Actions
    
    @objc private func saveAction() {
        let config = saveConfiguration()
        config.save()
        completionHandler?(config)
        close()
    }
    
    @objc private func cancelAction() {
        completionHandler?(nil)
        close()
    }
}
