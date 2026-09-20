// Gemini 호출 공통 래퍼. API 키는 Edge Function secret으로만 주입하고
// 클라이언트나 저장소에는 절대 넣지 않습니다.

export class GeminiError extends Error {
  constructor(message: string, readonly status: number) {
    super(message);
    this.name = "GeminiError";
  }
}

const DEFAULT_MODEL = "gemini-2.5-flash";

export function geminiModel(): string {
  return Deno.env.get("GEMINI_MODEL") ?? DEFAULT_MODEL;
}

/**
 * responseSchema를 강제해 JSON만 돌려받습니다.
 * 스키마를 벗어난 응답은 파싱 단계에서 502로 떨어집니다.
 */
export async function generateJson<T>(
  prompt: string,
  responseSchema: Record<string, unknown>,
  { temperature = 0.3 }: { temperature?: number } = {},
): Promise<{ data: T; model: string }> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) throw new GeminiError("GEMINI_API_KEY is not configured", 500);

  const model = geminiModel();
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: {
          temperature,
          responseMimeType: "application/json",
          responseSchema,
        },
      }),
    },
  );

  if (!res.ok) {
    console.error("Gemini request failed", res.status, await res.text());
    throw new GeminiError("Gemini request failed", 502);
  }

  const payload = await res.json();
  const text = payload?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) throw new GeminiError("Gemini returned an empty response", 502);

  try {
    return { data: JSON.parse(text) as T, model };
  } catch {
    throw new GeminiError("Gemini returned invalid JSON", 502);
  }
}
