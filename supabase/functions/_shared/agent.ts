// Agent Core의 Rule Engine·안전 분기를 Edge Function에서 그대로 쓰기 위한 포팅본입니다.
// agent-core/src/{domain,rule-engine,safety}.js와 판단 기준이 동일해야 하므로
// 한쪽을 고치면 반드시 다른 쪽도 함께 고쳐 주세요.

export const FeedbackStatus = {
  COMPLETED: "completed",
  PARTIAL: "partial",
  SKIPPED: "skipped",
  NO_RESPONSE: "no_response",
} as const;

export const DecisionType = {
  KEEP: "keep",
  REDUCE_DURATION: "reduce_duration",
  ADVANCE: "advance",
  PAUSE_FOR_SAFETY: "pause_for_safety",
} as const;

export const SafetyLevel = {
  SAFE: "safe",
  REVIEW: "review",
  CRISIS: "crisis",
} as const;

export type FeedbackEntry = {
  status: string;
  reason?: string | null;
  difficulty?: string | null;
};

export type Decision = {
  type: string;
  nextDurationMinutes: number;
  nextStage: number;
  ruleCode: string;
  reason: string;
};

function trailingCount(feedback: FeedbackEntry[], statuses: Set<string>) {
  let count = 0;
  for (let i = feedback.length - 1; i >= 0; i -= 1) {
    if (!statuses.has(feedback[i].status)) break;
    count += 1;
  }
  return count;
}

/** 기능 정의서 "Rule-based Decision": 건너뛰기·무응답 2회 → 축소, 완료 2회 → 다음 단계. */
export function decideNextAction({
  feedback = [],
  currentDurationMinutes = 10,
  currentStage = 1,
}: {
  feedback?: FeedbackEntry[];
  currentDurationMinutes?: number;
  currentStage?: number;
}): Decision {
  const recent = feedback.slice(-10);
  const missedCount = trailingCount(
    recent,
    new Set<string>([FeedbackStatus.SKIPPED, FeedbackStatus.NO_RESPONSE]),
  );
  const completedCount = trailingCount(recent, new Set<string>([FeedbackStatus.COMPLETED]));

  if (missedCount >= 2) {
    const nextDuration = Math.max(2, Math.min(5, currentDurationMinutes - 2));
    return {
      type: DecisionType.REDUCE_DURATION,
      nextDurationMinutes: nextDuration,
      nextStage: currentStage,
      ruleCode: "TWO_CONSECUTIVE_MISSES",
      reason:
        `최근 건너뛰기·무응답이 ${missedCount}회 연속 확인되어 Mission 시간을 ` +
        `${currentDurationMinutes}분에서 ${nextDuration}분으로 줄입니다.`,
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

/** 난이도 피드백은 다음 Mission의 분량을 한 단계씩만 움직입니다. */
export function applyDifficulty(decision: Decision, difficulty?: string | null): Decision {
  if (difficulty === "hard") {
    return {
      ...decision,
      nextDurationMinutes: Math.max(2, decision.nextDurationMinutes - 2),
      ruleCode: `${decision.ruleCode}+DIFFICULTY_HARD`,
      reason: `${decision.reason} 직전 미션이 어려웠다는 피드백을 반영해 분량을 한 단계 줄입니다.`,
    };
  }
  if (difficulty === "easy") {
    return {
      ...decision,
      nextDurationMinutes: Math.min(10, decision.nextDurationMinutes + 2),
      ruleCode: `${decision.ruleCode}+DIFFICULTY_EASY`,
      reason: `${decision.reason} 직전 미션이 쉬웠다는 피드백을 반영해 분량을 한 단계 늘립니다.`,
    };
  }
  return decision;
}

const CRISIS_PATTERNS = [
  /자살|자해|죽고\s*싶|목숨을\s*끊/i,
  /suicid|self[- ]?harm|kill myself/i,
];

const DIAGNOSIS_PATTERNS = [
  /진단해|병명|우울증인지|adhd인지|정신병인지/i,
  /diagnose me|do i have (?:depression|adhd)/i,
];

export type SafetyResult = {
  level: string;
  reasonCode: string;
  allowMission: boolean;
  message?: string;
};

/** 기능 정의서 "안전 분기". 운영에서는 최신 공식 위기지원 정보로 문구를 교체해야 합니다. */
export function classifySafety(text: unknown): SafetyResult {
  const normalized = String(text ?? "").trim();
  if (CRISIS_PATTERNS.some((pattern) => pattern.test(normalized))) {
    return {
      level: SafetyLevel.CRISIS,
      reasonCode: "CRISIS_LANGUAGE_DETECTED",
      allowMission: false,
      message:
        "지금은 일반 Mission보다 안전이 우선입니다. 즉시 주변의 믿을 수 있는 사람이나 " +
        "지역의 긴급·전문 지원 기관에 도움을 요청해 주세요.",
    };
  }
  if (DIAGNOSIS_PATTERNS.some((pattern) => pattern.test(normalized))) {
    return {
      level: SafetyLevel.REVIEW,
      reasonCode: "DIAGNOSIS_REQUEST_DETECTED",
      allowMission: false,
      message:
        "채움은 정신건강이나 성격을 진단하지 않습니다. 진단이 필요하다면 자격을 갖춘 " +
        "전문가와 상담해 주세요.",
    };
  }
  return { level: SafetyLevel.SAFE, reasonCode: "NO_SAFETY_SIGNAL", allowMission: true };
}
