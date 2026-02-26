/**
 * Tree data provider for task history view
 */

import * as vscode from 'vscode';
import { HistoryManager, HistoryEntry } from '../utils/HistoryManager';
import { OrchestrationResult } from '../orchestrator';

export class HistoryItem extends vscode.TreeItem {
    constructor(
        public readonly label: string,
        public readonly collapsibleState: vscode.TreeItemCollapsibleState,
        public readonly task?: string,
        public readonly result?: OrchestrationResult,
        public readonly timestamp?: number,
        public readonly id?: string
    ) {
        super(label, collapsibleState);

        if (timestamp) {
            const date = new Date(timestamp);
            this.description = date.toLocaleString();
        }

        if (result) {
            this.iconPath = new vscode.ThemeIcon(
                result.success ? 'check' : 'warning',
                new vscode.ThemeColor(result.success ? 'testing.iconPassed' : 'testing.iconFailed')
            );
            
            this.tooltip = new vscode.MarkdownString();
            this.tooltip.appendMarkdown(`**Task:** ${task}\n\n`);
            this.tooltip.appendMarkdown(`**Status:** ${result.success ? '✅ Success' : '⚠️ Partial'}\n\n`);
            this.tooltip.appendMarkdown(`**Models Used:** ${result.subtaskResults.map(sr => sr.subtask.targetModel).join(', ')}`);
        }

        this.contextValue = 'historyItem';
    }
}

export class HistoryTreeProvider implements vscode.TreeDataProvider<HistoryItem> {
    private _onDidChangeTreeData: vscode.EventEmitter<HistoryItem | undefined | null | void> = new vscode.EventEmitter<HistoryItem | undefined | null | void>();
    readonly onDidChangeTreeData: vscode.Event<HistoryItem | undefined | null | void> = this._onDidChangeTreeData.event;

    constructor(private historyManager: HistoryManager) {}

    refresh(): void {
        this._onDidChangeTreeData.fire();
    }

    getTreeItem(element: HistoryItem): vscode.TreeItem {
        return element;
    }

    getChildren(element?: HistoryItem): Thenable<HistoryItem[]> {
        if (element) {
            // Child items (subtask details)
            if (element.result) {
                return Promise.resolve(
                    element.result.subtaskResults.map(sr => {
                        const item = new HistoryItem(
                            `${sr.subtask.taskType} (${sr.response.modelProvider})`,
                            vscode.TreeItemCollapsibleState.None
                        );
                        item.iconPath = new vscode.ThemeIcon(
                            sr.response.success ? 'pass' : 'error',
                            new vscode.ThemeColor(sr.response.success ? 'testing.iconPassed' : 'testing.iconFailed')
                        );
                        item.tooltip = sr.response.success 
                            ? sr.response.content.substring(0, 200) + '...'
                            : sr.response.error;
                        return item;
                    })
                );
            }
            return Promise.resolve([]);
        }

        // Root items (history entries)
        const history = this.historyManager.getHistory();
        
        if (history.length === 0) {
            const emptyItem = new HistoryItem(
                'No tasks yet',
                vscode.TreeItemCollapsibleState.None
            );
            emptyItem.iconPath = new vscode.ThemeIcon('info');
            return Promise.resolve([emptyItem]);
        }

        return Promise.resolve(
            history.map(entry => {
                const taskPreview = entry.task.length > 40 
                    ? entry.task.substring(0, 40) + '...' 
                    : entry.task;
                    
                return new HistoryItem(
                    taskPreview,
                    vscode.TreeItemCollapsibleState.Collapsed,
                    entry.task,
                    entry.result,
                    entry.timestamp,
                    entry.id
                );
            })
        );
    }
}
