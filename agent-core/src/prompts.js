export function buildGoalStructurePrompt(input) {
  return `당신은 개인 성장 서비스 채움의 목표 구조화 도우미다.
사용자가 직접 말한 내용만 사용하며 단점, 성격, 질환을 추측하거나 진단하지 않는다.
다음 JSON 스키마만 출력한다:
{"weakness":"string","desiredBehavior":"string","successCriteria":"string","durationDays":number,"needsClarification":boolean,"clarifyingQuestion":"string|null"}
구체성이 부족하면 시점·빈도·완료 조건 중 가장 중요한 한 가지만 질문한다.

사용자 입력:
${JSON.stringify(input)}`;
}

export function buildMissionPrompt({ goal, decision, previousMission }) {
  return `당신은 개인 성장 서비스 채움의 Mission 생성기다.
규칙:
- 한 번에 행동 하나만 제안한다.
- ${decision.nextDurationMinutes}분 이내에 끝나야 한다.
- 완료 조건은 관찰 가능해야 한다.
- 사용자가 직접 입력하지 않은 성격이나 감정을 추측하지 않는다.
- JSON만 출력한다: {"title":"string","description":"string","completionCriteria":"string"}

목표: ${JSON.stringify({ weakness: goal.weakness, desiredBehavior: goal.desiredBehavior })}
규칙 판단: ${JSON.stringify(decision)}
이전 Mission: ${JSON.stringify(previousMission ?? null)}`;
}
