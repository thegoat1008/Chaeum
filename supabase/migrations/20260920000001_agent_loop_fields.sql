-- Agent Loop(목표 위임 -> Mission -> Feedback -> 재계획)가 실제로 돌려면 필요한 컬럼들.
-- 20260919000001_init_schema.sql의 테이블 구조는 그대로 두고 확장만 합니다.

-- ── Goals: 사용자가 직접 입력한 원문과 기간 ────────────────────────────
-- "AI가 단점을 추측하지 않는다"는 원칙 때문에 사용자의 표현을 그대로 보관합니다.
alter table public.goals
  add column if not exists weakness text,
  add column if not exists desired_change text,
  add column if not exists period_text text,
  add column if not exists duration_days integer check (duration_days is null or duration_days > 0),
  add column if not exists started_on date not null default current_date,
  add column if not exists paused boolean not null default false,
  -- 계획·권한 승인 화면에서 사용자가 켠 항목만 들어갑니다. 기본값은 아무 권한도 없는 상태.
  add column if not exists permissions jsonb not null default '{}'::jsonb;

-- ── Missions: Rule Engine 판단 결과와 Mission 카드 본문 ────────────────
alter table public.missions
  add column if not exists day_index integer,
  add column if not exists emoji text,
  add column if not exists objective text,
  add column if not exists objective_highlight text,
  add column if not exists completion_criteria jsonb not null default '[]'::jsonb,
  add column if not exists hints jsonb not null default '[]'::jsonb,
  add column if not exists duration_minutes integer
    check (duration_minutes is null or duration_minutes between 1 and 10),
  add column if not exists stage integer not null default 1,
  add column if not exists rule_code text,
  add column if not exists decision_reason text,
  add column if not exists source text not null default 'gemini',
  -- 사용자가 제출한 수행 내용과 완료 조건 판정 결과(evaluate-mission 응답).
  add column if not exists answer text,
  add column if not exists evaluation jsonb;

-- 하루에 목표당 Mission 하나. 재생성은 같은 행을 덮어씁니다.
create unique index if not exists missions_plan_day_idx
  on public.missions(plan_id, day_index)
  where day_index is not null;

-- ── Feedbacks: 난이도와 선택형 이유 ────────────────────────────────────
alter table public.feedbacks
  add column if not exists status text
    check (status is null or status in ('completed','partial','skipped','no_response')),
  add column if not exists difficulty text
    check (difficulty is null or difficulty in ('hard','normal','easy')),
  -- 디자인의 이유 칩은 복수 선택이라 배열로 저장합니다.
  add column if not exists reasons jsonb not null default '[]'::jsonb;

create index if not exists feedbacks_created_at_idx on public.feedbacks(created_at);

-- ── Agent events: 활동 이력 화면이 최신순으로 읽습니다 ─────────────────
create index if not exists agent_events_user_created_idx
  on public.agent_events(user_id, created_at desc);
