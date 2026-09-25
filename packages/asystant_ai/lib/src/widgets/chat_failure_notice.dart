import 'package:flutter/material.dart';
import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';

/// Calm, readable failure feedback kept inside the conversation timeline.
class ChatFailureNotice extends StatelessWidget {
  const ChatFailureNotice({
    super.key,
    required this.failure,
    required this.strings,
  });

  final AssistantFailure failure;

  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.all(tokens.spacing),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(
            color: colors.error.withValues(
              alpha: tokens.permissionBorderOpacity,
            ),
          ),
          borderRadius: BorderRadius.circular(tokens.radius),
        ),
        child: Row(
          crossAxisAlignment: .start,
          children: [
            AsystantGlyph(AsystantGlyphKind.warning, color: colors.error),
            SizedBox(width: tokens.spacing),
            Expanded(
              child: Text(
                strings.failure(failure.code),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
