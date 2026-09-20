// POST { mission: { title, objective, completionCriteria[] }, answer }
//   -> { data: { status, criteria: [{ text, met, comment }], summary }, model }
//
// 디자인의 "AI가 완료 조건을 분석하고 있어요" 화면이 기다리는 응답입니다.
// 완료 여부는 Gemini가 조건별로 판정하고, 최종 status(completed/partial)는
// 조건 충족 개수로 코드가 결정합니다. 판정 근거는 화면과 DB에 함께 남깁니다.
import { guard, json, text } from "../_shared/http.ts";
import { generateJson, GeminiError } from "../_shared/gemini.ts";
import { classifySafety } from "../_shared/agent.ts";

type Evaluation = {
  criteria: Array<{ index: number; met: boolean; comment: string }>;
  summary: string;
};

const RESPONSE_SCHEMA = {
  type: "OBJECT",
  properties: {
    criteria: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          index: { type: "INTEGER" },
          met: { type: "BOOLEAN" },
          comment: { type: "STRING" },
        },
        required: ["index", "met", "comment"],
      },
    },
    summary: { type: "STRING" },
  },
  required: ["criteria", "summary"],
};

function buildPrompt(title: string, objective: string, criteria: string[], answer: string) {
  const numbered = criteria.map((item, i) => `${i}. ${item}`).join("\n");
  return `당신은 개인 성장 서비스 "채움"의 미션 완료 조건 판정기입니다.

미션: ${title}
목적: ${objective}
완료 조건:
${numbered}

사용자가 작성한 수행 내용:
"""
${answer}
"""

규칙:
- 각 완료 조건마다 사용자가 쓴 내용만 근거로 충족 여부를 판정합니다. 추측하지 않습니다.
- index는 위 완료 조건의 번호를 그대로 씁니다. 조건 ${criteria.length}개 모두에 대해 하나씩 답합니다.
- comment: 왜 그렇게 판정했는지 사용자에게 말하듯 한 문장. 충족했다면 어떤 부분이 근거인지,
  못 했다면 무엇을 더 쓰면 되는지 알려 줍니다.
- summary: 전체 결과를 격려하는 1~2문장. 사용자의 성격이나 능력을 평가하지 않고 행동만 언급합니다.
- 분량이 적어도 조건을 만족했다면 충족으로 봅니다. 완벽함을 요구하지 않습니다.
- 모든 문장은 한국어 존댓말입니다.`;
}

Deno.serve(async (req) => {
  const blocked = guard(req);
  if (blocked) return blocked;

  const body = await req.json().catch(() => null);
  const mission = body?.mission;
  const title = text(mission?.title);
  const objective = text(mission?.objective);
  const criteria: string[] = Array.isArray(mission?.completionCriteria)
    ? mission.completionCriteria.map(text).filter(Boolean)
    : [];
  const answer = text(body?.answer);

  if (!title || criteria.length === 0) {
    return json({ error: "mission.title and mission.completionCriteria are required" }, 400);
  }
  if (!answer) return json({ error: "answer is required" }, 400);

  const safety = classifySafety(answer);
  if (!safety.allowMission) {
    return json({ error: safety.message, safety }, 422);
  }

  try {
    const { data, model } = await generateJson<Evaluation>(
      buildPrompt(title, objective, criteria, answer),
      RESPONSE_SCHEMA,
      { temperature: 0.2 },
    );

    // 조건 순서는 우리가 보낸 배열이 기준입니다. 모델이 빠뜨린 조건은 미충족으로 둡니다.
    const byIndex = new Map<number, { met: boolean; comment: string }>();
    for (const item of data.criteria ?? []) {
      if (Number.isInteger(item?.index)) {
        byIndex.set(item.index, { met: item.met === true, comment: text(item.comment) });
      }
    }
    const results = criteria.map((criterion, index) => ({
      text: criterion,
      met: byIndex.get(index)?.met ?? false,
      comment: byIndex.get(index)?.comment ?? "작성한 내용에서 이 조건을 확인하지 못했어요.",
    }));

    // 조건을 전부 채웠을 때만 completed. 하나라도 남았으면 partial로 두고
    // 남은 조건은 다음 Mission에서 이어 갑니다.
    const metCount = results.filter((item) => item.met).length;
    const status = metCount === results.length ? "completed" : "partial";

    return json({
      data: {
        status,
        metCount,
        totalCount: results.length,
        criteria: results,
        summary: text(data.summary),
      },
      safety,
      model,
    });
  } catch (error) {
    if (error instanceof GeminiError) return json({ error: error.message }, error.status);
    throw error;
  }
});
