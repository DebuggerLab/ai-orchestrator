//
//  DiffViewerWindow.swift
//  AI Orchestrator for Xcode
//
//  Diff viewer window for reviewing code changes
//  Copyright © 2026 DebuggerLab. All rights reserved.
//

import Foundation
import AppKit

/// Diff viewer window for reviewing code changes before applying
class DiffViewerWindow: NSWindowController {
    
    // MARK: - Types
    
    enum UserAction {
        case apply
        case cancel
        case applySelected
    }
    
    typealias CompletionHandler = (UserAction, [DiffChange]) -> Void
    
    // MARK: - Properties
    
    private var diffResult: DiffResult?
    private var completionHandler: CompletionHandler?
    
    private var originalTextView: NSTextView?
    private var modifiedTextView: NSTextView?
    private var selectedChanges: Set<Int> = []
    
    // MARK: - Initialization
    
    convenience init(diffResult: DiffResult, completion: @escaping CompletionHandler) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        self.init(window: window)
        self.diffResult = diffResult
        self.completionHandler = completion
        
        setupWindow()
    }
    
    // MARK: - Setup
    
    private func setupWindow() {
        guard let window = self.window else { return }
        
        window.title = "Review Changes - AI Orchestrator"
        window.center()
        
        // Create main split view
        let splitView = NSSplitView(frame: window.contentView!.bounds)
        splitView.isVertical = true
        splitView.autoresizingMask = [.width, .height]
        
        // Original code view
        let originalScroll = createScrollView(title: "Original")
        originalTextView = originalScroll.documentView as? NSTextView
        splitView.addSubview(originalScroll)
        
        // Modified code view
        let modifiedScroll = createScrollView(title: "Modified")
        modifiedTextView = modifiedScroll.documentView as? NSTextView
        splitView.addSubview(modifiedScroll)
        
        // Button bar
        let buttonBar = createButtonBar()
        
        // Layout
        let contentView = NSView(frame: window.contentView!.bounds)
        contentView.autoresizingMask = [.width, .height]
        
        splitView.frame = NSRect(
            x: 0, y: 50,
            width: contentView.bounds.width,
            height: contentView.bounds.height - 50
        )
        buttonBar.frame = NSRect(
            x: 0, y: 0,
            width: contentView.bounds.width,
            height: 50
        )
        
        contentView.addSubview(splitView)
        contentView.addSubview(buttonBar)
        
        window.contentView = contentView
        
        // Populate content
        populateDiff()
    }
    
    private func createScrollView(title: String) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autoresizingMask = [.width, .height]
        
        let textView = NSTextView()
        textView.isEditable = false
        textView.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.autoresizingMask = [.width]
        
        scrollView.documentView = textView
        
        return scrollView
    }
    
    private func createButtonBar() -> NSView {
        let bar = NSView()
        bar.autoresizingMask = [.width]
        
        // Cancel button
        let cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancelAction))
        cancelButton.frame = NSRect(x: 20, y: 10, width: 100, height: 30)
        bar.addSubview(cancelButton)
        
        // Apply button
        let applyButton = NSButton(title: "Apply All Changes", target: self, action: #selector(applyAction))
        applyButton.frame = NSRect(x: 680, y: 10, width: 100, height: 30)
        applyButton.bezelStyle = .rounded
        applyButton.keyEquivalent = "\r"
        bar.addSubview(applyButton)
        
        // Statistics label
        if let diff = diffResult {
            let statsLabel = NSTextField(labelWithString: "\(diff.statistics.additions) additions, \(diff.statistics.deletions) deletions, \(diff.statistics.modifications) modifications")
            statsLabel.frame = NSRect(x: 200, y: 15, width: 400, height: 20)
            statsLabel.alignment = .center
            bar.addSubview(statsLabel)
        }
        
        return bar
    }
    
    // MARK: - Content
    
    private func populateDiff() {
        guard let diff = diffResult else { return }
        
        // Format original code with highlighting
        let originalAttributed = formatCodeWithHighlighting(
            diff.original,
            changes: diff.changes,
            isOriginal: true
        )
        originalTextView?.textStorage?.setAttributedString(originalAttributed)
        
        // Format modified code with highlighting
        let modifiedAttributed = formatCodeWithHighlighting(
            diff.modified,
            changes: diff.changes,
            isOriginal: false
        )
        modifiedTextView?.textStorage?.setAttributedString(modifiedAttributed)
    }
    
    private func formatCodeWithHighlighting(_ code: String, changes: [DiffChange], isOriginal: Bool) -> NSAttributedString {
        let attributed = NSMutableAttributedString(string: code)
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        
        attributed.addAttribute(.font, value: font, range: NSRange(location: 0, length: attributed.length))
        
        // Apply highlighting based on changes
        let lines = code.components(separatedBy: "\n")
        var currentPosition = 0
        
        for (lineIndex, line) in lines.enumerated() {
            let lineRange = NSRange(location: currentPosition, length: line.count)
            
            // Find if this line has a change
            for change in changes {
                let changeLine = isOriginal ? change.originalLine : change.modifiedLine
                if changeLine == lineIndex + 1 {
                    switch change.type {
                    case .addition:
                        if !isOriginal {
                            attributed.addAttribute(.backgroundColor, value: NSColor.green.withAlphaComponent(0.2), range: lineRange)
                        }
                    case .deletion:
                        if isOriginal {
                            attributed.addAttribute(.backgroundColor, value: NSColor.red.withAlphaComponent(0.2), range: lineRange)
                        }
                    case .modification:
                        let color = isOriginal ? NSColor.red.withAlphaComponent(0.2) : NSColor.green.withAlphaComponent(0.2)
                        attributed.addAttribute(.backgroundColor, value: color, range: lineRange)
                    case .unchanged:
                        break
                    }
                }
            }
            
            currentPosition += line.count + 1 // +1 for newline
        }
        
        return attributed
    }
    
    // MARK: - Actions
    
    @objc private func applyAction() {
        completionHandler?(.apply, diffResult?.changes ?? [])
        close()
    }
    
    @objc private func cancelAction() {
        completionHandler?(.cancel, [])
        close()
    }
}
