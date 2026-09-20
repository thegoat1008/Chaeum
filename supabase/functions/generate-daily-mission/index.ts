// POST { goal, dayIndex, previousMission?, recentFeedback?[] }
//   -> { data: Mission, decision, safety, model }
//
// Agent Loop의 "상태 확인 -> Rule-based Decision -> Mission 생성" 구간입니다.
// 수치 판단(시간·단계)은 Rule Engine이 코드로 내리고, Gemini는 그 결정을 문장으로
// 채우기만 합니다. 기능 정의서의 "LLM 후보 생성 후 규칙 검증" 원칙을 지키기 위해
// 생성 결과는 assertMission으로 다시 검증합니다.
import { guard, json, text } from "../_shared/http.ts";
import { generateJson, GeminiError } from "../_shared/gemini.ts";
import { applyDifficulty, classifySafety, decideNextAction, type Decision, type FeedbackEntry } from "../_shared/agent.ts";

type MissionContent = {
  title: string;
  emoji: string;
  objective: string;
  objectiveHighlight: string;
  completionCriteria: string[];
  hints: Array<{ title: string; subtext: string }>;
};

const RESPONSE_SCHEMA = {
  type: "OBJECT",
  properties: {
    title: { type: "STRING" },
    emoji: { type: "STRING", enum: ["🦀", "🐠", "🪼"] },
    objective: { type: "STRING" },
    objectiveHighlight: { type: "STRING" },
    completionCriteria: { type: "ARRAY", minItems: 2, maxItems: 3, items: { type: "STRING" } },
    hints: {
      type: "ARRAY",
      minItems: 3,
      maxItems: 3,
      items: {
        type: "OBJECT",
        properties: { title: { type: "STRING" }, subtext: { type: "STRING" } },
        required: ["title", "subtext"],
      },
    },
  },
  required: ["title", "emoji", "objective", "objectiveHighlight", "completionCriteria", "hints"],
};

function buildPrompt(
  goal: { title: string; weakness: string; desiredChange: string },
  decision: Decision,
  dayIndex: number,
  previousMission: unknown,
) {
  return `당신은 개인 성장 서비스 "채움"의 Mission 생성기입니다.

목표: ${JSON.stringify(goal)}
오늘은 도전 ${dayIndex}일차입니다.
규칙 엔진 판단: ${JSON.stringify(decision)}
어제 Mission: ${JSON.stringify(previousMission ?? null)}

규칙:
- 한 번에 행동 하나만 제안합니다. 여러 개를 묶지 않습니다.
- ${decision.nextDurationMinutes}분 안에 끝나야 합니다.
- 어제 Mission과 같은 행동을 반복하지 않습니다.
- 사용자가 직접 입력하지 않은 성격·감정·질환을 추측하지 않습니다.
- title: "프로젝트 브레인스토밍하기"처럼 동사로 끝나는 20자 이내의 행동 이름.
- emoji: 오늘 미션 분위기에 맞는 바다 생물 이모지 한 개. 반드시 🦀 🐠 🪼 중 하나만 씁니다.
  (앱이 이 값으로 피그마 일러스트를 고르므로 다른 이모지는 쓸 수 없습니다.)
- objective: 왜 이 행동을 하는지 설명하는 한 문장. 존댓말.
- objectiveHighlight: objective 안에 글자 그대로 들어 있는 핵심 어구. 반드시 objective의 부분 문자열이어야 합니다.
- completionCriteria: 관찰 가능한 완료 조건 3개. 각 조건은 개수나 분량이 드러나야 합니다(예: "아이디어 3개 이상 적기").
- hints: 막혔을 때 따라 할 순서 3단계.
  - title: 그 단계에서 할 일 한 문장.
  - subtext: 부담을 덜어 주는 한 문장. 덧붙일 말이 없으면 빈 문자열.
- 모든 문장은 한국어 존댓말입니다.`;
}

/** agent-core의 assertMission과 같은 역할. 규칙을 못 지킨 생성물은 여기서 걸러 냅니다. */
function validate(content: MissionContent): string | null {
  if (!text(content.title)) return "title이 비어 있습니다.";
  if (!text(content.objective)) return "objective가 비어 있습니다.";
  const criteria = (content.completionCriteria ?? []).map(text).filter(Boolean);
  if (criteria.length < 2) return "완료 조건이 2개 미만입니다.";
  return null;
}

Deno.serve(async (req) => {
  const blocked = guard(req);
  if (blocked) return blocked;

  const body = await req.json().catch(() => null);
  const goal = body?.goal;
  const goalTitle = text(goal?.title);
  const weakness = text(goal?.weakness);
  const desiredChange = text(goal?.desiredChange);
  if (!goalTitle && !desiredChange) {
    return json({ error: "goal.title or goal.desiredChange is required" }, 400);
  }

  const safety = classifySafety(`${goalTitle} ${weakness} ${desiredChange} ${text(body?.note)}`);
  if (!safety.allowMission) {
    return json({ error: safety.message, safety }, 422);
  }

  const dayIndex = Number.isInteger(body?.dayIndex) && body.dayIndex > 0 ? body.dayIndex : 1;
  const previousMission = body?.previousMission ?? null;
  const recentFeedback: FeedbackEntry[] = Array.isArray(body?.recentFeedback) ? body.recentFeedback : [];

  const decision = applyDifficulty(
    decideNextAction({
      feedback: recentFeedback,
      currentDurationMinutes: previousMission?.durationMinutes ?? 10,
      currentStage: previousMission?.stage ?? 1,
    }),
    recentFeedback.at(-1)?.difficulty,
  );

  try {
    const { data, model } = await generateJson<MissionContent>(
      buildPrompt({ title: goalTitle, weakness, desiredChange }, decision, dayIndex, previousMission),
      RESPONSE_SCHEMA,
      { temperature: 0.6 },
    );

    const invalid = validate(data);
    if (invalid) {
      console.error("Mission validation failed", invalid, data);
      return json({ error: `생성된 Mission이 규칙을 만족하지 못했어요. (${invalid})` }, 502);
    }

    // objectiveHighlight는 화면에서 부분 강조에 쓰이므로, 실제 부분 문자열일 때만 넘깁니다.
    const highlight = text(data.objectiveHighlight);
    const objective = text(data.objective);

    return json({
      data: {
        dayIndex,
        title: text(data.title),
        emoji: text(data.emoji) || "🐠",
        objective,
        objectiveHighlight: objective.includes(highlight) ? highlight : "",
        completionCriteria: data.completionCriteria.map(text).filter(Boolean),
        hints: (data.hints ?? []).map((hint) => ({
          title: text(hint.title),
          subtext: text(hint.subtext),
        })).filter((hint) => hint.title),
        durationMinutes: decision.nextDurationMinutes,
        stage: decision.nextStage,
      },
      decision,
      safety,
      model,
    });
  } catch (error) {
    if (error instanceof GeminiError) return json({ error: error.message }, error.status);
    throw error;
  }
});
