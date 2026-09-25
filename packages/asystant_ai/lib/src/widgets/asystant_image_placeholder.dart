import 'package:flutter/material.dart';

import 'package:asystant_ai/src/widgets/asystant_link_scope.dart';

/// Keeps model-supplied image markup readable without fetching external assets.
class AsystantImagePlaceholder extends StatelessWidget {
  const AsystantImagePlaceholder(this.uri, this.title, this.alt, {super.key});

  final Uri uri;

  final String? title;

  final String? alt;

  @override
  Widget build(BuildContext context) => Text(switch (alt) {
    final description? when description.isNotEmpty => description,
    _ => AsystantLinkScope.stringsOf(context).imageOmitted,
  }, style: Theme.of(context).textTheme.bodySmall);
}
