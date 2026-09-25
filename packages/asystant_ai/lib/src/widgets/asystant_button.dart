import 'package:flutter/material.dart';

import '../asystant_ai.dart';
import '../l10n/asystant_strings.dart';
import '../theme/asystant_theme.dart';
import 'asystant_chat.dart';

/// Default launcher. Hosts can instead mount AsystantChat in an endDrawer.
class AsystantButton extends StatelessWidget {
  const AsystantButton({super.key, required this.assistant, this.strings});
  final AsystantAI assistant;
  final AsystantStrings? strings;
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
        heightFactor: .92,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: AsystantChat(
            assistant: assistant,
            strings: strings,
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
        ),
      ),
    ),
    icon: const Icon(Icons.auto_awesome_rounded),
    label: Text(assistant.name),
  );
}
