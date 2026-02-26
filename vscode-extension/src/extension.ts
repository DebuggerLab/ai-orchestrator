/**
 * AI Orchestrator VS Code Extension
 * Main extension entry point
 */

import * as vscode from 'vscode';
import { ChatViewProvider } from './providers/ChatViewProvider';
import { HistoryTreeProvider, HistoryItem } from './providers/HistoryTreeProvider';
import { StatusBarManager } from './providers/StatusBarManager';
import { Orchestrator } from './orchestrator';
import { ConfigManager } from './utils/ConfigManager';
import { HistoryManager } from './utils/HistoryManager';

let orchestrator: Orchestrator;
let statusBarManager: StatusBarManager;
let historyTreeProvider: HistoryTreeProvider;
let chatViewProvider: ChatViewProvider;
let historyManager: HistoryManager;

export async function activate(context: vscode.ExtensionContext) {
    console.log('AI Orchestrator extension is now active!');

    // Initialize managers
    const configManager = new ConfigManager(context);
    historyManager = new HistoryManager(context);
    orchestrator = new Orchestrator(configManager);
    statusBarManager = new StatusBarManager();
    historyTreeProvider = new HistoryTreeProvider(historyManager);
    chatViewProvider = new ChatViewProvider(context.extensionUri, orchestrator, historyManager, statusBarManager);

    // Register providers
    context.subscriptions.push(
        vscode.window.registerWebviewViewProvider('aiOrchestrator.chatView', chatViewProvider)
    );

    context.subscriptions.push(
        vscode.window.registerTreeDataProvider('aiOrchestrator.historyView', historyTreeProvider)
    );

    // Register commands
    context.subscriptions.push(
        vscode.commands.registerCommand('aiOrchestrator.runTask', async () => {
            const task = await vscode.window.showInputBox({
                prompt: 'Enter your task for AI Orchestrator',
                placeHolder: 'e.g., Design a REST API and implement authentication',
                ignoreFocusOut: true
            });

            if (task) {
                await executeTask(task, context);
            }
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('aiOrchestrator.configure', async () => {
            const configManager = new ConfigManager(context);
            await configManager.showConfigurationUI();
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('aiOrchestrator.checkStatus', async () => {
            await showStatus(context);
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('aiOrchestrator.sendToOrchestrator', async () => {
            const editor = vscode.window.activeTextEditor;
            if (editor && editor.selection) {
                const selectedText = editor.document.getText(editor.selection);
                if (selectedText) {
                    const action = await vscode.window.showQuickPick([
                        { label: '$(code) Review Code', value: 'review' },
                        { label: '$(bug) Debug/Fix', value: 'debug' },
                        { label: '$(edit) Improve/Refactor', value: 'refactor' },
                        { label: '$(book) Document', value: 'document' },
                        { label: '$(lightbulb) Explain', value: 'explain' },
                        { label: '$(pencil) Custom Task', value: 'custom' }
                    ], {
                        placeHolder: 'What would you like to do with the selected code?'
                    });

                    if (action) {
                        let task = '';
                        switch (action.value) {
                            case 'review':
                                task = `Review the following code and provide feedback on quality, best practices, and potential issues:\n\n\`\`\`\n${selectedText}\n\`\`\``;
                                break;
                            case 'debug':
                                task = `Debug and fix any issues in the following code:\n\n\`\`\`\n${selectedText}\n\`\`\``;
                                break;
                            case 'refactor':
                                task = `Improve and refactor the following code for better readability and performance:\n\n\`\`\`\n${selectedText}\n\`\`\``;
                                break;
                            case 'document':
                                task = `Write comprehensive documentation and comments for the following code:\n\n\`\`\`\n${selectedText}\n\`\`\``;
                                break;
                            case 'explain':
                                task = `Explain what the following code does step by step:\n\n\`\`\`\n${selectedText}\n\`\`\``;
                                break;
                            case 'custom':
                                const customTask = await vscode.window.showInputBox({
                                    prompt: 'Enter your custom task',
                                    placeHolder: 'What would you like to do?'
                                });
                                if (customTask) {
                                    task = `${customTask}\n\n\`\`\`\n${selectedText}\n\`\`\``;
                                }
                                break;
                        }

                        if (task) {
                            await executeTask(task, context);
                        }
                    }
                }
            } else {
                vscode.window.showWarningMessage('Please select some code first.');
            }
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('aiOrchestrator.clearHistory', async () => {
            const confirm = await vscode.window.showWarningMessage(
                'Are you sure you want to clear all task history?',
                'Yes', 'No'
            );
            if (confirm === 'Yes') {
                historyManager.clearHistory();
                historyTreeProvider.refresh();
                vscode.window.showInformationMessage('Task history cleared.');
            }
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('aiOrchestrator.rerunTask', async (item: HistoryItem) => {
            if (item && item.task) {
                await executeTask(item.task, context);
            }
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('aiOrchestrator.exportToMarkdown', async (item: HistoryItem) => {
            if (item && item.result) {
                const document = await vscode.workspace.openTextDocument({
                    content: generateMarkdownExport(item),
                    language: 'markdown'
                });
                await vscode.window.showTextDocument(document);
            }
        })
    );

    context.subscriptions.push(
        vscode.commands.registerCommand('aiOrchestrator.refreshHistory', () => {
            historyTreeProvider.refresh();
        })
    );

    // Initialize status bar
    statusBarManager.initialize(context);
    statusBarManager.setIdle();

    // Check for API keys on startup
    const config = new ConfigManager(context);
    const hasKeys = await config.hasAnyApiKeys();
    if (!hasKeys) {
        const action = await vscode.window.showInformationMessage(
            'AI Orchestrator: No API keys configured. Configure now?',
            'Configure', 'Later'
        );
        if (action === 'Configure') {
            await config.showConfigurationUI();
        }
    }
}

async function executeTask(task: string, context: vscode.ExtensionContext) {
    statusBarManager.setProcessing();
    
    try {
        const result = await orchestrator.execute(task, (status) => {
            statusBarManager.setProcessing(status);
            chatViewProvider.sendProgressUpdate(status);
        });

        const historyItem = historyManager.addTask(task, result);
        historyTreeProvider.refresh();
        
        // Show results in webview
        chatViewProvider.showResult(result);
        
        if (result.success) {
            statusBarManager.setSuccess();
        } else {
            statusBarManager.setError();
        }
    } catch (error) {
        statusBarManager.setError();
        vscode.window.showErrorMessage(`AI Orchestrator Error: ${error}`);
    }
}

async function showStatus(context: vscode.ExtensionContext) {
    const configManager = new ConfigManager(context);
    const status = await configManager.getStatusInfo();
    
    const panel = vscode.window.createWebviewPanel(
        'aiOrchestratorStatus',
        'AI Orchestrator Status',
        vscode.ViewColumn.One,
        {}
    );

    panel.webview.html = `
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: var(--vscode-font-family); padding: 20px; }
        .status-card { 
            background: var(--vscode-editor-background);
            border: 1px solid var(--vscode-panel-border);
            border-radius: 8px;
            padding: 16px;
            margin-bottom: 16px;
        }
        .model-status {
            display: flex;
            align-items: center;
            margin: 8px 0;
        }
        .status-icon {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            margin-right: 8px;
        }
        .status-active { background: #4caf50; }
        .status-inactive { background: #f44336; }
        h2 { color: var(--vscode-foreground); }
        .model-name { font-weight: bold; }
        .model-specialty { color: var(--vscode-descriptionForeground); font-size: 12px; }
    </style>
</head>
<body>
    <h2>🤖 AI Orchestrator Status</h2>
    
    <div class="status-card">
        <h3>Configured Models</h3>
        ${status.models.map(m => `
            <div class="model-status">
                <span class="status-icon ${m.active ? 'status-active' : 'status-inactive'}"></span>
                <div>
                    <span class="model-name">${m.name}</span>
                    <div class="model-specialty">${m.specialty}</div>
                </div>
            </div>
        `).join('')}
    </div>
    
    <div class="status-card">
        <h3>Statistics</h3>
        <p>Tasks Completed: ${status.tasksCompleted}</p>
        <p>Available Models: ${status.availableModels}/${status.totalModels}</p>
    </div>
</body>
</html>`;
}

function generateMarkdownExport(item: HistoryItem): string {
    const date = item.timestamp ? new Date(item.timestamp) : new Date();
    let md = `# AI Orchestrator Result\n\n`;
    md += `**Date:** ${date.toLocaleString()}\n\n`;
    md += `## Task\n\n${item.task || 'N/A'}\n\n`;
    md += `## Models Used\n\n`;
    
    if (item.result?.subtaskResults) {
        for (const sr of item.result.subtaskResults) {
            md += `- **${sr.response.modelProvider}** (${sr.response.modelName}): ${sr.subtask.taskType}\n`;
        }
    }
    
    md += `\n## Result\n\n${item.result?.consolidatedOutput || 'No output'}\n`;
    
    return md;
}

export function deactivate() {
    if (statusBarManager) {
        statusBarManager.dispose();
    }
}
