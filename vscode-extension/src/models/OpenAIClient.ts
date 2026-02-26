/**
 * OpenAI (ChatGPT) client for architecture and roadmap tasks
 */

import { BaseModelClient, ModelResponse } from './BaseClient';

export class OpenAIClient extends BaseModelClient {
    constructor(apiKey: string, modelName: string = 'gpt-4') {
        super(apiKey, modelName, 'OpenAI');
    }

    async complete(prompt: string, systemPrompt?: string): Promise<ModelResponse> {
        try {
            const messages: Array<{role: string; content: string}> = [];
            
            if (systemPrompt) {
                messages.push({ role: 'system', content: systemPrompt });
            }
            messages.push({ role: 'user', content: prompt });

            const response = await fetch('https://api.openai.com/v1/chat/completions', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${this.apiKey}`
                },
                body: JSON.stringify({
                    model: this.modelName,
                    messages: messages,
                    temperature: 0.7,
                    max_tokens: 4096
                })
            });

            if (!response.ok) {
                const errorData = await response.json().catch(() => ({})) as { error?: { message?: string } };
                throw new Error(errorData.error?.message || `HTTP ${response.status}`);
            }

            const data = await response.json() as {
                choices: Array<{ message?: { content?: string }; finish_reason?: string }>;
                usage?: { total_tokens?: number };
            };

            return {
                modelName: this.modelName,
                modelProvider: this.providerName,
                taskType: 'architecture/roadmap',
                content: data.choices[0]?.message?.content || '',
                success: true,
                tokensUsed: data.usage?.total_tokens,
                metadata: { finishReason: data.choices[0]?.finish_reason }
            };
        } catch (error) {
            return {
                modelName: this.modelName,
                modelProvider: this.providerName,
                taskType: 'architecture/roadmap',
                content: '',
                success: false,
                error: String(error)
            };
        }
    }
}
