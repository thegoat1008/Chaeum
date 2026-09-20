export class GeminiClient {
  constructor({ apiKey, model = "gemini-2.5-flash", fetchImpl = globalThis.fetch } = {}) {
    this.apiKey = apiKey;
    this.model = model;
    this.fetch = fetchImpl;
  }

  async generateJson(prompt) {
    if (!this.apiKey) throw new Error("GEMINI_API_KEY가 설정되지 않았습니다.");
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(this.model)}:generateContent`;
    const response = await this.fetch(url, {
      method: "POST",
      headers: { "content-type": "application/json", "x-goog-api-key": this.apiKey },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: { responseMimeType: "application/json", temperature: 0.3 },
      }),
    });
    if (!response.ok) throw new Error(`Gemini 요청 실패: ${response.status}`);
    const payload = await response.json();
    const text = payload?.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) throw new Error("Gemini 응답에 JSON 텍스트가 없습니다.");
    return JSON.parse(text);
  }
}
