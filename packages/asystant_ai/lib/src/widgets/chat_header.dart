import 'package:flutter/material.dart';
import 'package:multiselect_field/multiselect_field.dart';

import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/asystant_conversation_actions_style.dart';
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
    this.actionsStyle = AsystantConversationActionsStyle.inline,
    this.menuIcon,
    this.identityIcon,
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

  /// Inline icons or one dropdown menu for history, new and delete.
  final AsystantConversationActionsStyle actionsStyle;

  /// Opens the menu style; a "more" glyph when null.
  final Widget? menuIcon;

  /// Host-provided identity mark inside the header tile.
  final Widget? identityIcon;

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
                    child:
                        identityIcon ??
                        AsystantGlyph(
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
                  if (actionsStyle == AsystantConversationActionsStyle.menu &&
                      (onHistory != null || onNew != null || onDelete != null))
                    _ConversationMenu(
                      strings: strings,
                      icon: menuIcon,
                      onHistory: canManage ? onHistory : null,
                      onNew: canChange ? onNew : null,
                      onDelete: canChange ? onDelete : null,
                    ),
                  if (actionsStyle == AsystantConversationActionsStyle.inline)
                    _InlineConversationActions(
                      strings: strings,
                      showsDelete: metrics.showsHeaderDelete,
                      onHistory: onHistory,
                      onNew: onNew,
                      onDelete: onDelete,
                      canManage: canManage,
                      canChange: canChange,
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

/// History, new and delete as icon buttons; delete moves to a menu when compact.
class _InlineConversationActions extends StatelessWidget {
  const _InlineConversationActions({
    required this.strings,
    required this.showsDelete,
    required this.onHistory,
    required this.onNew,
    required this.onDelete,
    required this.canManage,
    required this.canChange,
  });

  final AsystantStrings strings;

  final bool showsDelete;

  final VoidCallback? onHistory;

  final VoidCallback? onNew;

  final VoidCallback? onDelete;

  final bool canManage;

  final bool canChange;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
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
      if (onDelete case final delete? when showsDelete)
        _HeaderAction(
          glyph: AsystantGlyphKind.trash,
          tooltip: strings.deleteConversation,
          onPressed: canChange ? delete : null,
        ),
      if (onDelete case final delete? when !showsDelete)
        _MoreActions(strings: strings, onDelete: canChange ? delete : null),
    ],
  );
}

/// History, new and delete behind one icon, as a dropdown with an icon each.
class _ConversationMenu extends StatefulWidget {
  const _ConversationMenu({
    required this.strings,
    required this.icon,
    required this.onHistory,
    required this.onNew,
    required this.onDelete,
  });

  final AsystantStrings strings;

  /// The trigger; a "more" glyph when null.
  final Widget? icon;

  /// A null action is shown disabled.
  final VoidCallback? onHistory;

  final VoidCallback? onNew;

  final VoidCallback? onDelete;

  @override
  State<_ConversationMenu> createState() => _ConversationMenuState();
}

class _ConversationMenuState extends State<_ConversationMenu> {
  final MenuController _controller = MenuController();

  void _run(VoidCallback action) {
    _controller.close();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MultiSelectField<VoidCallback>.chip(
      label: '',
      controller: _controller,
      showDropdownIcon: false,
      chipStyle: const ChipStyle(
        backgroundColor: Colors.transparent,
        activeBackgroundColor: Colors.transparent,
        borderColor: Colors.transparent,
        activeBorderColor: Colors.transparent,
        padding: EdgeInsets.all(8),
      ),
      leading: Tooltip(
        message: widget.strings.moreActions,
        child:
            widget.icon ??
            AsystantGlyph(
              AsystantGlyphKind.more,
              color: colors.onSurfaceVariant,
            ),
      ),
      menuContent: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          _ConversationMenuEntry(
            glyph: AsystantGlyphKind.history,
            label: widget.strings.history,
            onPressed: widget.onHistory == null
                ? null
                : () => _run(widget.onHistory!),
          ),
          _ConversationMenuEntry(
            glyph: AsystantGlyphKind.plus,
            label: widget.strings.newConversation,
            onPressed: widget.onNew == null ? null : () => _run(widget.onNew!),
          ),
          _ConversationMenuEntry(
            glyph: AsystantGlyphKind.trash,
            label: widget.strings.deleteConversation,
            onPressed: widget.onDelete == null
                ? null
                : () => _run(widget.onDelete!),
          ),
        ],
      ),
    );
  }
}

class _ConversationMenuEntry extends StatelessWidget {
  const _ConversationMenuEntry({
    required this.glyph,
    required this.label,
    required this.onPressed,
  });

  final AsystantGlyphKind glyph;

  final String label;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = onPressed == null
        ? colors.onSurface.withValues(alpha: .38)
        : colors.onSurface;
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: .min,
          children: [
            AsystantGlyph(glyph, color: color),
            const SizedBox(width: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: color),
            ),
          ],
        ),
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
