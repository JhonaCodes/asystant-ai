import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:flutter/material.dart';

import 'package:asystant_ai/src/widgets/asystant_card_content.dart';
import 'package:asystant_ai/src/asystant_ai.dart';
import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/service/asystant_link_opener.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/asystant_chat.dart';

/// Default launcher. Hosts can instead mount AsystantChat in an endDrawer.
class AsystantButton extends StatelessWidget {
  const AsystantButton({
    super.key,
    required this.assistant,
    this.strings,
    this.onOpenLink,
    this.cardContentBuilder,
  });

  final AsystantAI assistant;

  /// Adds typed, host-owned content to completed cards only.
  final AsystantCardContentBuilder? cardContentBuilder;

  final AsystantStrings? strings;

  /// Optional HTTP(S) navigation override shared with the opened chat.
  final AsystantLinkCallback? onOpenLink;

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: () => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      constraints: BoxConstraints(
        maxWidth: AsystantTheme.of(context).maxContentWidth,
      ),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: AsystantTheme.of(sheetContext).sheetHeightFactor,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: AsystantChat(
            assistant: assistant,
            cardContentBuilder: cardContentBuilder,
            strings: strings,
            onOpenLink: onOpenLink,
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ),
    ),
    icon: const AsystantGlyph(AsystantGlyphKind.sparkle),
    label: Text(assistant.name),
  );
}
