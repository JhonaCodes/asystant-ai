import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:asystant_ai/src/theme/asystant_theme.dart';

/// Keeps the end of the conversation in view while the reader follows it.
///
/// It follows new messages and content that grows or moves (a reply that
/// streams in, a photo that loads, the keyboard that opens), and always goes
/// to the end when the person sends a message. Scrolling back to read stops
/// it; returning to the end resumes it.
class ChatTimeline extends StatefulWidget {
  const ChatTimeline({
    super.key,
    required this.children,
    required this.padding,
    required this.anchor,
    this.forceFollow = false,
    this.startAtTop = false,
  });

  final List<Widget> children;

  final EdgeInsets padding;

  /// Changes when the person sends a message or opens another conversation:
  /// the timeline goes to the end and follows again.
  final Object anchor;

  /// Brings the end into view when it turns true, e.g. a decision waits there.
  final bool forceFollow;

  /// Empty welcomes open at their beginning even when taller than the screen.
  final bool startAtTop;

  @override
  State<ChatTimeline> createState() => _ChatTimelineState();
}

class _ChatTimelineState extends State<ChatTimeline> {
  final ScrollController _scroll = ScrollController();

  bool _hasSelection = false;

  bool _follows = true;

  bool _endScheduled = false;

  @override
  void initState() {
    super.initState();
    _follows = !widget.startAtTop;
    _showEnd();
  }

  @override
  void didUpdateWidget(covariant ChatTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.startAtTop) {
      _follows = false;
      if (!oldWidget.startAtTop) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
        });
      }
    } else if (widget.anchor != oldWidget.anchor ||
        (widget.forceFollow && !oldWidget.forceFollow)) {
      _follows = true;
    }
    _showEnd();
  }

  /// The reader decides: while they scroll it does not follow, and when they
  /// stop it follows only if they stopped at the end. Nested scrollables
  /// (a wide table) do not count.
  bool _onUserScroll(UserScrollNotification notification) {
    if (notification.depth == 0) {
      _follows =
          notification.direction == ScrollDirection.idle &&
          notification.metrics.extentAfter <
              AsystantTheme.of(context).timelineFollowThreshold;
    }
    return false;
  }

  /// The content or the viewport changed size without a new message.
  bool _onResize(ScrollMetricsNotification notification) {
    if (notification.depth == 0) {
      _showEnd();
    }
    return false;
  }

  /// After this frame's layout, when the timeline still follows.
  void _showEnd() {
    if (!_follows || _endScheduled) {
      return;
    }
    _endScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _endScheduled = false;
      if (mounted && _follows && !_hasSelection && _scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
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
    child: NotificationListener<UserScrollNotification>(
      onNotification: _onUserScroll,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: _onResize,
        child: ListView(
          controller: _scroll,
          padding: widget.padding,
          keyboardDismissBehavior: .onDrag,
          children: widget.children,
        ),
      ),
    ),
  );
}
