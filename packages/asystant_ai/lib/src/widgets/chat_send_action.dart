import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/theme/asystant_metrics.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/viewmodel/chat_view_model.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';

/// Send, or Stop while a turn runs. The icon takes a contrasting color from
/// the button's own fill, whatever the host theme is.
class ChatSendAction extends StatelessWidget {
  const ChatSendAction({
    super.key,
    required this.state,
    required this.viewModel,
    required this.strings,
    required this.onSend,
  });

  final ChatState state;

  final ChatViewModel viewModel;

  final AsystantStrings strings;

  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final size = AsystantMetrics.of(context).sendSize;
    final colors = Theme.of(context).colorScheme;
    final onPressed = switch ((state.busy, viewModel.canSend)) {
      (true, _) => viewModel.stop,
      (false, true) => onSend,
      _ => null,
    };
    final fill = switch ((onPressed, state.busy)) {
      (null, _) => colors.onSurface.withValues(alpha: .12),
      (_, true) => colors.error,
      (_, false) => colors.primary,
    };
    final glyph = onPressed == null
        ? colors.onSurface.withValues(alpha: .38)
        : AsystantTheme.contrastOn(fill);
    // The fill follows the density; the touch area never drops below 48.
    return IconButton.filled(
      tooltip: state.busy ? strings.stop : strings.send,
      padding: EdgeInsets.zero,
      style: IconButton.styleFrom(
        fixedSize: Size.square(size),
        minimumSize: Size.square(size),
        tapTargetSize: MaterialTapTargetSize.padded,
        backgroundColor: fill,
        disabledBackgroundColor: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size / 3.5),
        ),
      ),
      onPressed: onPressed,
      icon: AnimatedSwitcher(
        duration: kThemeAnimationDuration,
        child: AsystantGlyph(
          state.busy ? AsystantGlyphKind.stop : AsystantGlyphKind.send,
          key: ValueKey(state.busy),
          color: glyph,
        ),
      ),
    );
  }
}
