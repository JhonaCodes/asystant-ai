import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';

/// How the status indicator draws each [ChatPhase].
extension ChatPhasePresentation on ChatPhase {
  AsystantGlyphKind toGlyph() => switch (this) {
    .idle || .ready => .chat,
    .initializing || .executing => .refresh,
    .thinking => .sparkle,
    .permission => .shield,
    .done => .check,
    .canceled => .pause,
    .error => .warning,
  };

  /// Whether the glyph pulses: the phases where work is underway.
  bool get isPulsing => switch (this) {
    .initializing || .thinking || .executing => true,
    .idle || .ready || .permission || .done || .canceled || .error => false,
  };
}
