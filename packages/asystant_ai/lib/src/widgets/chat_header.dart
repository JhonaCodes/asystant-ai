import 'package:flutter/material.dart';

import '../model/chat_state.dart';
import '../l10n/asystant_strings.dart';
import '../theme/asystant_theme.dart';
import 'status_indicator.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.name,
    required this.phase,
    required this.strings,
    this.onClose,
  });
  final String name;
  final ChatPhase phase;
  final AsystantStrings strings;
  final VoidCallback? onClose;
  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    return Padding(
      padding: EdgeInsets.all(tokens.padding),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: tokens.spacing),
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: tokens.spacing / 2),
                StatusIndicator(phase: phase, strings: strings),
              ],
            ),
          ),
          if (onClose case final close?)
            IconButton(
              tooltip: strings.close,
              onPressed: close,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}
