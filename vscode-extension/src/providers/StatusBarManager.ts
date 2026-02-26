/**
 * Status bar manager for AI Orchestrator
 */

import * as vscode from 'vscode';

export class StatusBarManager {
    private statusBarItem: vscode.StatusBarItem;
    private timeoutId?: NodeJS.Timeout;

    constructor() {
        this.statusBarItem = vscode.window.createStatusBarItem(
            vscode.StatusBarAlignment.Right,
            100
        );
    }

    initialize(context: vscode.ExtensionContext): void {
        this.statusBarItem.command = 'aiOrchestrator.checkStatus';
        context.subscriptions.push(this.statusBarItem);
        this.statusBarItem.show();
    }

    setIdle(): void {
        this.clearTimeout();
        this.statusBarItem.text = '$(robot) AI Orchestrator';
        this.statusBarItem.tooltip = 'AI Orchestrator - Ready';
        this.statusBarItem.backgroundColor = undefined;
    }

    setProcessing(status?: string): void {
        this.clearTimeout();
        this.statusBarItem.text = '$(sync~spin) ' + (status || 'Processing...');
        this.statusBarItem.tooltip = 'AI Orchestrator - Processing task';
        this.statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.warningBackground');
    }

    setSuccess(): void {
        this.statusBarItem.text = '$(check) AI Orchestrator';
        this.statusBarItem.tooltip = 'AI Orchestrator - Task completed';
        this.statusBarItem.backgroundColor = undefined;
        
        // Reset after 5 seconds
        this.timeoutId = setTimeout(() => this.setIdle(), 5000);
    }

    setError(): void {
        this.statusBarItem.text = '$(warning) AI Orchestrator';
        this.statusBarItem.tooltip = 'AI Orchestrator - Task completed with errors';
        this.statusBarItem.backgroundColor = new vscode.ThemeColor('statusBarItem.errorBackground');
        
        // Reset after 10 seconds
        this.timeoutId = setTimeout(() => this.setIdle(), 10000);
    }

    private clearTimeout(): void {
        if (this.timeoutId) {
            clearTimeout(this.timeoutId);
            this.timeoutId = undefined;
        }
    }

    dispose(): void {
        this.clearTimeout();
        this.statusBarItem.dispose();
    }
}
