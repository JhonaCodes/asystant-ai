import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:asystant_ai/src/model/asystant_composer_action_placement.dart';
import 'package:flutter/material.dart';

import 'package:asystant_ai/src/widgets/asystant_card_content.dart';
import 'package:asystant_ai/src/asystant_ai.dart';
import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/service/asystant_file_picker.dart';
import 'package:asystant_core/asystant_core.dart';
import 'package:asystant_ai/src/service/asystant_link_opener.dart';
import 'package:asystant_ai/src/theme/asystant_device_type.dart';
import 'package:asystant_ai/src/widgets/asystant_panel.dart';
import 'package:asystant_ai/src/widgets/asystant_phone_sheet.dart';

/// Default launcher. Hosts can instead mount AsystantChat or AsystantPanel.
class AsystantButton extends StatelessWidget {
  const AsystantButton({
    super.key,
    required this.assistant,
    this.strings,
    this.onOpenLink,
    this.cardContentBuilder,
    this.attachments,
    this.onPickFiles,
    this.enablePrivateValueAttachment = false,
    this.attachmentActionPlacement = AsystantComposerActionPlacement.inside,
    this.privateValueActionPlacement = AsystantComposerActionPlacement.inside,
    this.opensExpanded = true,
  });

  final AsystantAI assistant;

  /// Adds typed, host-owned content to completed cards only.
  final AsystantCardContentBuilder? cardContentBuilder;

  final AsystantStrings? strings;

  /// Optional HTTP(S) navigation override shared with the opened chat.
  final AsystantLinkCallback? onOpenLink;

  /// The files the opened chat accepts; the assistant's policy when null.
  final AsystantAttachmentPolicy? attachments;

  /// Replaces the system file picker in the opened chat.
  final AsystantFilePick? onPickFiles;

  /// Shows the optional private-value button in the opened chat.
  final bool enablePrivateValueAttachment;
  final AsystantComposerActionPlacement attachmentActionPlacement;
  final AsystantComposerActionPlacement privateValueActionPlacement;

  /// On phones, whether the chat opens over the whole screen (and the
  /// host's bottom navigation) or as a sheet; its header switches between
  /// the two either way.
  final bool opensExpanded;

  /// Phones get the chat from the bottom; tablets and desktops a side panel.
  Future<void> _open(BuildContext context) =>
      switch (context.asystantDeviceType) {
        AsystantDeviceType.mobile => AsystantPhoneSheet.show(
          context,
          assistant: assistant,
          strings: strings,
          onOpenLink: onOpenLink,
          cardContentBuilder: cardContentBuilder,
          attachments: attachments,
          onPickFiles: onPickFiles,
          enablePrivateValueAttachment: enablePrivateValueAttachment,
          attachmentActionPlacement: attachmentActionPlacement,
          privateValueActionPlacement: privateValueActionPlacement,
          startsExpanded: opensExpanded,
        ),
        AsystantDeviceType.tablet ||
        AsystantDeviceType.desktop => AsystantPanel.show(
          context,
          assistant: assistant,
          strings: strings,
          onOpenLink: onOpenLink,
          cardContentBuilder: cardContentBuilder,
          attachments: attachments,
          onPickFiles: onPickFiles,
          enablePrivateValueAttachment: enablePrivateValueAttachment,
          attachmentActionPlacement: attachmentActionPlacement,
          privateValueActionPlacement: privateValueActionPlacement,
        ),
      };

  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: () => _open(context),
    icon: const AsystantGlyph(AsystantGlyphKind.sparkle),
    label: Text(assistant.name),
  );
}
