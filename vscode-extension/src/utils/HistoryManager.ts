/**
 * Task history manager for storing and retrieving past orchestrations
 */

import * as vscode from 'vscode';
import { OrchestrationResult } from '../orchestrator';

export interface HistoryEntry {
    id: string;
    timestamp: number;
    task: string;
    result: OrchestrationResult;
}

export class HistoryManager {
    private context: vscode.ExtensionContext;
    private static readonly HISTORY_KEY = 'aiOrchestrator.taskHistory';

    constructor(context: vscode.ExtensionContext) {
        this.context = context;
    }

    getHistory(): HistoryEntry[] {
        return this.context.globalState.get<HistoryEntry[]>(HistoryManager.HISTORY_KEY, []);
    }

    addTask(task: string, result: OrchestrationResult): HistoryEntry {
        const history = this.getHistory();
        const maxItems = vscode.workspace.getConfiguration('aiOrchestrator').get<number>('history.maxItems', 50);

        const entry: HistoryEntry = {
            id: this.generateId(),
            timestamp: Date.now(),
            task: task,
            result: result
        };

        history.unshift(entry);

        // Trim to max items
        while (history.length > maxItems) {
            history.pop();
        }

        this.context.globalState.update(HistoryManager.HISTORY_KEY, history);
        return entry;
    }

    getTask(id: string): HistoryEntry | undefined {
        const history = this.getHistory();
        return history.find(h => h.id === id);
    }

    removeTask(id: string): void {
        const history = this.getHistory();
        const filtered = history.filter(h => h.id !== id);
        this.context.globalState.update(HistoryManager.HISTORY_KEY, filtered);
    }

    clearHistory(): void {
        this.context.globalState.update(HistoryManager.HISTORY_KEY, []);
    }

    private generateId(): string {
        return `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    }
}
