import 'package:flutter/material.dart';

import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';

class ChatFailureNotice extends StatelessWidget {
  const ChatFailureNotice({
    super.key,
    required this.failure,
    required this.strings,
  });

  final AssistantFailure failure;

  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        switch (failure.code) {
          FailureCode.authentication => Icons.lock_clock_outlined,
          FailureCode.budget => Icons.account_balance_wallet_outlined,
          FailureCode.network => Icons.wifi_off_rounded,
          FailureCode.protocol ||
          FailureCode.unavailable ||
          FailureCode.invalidTool ||
          FailureCode.toolFailed ||
          FailureCode.canceled ||
          FailureCode.limit => Icons.error_outline_rounded,
        },
        size: AsystantTheme.of(context).iconSize,
        color: Theme.of(context).colorScheme.error,
      ),
      title: Text(strings.failure(failure.code)),
    ),
  );
}
