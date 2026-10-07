import 'package:flutter/material.dart';

import 'package:asystant_ai/src/asystant_ai.dart';
import 'package:asystant_ai/src/model/asystant_composer_action_placement.dart';
import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/service/asystant_file_picker.dart';
import 'package:asystant_ai/src/service/asystant_link_opener.dart';
import 'package:asystant_ai/src/theme/asystant_theme.dart';
import 'package:asystant_ai/src/widgets/asystant_card_content.dart';
import 'package:asystant_ai/src/widgets/asystant_chat.dart';
import 'package:asystant_core/asystant_core.dart';

/// The chat on a phone: the whole screen, or a sheet that leaves the top of
/// the app visible. The header's expand button switches between the two.
///
/// Shown from the root navigator, so it also covers the host's bottom
/// navigation. A screen the host pushes from the chat (a detail) opens over
/// it, and going back returns to the conversation.
class AsystantPhoneSheet extends StatefulWidget {
  const AsystantPhoneSheet({
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
    this.startsExpanded = true,
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

  /// Whether it opens over the whole screen or as a sheet.
  final bool startsExpanded;

  /// Material 3's bottom sheet corner, used while the chat is a sheet.
  static const sheetRadius = 28.0;

  /// Opens the chat from the bottom, over everything the host shows.
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
    bool startsExpanded = true,
  }) => showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    // Expanded, the chat reaches the top edge and pads for the status bar.
    useSafeArea: false,
    showDragHandle: false,
    // The sheet paints the surface and rounds its own corners.
    backgroundColor: Colors.transparent,
    elevation: 0,
    shape: const RoundedRectangleBorder(),
    constraints: BoxConstraints(
      maxWidth: AsystantTheme.of(context).maxContentWidth,
    ),
    builder: (sheetContext) => AsystantPhoneSheet(
      assistant: assistant,
      strings: strings,
      onOpenLink: onOpenLink,
      cardContentBuilder: cardContentBuilder,
      attachments: attachments,
      onPickFiles: onPickFiles,
      enablePrivateValueAttachment: enablePrivateValueAttachment,
      attachmentActionPlacement: attachmentActionPlacement,
      privateValueActionPlacement: privateValueActionPlacement,
      startsExpanded: startsExpanded,
      onClose: () => Navigator.of(sheetContext).pop(),
    ),
  );

  @override
  State<AsystantPhoneSheet> createState() => _AsystantPhoneSheetState();
}

class _AsystantPhoneSheetState extends State<AsystantPhoneSheet> {
  late bool _expanded = widget.startsExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final tokens = AsystantTheme.of(context);
    // The modal route drops the status bar inset; the whole-screen chat
    // needs it back to keep its header below the clock.
    final statusBar = MediaQueryData.fromView(View.of(context)).padding.top;
    final media = MediaQuery.of(context);
    return AnimatedFractionallySizedBox(
      duration: tokens.transitionDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      heightFactor: _expanded ? 1 : tokens.sheetHeightFactor,
      child: AnimatedContainer(
        duration: tokens.transitionDuration,
        curve: Curves.easeOutCubic,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(
              _expanded ? 0 : AsystantPhoneSheet.sheetRadius,
            ),
          ),
        ),
        // Over the whole screen there is no handle, so a drag must not close
        // it: claiming vertical drags here keeps them from the sheet, while
        // the conversation below still scrolls. As a sheet, drag closes it.
        child: GestureDetector(
          onVerticalDragStart: _expanded ? (_) {} : null,
          child: MediaQuery(
            data: media.copyWith(
              padding: media.padding.copyWith(top: _expanded ? statusBar : 0),
            ),
            child: AsystantChat(
              assistant: widget.assistant,
              onClose: widget.onClose,
              strings: widget.strings,
              onOpenLink: widget.onOpenLink,
              cardContentBuilder: widget.cardContentBuilder,
              attachments: widget.attachments,
              onPickFiles: widget.onPickFiles,
              enablePrivateValueAttachment: widget.enablePrivateValueAttachment,
              attachmentActionPlacement: widget.attachmentActionPlacement,
              privateValueActionPlacement: widget.privateValueActionPlacement,
              isExpanded: _expanded,
              onToggleExpansion: _toggle,
              // A handle only means something while it is a sheet.
              showsHandle: !_expanded,
            ),
          ),
        ),
      ),
    );
  }
}
