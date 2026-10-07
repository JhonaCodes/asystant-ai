import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';

/// How the live activity card names what the assistant is doing.
extension TurnActivityPresentation on TurnActivity {
  AsystantGlyphKind toGlyph() => switch (this) {
    .thinking => .thinking,
    .writing => .writing,
    .usingTool => .tool,
  };

  String toTitle(AsystantStrings strings, String name) => switch (this) {
    .thinking => strings.thinkingAs(name),
    .writing => strings.writingAs(name),
    .usingTool => strings.usingToolAs(name),
  };

  /// The last row of the live card; a running tool has none.
  String? toClosingStep(AsystantStrings strings) => switch (this) {
    .thinking => strings.analyzing,
    .writing => strings.drafting,
    .usingTool => null,
  };
}
