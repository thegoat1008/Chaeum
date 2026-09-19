export const FeedbackStatus = Object.freeze({
  COMPLETED: "completed",
  PARTIAL: "partial",
  SKIPPED: "skipped",
  NO_RESPONSE: "no_response",
});

export const DecisionType = Object.freeze({
  KEEP: "keep",
  REDUCE_DURATION: "reduce_duration",
  ADVANCE: "advance",
  PAUSE_FOR_SAFETY: "pause_for_safety",
});

export const SafetyLevel = Object.freeze({
  SAFE: "safe",
  REVIEW: "review",
  CRISIS: "crisis",
});

export function assertGoal(goal) {
  if (!goal || typeof goal !== "object") throw new TypeError("goal이 필요합니다.");
  for (const key of ["id", "userId", "weakness", "desiredBehavior", "durationDays"]) {
    if (goal[key] === undefined || goal[key] === null || goal[key] === "") {
      throw new TypeError(`goal.${key}가 필요합니다.`);
    }
  }
  if (!Number.isInteger(goal.durationDays) || goal.durationDays < 1) {
    throw new TypeError("goal.durationDays는 1 이상의 정수여야 합니다.");
  }
  if (goal.confirmed !== true) {
    throw new Error("사용자가 직접 확인한 목표만 Agent에 위임할 수 있습니다.");
  }
}

export function assertMission(mission) {
  if (!mission.title || !mission.completionCriteria) {
    throw new Error("Mission에는 제목과 명확한 완료 조건이 필요합니다.");
  }
  if (!Number.isInteger(mission.durationMinutes) || mission.durationMinutes < 1 || mission.durationMinutes > 10) {
    throw new Error("Mission 수행 시간은 1~10분이어야 합니다.");
  }
}
