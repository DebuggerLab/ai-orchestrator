/**
 * Chat webview provider for AI Orchestrator sidebar
 */

import * as vscode from 'vscode';
import { Orchestrator, OrchestrationResult } from '../orchestrator';
import { HistoryManager } from '../utils/HistoryManager';
import { StatusBarManager } from './StatusBarManager';

export class ChatViewProvider implements vscode.WebviewViewProvider {
    public static readonly viewType = 'aiOrchestrator.chatView';
    private _view?: vscode.WebviewView;

    constructor(
        private readonly _extensionUri: vscode.Uri,
        private readonly orchestrator: Orchestrator,
        private readonly historyManager: HistoryManager,
        private readonly statusBarManager: StatusBarManager
    ) {}

    public resolveWebviewView(
        webviewView: vscode.WebviewView,
        _context: vscode.WebviewViewResolveContext,
        _token: vscode.CancellationToken
    ) {
        this._view = webviewView;

        webviewView.webview.options = {
            enableScripts: true,
            localResourceRoots: [this._extensionUri]
        };

        webviewView.webview.html = this._getHtmlContent(webviewView.webview);

        // Handle messages from webview
        webviewView.webview.onDidReceiveMessage(async (message) => {
            switch (message.command) {
                case 'runTask':
                    await this._handleRunTask(message.task);
                    break;
                case 'configure':
                    await vscode.commands.executeCommand('aiOrchestrator.configure');
                    break;
            }
        });
    }

    private async _handleRunTask(task: string) {
        if (!this._view) return;

        this.statusBarManager.setProcessing();
        this._view.webview.postMessage({ command: 'startProcessing' });

        try {
            const result = await this.orchestrator.execute(task, (status) => {
                this.statusBarManager.setProcessing(status);
                this._view?.webview.postMessage({ 
                    command: 'progress', 
                    status 
                });
            });

            this.historyManager.addTask(task, result);
            this._view.webview.postMessage({ 
                command: 'result', 
                result: this._formatResult(result)
            });

            if (result.success) {
                this.statusBarManager.setSuccess();
            } else {
                this.statusBarManager.setError();
            }
        } catch (error) {
            this.statusBarManager.setError();
            this._view.webview.postMessage({ 
                command: 'error', 
                message: String(error)
            });
        }
    }

    public sendProgressUpdate(status: string) {
        if (this._view) {
            this._view.webview.postMessage({ command: 'progress', status });
        }
    }

    public showResult(result: OrchestrationResult) {
        if (this._view) {
            this._view.webview.postMessage({ 
                command: 'result', 
                result: this._formatResult(result)
            });
        }
    }

    private _formatResult(result: OrchestrationResult): unknown {
        return {
            success: result.success,
            task: result.originalTask,
            routingPlan: result.routingPlan,
            subtaskResults: result.subtaskResults.map(sr => ({
                taskType: sr.subtask.taskType,
                model: sr.subtask.targetModel,
                modelProvider: sr.response.modelProvider,
                modelName: sr.response.modelName,
                success: sr.response.success,
                content: sr.response.content,
                error: sr.response.error
            })),
            consolidatedOutput: result.consolidatedOutput,
            errors: result.errors
        };
    }

    private _getHtmlContent(webview: vscode.Webview): string {
        const nonce = this._getNonce();

        return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src ${webview.cspSource} 'unsafe-inline'; script-src 'nonce-${nonce}';">
    <title>AI Orchestrator</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        body {
            font-family: var(--vscode-font-family);
            font-size: var(--vscode-font-size);
            color: var(--vscode-foreground);
            background: var(--vscode-sideBar-background);
            padding: 12px;
        }
        .header {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 16px;
            padding-bottom: 12px;
            border-bottom: 1px solid var(--vscode-panel-border);
        }
        .header h2 {
            font-size: 14px;
            font-weight: 600;
        }
        .logo {
            width: 24px;
            height: 24px;
        }
        .input-container {
            margin-bottom: 12px;
        }
        textarea {
            width: 100%;
            min-height: 80px;
            padding: 10px;
            border: 1px solid var(--vscode-input-border);
            background: var(--vscode-input-background);
            color: var(--vscode-input-foreground);
            border-radius: 6px;
            font-family: inherit;
            font-size: 13px;
            resize: vertical;
        }
        textarea:focus {
            outline: none;
            border-color: var(--vscode-focusBorder);
        }
        .button-row {
            display: flex;
            gap: 8px;
            margin-bottom: 16px;
        }
        button {
            padding: 8px 16px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 12px;
            font-weight: 500;
            display: flex;
            align-items: center;
            gap: 6px;
        }
        .btn-primary {
            background: var(--vscode-button-background);
            color: var(--vscode-button-foreground);
            flex: 1;
        }
        .btn-primary:hover {
            background: var(--vscode-button-hoverBackground);
        }
        .btn-primary:disabled {
            opacity: 0.5;
            cursor: not-allowed;
        }
        .btn-secondary {
            background: var(--vscode-button-secondaryBackground);
            color: var(--vscode-button-secondaryForeground);
        }
        .progress-container {
            display: none;
            padding: 12px;
            background: var(--vscode-editor-background);
            border-radius: 6px;
            margin-bottom: 12px;
        }
        .progress-container.active {
            display: block;
        }
        .progress-spinner {
            display: inline-block;
            width: 16px;
            height: 16px;
            border: 2px solid var(--vscode-progressBar-background);
            border-top-color: transparent;
            border-radius: 50%;
            animation: spin 1s linear infinite;
            margin-right: 8px;
        }
        @keyframes spin {
            to { transform: rotate(360deg); }
        }
        .progress-status {
            font-size: 12px;
            color: var(--vscode-descriptionForeground);
        }
        .routing-plan {
            background: var(--vscode-editor-background);
            border-radius: 6px;
            padding: 12px;
            margin-bottom: 12px;
        }
        .routing-plan h4 {
            font-size: 12px;
            margin-bottom: 8px;
            color: var(--vscode-descriptionForeground);
        }
        .routing-item {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 6px 0;
            font-size: 12px;
            border-bottom: 1px solid var(--vscode-panel-border);
        }
        .routing-item:last-child {
            border-bottom: none;
        }
        .model-badge {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 10px;
            font-weight: 600;
            text-transform: uppercase;
        }
        .model-openai { background: #10a37f22; color: #10a37f; }
        .model-anthropic { background: #cc785c22; color: #cc785c; }
        .model-gemini { background: #4285f422; color: #4285f4; }
        .model-moonshot { background: #9333ea22; color: #9333ea; }
        .result-container {
            display: none;
        }
        .result-container.active {
            display: block;
        }
        .result-section {
            background: var(--vscode-editor-background);
            border-radius: 6px;
            padding: 12px;
            margin-bottom: 12px;
        }
        .result-header {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 8px;
        }
        .result-title {
            font-size: 12px;
            font-weight: 600;
        }
        .status-badge {
            padding: 2px 8px;
            border-radius: 10px;
            font-size: 10px;
        }
        .status-success { background: #22c55e22; color: #22c55e; }
        .status-error { background: #ef444422; color: #ef4444; }
        .result-content {
            font-size: 12px;
            line-height: 1.6;
            white-space: pre-wrap;
            word-break: break-word;
            max-height: 300px;
            overflow-y: auto;
        }
        .result-content code {
            background: var(--vscode-textCodeBlock-background);
            padding: 2px 4px;
            border-radius: 3px;
            font-family: var(--vscode-editor-font-family);
        }
        .result-content pre {
            background: var(--vscode-textCodeBlock-background);
            padding: 10px;
            border-radius: 4px;
            overflow-x: auto;
            margin: 8px 0;
        }
        .subtask-result {
            margin-bottom: 12px;
            padding: 10px;
            background: var(--vscode-sideBar-background);
            border-radius: 4px;
            border-left: 3px solid var(--vscode-activityBarBadge-background);
        }
        .subtask-header {
            display: flex;
            align-items: center;
            gap: 8px;
            margin-bottom: 8px;
        }
        .error-message {
            color: var(--vscode-errorForeground);
            padding: 8px;
            background: var(--vscode-inputValidation-errorBackground);
            border-radius: 4px;
            font-size: 12px;
        }
        .quick-actions {
            display: flex;
            flex-wrap: wrap;
            gap: 6px;
            margin-bottom: 12px;
        }
        .quick-action {
            padding: 4px 10px;
            font-size: 11px;
            background: var(--vscode-badge-background);
            color: var(--vscode-badge-foreground);
            border-radius: 12px;
            cursor: pointer;
            border: none;
        }
        .quick-action:hover {
            opacity: 0.8;
        }
    </style>
</head>
<body>
    <div class="header">
        <svg class="logo" viewBox="0 0 24 24" fill="none" xmlns="https://upload.wikimedia.org/wikipedia/commons/d/d2/ReuleauxTriangle.svg">
            <circle cx="12" cy="12" r="10" stroke="var(--vscode-activityBarBadge-background)" stroke-width="2"/>
            <circle cx="12" cy="8" r="2" fill="var(--vscode-activityBarBadge-background)"/>
            <circle cx="8" cy="14" r="2" fill="var(--vscode-activityBarBadge-background)"/>
            <circle cx="16" cy="14" r="2" fill="var(--vscode-activityBarBadge-background)"/>
            <path d="M12 10V12M12 12L9 13M12 12L15 13" stroke="var(--vscode-activityBarBadge-background)" stroke-width="1.5"/>
        </svg>
        <h2>AI Orchestrator</h2>
    </div>

    <div class="input-container">
        <textarea id="taskInput" placeholder="Describe your task... &#10;e.g., Design and implement a REST API for user authentication"></textarea>
    </div>

    <div class="quick-actions">
        <button class="quick-action" data-task="Design the architecture for">🏗️ Architecture</button>
        <button class="quick-action" data-task="Implement code for">💻 Code</button>
        <button class="quick-action" data-task="Review and improve">🔍 Review</button>
        <button class="quick-action" data-task="Explain and analyze">🧠 Analyze</button>
    </div>

    <div class="button-row">
        <button class="btn-primary" id="runBtn">
            <span>▶</span> Run Task
        </button>
        <button class="btn-secondary" id="configBtn">
            ⚙️
        </button>
    </div>

    <div class="progress-container" id="progressContainer">
        <span class="progress-spinner"></span>
        <span class="progress-status" id="progressStatus">Analyzing task...</span>
    </div>

    <div id="routingPlan" class="routing-plan" style="display: none;">
        <h4>📋 Routing Plan</h4>
        <div id="routingItems"></div>
    </div>

    <div class="result-container" id="resultContainer">
        <div id="subtaskResults"></div>
        
        <div class="result-section">
            <div class="result-header">
                <span class="result-title">📝 Consolidated Output</span>
                <span class="status-badge status-success" id="statusBadge">Success</span>
            </div>
            <div class="result-content" id="consolidatedOutput"></div>
        </div>

        <div id="errorSection" class="result-section" style="display: none;">
            <div class="result-title">⚠️ Errors</div>
            <div id="errorList" class="error-message"></div>
        </div>
    </div>

    <script nonce="${nonce}">
        const vscode = acquireVsCodeApi();
        const taskInput = document.getElementById('taskInput');
        const runBtn = document.getElementById('runBtn');
        const configBtn = document.getElementById('configBtn');
        const progressContainer = document.getElementById('progressContainer');
        const progressStatus = document.getElementById('progressStatus');
        const routingPlan = document.getElementById('routingPlan');
        const routingItems = document.getElementById('routingItems');
        const resultContainer = document.getElementById('resultContainer');
        const subtaskResults = document.getElementById('subtaskResults');
        const consolidatedOutput = document.getElementById('consolidatedOutput');
        const statusBadge = document.getElementById('statusBadge');
        const errorSection = document.getElementById('errorSection');
        const errorList = document.getElementById('errorList');

        // Quick action buttons
        document.querySelectorAll('.quick-action').forEach(btn => {
            btn.addEventListener('click', () => {
                const prefix = btn.dataset.task;
                taskInput.value = prefix + ' ';
                taskInput.focus();
            });
        });

        runBtn.addEventListener('click', () => {
            const task = taskInput.value.trim();
            if (task) {
                vscode.postMessage({ command: 'runTask', task });
            }
        });

        configBtn.addEventListener('click', () => {
            vscode.postMessage({ command: 'configure' });
        });

        // Handle Ctrl+Enter to run
        taskInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' && (e.ctrlKey || e.metaKey)) {
                runBtn.click();
            }
        });

        window.addEventListener('message', (event) => {
            const message = event.data;
            
            switch (message.command) {
                case 'startProcessing':
                    runBtn.disabled = true;
                    progressContainer.classList.add('active');
                    resultContainer.classList.remove('active');
                    routingPlan.style.display = 'none';
                    break;

                case 'progress':
                    progressStatus.textContent = message.status;
                    break;

                case 'result':
                    runBtn.disabled = false;
                    progressContainer.classList.remove('active');
                    resultContainer.classList.add('active');
                    displayResult(message.result);
                    break;

                case 'error':
                    runBtn.disabled = false;
                    progressContainer.classList.remove('active');
                    errorSection.style.display = 'block';
                    errorList.textContent = message.message;
                    break;
            }
        });

        function displayResult(result) {
            // Show routing plan
            if (result.routingPlan && result.routingPlan.length > 0) {
                routingPlan.style.display = 'block';
                routingItems.innerHTML = result.routingPlan.map(item => \`
                    <div class="routing-item">
                        <span class="model-badge model-\${item.model}">\${item.model}</span>
                        <span>\${item.taskType.replace(/_/g, ' ')}</span>
                    </div>
                \`).join('');
            }

            // Show subtask results
            if (result.subtaskResults && result.subtaskResults.length > 1) {
                subtaskResults.innerHTML = result.subtaskResults.map(sr => \`
                    <div class="subtask-result">
                        <div class="subtask-header">
                            <span class="model-badge model-\${sr.model}">\${sr.modelProvider}</span>
                            <span>\${sr.taskType.replace(/_/g, ' ')}</span>
                            <span class="status-badge \${sr.success ? 'status-success' : 'status-error'}">
                                \${sr.success ? '✓' : '✗'}
                            </span>
                        </div>
                        <div class="result-content">\${escapeHtml(sr.content || sr.error || '')}</div>
                    </div>
                \`).join('');
            } else {
                subtaskResults.innerHTML = '';
            }

            // Show consolidated output
            consolidatedOutput.innerHTML = formatMarkdown(result.consolidatedOutput || 'No output');
            
            // Update status
            statusBadge.textContent = result.success ? 'Success' : 'Partial Success';
            statusBadge.className = 'status-badge ' + (result.success ? 'status-success' : 'status-error');

            // Show errors if any
            if (result.errors && result.errors.length > 0) {
                errorSection.style.display = 'block';
                errorList.innerHTML = result.errors.map(e => \`<div>• \${escapeHtml(e)}</div>\`).join('');
            } else {
                errorSection.style.display = 'none';
            }
        }

        function escapeHtml(text) {
            const div = document.createElement('div');
            div.textContent = text;
            return div.innerHTML;
        }

        function formatMarkdown(text) {
            // Simple markdown formatting
            return escapeHtml(text)
                .replace(/\`\`\`([\\s\\S]*?)\`\`\`/g, '<pre><code>$1</code></pre>')
                .replace(/\`([^\`]+)\`/g, '<code>$1</code>')
                .replace(/\\*\\*([^*]+)\\*\\*/g, '<strong>$1</strong>')
                .replace(/\\*([^*]+)\\*/g, '<em>$1</em>')
                .replace(/^## (.+)$/gm, '<h3>$1</h3>')
                .replace(/^### (.+)$/gm, '<h4>$1</h4>')
                .replace(/\\n/g, '<br>');
        }
    </script>
</body>
</html>`;
    }

    private _getNonce(): string {
        let text = '';
        const possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        for (let i = 0; i < 32; i++) {
            text += possible.charAt(Math.floor(Math.random() * possible.length));
        }
        return text;
    }
}
