/// Ephemeral execution trace; never persisted or sent as model reasoning.
class AssistantStep {
  const AssistantStep({
    required this.id,
    required this.title,
    this.phase = .preparing,
  });

  final String id;

  final String title;

  final StepPhase phase;

  AssistantStep copyWith({String? id, String? title, StepPhase? phase}) =>
      AssistantStep(
        id: id ?? this.id,
        title: title ?? this.title,
        phase: phase ?? this.phase,
      );

  bool get active => switch (phase) {
    StepPhase.preparing || StepPhase.permission || StepPhase.running => true,
    StepPhase.completed ||
    StepPhase.declined ||
    StepPhase.canceled ||
    StepPhase.failed => false,
  };

  /// Finished without doing what it set out to do.
  bool get hasIssue => switch (phase) {
    StepPhase.declined || StepPhase.canceled || StepPhase.failed => true,
    StepPhase.preparing ||
    StepPhase.permission ||
    StepPhase.running ||
    StepPhase.completed => false,
  };

  StepOutcome get outcome => switch (this) {
    AssistantStep(active: true) => StepOutcome.running,
    AssistantStep(hasIssue: true) => StepOutcome.issue,
    _ => StepOutcome.done,
  };

  @override
  bool operator ==(Object other) =>
      other is AssistantStep &&
      id == other.id &&
      title == other.title &&
      phase == other.phase;

  @override
  int get hashCode => Object.hash(id, title, phase);
}

/// The execution or permission state of a displayed local-tool step.
enum StepPhase {
  preparing,
  permission,
  running,
  completed,
  declined,
  canceled,
  failed,
}

/// How a step looks at a glance: still going, done, or with an issue.
enum StepOutcome { running, done, issue }
