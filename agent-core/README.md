# 채움 Agent Core

Google Sheets의 `채움 아이디어 총정리`, `기능 정의서`, `화면 구성`, `3인 개발 분담`을 기준으로 구현한 김희성 담당 MVP입니다.

## 구현 범위

- 사용자가 직접 승인한 목표만 처리
- 최근 결과를 이용한 Rule Engine
  - 건너뛰기·무응답 2회 연속: Mission 시간 축소
  - 완료 2회 연속: 다음 단계 이동
- 한 번에 하나, 최대 10분인 Mission 생성
- Gemini JSON 프롬프트와 실패 시 규칙 기반 폴백
- 판단 근거 및 Agent Event 저장
- 위기 표현·진단 요청 안전 분기
- 전체 Agent Loop 통합 테스트

## 실행

```bash
npm test
npm run demo
```

Node.js 20 이상이면 별도 패키지 설치 없이 실행됩니다.

## 백엔드 연결 계약

`AgentController`가 요구하는 repository 메서드는 다음과 같습니다. Supabase 구현체에서 동일 인터페이스를 제공하면 교체할 수 있습니다.

```js
getGoal(goalId)
listFeedback(goalId)
getLatestMission(goalId)
saveMission(mission)
addFeedback(feedback)
appendEvent(event)
```

권장 테이블은 `goals`, `missions`, `feedback`, `agent_events`입니다. 화면에서는 `run()` 응답의 `mission`, `decision.reason`, `decision.ruleCode`를 Mission 및 재계획 카드에 표시하면 됩니다.

## Gemini 연결

```js
import { AgentController, GeminiClient } from "./src/index.js";

const llm = new GeminiClient({ apiKey: process.env.GEMINI_API_KEY });
const agent = new AgentController({ repository, llm });
```

API 키는 반드시 서버 환경 변수로만 관리합니다. 안전 분기의 위기지원 문구와 연락처는 배포 지역의 최신 공식 자료로 교체해야 합니다.
