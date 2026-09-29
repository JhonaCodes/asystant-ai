import 'package:flutter/material.dart';
import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:asystant_ai/src/widgets/chat_status_card.dart';

/// Calm, readable failure feedback kept inside the conversation timeline.
class ChatFailureNotice extends StatelessWidget {
  const ChatFailureNotice({
    super.key,
    required this.failure,
    required this.strings,
    this.onStartNew,
  });

  final AssistantFailure failure;

  final AsystantStrings strings;

  /// Offered when only a new conversation can continue.
  final VoidCallback? onStartNew;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: ChatStatusCard(
      icon: AsystantGlyphKind.warning,
      color: Theme.of(context).colorScheme.error,
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(strings.failure(failure.code)),
          if (onStartNew case final startNew?) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: startNew,
              child: Text(strings.newConversation),
            ),
          ],
        ],
      ),
    ),
  );
}
