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
  ),
  plus('<path d="M12 5v14M5 12h14"/>'),
  history(
    '<path d="M3 12a9 9 0 1 0 3-6.7L3 8"/><path d="M3 3v5h5M12 7v5l3 2"/>',
  ),
  trash('<path d="M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3"/>'),
  expand('<path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7"/>'),
  collapse('<path d="M4 14h6v6M20 10h-6V4M14 10l7-7M3 21l7-7"/>'),
  thinking(
    '<path d="M9 18h6M10 21h4M12 3a6 6 0 0 0-4 10.5c.7.7 1 1.5 1 2.5h6c0-1 .3-1.8 1-2.5A6 6 0 0 0 12 3Z"/>',
  ),
  writing('<path d="M4 20h4L19 9l-4-4L4 16Z M13 7l4 4"/>'),
  activity(
    '<rect x="4" y="3" width="16" height="18" rx="2"/><path d="m8 9 1.5 1.5L12 8M8 15l1.5 1.5L12 14M14 9h2M14 15h2"/>',
  ),
  inbox('<path d="M4 13h4l2 3h4l2-3h4M4 13l2-8h12l2 8v6H4Z"/>'),
  key('<circle cx="8" cy="15" r="4"/><path d="m11 12 9-9M17 6l3 3M14 9l2 2"/>'),
  tool(
    '<path d="M14 6a4 4 0 0 0 5 5l-9 9a2.1 2.1 0 0 1-3-3l9-9a4 4 0 0 1-2-2Z"/>',
  ),
  pending(
    '<circle cx="12" cy="12" r="9"/><path d="M8 12h.01M12 12h.01M16 12h.01"/>',
  ),
  chevronUp('<path d="m6 15 6-6 6 6"/>'),
  attach(
    '<path d="m21 11-8.5 8.5a5 5 0 0 1-7-7L14 4a3.5 3.5 0 0 1 5 5l-8.5 8.5a2 2 0 0 1-3-3L15 7"/>',
  ),
  more('<path d="M12 5h.01M12 12h.01M12 19h.01"/>'),
  back('<path d="M19 12H5m6-6-6 6 6 6"/>'),
  image(
    '<rect x="3" y="4" width="18" height="16" rx="2"/><circle cx="9" cy="10" r="2"/><path d="m21 16-5-5-9 9"/>',
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
