-- Chaeum backend schema (담당자: 신수아 — Supabase Auth/DB, Goal·Plan·Mission·Feedback, Trigger/Push, 실행 이력, Agent Event, 권한)

create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ── Goals ──────────────────────────────────────────────────────────────
create table public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  status text not null default 'active' check (status in ('active','completed','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index goals_user_id_idx on public.goals(user_id);

alter table public.goals enable row level security;

create policy "goals_select_own" on public.goals for select using (auth.uid() = user_id);
create policy "goals_insert_own" on public.goals for insert with check (auth.uid() = user_id);
create policy "goals_update_own" on public.goals for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "goals_delete_own" on public.goals for delete using (auth.uid() = user_id);

create trigger goals_set_updated_at before update on public.goals
  for each row execute function public.set_updated_at();

-- ── Plans ──────────────────────────────────────────────────────────────
create table public.plans (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references public.goals(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  start_date date,
  end_date date,
  status text not null default 'active' check (status in ('active','completed','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index plans_user_id_idx on public.plans(user_id);
create index plans_goal_id_idx on public.plans(goal_id);

alter table public.plans enable row level security;

create policy "plans_select_own" on public.plans for select using (auth.uid() = user_id);
create policy "plans_insert_own" on public.plans for insert with check (auth.uid() = user_id);
create policy "plans_update_own" on public.plans for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "plans_delete_own" on public.plans for delete using (auth.uid() = user_id);

create trigger plans_set_updated_at before update on public.plans
  for each row execute function public.set_updated_at();

-- ── Missions ───────────────────────────────────────────────────────────
create table public.missions (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid not null references public.plans(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  description text,
  scheduled_at timestamptz,
  status text not null default 'pending' check (status in ('pending','in_progress','completed','failed','cancelled')),
  push_sent boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index missions_user_id_idx on public.missions(user_id);
create index missions_plan_id_idx on public.missions(plan_id);
create index missions_scheduled_at_idx on public.missions(scheduled_at);

alter table public.missions enable row level security;

create policy "missions_select_own" on public.missions for select using (auth.uid() = user_id);
create policy "missions_insert_own" on public.missions for insert with check (auth.uid() = user_id);
create policy "missions_update_own" on public.missions for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "missions_delete_own" on public.missions for delete using (auth.uid() = user_id);

create trigger missions_set_updated_at before update on public.missions
  for each row execute function public.set_updated_at();

-- ── Feedbacks ──────────────────────────────────────────────────────────
create table public.feedbacks (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references public.missions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  content text,
  rating smallint check (rating between 1 and 5),
  created_at timestamptz not null default now()
);

create index feedbacks_user_id_idx on public.feedbacks(user_id);
create index feedbacks_mission_id_idx on public.feedbacks(mission_id);

alter table public.feedbacks enable row level security;

create policy "feedbacks_select_own" on public.feedbacks for select using (auth.uid() = user_id);
create policy "feedbacks_insert_own" on public.feedbacks for insert with check (auth.uid() = user_id);
create policy "feedbacks_update_own" on public.feedbacks for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "feedbacks_delete_own" on public.feedbacks for delete using (auth.uid() = user_id);

-- ── Push tokens ────────────────────────────────────────────────────────
create table public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null,
  platform text not null check (platform in ('ios','android')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, token)
);

create index push_tokens_user_id_idx on public.push_tokens(user_id);

alter table public.push_tokens enable row level security;

create policy "push_tokens_select_own" on public.push_tokens for select using (auth.uid() = user_id);
create policy "push_tokens_insert_own" on public.push_tokens for insert with check (auth.uid() = user_id);
create policy "push_tokens_update_own" on public.push_tokens for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "push_tokens_delete_own" on public.push_tokens for delete using (auth.uid() = user_id);

create trigger push_tokens_set_updated_at before update on public.push_tokens
  for each row execute function public.set_updated_at();

-- ── Mission triggers (예약된 푸시) ─────────────────────────────────────
create table public.mission_triggers (
  id uuid primary key default gen_random_uuid(),
  mission_id uuid not null references public.missions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  scheduled_at timestamptz not null,
  status text not null default 'scheduled' check (status in ('scheduled','sent','cancelled','failed')),
  attempted_at timestamptz,
  created_at timestamptz not null default now()
);

create index mission_triggers_user_id_idx on public.mission_triggers(user_id);
create index mission_triggers_due_idx on public.mission_triggers(status, scheduled_at);

alter table public.mission_triggers enable row level security;

create policy "mission_triggers_select_own" on public.mission_triggers for select using (auth.uid() = user_id);
create policy "mission_triggers_insert_own" on public.mission_triggers for insert with check (auth.uid() = user_id);
create policy "mission_triggers_update_own" on public.mission_triggers for update using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "mission_triggers_delete_own" on public.mission_triggers for delete using (auth.uid() = user_id);

-- ── Trigger executions (실행 이력) ─────────────────────────────────────
create table public.trigger_executions (
  id uuid primary key default gen_random_uuid(),
  trigger_id uuid not null references public.mission_triggers(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null check (status in ('sent','failed','skipped')),
  detail jsonb,
  created_at timestamptz not null default now()
);

create index trigger_executions_user_id_idx on public.trigger_executions(user_id);
create index trigger_executions_trigger_id_idx on public.trigger_executions(trigger_id);

alter table public.trigger_executions enable row level security;

create policy "trigger_executions_select_own" on public.trigger_executions for select using (auth.uid() = user_id);
-- inserts come only from the service role (dispatch-scheduled-triggers function), which bypasses RLS.

-- ── Agent events (Agent Controller 로그) ──────────────────────────────
create table public.agent_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  agent_type text not null,
  event_type text not null,
  payload jsonb,
  created_at timestamptz not null default now()
);

create index agent_events_user_id_idx on public.agent_events(user_id);
create index agent_events_created_at_idx on public.agent_events(created_at);

alter table public.agent_events enable row level security;

create policy "agent_events_select_own" on public.agent_events for select using (auth.uid() = user_id);
create policy "agent_events_insert_own" on public.agent_events for insert with check (auth.uid() = user_id);
-- the agent-event Edge Function also allows the service role (used by the Agent Controller) to insert on a user's behalf.
