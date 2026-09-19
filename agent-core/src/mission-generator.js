import { assertMission } from "./domain.js";
import { buildMissionPrompt } from "./prompts.js";

function fallbackMission({ goal, decision }) {
  const minutes = decision.nextDurationMinutes;
  return {
    title: `${minutes}분만 첫 단계 실행`,
    description: `타이머를 ${minutes}분으로 맞추고 ${goal.desiredBehavior}의 첫 단계 하나만 실행하세요.`,
    completionCriteria: `${minutes}분 동안 첫 단계 한 가지를 실행하고 결과를 기록하면 완료`,
  };
}

export async function generateMission({ goal, decision, previousMission, llm }) {
  let content;
  let source = "rule_fallback";
  if (llm) {
    try {
      content = await llm.generateJson(buildMissionPrompt({ goal, decision, previousMission }));
      source = "gemini";
    } catch {
      content = fallbackMission({ goal, decision });
    }
  } else {
    content = fallbackMission({ goal, decision });
  }

  const mission = {
    ...content,
    durationMinutes: decision.nextDurationMinutes,
    stage: decision.nextStage,
    source,
  };
  assertMission(mission);
  return mission;
}
