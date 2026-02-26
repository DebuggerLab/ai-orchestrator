/**
 * Anthropic (Claude) client for coding tasks
 */

import { BaseModelClient, ModelResponse } from './BaseClient';

export class AnthropicClient extends BaseModelClient {
    constructor(apiKey: string, modelName: string = 'claude-3-5-sonnet-20240620') {
        super(apiKey, modelName, 'Anthropic');
    }

    async complete(prompt: string, systemPrompt?: string): Promise<ModelResponse> {
        try {
            const body: Record<string, unknown> = {
                model: this.modelName,
                max_tokens: 4096,
                messages: [{ role: 'user', content: prompt }]
            };

            if (systemPrompt) {
                body.system = systemPrompt;
            }

            const response = await fetch('https://api.anthropic.com/v1/messages', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'x-api-key': this.apiKey,
                    'anthropic-version': '2023-06-01'
                },
                body: JSON.stringify(body)
            });

            if (!response.ok) {
                const errorData = await response.json().catch(() => ({})) as { error?: { message?: string } };
                throw new Error(errorData.error?.message || `HTTP ${response.status}`);
            }

            const data = await response.json() as {
                content?: Array<{ text?: string }>;
                usage?: { input_tokens?: number; output_tokens?: number };
                stop_reason?: string;
            };
            const content = data.content?.[0]?.text || '';

            return {
                modelName: this.modelName,
                modelProvider: this.providerName,
                taskType: 'coding',
                content: content,
                success: true,
                tokensUsed: (data.usage?.input_tokens || 0) + (data.usage?.output_tokens || 0),
                metadata: { stopReason: data.stop_reason }
            };
        } catch (error) {
            return {
                modelName: this.modelName,
                modelProvider: this.providerName,
                taskType: 'coding',
                content: '',
                success: false,
                error: String(error)
            };
        }
    }
}
