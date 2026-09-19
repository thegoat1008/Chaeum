import { DecisionType, FeedbackStatus } from "./domain.js";

function trailingCount(feedback, statuses) {
  let count = 0;
  for (let i = feedback.length - 1; i >= 0; i -= 1) {
    if (!statuses.has(feedback[i].status)) break;
    count += 1;
  }
  return count;
}

export function decideNextAction({ feedback = [], currentDurationMinutes = 10, currentStage = 1 }) {
  const recent = feedback.slice(-10);
  const missedCount = trailingCount(recent, new Set([FeedbackStatus.SKIPPED, FeedbackStatus.NO_RESPONSE]));
  const completedCount = trailingCount(recent, new Set([FeedbackStatus.COMPLETED]));

  if (missedCount >= 2) {
    const nextDuration = Math.max(2, Math.min(5, currentDurationMinutes - 2));
    return {
      type: DecisionType.REDUCE_DURATION,
      nextDurationMinutes: nextDuration,
      nextStage: currentStage,
      ruleCode: "TWO_CONSECUTIVE_MISSES",
      reason: `최근 건너뛰기·무응답이 ${missedCount}회 연속 확인되어 Mission 시간을 ${currentDurationMinutes}분에서 ${nextDuration}분으로 줄입니다.`,
    };
  }

  if (completedCount >= 2) {
    return {
      type: DecisionType.ADVANCE,
      nextDurationMinutes: Math.min(10, Math.max(5, currentDurationMinutes)),
      nextStage: currentStage + 1,
      ruleCode: "TWO_CONSECUTIVE_COMPLETIONS",
      reason: `동일 단계 Mission을 ${completedCount}회 연속 완료하여 다음 단계로 이동합니다.`,
    };
  }

  return {
    type: DecisionType.KEEP,
    nextDurationMinutes: Math.min(10, Math.max(5, currentDurationMinutes)),
    nextStage: currentStage,
    ruleCode: "INSUFFICIENT_PATTERN",
    reason: "전략을 바꿀 만큼 같은 결과가 반복되지 않아 현재 단계를 유지합니다.",
  };
}
