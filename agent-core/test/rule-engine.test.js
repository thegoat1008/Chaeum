import test from "node:test";
import assert from "node:assert/strict";
import { decideNextAction, DecisionType } from "../src/index.js";

test("건너뛰기·무응답 2회 연속이면 시간을 줄인다", () => {
  const decision = decideNextAction({
    feedback: [{ status: "skipped" }, { status: "no_response" }],
    currentDurationMinutes: 10,
    currentStage: 1,
  });
  assert.equal(decision.type, DecisionType.REDUCE_DURATION);
  assert.equal(decision.nextDurationMinutes, 5);
  assert.equal(decision.ruleCode, "TWO_CONSECUTIVE_MISSES");
});

test("완료 2회 연속이면 다음 단계로 이동한다", () => {
  const decision = decideNextAction({
    feedback: [{ status: "completed" }, { status: "completed" }],
    currentDurationMinutes: 5,
    currentStage: 2,
  });
  assert.equal(decision.type, DecisionType.ADVANCE);
  assert.equal(decision.nextStage, 3);
});

test("연속 결과가 아니면 현재 전략을 유지한다", () => {
  const decision = decideNextAction({
    feedback: [{ status: "skipped" }, { status: "completed" }],
    currentDurationMinutes: 7,
    currentStage: 1,
  });
  assert.equal(decision.type, DecisionType.KEEP);
  assert.equal(decision.nextDurationMinutes, 7);
});
