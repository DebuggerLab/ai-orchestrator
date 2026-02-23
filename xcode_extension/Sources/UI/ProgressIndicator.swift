//
//  ProgressIndicator.swift
//  AI Orchestrator for Xcode
//
//  Progress indicator for async operations
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation
import AppKit

/// Progress indicator for showing operation status
class ProgressIndicator {
    
    // MARK: - Types
    
    enum ProgressStyle {
        case indeterminate
        case determinate(current: Double, total: Double)
    }
    
    struct ProgressState {
        var message: String
        var style: ProgressStyle
        var isAnimating: Bool
    }
    
    // MARK: - Properties
    
    private var state: ProgressState
    private var progressWindow: NSWindow?
    private var progressView: NSProgressIndicator?
    private var messageLabel: NSTextField?
    
    // MARK: - Initialization
    
    init() {
        self.state = ProgressState(
            message: "Processing...",
            style: .indeterminate,
            isAnimating: false
        )
    }
    
    // MARK: - Public Methods
    
    /// Show progress indicator
    func show(message: String = "Processing...", style: ProgressStyle = .indeterminate) {
        DispatchQueue.main.async { [weak self] in
            self?.createProgressWindow(message: message, style: style)
            self?.state.isAnimating = true
        }
    }
    
    /// Update progress message
    func updateMessage(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.messageLabel?.stringValue = message
            self?.state.message = message
        }
    }
    
    /// Update progress value (for determinate style)
    func updateProgress(_ current: Double, total: Double) {
        DispatchQueue.main.async { [weak self] in
            guard let progressView = self?.progressView else { return }
            progressView.isIndeterminate = false
            progressView.maxValue = total
            progressView.doubleValue = current
            self?.state.style = .determinate(current: current, total: total)
        }
    }
    
    /// Hide progress indicator
    func hide() {
        DispatchQueue.main.async { [weak self] in
            self?.progressView?.stopAnimation(nil)
            self?.progressWindow?.close()
            self?.progressWindow = nil
            self?.state.isAnimating = false
        }
    }
    
    // MARK: - Private Methods
    
    private func createProgressWindow(message: String, style: ProgressStyle) {
        // Create window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 80),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.title = "AI Orchestrator"
        window.center()
        
        // Create content view
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 300, height: 80))
        
        // Create progress indicator
        let progress = NSProgressIndicator(frame: NSRect(x: 20, y: 40, width: 260, height: 20))
        switch style {
        case .indeterminate:
            progress.isIndeterminate = true
        case .determinate(let current, let total):
            progress.isIndeterminate = false
            progress.maxValue = total
            progress.doubleValue = current
        }
        progress.style = .bar
        contentView.addSubview(progress)
        
        // Create message label
        let label = NSTextField(frame: NSRect(x: 20, y: 10, width: 260, height: 20))
        label.stringValue = message
        label.isEditable = false
        label.isBordered = false
        label.backgroundColor = .clear
        label.alignment = .center
        contentView.addSubview(label)
        
        window.contentView = contentView
        
        // Store references
        self.progressWindow = window
        self.progressView = progress
        self.messageLabel = label
        
        // Start animation and show
        progress.startAnimation(nil)
        window.makeKeyAndOrderFront(nil)
    }
}

// MARK: - Toast Notification

class ToastNotification {
    
    /// Show a toast notification
    static func show(title: String, message: String, duration: TimeInterval = 3.0) {
        DispatchQueue.main.async {
            let notification = NSUserNotification()
            notification.title = title
            notification.informativeText = message
            notification.soundName = NSUserNotificationDefaultSoundName
            
            NSUserNotificationCenter.default.deliver(notification)
            
            // Remove after duration
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                NSUserNotificationCenter.default.removeDeliveredNotification(notification)
            }
        }
    }
    
    /// Show success notification
    static func showSuccess(_ message: String) {
        show(title: "✅ Success", message: message)
    }
    
    /// Show error notification
    static func showError(_ message: String) {
        show(title: "❌ Error", message: message, duration: 5.0)
    }
    
    /// Show info notification
    static func showInfo(_ message: String) {
        show(title: "ℹ️ Info", message: message)
    }
}
