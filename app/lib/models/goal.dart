class GoalDraft {
  final String weakness;
  final String desiredChange;
  final String period;

  const GoalDraft({required this.weakness, required this.desiredChange, required this.period});
}

class GeneratedGoal {
  final String title;
  final String description;
  final List<GoalStep> steps;

  const GeneratedGoal({required this.title, required this.description, required this.steps});
}

class GoalStep {
  final String title;
  final String description;

  const GoalStep({required this.title, required this.description});
}
