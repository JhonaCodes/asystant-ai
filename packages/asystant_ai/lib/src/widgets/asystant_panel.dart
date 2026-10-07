import 'package:flutter/material.dart';

import 'package:asystant_ai/src/asystant_ai.dart';
import 'package:asystant_ai/src/model/asystant_composer_action_placement.dart';
import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/service/asystant_file_picker.dart';
import 'package:asystant_core/asystant_core.dart';
import 'package:asystant_ai/src/service/asystant_link_opener.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/asystant_card_content.dart';
import 'package:asystant_ai/src/widgets/asystant_chat.dart';

/// The chat as a panel on the right, over the host's content, that can widen.
///
/// Its width is a share of the window between the theme's minimum and
/// maximum; expanded, it grows by [AsystantTheme.panelExpandedFactor]. When
/// the window is narrower than the minimum the panel fills it and does not
/// offer to expand.
class AsystantPanel extends StatefulWidget {
  const AsystantPanel({
    super.key,
    required this.assistant,
    this.onClose,
    this.strings,
    this.onOpenLink,
    this.cardContentBuilder,
    this.attachments,
    this.onPickFiles,
    this.enablePrivateValueAttachment = false,
    this.attachmentActionPlacement = AsystantComposerActionPlacement.inside,
    this.privateValueActionPlacement = AsystantComposerActionPlacement.inside,
  });

  final AsystantAI assistant;

  final VoidCallback? onClose;

  final AsystantStrings? strings;

  final AsystantLinkCallback? onOpenLink;

  final AsystantCardContentBuilder? cardContentBuilder;

  /// The files the chat accepts; the assistant's policy when null.
  final AsystantAttachmentPolicy? attachments;

  /// Replaces the system file picker.
  final AsystantFilePick? onPickFiles;

  /// Shows the optional private-value button in the opened chat.
  final bool enablePrivateValueAttachment;
  final AsystantComposerActionPlacement attachmentActionPlacement;
  final AsystantComposerActionPlacement privateValueActionPlacement;

  /// Opens the panel from the right over the current route.
  static Future<void> show(
    BuildContext context, {
    required AsystantAI assistant,
    AsystantStrings? strings,
    AsystantLinkCallback? onOpenLink,
    AsystantCardContentBuilder? cardContentBuilder,
    AsystantAttachmentPolicy? attachments,
    AsystantFilePick? onPickFiles,
    bool enablePrivateValueAttachment = false,
    AsystantComposerActionPlacement attachmentActionPlacement =
        AsystantComposerActionPlacement.inside,
    AsystantComposerActionPlacement privateValueActionPlacement =
        AsystantComposerActionPlacement.inside,
  }) => showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: .13),
    transitionDuration: AsystantTheme.of(context).transitionDuration,
    pageBuilder: (dialogContext, _, _) => AsystantPanel(
      assistant: assistant,
      strings: strings,
      onOpenLink: onOpenLink,
      cardContentBuilder: cardContentBuilder,
      attachments: attachments,
      onPickFiles: onPickFiles,
      enablePrivateValueAttachment: enablePrivateValueAttachment,
      attachmentActionPlacement: attachmentActionPlacement,
      privateValueActionPlacement: privateValueActionPlacement,
      onClose: () => Navigator.of(dialogContext).pop(),
    ),
    transitionBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );

  @override
  State<AsystantPanel> createState() => _AsystantPanelState();
}

class _AsystantPanelState extends State<AsystantPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    final colors = Theme.of(context).colorScheme;
    // Measures the space this panel may take, not the device class.
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final fillsWindow = available <= tokens.panelMinWidth;
        final normal = fillsWindow
            ? available
            : (available * tokens.panelWidthFactor)
                  .clamp(tokens.panelMinWidth, tokens.panelMaxWidth)
                  .toDouble();
        final width = fillsWindow || !_isExpanded
            ? normal
            : (normal * tokens.panelExpandedFactor)
                  .clamp(0, available)
                  .toDouble();
        return Align(
          alignment: .centerRight,
          child: AnimatedContainer(
            width: width,
            height: double.infinity,
            duration: tokens.transitionDuration,
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(left: BorderSide(color: colors.outlineVariant)),
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(alpha: .17),
                  blurRadius: 42,
                  offset: const Offset(-8, 0),
                ),
              ],
            ),
            child: AsystantChat(
              assistant: widget.assistant,
              strings: widget.strings,
              onOpenLink: widget.onOpenLink,
              cardContentBuilder: widget.cardContentBuilder,
              attachments: widget.attachments,
              onPickFiles: widget.onPickFiles,
              enablePrivateValueAttachment: widget.enablePrivateValueAttachment,
              attachmentActionPlacement: widget.attachmentActionPlacement,
              privateValueActionPlacement: widget.privateValueActionPlacement,
              onClose: widget.onClose,
              isExpanded: _isExpanded,
              onToggleExpansion: fillsWindow
                  ? null
                  : () => setState(() => _isExpanded = !_isExpanded),
            ),
          ),
        );
      },
    );
  }
}
