import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:asystant_ai/src/theme/asystant_theme.dart';

/// Bundled vector controls remain visible without any icon-font downloads.
enum AsystantGlyphKind {
  chevron('<path d="m6 9 6 6 6-6"/>'),
  document('<path d="M6 3h9l4 4v14H6Z M9 11h7M9 15h7"/>'),
  search('<circle cx="10" cy="10" r="6"/><path d="m15 15 6 6"/>'),
  close('<path d="m6 6 12 12M18 6 6 18"/>'),
  send('<path d="M12 20V4m-7 7 7-7 7 7"/>'),
  stop('<rect x="6" y="6" width="12" height="12" rx="2"/>'),
  sparkle(
    '<path d="m12 3 2.5 6.5L21 12l-6.5 2.5L12 21l-2.5-6.5L3 12l6.5-2.5Z"/>',
  ),
  chat(
    '<path d="M5 4h14a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H9l-6 3V6a2 2 0 0 1 2-2Z"/>',
  ),
  check('<circle cx="12" cy="12" r="9"/><path d="m8 12 3 3 5-6"/>'),
  warning('<circle cx="12" cy="12" r="9"/><path d="M12 7v6m0 4h.01"/>'),
  shield('<path d="m12 3 8 3v5c0 5-4 8-8 10-4-2-8-5-8-10V6Z"/>'),
  pause('<circle cx="12" cy="12" r="9"/><path d="M9 8v8m6-8v8"/>'),
  refresh(
    '<path d="M20 7v5h-5M4 17v-5h5M5 7a8 8 0 0 1 14-1l1 6M4 12l1 6a8 8 0 0 0 14-1"/>',
  );

  const AsystantGlyphKind(this.paths);

  final String paths;

  String get svg =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="black" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">$paths</svg>';
}

/// A decorative icon. Its owning button or status provides accessible labels.
class AsystantGlyph extends StatelessWidget {
  const AsystantGlyph(this.kind, {super.key, this.color});

  final AsystantGlyphKind kind;

  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.string(
    kind.svg,
    width: AsystantTheme.of(context).iconSize,
    height: AsystantTheme.of(context).iconSize,
    colorFilter: ColorFilter.mode(
      color ??
          IconTheme.of(context).color ??
          Theme.of(context).colorScheme.onSurface,
      .srcIn,
    ),
    excludeFromSemantics: true,
  );
}
