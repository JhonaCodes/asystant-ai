import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';

class ChatWelcome extends StatelessWidget {
  const ChatWelcome({super.key, required this.strings});

  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.padding),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            strings.welcome,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: tokens.spacing),
          Text(
            strings.introduction,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
