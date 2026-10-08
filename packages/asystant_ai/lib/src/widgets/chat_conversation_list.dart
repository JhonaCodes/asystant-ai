import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/conversation_summary.dart';
import 'package:asystant_ai/src/theme/asystant_metrics.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:asystant_ai/src/widgets/asystant_icon_action.dart';
import 'package:asystant_ai/src/widgets/chat_confirm_dialog.dart';

/// Every conversation, the most recent first: open one, start a new one or
/// delete one. Deleting asks first, because it cannot be undone.
///
/// Used as a layer over the chat and, in a wide expanded chat, as a column
/// beside it ([onBack] null).
class ChatConversationList extends StatelessWidget {
  const ChatConversationList({
    super.key,
    required this.conversations,
    required this.activeId,
    required this.strings,
    required this.canManage,
    required this.onOpen,
    required this.onDelete,
    required this.onNew,
    this.onBack,
  });

  final List<ConversationSummary> conversations;

  /// The one on screen.
  final String activeId;

  final AsystantStrings strings;

  /// Whether conversations can change now.
  final bool canManage;

  final ValueChanged<String> onOpen;

  final ValueChanged<String> onDelete;

  final VoidCallback onNew;

  /// Returns to the chat; hides the back button when null.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(onBack == null ? 16 : 4, 8, 16, 8),
            child: Row(
              children: [
                if (onBack case final back?)
                  AsystantIconAction(
                    glyph: AsystantGlyphKind.back,
                    tooltip: strings.back,
                    onPressed: back,
                    compact: false,
                  ),
                Expanded(
                  child: Text(
                    strings.conversations,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const AsystantGlyph(AsystantGlyphKind.plus),
                label: Text(strings.newConversation),
                onPressed: canManage ? onNew : null,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: switch (conversations) {
              [] => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(strings.noConversations),
              ),
              _ => ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: conversations.length,
                itemBuilder: (context, index) => _ConversationTile(
                  summary: conversations[index],
                  isActive: conversations[index].id == activeId,
                  strings: strings,
                  canManage: canManage,
                  onOpen: onOpen,
                  onDelete: onDelete,
                  onBack: onBack,
                ),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.summary,
    required this.isActive,
    required this.strings,
    required this.canManage,
    required this.onOpen,
    required this.onDelete,
    required this.onBack,
  });

  final ConversationSummary summary;

  final bool isActive;

  final AsystantStrings strings;

  final bool canManage;

  final ValueChanged<String> onOpen;

  final ValueChanged<String> onDelete;

  final VoidCallback? onBack;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showChatConfirmDialog(
      context,
      strings: strings,
      title: strings.deleteTitle,
      body: strings.deleteBody,
      confirmLabel: strings.delete,
    );
    if (confirmed) {
      onDelete(summary.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(summary.updatedAt.toLocal()),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        selected: isActive,
        selectedTileColor: colors.secondaryContainer,
        selectedColor: colors.onSecondaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          switch (summary.title) {
            '' => strings.untitledConversation,
            final title => title,
          },
          maxLines: 2,
          overflow: .ellipsis,
        ),
        subtitle: Text(
          isActive
              ? '${strings.current} · ${strings.shortDate(summary.updatedAt)}, $time'
              : '${strings.shortDate(summary.updatedAt)}, $time',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
        // The one on screen returns to the chat; the others open.
        onTap: switch ((canManage, isActive)) {
          (false, _) => null,
          (true, true) => onBack,
          (true, false) => () => onOpen(summary.id),
        },
        trailing: AsystantIconAction(
          glyph: AsystantGlyphKind.trash,
          tooltip: strings.delete,
          onPressed: canManage ? () => _confirmDelete(context) : null,
          compact: false,
        ),
      ),
    );
  }
}

/// The list over the chat: the whole chat when there is little room beside
/// it, otherwise a panel on the right over a scrim.
class ChatConversationLayer extends StatelessWidget {
  const ChatConversationLayer({
    super.key,
    required this.list,
    required this.onDismiss,
  });

  /// The list, with its back button wired to [onDismiss].
  final Widget list;

  final VoidCallback onDismiss;

  /// A side panel needs at least this much of the chat visible beside it.
  static const double minVisibleChat = 72;

  @override
  Widget build(BuildContext context) {
    final maxWidth = AsystantMetrics.of(context).listMaxWidth;
    // Measures the chat's own width, not the device class.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth - maxWidth < minVisibleChat) {
          return list;
        }
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: onDismiss,
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.scrim
                      .withValues(alpha: .32),
                ),
              ),
            ),
            Align(
              alignment: .centerRight,
              child: SizedBox(width: maxWidth, child: list),
            ),
          ],
        );
      },
    );
  }
}
