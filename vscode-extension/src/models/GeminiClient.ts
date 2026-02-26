/**
 * Google Gemini client for reasoning tasks
 */

import { BaseModelClient, ModelResponse } from './BaseClient';

export class GeminiClient extends BaseModelClient {
    constructor(apiKey: string, modelName: string = 'gemini-pro') {
        super(apiKey, modelName, 'Gemini');
    }

    async complete(prompt: string, systemPrompt?: string): Promise<ModelResponse> {
        try {
            const fullPrompt = systemPrompt ? `${systemPrompt}\n\n${prompt}` : prompt;

            const response = await fetch(
                `https://generativelanguage.googleapis.com/v1beta/models/${this.modelName}:generateContent?key=${this.apiKey}`,
                {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json'
                    },
                    body: JSON.stringify({
                        contents: [{
                            parts: [{ text: fullPrompt }]
                        }],
                        generationConfig: {
                            temperature: 0.7,
                            maxOutputTokens: 4096
                        }
                    })
                }
            );

            if (!response.ok) {
                const errorData = await response.json().catch(() => ({})) as { error?: { message?: string } };
                throw new Error(errorData.error?.message || `HTTP ${response.status}`);
            }

            const data = await response.json() as {
                candidates?: Array<{
                    content?: { parts?: Array<{ text?: string }> };
                    finishReason?: string;
                }>;
            };
            const content = data.candidates?.[0]?.content?.parts?.[0]?.text || '';

            return {
                modelName: this.modelName,
                modelProvider: this.providerName,
                taskType: 'reasoning',
                content: content,
                success: true,
                metadata: { finishReason: data.candidates?.[0]?.finishReason }
            };
        } catch (error) {
            return {
                modelName: this.modelName,
                modelProvider: this.providerName,
                taskType: 'reasoning',
                content: '',
                success: false,
                error: String(error)
            };
        }
    }
}
