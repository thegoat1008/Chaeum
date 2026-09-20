# 채움 (Chaeum)

사용자가 직접 입력한 단점을 바탕으로, Agent Controller가 목표·상태·결과를 보고
다음 행동을 선택·실행·재계획하는 개인 성장 앱입니다.

```
app/          Flutter 모바일 앱          (김지우)
supabase/     DB 스키마 · Edge Functions (신수아)
agent-core/   Rule Engine · 안전 분기    (김희성)
```

## Agent Loop

```
목표 위임 ──▶ generate-mission        목표 + 알림 계획(Trigger) 생성
             │
             ▼
상태 확인 ──▶ generate-daily-mission   Rule Engine이 시간·단계 결정
             │                        → Gemini가 미션 문장 작성 → 규칙 재검증
             ▼
   실행  ──▶ evaluate-mission          사용자가 쓴 내용으로 완료 조건 판정
             │
             ▼
 피드백  ──▶ 난이도 + 이유             다음 generate-daily-mission 요청에 실려
             │                        Rule Engine의 판단 근거가 됨
             └──────────────▶ (재계획)
```

수치 판단(미션 시간·단계)은 **항상 코드**가 내립니다. Gemini는 그 결정을 문장으로
채우기만 하고, 결과는 다시 규칙으로 검증합니다.

| 규칙 | 조건 | 결과 |
|---|---|---|
| `TWO_CONSECUTIVE_MISSES` | 건너뛰기·무응답 2회 연속 | 미션 시간 축소 (최소 2분) |
| `TWO_CONSECUTIVE_COMPLETIONS` | 완료 2회 연속 | 다음 단계로 이동 |
| `INSUFFICIENT_PATTERN` | 그 외 | 현재 단계 유지 |
| `+DIFFICULTY_HARD/EASY` | 난이도 피드백 | 분량 한 단계 조정 |

규칙은 `agent-core/src/rule-engine.js`와 `supabase/functions/_shared/agent.ts`에
같은 내용으로 존재합니다. **한쪽을 고치면 반드시 다른 쪽도 함께 고쳐 주세요.**

## Edge Functions

| 함수 | 입력 | 출력 |
|---|---|---|
| `generate-mission` | `{ weakness, desiredChange, period }` | 목표 + `steps[]` (예약할 Trigger 계획) |
| `generate-daily-mission` | `{ goal, dayIndex, previousMission?, recentFeedback[] }` | 미션 카드 + `decision` |
| `evaluate-mission` | `{ mission, answer }` | 조건별 충족 여부 + 요약 |
| `push-token` | `{ token, platform }` | 디바이스 토큰 등록/삭제 |
| `cancel-trigger` | `{ trigger_id }` | 예약 알림 취소 |
| `agent-event` | `{ agent_type, event_type, payload }` | 활동 이력 적재 |
| `dispatch-scheduled-triggers` | (pg_cron 전용) | 예약된 FCM 푸시 발송 |

세 개의 Gemini 함수는 모두 **안전 분기를 Gemini 호출보다 먼저** 실행합니다.
위기 신호나 진단 요청이 감지되면 `422`와 안내 문구를 돌려주고, 앱은 재시도 버튼
대신 안내만 보여 줍니다.

## 실행

### 앱만 (백엔드 없이)

Supabase 설정이 없으면 각 Repository가 Mock 구현으로 떨어져서 온보딩부터
미션·피드백까지 전체 흐름을 그대로 확인할 수 있습니다.

```bash
cd app
flutter run
```

### 백엔드 연결

```bash
cd app
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key>
```

Google 로그인을 쓸 때는 `GOOGLE_WEB_CLIENT_ID` / `GOOGLE_SERVER_CLIENT_ID`도
같은 방식으로 넘깁니다.

### 배포

```bash
supabase link --project-ref <project-ref>
supabase db push
supabase secrets set --env-file .env      # GEMINI_API_KEY 등
supabase functions deploy generate-mission
supabase functions deploy generate-daily-mission
supabase functions deploy evaluate-mission
```

`GEMINI_API_KEY`는 Edge Function secret으로만 설정합니다. 앱이나 저장소에는
절대 넣지 않습니다. 값은 `.env.example`을 참고하세요.

## 테스트

```bash
cd app         && flutter test    # 세션 상태 · 미션 흐름 · 이유 칩
cd agent-core  && npm test        # Rule Engine · 안전 분기 · Agent Loop
```

## 개발 원칙

1. AI가 단점을 추측하지 않습니다. 사용자가 직접 입력·확정한 목표만 다룹니다.
2. 한 번에 하나의 행동, 기본 5~10분.
3. 행동하거나 계획을 바꿀 때 목표·최근 결과·적용 규칙을 함께 저장하고 보여 줍니다.
4. 실패해도 같은 알림을 반복하지 않고 난이도·시간·빈도·표현 중 하나를 바꿉니다.
5. 승인되지 않은 데이터 접근이나 푸시를 실행하지 않습니다.
6. 정신건강 진단·성격 판정을 하지 않고, 위기 신호가 있으면 전문 지원 안내를 우선합니다.
