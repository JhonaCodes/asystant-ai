import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/pending_action.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:asystant_ai/src/widgets/chat_status_card.dart';
import 'package:asystant_ai/src/widgets/asystant_sensitivity_badge.dart';
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
    required this.onAllowSession,
  });

  final PendingAction pending;

  final AsystantStrings strings;

  final ValueChanged<String> onSelect;

  final ValueChanged<bool> onDecide;

  final VoidCallback onAllowSession;

  @override
  Widget build(BuildContext context) => ChatStatusCard(
    icon: AsystantGlyphKind.key,
    color: pending.policy.requiresApproval
        ? pending.policy.displaySensitivity.color
        : null,
    child: Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          pending.policy.requiresApproval
              ? strings.reviewBeforeAuthorizing
              : strings.chooseBeforeContinuing,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (pending.policy.requiresApproval) ...[
          SizedBox(height: AsystantTheme.of(context).spacing / 2),
          AsystantSensitivityBadge(
            sensitivity: pending.policy.displaySensitivity,
            strings: strings,
          ),
        ],
        SizedBox(height: AsystantTheme.of(context).spacing - 4),
        GenUiCard(
          card: pending.card,
          strings: strings,
          framed: false,
          selected: pending.selected,
          onSelect: onSelect,
          onApprove: pending.canApprove ? () => onDecide(true) : null,
          onDeny: () => onDecide(false),
          approveLabel: pending.policy.requiresApproval
              ? null
              : strings.continueAction,
          denyLabel: pending.policy.requiresApproval ? null : strings.cancel,
        ),
        if (pending.policy.requiresApproval &&
            pending.policy.allowSessionApproval) ...[
          SizedBox(height: AsystantTheme.of(context).spacing),
          TextButton.icon(
            onPressed: pending.canApprove ? onAllowSession : null,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(strings.allowAllForSession),
          ),
          Text(
            strings.allowAllForSessionDetail,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    ),
  );
}
