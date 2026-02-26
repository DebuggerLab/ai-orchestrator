/**
 * Main orchestrator for AI task distribution
 */

import { ConfigManager } from './utils/ConfigManager';
import { TaskRouter, SubTask, ModelProvider, TaskType } from './router';
import { OpenAIClient } from './models/OpenAIClient';
import { AnthropicClient } from './models/AnthropicClient';
import { GeminiClient } from './models/GeminiClient';
import { MoonshotClient } from './models/MoonshotClient';
import { BaseModelClient, ModelResponse } from './models/BaseClient';

export interface SubtaskResult {
    subtask: SubTask;
    response: ModelResponse;
}

export interface OrchestrationResult {
    originalTask: string;
    subtaskResults: SubtaskResult[];
    consolidatedOutput: string;
    success: boolean;
    errors: string[];
    routingPlan: RoutingPlanItem[];
}

export interface RoutingPlanItem {
    id: number;
    taskType: string;
    model: string;
    description: string;
}

type ProgressCallback = (status: string) => void;

export class Orchestrator {
    private configManager: ConfigManager;
    private clients: Map<ModelProvider, BaseModelClient> = new Map();
    private router: TaskRouter;

    constructor(configManager: ConfigManager) {
        this.configManager = configManager;
        this.router = new TaskRouter([]);
    }

    private async initializeClients(): Promise<void> {
        this.clients.clear();
        const available: string[] = [];

        // OpenAI
        const openaiKey = await this.configManager.getApiKey('openai');
        const openaiModel = this.configManager.getModelConfig('openai');
        if (openaiKey) {
            try {
                this.clients.set(ModelProvider.OPENAI, new OpenAIClient(openaiKey, openaiModel));
                available.push('openai');
            } catch (e) {
                console.warn('Could not initialize OpenAI client:', e);
            }
        }

        // Anthropic
        const anthropicKey = await this.configManager.getApiKey('anthropic');
        const anthropicModel = this.configManager.getModelConfig('anthropic');
        if (anthropicKey) {
            try {
                this.clients.set(ModelProvider.ANTHROPIC, new AnthropicClient(anthropicKey, anthropicModel));
                available.push('anthropic');
            } catch (e) {
                console.warn('Could not initialize Anthropic client:', e);
            }
        }

        // Gemini
        const geminiKey = await this.configManager.getApiKey('gemini');
        const geminiModel = this.configManager.getModelConfig('gemini');
        if (geminiKey) {
            try {
                this.clients.set(ModelProvider.GEMINI, new GeminiClient(geminiKey, geminiModel));
                available.push('gemini');
            } catch (e) {
                console.warn('Could not initialize Gemini client:', e);
            }
        }

        // Moonshot
        const moonshotKey = await this.configManager.getApiKey('moonshot');
        const moonshotModel = this.configManager.getModelConfig('moonshot');
        if (moonshotKey) {
            try {
                this.clients.set(ModelProvider.MOONSHOT, new MoonshotClient(moonshotKey, moonshotModel));
                available.push('moonshot');
            } catch (e) {
                console.warn('Could not initialize Moonshot client:', e);
            }
        }

        this.router = new TaskRouter(available);
    }

    async execute(taskDescription: string, onProgress?: ProgressCallback): Promise<OrchestrationResult> {
        const result: OrchestrationResult = {
            originalTask: taskDescription,
            subtaskResults: [],
            consolidatedOutput: '',
            success: true,
            errors: [],
            routingPlan: []
        };

        // Initialize clients
        await this.initializeClients();

        if (this.clients.size === 0) {
            result.success = false;
            result.errors.push('No AI models available. Please configure at least one API key.');
            return result;
        }

        onProgress?.('Analyzing task...');

        // Analyze and route the task
        let subtasks: SubTask[];
        try {
            subtasks = this.router.analyzeAndRoute(taskDescription);
        } catch (e) {
            result.success = false;
            result.errors.push(String(e));
            return result;
        }

        // Build routing plan
        result.routingPlan = subtasks.map(st => ({
            id: st.id,
            taskType: st.taskType,
            model: st.targetModel,
            description: st.description
        }));

        // Execute each subtask
        for (const subtask of subtasks) {
            const modelName = subtask.targetModel.charAt(0).toUpperCase() + subtask.targetModel.slice(1);
            onProgress?.(`Processing with ${modelName}: ${subtask.description.substring(0, 40)}...`);

            const response = await this.executeSubtask(subtask);
            result.subtaskResults.push({ subtask, response });

            if (!response.success) {
                result.errors.push(`[${subtask.targetModel}] ${response.error}`);
            }
        }

        // Consolidate results
        onProgress?.('Consolidating results...');
        result.consolidatedOutput = this.consolidateResults(result.subtaskResults);
        result.success = result.errors.length === 0 || result.subtaskResults.some(sr => sr.response.success);

        return result;
    }

    private async executeSubtask(subtask: SubTask): Promise<ModelResponse> {
        const provider = this.getProviderEnum(subtask.targetModel);
        let client = this.clients.get(provider);

        if (!client) {
            // Fallback to any available client
            const firstClient = this.clients.values().next().value;
            if (firstClient) {
                client = firstClient;
            } else {
                return {
                    modelName: 'none',
                    modelProvider: 'none',
                    taskType: subtask.taskType,
                    content: '',
                    success: false,
                    error: `No client available for ${subtask.targetModel}`
                };
            }
        }

        return await client.complete(subtask.prompt, subtask.systemPrompt);
    }

    private getProviderEnum(provider: string): ModelProvider {
        switch (provider.toLowerCase()) {
            case 'openai': return ModelProvider.OPENAI;
            case 'anthropic': return ModelProvider.ANTHROPIC;
            case 'gemini': return ModelProvider.GEMINI;
            case 'moonshot': return ModelProvider.MOONSHOT;
            default: return ModelProvider.OPENAI;
        }
    }

    private consolidateResults(subtaskResults: SubtaskResult[]): string {
        if (subtaskResults.length === 0) {
            return 'No results to consolidate.';
        }

        if (subtaskResults.length === 1) {
            return subtaskResults[0].response.content;
        }

        // Multiple results - create structured output
        const parts: string[] = [];
        for (const { subtask, response } of subtaskResults) {
            if (response.success && response.content) {
                const title = subtask.taskType.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
                parts.push(`## ${title} (${response.modelProvider})\n\n${response.content}`);
            }
        }

        return parts.join('\n\n---\n\n');
    }

    async getAvailableModels(): Promise<string[]> {
        await this.initializeClients();
        return Array.from(this.clients.keys()).map(k => k.toString());
    }
}
