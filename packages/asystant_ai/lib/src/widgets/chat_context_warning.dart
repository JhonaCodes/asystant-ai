import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:asystant_ai/src/widgets/chat_status_card.dart';

/// The conversation nearly fills what the model can keep in mind.
///
/// Shown before the limit so the person can close the topic, or start a new
/// conversation when it suits them, instead of being cut off.
class ChatContextWarning extends StatelessWidget {
  const ChatContextWarning({
    super.key,
    required this.strings,
    required this.onStartNew,
  });

  final AsystantStrings strings;

  final VoidCallback onStartNew;

  @override
  Widget build(BuildContext context) => ChatStatusCard(
    icon: AsystantGlyphKind.warning,
    color: AsystantTheme.of(context).warningColor(context),
    child: Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          strings.contextWarningTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          strings.contextWarningBody,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onStartNew, child: Text(strings.startNewNow)),
      ],
    ),
  );
}
