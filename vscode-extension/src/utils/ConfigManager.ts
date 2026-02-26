/**
 * Configuration manager using VS Code secrets API for secure storage
 */

import * as vscode from 'vscode';

interface ModelStatus {
    name: string;
    active: boolean;
    specialty: string;
}

interface StatusInfo {
    models: ModelStatus[];
    tasksCompleted: number;
    availableModels: number;
    totalModels: number;
}

const MODEL_SPECIALTIES: Record<string, string> = {
    openai: 'Architecture & Roadmap',
    anthropic: 'Coding & Debugging',
    gemini: 'Reasoning & Logic',
    moonshot: 'Code Review'
};

export class ConfigManager {
    private context: vscode.ExtensionContext;
    private static readonly API_KEY_PREFIX = 'aiOrchestrator.apiKey.';

    constructor(context: vscode.ExtensionContext) {
        this.context = context;
    }

    async getApiKey(provider: string): Promise<string | undefined> {
        try {
            return await this.context.secrets.get(`${ConfigManager.API_KEY_PREFIX}${provider}`);
        } catch {
            return undefined;
        }
    }

    async setApiKey(provider: string, key: string): Promise<void> {
        await this.context.secrets.store(`${ConfigManager.API_KEY_PREFIX}${provider}`, key);
    }

    async deleteApiKey(provider: string): Promise<void> {
        await this.context.secrets.delete(`${ConfigManager.API_KEY_PREFIX}${provider}`);
    }

    async hasAnyApiKeys(): Promise<boolean> {
        const providers = ['openai', 'anthropic', 'gemini', 'moonshot'];
        for (const provider of providers) {
            const key = await this.getApiKey(provider);
            if (key) return true;
        }
        return false;
    }

    getModelConfig(provider: string): string {
        const config = vscode.workspace.getConfiguration('aiOrchestrator');
        return config.get<string>(`${provider}.model`) || this.getDefaultModel(provider);
    }

    private getDefaultModel(provider: string): string {
        const defaults: Record<string, string> = {
            openai: 'gpt-4',
            anthropic: 'claude-3-opus-20240229',
            gemini: 'gemini-pro',
            moonshot: 'moonshot-v1-8k'
        };
        return defaults[provider] || 'default';
    }

    async showConfigurationUI(): Promise<void> {
        const items: vscode.QuickPickItem[] = [
            { label: '$(key) OpenAI API Key', description: 'For architecture and roadmap tasks', detail: 'ChatGPT / GPT-4' },
            { label: '$(key) Anthropic API Key', description: 'For coding and debugging tasks', detail: 'Claude' },
            { label: '$(key) Gemini API Key', description: 'For reasoning and logic tasks', detail: 'Google Gemini' },
            { label: '$(key) Moonshot API Key', description: 'For code review tasks', detail: 'Kimi' },
            { label: '$(gear) Model Settings', description: 'Configure model preferences' },
            { label: '$(info) View Current Status', description: 'See which models are configured' }
        ];

        const selected = await vscode.window.showQuickPick(items, {
            placeHolder: 'Select what to configure',
            title: 'AI Orchestrator Configuration'
        });

        if (!selected) return;

        if (selected.label.includes('OpenAI')) {
            await this.configureApiKey('openai', 'OpenAI');
        } else if (selected.label.includes('Anthropic')) {
            await this.configureApiKey('anthropic', 'Anthropic');
        } else if (selected.label.includes('Gemini')) {
            await this.configureApiKey('gemini', 'Gemini');
        } else if (selected.label.includes('Moonshot')) {
            await this.configureApiKey('moonshot', 'Moonshot');
        } else if (selected.label.includes('Model Settings')) {
            await vscode.commands.executeCommand('workbench.action.openSettings', 'aiOrchestrator');
        } else if (selected.label.includes('Status')) {
            await vscode.commands.executeCommand('aiOrchestrator.checkStatus');
        }
    }

    private async configureApiKey(provider: string, displayName: string): Promise<void> {
        const currentKey = await this.getApiKey(provider);
        const hasKey = !!currentKey;

        const action = await vscode.window.showQuickPick([
            { label: hasKey ? '$(edit) Update API Key' : '$(add) Add API Key', value: 'set' },
            ...(hasKey ? [{ label: '$(trash) Remove API Key', value: 'remove' }] : [])
        ], {
            placeHolder: `${displayName} API Key Configuration`
        });

        if (!action) return;

        if (action.value === 'set') {
            const key = await vscode.window.showInputBox({
                prompt: `Enter your ${displayName} API Key`,
                password: true,
                placeHolder: 'sk-...',
                ignoreFocusOut: true,
                validateInput: (value) => {
                    if (!value || value.trim().length === 0) {
                        return 'API key cannot be empty';
                    }
                    return undefined;
                }
            });

            if (key) {
                await this.setApiKey(provider, key.trim());
                vscode.window.showInformationMessage(`${displayName} API key saved securely.`);
            }
        } else if (action.value === 'remove') {
            const confirm = await vscode.window.showWarningMessage(
                `Are you sure you want to remove the ${displayName} API key?`,
                'Yes', 'No'
            );
            if (confirm === 'Yes') {
                await this.deleteApiKey(provider);
                vscode.window.showInformationMessage(`${displayName} API key removed.`);
            }
        }
    }

    async getStatusInfo(): Promise<StatusInfo> {
        const providers = ['openai', 'anthropic', 'gemini', 'moonshot'];
        const models: ModelStatus[] = [];
        let availableCount = 0;

        for (const provider of providers) {
            const hasKey = !!(await this.getApiKey(provider));
            if (hasKey) availableCount++;

            models.push({
                name: provider.charAt(0).toUpperCase() + provider.slice(1),
                active: hasKey,
                specialty: MODEL_SPECIALTIES[provider] || 'General'
            });
        }

        const tasksCompleted = this.context.globalState.get<number>('aiOrchestrator.tasksCompleted', 0);

        return {
            models,
            tasksCompleted,
            availableModels: availableCount,
            totalModels: providers.length
        };
    }

    incrementTaskCount(): void {
        const current = this.context.globalState.get<number>('aiOrchestrator.tasksCompleted', 0);
        this.context.globalState.update('aiOrchestrator.tasksCompleted', current + 1);
    }
}
