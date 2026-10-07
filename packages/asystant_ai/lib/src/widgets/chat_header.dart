import 'package:flutter/material.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/chat_state.dart';
import 'package:asystant_ai/src/theme/asystant_metrics.dart';
import 'package:asystant_ai/src/widgets/asystant_glyph.dart';
import 'package:asystant_ai/src/widgets/status_indicator.dart';

/// Identity and the conversation actions: expand, list, new, delete, close.
///
/// A null callback hides its action. Actions that change conversations are
/// disabled while a turn runs. When compact, delete moves to a menu.
class ChatHeader extends StatelessWidget {
  const ChatHeader({
    super.key,
    required this.name,
    required this.state,
    required this.strings,
    required this.canManage,
    this.description,
    this.showsHandle = false,
    this.isExpanded = false,
    this.onToggleExpansion,
    this.actions = const [],
    this.onHistory,
    this.onNew,
    this.onDelete,
    this.onClose,
  });

  final String name;

  /// A fixed line under the name while nothing is happening.
  final String? description;

  final ChatState state;

  final AsystantStrings strings;

  /// Whether conversations can change now.
  final bool canManage;

  /// A drag handle on top, for bottom sheets.
  final bool showsHandle;

  final bool isExpanded;

  final VoidCallback? onToggleExpansion;

  /// Host buttons drawn before the conversation actions.
  final List<Widget> actions;

  final VoidCallback? onHistory;

  final VoidCallback? onNew;

  final VoidCallback? onDelete;

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final metrics = AsystantMetrics.of(context);
    final colors = Theme.of(context).colorScheme;
    final hasMessages = state.messages.isNotEmpty;
    final canChange = canManage && hasMessages;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: metrics.headerHeight + (showsHandle ? 10 : 0),
      ),
      child: Column(
        mainAxisSize: .min,
        children: [
          if (showsHandle)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withValues(alpha: .4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: metrics.headerHeight),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 4),
              child: Row(
                children: [
                  Container(
                    width: metrics.identitySize,
                    height: metrics.identitySize,
                    alignment: .center,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(
                        metrics.identityRadius,
                      ),
                    ),
                    child: AsystantGlyph(
                      AsystantGlyphKind.sparkle,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Identity(
                      name: name,
                      description: description,
                      state: state,
                      strings: strings,
                    ),
                  ),
                  if (onToggleExpansion case final toggle?)
                    _HeaderAction(
                      glyph: isExpanded
                          ? AsystantGlyphKind.collapse
                          : AsystantGlyphKind.expand,
                      tooltip: isExpanded ? strings.collapse : strings.expand,
                      onPressed: toggle,
                    ),
                  ...actions,
                  if (onHistory case final history?)
                    _HeaderAction(
                      glyph: AsystantGlyphKind.history,
                      tooltip: strings.history,
                      onPressed: canManage ? history : null,
                    ),
                  if (onNew case final create?)
                    _HeaderAction(
                      glyph: AsystantGlyphKind.plus,
                      tooltip: strings.newConversation,
                      onPressed: canChange ? create : null,
                    ),
                  if (onDelete case final delete?
                      when metrics.showsHeaderDelete)
                    _HeaderAction(
                      glyph: AsystantGlyphKind.trash,
                      tooltip: strings.deleteConversation,
                      onPressed: canChange ? delete : null,
                    ),
                  if (onDelete case final delete?
                      when !metrics.showsHeaderDelete)
                    _MoreActions(
                      strings: strings,
                      onDelete: canChange ? delete : null,
                    ),
                  if (onClose case final close?)
                    _HeaderAction(
                      glyph: AsystantGlyphKind.close,
                      tooltip: strings.close,
                      onPressed: close,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({
    required this.name,
    required this.description,
    required this.state,
    required this.strings,
  });

  final String name;

  final String? description;

  final ChatState state;

  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: .center,
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: .ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (state.showsStatus)
          StatusIndicator(phase: state.phase, strings: strings)
        else if (description case final text?)
          Text(
            text,
            maxLines: 1,
            overflow: .ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.glyph,
    required this.tooltip,
    required this.onPressed,
  });

  final AsystantGlyphKind glyph;

  final String tooltip;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
      icon: AsystantGlyph(
        glyph,
        color: onPressed == null
            ? colors.onSurface.withValues(alpha: .38)
            : colors.onSurfaceVariant,
      ),
    );
  }
}

class _MoreActions extends StatelessWidget {
  const _MoreActions({required this.strings, required this.onDelete});

  final AsystantStrings strings;

  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => PopupMenuButton<VoidCallback>(
    tooltip: strings.moreActions,
    icon: AsystantGlyph(
      AsystantGlyphKind.more,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    onSelected: (action) => action(),
    itemBuilder: (_) => [
      PopupMenuItem(
        value: onDelete,
        enabled: onDelete != null,
        child: Text(strings.deleteConversation),
      ),
    ],
  );
}
