/**
 * Intelligent task router for AI Orchestrator
 */

export enum ModelProvider {
    OPENAI = 'openai',
    ANTHROPIC = 'anthropic',
    GEMINI = 'gemini',
    MOONSHOT = 'moonshot'
}

export enum TaskType {
    ARCHITECTURE = 'architecture',
    ROADMAP = 'roadmap',
    CODING = 'coding',
    DEBUGGING = 'debugging',
    REASONING = 'reasoning',
    LOGIC = 'logic',
    CODE_REVIEW = 'code_review',
    DOCUMENTATION = 'documentation',
    GENERAL = 'general'
}

export interface SubTask {
    id: number;
    description: string;
    taskType: string;
    targetModel: string;
    prompt: string;
    systemPrompt?: string;
    dependencies: number[];
}

// Keywords for task type detection
const TASK_PATTERNS: Record<TaskType, RegExp[]> = {
    [TaskType.ARCHITECTURE]: [
        /architect/i, /design/i, /structure/i, /system design/i,
        /high.?level/i, /overview/i, /blueprint/i, /schema/i,
        /database design/i, /api design/i, /microservice/i
    ],
    [TaskType.ROADMAP]: [
        /roadmap/i, /plan/i, /strategy/i, /milestone/i, /timeline/i,
        /phase/i, /sprint/i, /project plan/i, /release plan/i
    ],
    [TaskType.CODING]: [
        /implement/i, /code/i, /write/i, /function/i, /class/i,
        /script/i, /program/i, /develop/i, /build/i, /create.*function/i,
        /api endpoint/i, /module/i, /library/i
    ],
    [TaskType.DEBUGGING]: [
        /debug/i, /fix/i, /error/i, /bug/i, /issue/i, /problem/i,
        /not working/i, /fails/i, /crash/i, /exception/i
    ],
    [TaskType.REASONING]: [
        /reason/i, /logic/i, /explain/i, /why/i, /analyze/i,
        /think/i, /evaluate/i, /compare/i, /pros.?cons/i,
        /trade.?off/i, /decision/i, /choose/i, /best approach/i
    ],
    [TaskType.LOGIC]: [
        /algorithm/i, /optimize/i, /complexity/i, /efficient/i,
        /performance/i, /mathematical/i, /formula/i, /calculate/i
    ],
    [TaskType.CODE_REVIEW]: [
        /review/i, /check/i, /audit/i, /inspect/i, /feedback/i,
        /improve/i, /refactor/i, /quality/i, /best practice/i,
        /security/i, /vulnerability/i
    ],
    [TaskType.DOCUMENTATION]: [
        /document/i, /readme/i, /comment/i, /docstring/i,
        /specification/i, /wiki/i, /guide/i, /tutorial/i
    ],
    [TaskType.GENERAL]: []
};

// Model specialization mapping
const MODEL_SPECIALIZATIONS: Record<TaskType, ModelProvider> = {
    [TaskType.ARCHITECTURE]: ModelProvider.OPENAI,
    [TaskType.ROADMAP]: ModelProvider.OPENAI,
    [TaskType.CODING]: ModelProvider.ANTHROPIC,
    [TaskType.DEBUGGING]: ModelProvider.ANTHROPIC,
    [TaskType.REASONING]: ModelProvider.GEMINI,
    [TaskType.LOGIC]: ModelProvider.GEMINI,
    [TaskType.CODE_REVIEW]: ModelProvider.MOONSHOT,
    [TaskType.DOCUMENTATION]: ModelProvider.OPENAI,
    [TaskType.GENERAL]: ModelProvider.OPENAI
};

// System prompts for different task types
const SYSTEM_PROMPTS: Record<TaskType, string> = {
    [TaskType.ARCHITECTURE]: "You are a senior software architect. Focus on system design, scalability, and best practices. Provide clear architectural diagrams in text format when helpful.",
    [TaskType.ROADMAP]: "You are a technical project manager. Create detailed, actionable roadmaps with clear milestones and timelines.",
    [TaskType.CODING]: "You are an expert software engineer. Write clean, well-documented, production-ready code. Include error handling and follow best practices.",
    [TaskType.DEBUGGING]: "You are a debugging expert. Analyze issues methodically, identify root causes, and provide clear solutions with explanations.",
    [TaskType.REASONING]: "You are an analytical thinker. Break down complex problems, evaluate trade-offs, and provide well-reasoned conclusions.",
    [TaskType.LOGIC]: "You are an algorithms expert. Focus on efficiency, complexity analysis, and optimal solutions.",
    [TaskType.CODE_REVIEW]: "You are a code review specialist. Identify issues, suggest improvements, check for security vulnerabilities, and ensure code quality.",
    [TaskType.DOCUMENTATION]: "You are a technical writer. Create clear, comprehensive documentation that is easy to understand.",
    [TaskType.GENERAL]: "You are a helpful AI assistant. Provide clear, accurate, and helpful responses."
};

// Contextual prompt prefixes
const PROMPT_PREFIXES: Record<TaskType, string> = {
    [TaskType.ARCHITECTURE]: "Focus on the architecture and system design aspects of this task:\n\n",
    [TaskType.ROADMAP]: "Create a roadmap and project plan for:\n\n",
    [TaskType.CODING]: "Implement the code for the following requirement:\n\n",
    [TaskType.DEBUGGING]: "Debug and fix issues in the following:\n\n",
    [TaskType.REASONING]: "Analyze and reason about the following:\n\n",
    [TaskType.LOGIC]: "Provide algorithmic and logical analysis for:\n\n",
    [TaskType.CODE_REVIEW]: "Review and provide feedback on:\n\n",
    [TaskType.DOCUMENTATION]: "Write documentation for:\n\n",
    [TaskType.GENERAL]: ""
};

export class TaskRouter {
    private availableModels: ModelProvider[];

    constructor(availableModelStrings: string[]) {
        this.availableModels = availableModelStrings
            .filter(m => Object.values(ModelProvider).includes(m as ModelProvider))
            .map(m => m as ModelProvider);
    }

    detectTaskType(text: string): TaskType {
        const scores: Record<TaskType, number> = {} as Record<TaskType, number>;
        
        for (const taskType of Object.values(TaskType)) {
            scores[taskType] = 0;
        }

        for (const [taskType, patterns] of Object.entries(TASK_PATTERNS)) {
            for (const pattern of patterns) {
                const matches = text.match(new RegExp(pattern, 'gi'));
                if (matches) {
                    scores[taskType as TaskType] += matches.length;
                }
            }
        }

        // Find task type with highest score
        let maxScore = 0;
        let detectedType = TaskType.GENERAL;

        for (const [taskType, score] of Object.entries(scores)) {
            if (score > maxScore) {
                maxScore = score;
                detectedType = taskType as TaskType;
            }
        }

        return detectedType;
    }

    getTargetModel(taskType: TaskType): ModelProvider {
        const preferred = MODEL_SPECIALIZATIONS[taskType] || ModelProvider.OPENAI;

        if (this.availableModels.includes(preferred)) {
            return preferred;
        }

        // Fallback to any available model
        if (this.availableModels.length > 0) {
            return this.availableModels[0];
        }

        throw new Error("No AI models available. Please configure at least one API key.");
    }

    analyzeAndRoute(taskDescription: string): SubTask[] {
        const subtasks: SubTask[] = [];

        // Detect all task types present
        const detectedTypes = this.detectAllTaskTypes(taskDescription);

        if (detectedTypes.length <= 1) {
            // Simple task - route to single model
            const taskType = detectedTypes[0] || TaskType.GENERAL;
            const target = this.getTargetModel(taskType);

            subtasks.push({
                id: 1,
                description: taskDescription,
                taskType: taskType,
                targetModel: target,
                prompt: taskDescription,
                systemPrompt: SYSTEM_PROMPTS[taskType],
                dependencies: []
            });
        } else {
            // Complex task - break down and route to multiple models
            return this.createMultiModelWorkflow(taskDescription, detectedTypes);
        }

        return subtasks;
    }

    private detectAllTaskTypes(text: string): TaskType[] {
        const detected: TaskType[] = [];

        for (const [taskType, patterns] of Object.entries(TASK_PATTERNS)) {
            if (taskType === TaskType.GENERAL) continue;
            
            for (const pattern of patterns) {
                if (pattern.test(text)) {
                    if (!detected.includes(taskType as TaskType)) {
                        detected.push(taskType as TaskType);
                    }
                    break;
                }
            }
        }

        return detected.length > 0 ? detected : [TaskType.GENERAL];
    }

    private createMultiModelWorkflow(taskDescription: string, taskTypes: TaskType[]): SubTask[] {
        const subtasks: SubTask[] = [];

        // Priority order for task types
        const priorityOrder = [
            TaskType.ARCHITECTURE, TaskType.ROADMAP,
            TaskType.REASONING, TaskType.LOGIC,
            TaskType.CODING, TaskType.DEBUGGING,
            TaskType.CODE_REVIEW,
            TaskType.DOCUMENTATION
        ];

        // Sort detected types by priority
        const sortedTypes = taskTypes.sort((a, b) => {
            const aIndex = priorityOrder.indexOf(a);
            const bIndex = priorityOrder.indexOf(b);
            return (aIndex === -1 ? 999 : aIndex) - (bIndex === -1 ? 999 : bIndex);
        });

        let taskId = 1;
        let previousId: number | null = null;

        for (const taskType of sortedTypes) {
            const target = this.getTargetModel(taskType);
            const prompt = this.createContextualPrompt(taskDescription, taskType);

            subtasks.push({
                id: taskId,
                description: `${taskType.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())} phase`,
                taskType: taskType,
                targetModel: target,
                prompt: prompt,
                systemPrompt: SYSTEM_PROMPTS[taskType],
                dependencies: previousId ? [previousId] : []
            });

            previousId = taskId;
            taskId++;
        }

        return subtasks;
    }

    private createContextualPrompt(originalTask: string, taskType: TaskType): string {
        const prefix = PROMPT_PREFIXES[taskType] || "";
        return prefix + originalTask;
    }
}
