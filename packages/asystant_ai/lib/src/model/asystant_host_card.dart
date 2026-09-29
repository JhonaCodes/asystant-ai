import 'package:asystant_core/asystant_core.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'package:asystant_ai/src/model/asystant_card_action.dart';

/// A card the host pins at the end of the conversation, with its own
/// buttons: a decision the host's workflow waits for, or a notice about the
/// app's state.
///
/// It reflects host state, not the conversation: it is not stored with the
/// conversation and never reaches the model. The host rebuilds the chat with
/// the cards that apply now, so a decision taken elsewhere in the app
/// removes its card here too.
///
/// ```dart
/// AsystantHostCard(
///   card: AssistantCard(title: 'Publish the draft', kind: .permission),
///   actions: [
///     AsystantCardAction(label: 'Publish', onPressed: publish, isPrimary: true),
///     AsystantCardAction(label: 'Keep editing', onPressed: keepEditing),
///   ],
/// )
/// ```
@immutable
class AsystantHostCard {
  const AsystantHostCard({required this.card, this.actions = const []});

  /// What the card says: title, body and optional chart.
  final AssistantCard card;

  /// Its buttons, in order; none for a notice.
  final List<AsystantCardAction> actions;

  /// Whether a button can be pressed now, so the card waits for the person.
  bool get awaitsDecision => actions.any((action) => action.onPressed != null);

  AsystantHostCard copyWith({
    AssistantCard? card,
    List<AsystantCardAction>? actions,
  }) => AsystantHostCard(
    card: card ?? this.card,
    actions: List.unmodifiable(actions ?? this.actions),
  );

  @override
  bool operator ==(Object other) =>
      other is AsystantHostCard &&
      card == other.card &&
      const ListEquality<AsystantCardAction>().equals(actions, other.actions);

  @override
  int get hashCode => Object.hash(card, Object.hashAll(actions));
}
