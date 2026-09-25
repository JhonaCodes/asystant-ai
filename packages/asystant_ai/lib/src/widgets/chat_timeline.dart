import 'package:flutter/material.dart';

import 'package:asystant_ai/src/theme/asystant_theme.dart';

/// Keeps new content visible while allowing the reader to scroll older messages.
class ChatTimeline extends StatefulWidget {
  const ChatTimeline({
    super.key,
    required this.children,
    required this.padding,
    required this.revision,
    this.forceFollow = false,
  });

  final List<Widget> children;

  final EdgeInsets padding;

  final Object revision;

  final bool forceFollow;

  @override
  State<ChatTimeline> createState() => _ChatTimelineState();
}

class _ChatTimelineState extends State<ChatTimeline> {
  final ScrollController _scroll = ScrollController();

  bool _hasSelection = false;

  @override
  void didUpdateWidget(covariant ChatTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revision == oldWidget.revision || _hasSelection) {
      return;
    }
    final follow =
        widget.forceFollow ||
        !_scroll.hasClients ||
        _scroll.position.extentAfter <
            AsystantTheme.of(context).timelineFollowThreshold;
    if (follow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients && !_hasSelection) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SelectionArea(
    onSelectionChanged: (selection) =>
        _hasSelection = selection?.plainText.isNotEmpty ?? false,
    child: ListView(
      controller: _scroll,
      padding: widget.padding,
      keyboardDismissBehavior: .onDrag,
      children: widget.children,
    ),
  );
}
