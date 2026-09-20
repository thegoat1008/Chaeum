import { corsHeaders } from "../_shared/cors.ts";

const jsonHeaders = { ...corsHeaders, "Content-Type": "application/json" };

function response(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return response({ error: "Method Not Allowed" }, 405);

  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) return response({ error: "GEMINI_API_KEY is not configured" }, 500);

  const body = await req.json().catch(() => null);
  const weakness = body?.weakness?.toString().trim();
  const desiredChange = body?.desiredChange?.toString().trim();
  const period = body?.period?.toString().trim();
  if (!weakness || !desiredChange || !period) {
    return response({ error: "weakness, desiredChange and period are required" }, 400);
  }

  const prompt = `당신은 사용자가 작은 행동으로 목표를 달성하도록 돕는 코치입니다.
사용자의 단점: ${weakness}
원하는 변화: ${desiredChange}
도전 기간: ${period}

한국어로 현실적이고 부담이 적은 맞춤 목표를 만드세요.
- title: 한 문장의 구체적인 목표
- description: 목표 진행 방법을 설명하는 1~2문장
- steps: 바로 실행할 수 있는 2개의 단계
- 각 단계는 title과 description을 포함
- 의료 진단이나 위험한 조언은 하지 마세요.`;

  const model = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.5-flash";
  const geminiResponse = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: {
          temperature: 0.3,
          responseMimeType: "application/json",
          responseSchema: {
            type: "OBJECT",
            properties: {
              title: { type: "STRING" },
              description: { type: "STRING" },
              steps: {
                type: "ARRAY",
                minItems: 2,
                maxItems: 2,
                items: {
                  type: "OBJECT",
                  properties: {
                    title: { type: "STRING" },
                    description: { type: "STRING" },
                  },
                  required: ["title", "description"],
                },
              },
            },
            required: ["title", "description", "steps"],
          },
        },
      }),
    },
  );

  if (!geminiResponse.ok) {
    const detail = await geminiResponse.text();
    console.error("Gemini request failed", geminiResponse.status, detail);
    return response({ error: "Gemini request failed" }, 502);
  }

  const payload = await geminiResponse.json();
  const text = payload?.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) return response({ error: "Gemini returned an empty response" }, 502);

  try {
    return response({ data: JSON.parse(text), model });
  } catch {
    return response({ error: "Gemini returned invalid JSON" }, 502);
  }
});
