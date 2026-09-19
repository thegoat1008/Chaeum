import { randomUUID } from "node:crypto";
import { assertGoal, DecisionType } from "./domain.js";
import { classifySafety } from "./safety.js";
import { decideNextAction } from "./rule-engine.js";
import { generateMission } from "./mission-generator.js";

export class AgentController {
  constructor({ repository, llm = null, clock = () => new Date() }) {
    if (!repository) throw new TypeError("repository가 필요합니다.");
    this.repository = repository;
    this.llm = llm;
    this.clock = clock;
  }

  async run({ goalId }) {
    const goal = await this.repository.getGoal(goalId);
    assertGoal(goal);

    const safety = classifySafety(`${goal.weakness} ${goal.desiredBehavior} ${goal.notes ?? ""}`);
    if (!safety.allowMission) {
      const decision = {
        type: DecisionType.PAUSE_FOR_SAFETY,
        ruleCode: safety.reasonCode,
        reason: safety.message,
      };
      await this.#event(goalId, "safety_paused", { decision, safety });
      return { status: "paused_for_safety", decision, safety, mission: null };
    }

    if (goal.paused === true || goal.permission?.allowProactiveMission !== true) {
      throw new Error("목표가 일시정지되었거나 선제 Mission 권한이 승인되지 않았습니다.");
    }

    const feedback = await this.repository.listFeedback(goalId);
    const previousMission = await this.repository.getLatestMission(goalId);
    const decision = decideNextAction({
      feedback,
      currentDurationMinutes: previousMission?.durationMinutes ?? 10,
      currentStage: previousMission?.stage ?? 1,
    });
    const generated = await generateMission({ goal, decision, previousMission, llm: this.llm });
    const mission = {
      id: randomUUID(),
      goalId,
      ...generated,
      status: "scheduled",
      decisionReason: decision.reason,
      ruleCode: decision.ruleCode,
      createdAt: this.clock().toISOString(),
    };
    await this.repository.saveMission(mission);
    await this.#event(goalId, "decision_made", { decision });
    await this.#event(goalId, "mission_created", { missionId: mission.id, decisionReason: decision.reason });
    return { status: "mission_created", decision, safety, mission };
  }

  async recordFeedback({ goalId, missionId, status, reason = null, note = null }) {
    const allowed = new Set(["completed", "partial", "skipped", "no_response"]);
    if (!allowed.has(status)) throw new TypeError("지원하지 않는 Feedback 상태입니다.");
    const feedback = {
      id: randomUUID(), goalId, missionId, status, reason, note,
      createdAt: this.clock().toISOString(),
    };
    await this.repository.addFeedback(feedback);
    await this.#event(goalId, "feedback_recorded", { feedbackId: feedback.id, missionId, status, reason });
    return feedback;
  }

  async #event(goalId, type, payload) {
    return this.repository.appendEvent({
      id: randomUUID(), goalId, type, payload, createdAt: this.clock().toISOString(),
    });
  }
}
