import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/service/asystant_link_opener.dart';

/// Shares host link handling and localized feedback throughout one chat.
class AsystantLinkScope extends InheritedWidget {
  const AsystantLinkScope({
    super.key,
    required this.opener,
    required this.strings,
    required super.child,
  });

  final AsystantLinkOpener opener;

  final AsystantStrings strings;

  static AsystantLinkOpener openerOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AsystantLinkScope>()?.opener ??
      const AsystantLinkOpener();

  static AsystantStrings stringsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AsystantLinkScope>()
          ?.strings ??
      AsystantStrings.of(context);

  @override
  bool updateShouldNotify(AsystantLinkScope oldWidget) =>
      opener.onOpenLink != oldWidget.opener.onOpenLink ||
      strings != oldWidget.strings;
}
