// POST { weakness, desiredChange, period }
//   -> { data: { title, description, durationDays, steps: [...] }, model }
//
// 화면 구성 3·4번(목표 구체화 → 계획·권한 승인)에 해당합니다.
// steps는 단순 설명이 아니라 실제로 예약할 Trigger 계획이라서,
// mission_triggers에 그대로 꽂을 수 있는 형태(triggerType/time/daysBefore)로 받습니다.
import { guard, json, text } from "../_shared/http.ts";
import { generateJson, GeminiError } from "../_shared/gemini.ts";
import { classifySafety } from "../_shared/agent.ts";

type GoalPlan = {
  title: string;
  description: string;
  durationDays: number;
  steps: Array<{
    title: string;
    description: string;
    triggerType: "deadline" | "daily" | "weekly";
    time: string;
    daysBefore: number;
  }>;
};

const RESPONSE_SCHEMA = {
  type: "OBJECT",
  properties: {
    title: { type: "STRING" },
    description: { type: "STRING" },
    durationDays: { type: "INTEGER" },
    steps: {
      type: "ARRAY",
      minItems: 2,
      maxItems: 2,
      items: {
        type: "OBJECT",
        properties: {
          title: { type: "STRING" },
          description: { type: "STRING" },
          triggerType: { type: "STRING", enum: ["deadline", "daily", "weekly"] },
          time: { type: "STRING" },
          daysBefore: { type: "INTEGER" },
        },
        required: ["title", "description", "triggerType", "time", "daysBefore"],
      },
    },
  },
  required: ["title", "description", "durationDays", "steps"],
};

function buildPrompt(weakness: string, desiredChange: string, period: string) {
  return `당신은 개인 성장 서비스 "채움"의 목표·알림 계획 설계자입니다.

사용자의 단점: ${weakness}
원하는 변화: ${desiredChange}
도전 기간: ${period}

규칙:
- 사용자가 직접 쓴 표현만 사용하고 성격·질환을 추측하거나 진단하지 않습니다.
- title: 관찰 가능한 한 문장 목표.
- description: 진행 방식을 설명하는 1~2문장.
- durationDays: "${period}"를 일 수로 환산한 정수(예: "1달 동안" -> 30, "2주" -> 14). 판단이 어려우면 30.
- steps: 이 목표를 위해 예약할 알림 계획 정확히 2개.
  - STEP 1은 마감·기한 기준 선제 알림(triggerType "deadline", daysBefore는 1 이상).
  - STEP 2는 매일 반복 알림(triggerType "daily", daysBefore 0).
  - title은 "마감 일주일 전 시작"처럼 계획을 요약한 8자 이상 15자 이하의 문구.
  - description은 "마감 일주일 전에 시작하도록 알려드릴게요"처럼 사용자에게 알림을 예고하는 존댓말 한 문장.
  - time은 24시간 "HH:MM" 형식. 사용자가 시간대를 말하지 않았다면 "18:00".
- 의료 진단이나 위험한 조언은 하지 않습니다.
- 모든 문장은 한국어 존댓말입니다.`;
}

Deno.serve(async (req) => {
  const blocked = guard(req);
  if (blocked) return blocked;

  const body = await req.json().catch(() => null);
  const weakness = text(body?.weakness);
  const desiredChange = text(body?.desiredChange);
  const period = text(body?.period);
  if (!weakness || !desiredChange || !period) {
    return json({ error: "weakness, desiredChange and period are required" }, 400);
  }

  // 안전 분기가 먼저입니다. 위기 신호가 있으면 Gemini를 호출하지 않고 안내로 끝냅니다.
  const safety = classifySafety(`${weakness} ${desiredChange} ${period}`);
  if (!safety.allowMission) {
    return json({ error: safety.message, safety }, 422);
  }

  try {
    const { data, model } = await generateJson<GoalPlan>(
      buildPrompt(weakness, desiredChange, period),
      RESPONSE_SCHEMA,
    );
    const durationDays = Number.isInteger(data.durationDays) && data.durationDays > 0
      ? Math.min(365, data.durationDays)
      : 30;
    return json({ data: { ...data, durationDays }, safety, model });
  } catch (error) {
    if (error instanceof GeminiError) return json({ error: error.message }, error.status);
    throw error;
  }
});
