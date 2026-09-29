import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/pending_action.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:asystant_ai/src/widgets/chat_status_card.dart';
import 'package:asystant_ai/src/widgets/gen_ui_card.dart';

/// An action waiting for the person: what it does, then Decline or Authorize.
///
/// Host card content is never rendered here: it only augments completed
/// cards, so it cannot sit next to or stand in for the approval controls.
class ChatConfirmationCard extends StatelessWidget {
  const ChatConfirmationCard({
    super.key,
    required this.pending,
    required this.strings,
    required this.onSelect,
    required this.onDecide,
  });

  final PendingAction pending;

  final AsystantStrings strings;

  final ValueChanged<String> onSelect;

  final ValueChanged<bool> onDecide;

  @override
  Widget build(BuildContext context) => ChatStatusCard(
    icon: AsystantGlyphKind.key,
    child: Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          strings.reviewBeforeAuthorizing,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SizedBox(height: AsystantTheme.of(context).spacing - 4),
        GenUiCard(
          card: pending.card,
          strings: strings,
          framed: false,
          selected: pending.selected,
          onSelect: onSelect,
          onApprove: pending.canApprove ? () => onDecide(true) : null,
          onDeny: () => onDecide(false),
        ),
      ],
    ),
  );
}
