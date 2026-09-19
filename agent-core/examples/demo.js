import { AgentController, InMemoryAgentRepository } from "../src/index.js";

const repository = new InMemoryAgentRepository();
await repository.saveGoal({
  id: "demo-goal",
  userId: "demo-user",
  weakness: "과제를 미루는 습관",
  desiredBehavior: "마감 이틀 전에 과제를 시작하기",
  durationDays: 14,
  confirmed: true,
  permission: { allowProactiveMission: true },
});

const agent = new AgentController({ repository });
let result = await agent.run({ goalId: "demo-goal" });
console.log("첫 Mission", result);
await agent.recordFeedback({ goalId: "demo-goal", missionId: result.mission.id, status: "skipped" });
result = await agent.run({ goalId: "demo-goal" });
await agent.recordFeedback({ goalId: "demo-goal", missionId: result.mission.id, status: "no_response" });
result = await agent.run({ goalId: "demo-goal" });
console.log("재계획된 Mission", result);
