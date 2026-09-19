export class InMemoryAgentRepository {
  constructor() {
    this.goals = new Map();
    this.feedback = new Map();
    this.missions = new Map();
    this.events = [];
  }

  async saveGoal(goal) { this.goals.set(goal.id, structuredClone(goal)); return goal; }
  async getGoal(goalId) { return structuredClone(this.goals.get(goalId) ?? null); }
  async listFeedback(goalId) { return structuredClone(this.feedback.get(goalId) ?? []); }
  async addFeedback(item) {
    const list = this.feedback.get(item.goalId) ?? [];
    list.push(structuredClone(item));
    this.feedback.set(item.goalId, list);
    return item;
  }
  async getLatestMission(goalId) { return structuredClone(this.missions.get(goalId) ?? null); }
  async saveMission(mission) { this.missions.set(mission.goalId, structuredClone(mission)); return mission; }
  async appendEvent(event) { this.events.push(structuredClone(event)); return event; }
  async listEvents(goalId) { return structuredClone(this.events.filter((event) => event.goalId === goalId)); }
}
