/**
 * Base class for AI model clients
 */

export interface ModelResponse {
    modelName: string;
    modelProvider: string;
    taskType: string;
    content: string;
    success: boolean;
    error?: string;
    tokensUsed?: number;
    metadata?: Record<string, unknown>;
}

export abstract class BaseModelClient {
    protected apiKey: string;
    protected modelName: string;
    public readonly providerName: string;

    constructor(apiKey: string, modelName: string, providerName: string) {
        this.apiKey = apiKey;
        this.modelName = modelName;
        this.providerName = providerName;
        this.validateApiKey();
    }

    protected validateApiKey(): void {
        if (!this.apiKey) {
            throw new Error(`API key required for ${this.providerName}`);
        }
    }

    abstract complete(prompt: string, systemPrompt?: string): Promise<ModelResponse>;
}
