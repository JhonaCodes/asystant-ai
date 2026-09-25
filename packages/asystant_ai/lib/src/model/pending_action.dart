import 'package:asystant_core/asystant_core.dart';
import 'package:collection/collection.dart';

/// A frozen preview of one invocation. Approval never applies to later calls.
class PendingAction {
  const PendingAction({
    required this.call,
    required this.card,
    this.selected = const [],
    this.requiresSelection = false,
  });
  final bool requiresSelection;
  final ToolCall call;
  final AssistantCard card;
  final List<String> selected;
  PendingAction copyWith({
    ToolCall? call,
    AssistantCard? card,
    List<String>? selected,
    bool? requiresSelection,
  }) => PendingAction(
    requiresSelection: requiresSelection ?? this.requiresSelection,
    call: call ?? this.call,
    card: card ?? this.card,
    selected: List.unmodifiable(selected ?? this.selected),
  );
  @override
  bool operator ==(Object other) =>
      other is PendingAction &&
      requiresSelection == other.requiresSelection &&
      call == other.call &&
      card == other.card &&
      const ListEquality<String>().equals(selected, other.selected);
  @override
  int get hashCode => Object.hash(
    requiresSelection,
    call,
    card,
    const ListEquality<String>().hash(selected),
  );
}
