import test from "node:test";
import assert from "node:assert/strict";
import { AgentController, InMemoryAgentRepository } from "../src/index.js";

const goal = {
  id: "goal-1",
  userId: "user-1",
  weakness: "과제를 미루는 습관",
  desiredBehavior: "마감 전에 과제를 시작하기",
  durationDays: 14,
  confirmed: true,
  paused: false,
  permission: { allowProactiveMission: true },
};

test("피드백 결과에 따라 실제 다음 Mission이 작아지고 근거가 저장된다", async () => {
  const repository = new InMemoryAgentRepository();
  await repository.saveGoal(goal);
  const agent = new AgentController({ repository, clock: () => new Date("2026-09-19T00:00:00Z") });

  const first = await agent.run({ goalId: goal.id });
  await agent.recordFeedback({ goalId: goal.id, missionId: first.mission.id, status: "skipped" });
  const second = await agent.run({ goalId: goal.id });
  await agent.recordFeedback({ goalId: goal.id, missionId: second.mission.id, status: "no_response" });
  const third = await agent.run({ goalId: goal.id });

  assert.equal(first.mission.durationMinutes, 10);
  assert.equal(third.mission.durationMinutes, 5);
  assert.equal(third.mission.ruleCode, "TWO_CONSECUTIVE_MISSES");
  assert.match(third.mission.decisionReason, /2회 연속/);
  assert.equal((await repository.listEvents(goal.id)).at(-1).type, "mission_created");
});

test("위기 신호가 있으면 일반 Mission을 생성하지 않는다", async () => {
  const repository = new InMemoryAgentRepository();
  await repository.saveGoal({ ...goal, id: "unsafe", notes: "죽고 싶다는 생각이 든다" });
  const agent = new AgentController({ repository });
  const result = await agent.run({ goalId: "unsafe" });
  assert.equal(result.status, "paused_for_safety");
  assert.equal(result.mission, null);
});

test("승인되지 않은 목표는 실행하지 않는다", async () => {
  const repository = new InMemoryAgentRepository();
  await repository.saveGoal({ ...goal, id: "unconfirmed", confirmed: false });
  const agent = new AgentController({ repository });
  await assert.rejects(() => agent.run({ goalId: "unconfirmed" }), /직접 확인한 목표/);
});
