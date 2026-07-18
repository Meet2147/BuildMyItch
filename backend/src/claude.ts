import Anthropic from "@anthropic-ai/sdk";

const rawKey = process.env.ANTHROPIC_API_KEY?.trim();
// Ignore the placeholder shipped in .env.example so a forgotten key surfaces clearly.
const apiKey = rawKey && rawKey.startsWith("sk-ant-") && !rawKey.includes("your-key") ? rawKey : undefined;
export const claudeReady = Boolean(apiKey);

const client = apiKey ? new Anthropic({ apiKey }) : null;

const MODEL = "claude-opus-4-8";

export class ClaudeNotConfigured extends Error {
  constructor() {
    super("The Claude API key is not set. Add ANTHROPIC_API_KEY to backend/.env");
    this.name = "ClaudeNotConfigured";
  }
}

/**
 * Ask Claude for a single JSON object matching the caller's shape.
 * Uses structured outputs so the response is always valid JSON.
 */
export async function askJSON(opts: {
  system: string;
  prompt: string;
  schema: Record<string, unknown>;
  maxTokens?: number;
}): Promise<any> {
  if (!client) throw new ClaudeNotConfigured();
  const res = await client.messages.create({
    model: MODEL,
    max_tokens: opts.maxTokens ?? 8000,
    thinking: { type: "adaptive" },
    output_config: { effort: "high", format: { type: "json_schema", schema: opts.schema } },
    system: opts.system,
    messages: [{ role: "user", content: opts.prompt }],
  } as any);
  const text = (res.content.find((b: any) => b.type === "text") as any)?.text ?? "{}";
  return JSON.parse(text);
}

/** Ask Claude for a short plain-text answer. */
export async function askText(opts: {
  system: string;
  prompt: string;
  maxTokens?: number;
}): Promise<string> {
  if (!client) throw new ClaudeNotConfigured();
  const res = await client.messages.create({
    model: MODEL,
    max_tokens: opts.maxTokens ?? 1500,
    thinking: { type: "adaptive" },
    output_config: { effort: "medium" },
    system: opts.system,
    messages: [{ role: "user", content: opts.prompt }],
  } as any);
  return (res.content.find((b: any) => b.type === "text") as any)?.text ?? "";
}
