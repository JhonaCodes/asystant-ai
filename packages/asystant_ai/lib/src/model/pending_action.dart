import 'package:asystant_core/asystant_core.dart';
import 'package:collection/collection.dart';

import 'package:asystant_ai/src/model/asystant_action_policy.dart';

/// An ephemeral preview of one invocation; never serialized or persisted.
/// Approval applies only to this invocation, never to later calls.
class PendingAction {
  const PendingAction({
    required this.call,
    required this.card,
    this.selected = const [],
    this.requiresSelection = false,
    this.policy = const AsystantActionPolicy(requiresApproval: true),
  });

  final bool requiresSelection;

  final AsystantActionPolicy policy;

  final ToolCall call;

  final AssistantCard card;

  final List<String> selected;

  /// Authorize stays off until something is selected, when selection is required.
  bool get canApprove => !requiresSelection || selected.isNotEmpty;

  PendingAction copyWith({
    ToolCall? call,
    AssistantCard? card,
    List<String>? selected,
    bool? requiresSelection,
    AsystantActionPolicy? policy,
  }) => PendingAction(
    requiresSelection: requiresSelection ?? this.requiresSelection,
    call: call ?? this.call,
    card: card ?? this.card,
    selected: List.unmodifiable(selected ?? this.selected),
    policy: policy ?? this.policy,
  );

  @override
  bool operator ==(Object other) =>
      other is PendingAction &&
      requiresSelection == other.requiresSelection &&
      call == other.call &&
      card == other.card &&
      policy == other.policy &&
      const ListEquality<String>().equals(selected, other.selected);

  @override
  int get hashCode => Object.hash(
    requiresSelection,
    call,
    card,
    policy,
    const ListEquality<String>().hash(selected),
  );
}
