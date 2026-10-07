import 'package:asystant_core/asystant_core.dart';

import 'package:asystant_ai/src/widgets/asystant_glyph.dart';

/// The glyph a card shows beside its title.
extension AssistantCardKindPresentation on AssistantCardKind {
  AsystantGlyphKind toGlyph() => switch (this) {
    .summary || .entity => .document,
    .selection || .result => .check,
    .permission => .shield,
  };
}
