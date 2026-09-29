import 'package:flutter/widgets.dart';

/// Component sizes for one chat density.
///
/// The chat picks [AsystantMetrics.compact] or [AsystantMetrics.regular]
/// from its own width (see `AsystantTheme.compactBelowWidth`), so a narrow
/// side panel on a tablet is as dense as a phone.
@immutable
class AsystantMetrics {
  const AsystantMetrics({
    required this.headerHeight,
    required this.identitySize,
    required this.identityRadius,
    required this.listPadding,
    required this.messageGap,
    required this.bubblePadding,
    required this.bubbleRadius,
    required this.bubbleWidthFactor,
    required this.flatAssistantBubble,
    required this.showsUserLabel,
    required this.composerPadding,
    required this.composerInnerPadding,
    required this.sendSize,
    required this.cardPadding,
    required this.listMaxWidth,
    required this.showsHeaderDelete,
  });

  /// Phones and narrow panels: more room for the conversation.
  static const compact = AsystantMetrics(
    headerHeight: 56,
    identitySize: 32,
    identityRadius: 10,
    listPadding: EdgeInsets.fromLTRB(16, 12, 16, 8),
    messageGap: 12,
    bubblePadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    bubbleRadius: 14,
    bubbleWidthFactor: .8,
    flatAssistantBubble: true,
    showsUserLabel: false,
    composerPadding: EdgeInsets.fromLTRB(12, 8, 12, 4),
    composerInnerPadding: 4,
    sendSize: 40,
    cardPadding: 12,
    listMaxWidth: 390,
    showsHeaderDelete: false,
  );

  /// Wide panels and full screens: the reference layout.
  static const regular = AsystantMetrics(
    headerHeight: 72,
    identitySize: 36,
    identityRadius: 11,
    listPadding: EdgeInsets.fromLTRB(18, 22, 18, 14),
    messageGap: 20,
    bubblePadding: EdgeInsets.all(16),
    bubbleRadius: 14,
    bubbleWidthFactor: .85,
    flatAssistantBubble: false,
    showsUserLabel: true,
    composerPadding: EdgeInsets.fromLTRB(16, 12, 16, 8),
    composerInnerPadding: 8,
    sendSize: 44,
    cardPadding: 16,
    listMaxWidth: 360,
    showsHeaderDelete: true,
  );

  final double headerHeight;

  final double identitySize;

  final double identityRadius;

  /// Around the list of messages.
  final EdgeInsets listPadding;

  /// Between one message and the next.
  final double messageGap;

  final EdgeInsets bubblePadding;

  final double bubbleRadius;

  /// Widest a bubble gets, as a share of the list's width.
  final double bubbleWidthFactor;

  /// Assistant text without a bubble, as plain text across the width.
  final bool flatAssistantBubble;

  /// "You" above the person's messages.
  final bool showsUserLabel;

  final EdgeInsets composerPadding;

  final double composerInnerPadding;

  final double sendSize;

  /// Inside activity, confirmation and notice cards.
  final double cardPadding;

  /// Widest the conversation list gets over the chat.
  final double listMaxWidth;

  /// The delete action sits in the header instead of the overflow menu.
  final bool showsHeaderDelete;

  static AsystantMetrics of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AsystantMetricsScope>()
          ?.metrics ??
      regular;

  AsystantMetrics copyWith({
    double? headerHeight,
    double? identitySize,
    double? identityRadius,
    EdgeInsets? listPadding,
    double? messageGap,
    EdgeInsets? bubblePadding,
    double? bubbleRadius,
    double? bubbleWidthFactor,
    bool? flatAssistantBubble,
    bool? showsUserLabel,
    EdgeInsets? composerPadding,
    double? composerInnerPadding,
    double? sendSize,
    double? cardPadding,
    double? listMaxWidth,
    bool? showsHeaderDelete,
  }) => AsystantMetrics(
    headerHeight: headerHeight ?? this.headerHeight,
    identitySize: identitySize ?? this.identitySize,
    identityRadius: identityRadius ?? this.identityRadius,
    listPadding: listPadding ?? this.listPadding,
    messageGap: messageGap ?? this.messageGap,
    bubblePadding: bubblePadding ?? this.bubblePadding,
    bubbleRadius: bubbleRadius ?? this.bubbleRadius,
    bubbleWidthFactor: bubbleWidthFactor ?? this.bubbleWidthFactor,
    flatAssistantBubble: flatAssistantBubble ?? this.flatAssistantBubble,
    showsUserLabel: showsUserLabel ?? this.showsUserLabel,
    composerPadding: composerPadding ?? this.composerPadding,
    composerInnerPadding: composerInnerPadding ?? this.composerInnerPadding,
    sendSize: sendSize ?? this.sendSize,
    cardPadding: cardPadding ?? this.cardPadding,
    listMaxWidth: listMaxWidth ?? this.listMaxWidth,
    showsHeaderDelete: showsHeaderDelete ?? this.showsHeaderDelete,
  );

  @override
  bool operator ==(Object other) =>
      other is AsystantMetrics &&
      headerHeight == other.headerHeight &&
      identitySize == other.identitySize &&
      identityRadius == other.identityRadius &&
      listPadding == other.listPadding &&
      messageGap == other.messageGap &&
      bubblePadding == other.bubblePadding &&
      bubbleRadius == other.bubbleRadius &&
      bubbleWidthFactor == other.bubbleWidthFactor &&
      flatAssistantBubble == other.flatAssistantBubble &&
      showsUserLabel == other.showsUserLabel &&
      composerPadding == other.composerPadding &&
      composerInnerPadding == other.composerInnerPadding &&
      sendSize == other.sendSize &&
      cardPadding == other.cardPadding &&
      listMaxWidth == other.listMaxWidth &&
      showsHeaderDelete == other.showsHeaderDelete;

  @override
  int get hashCode => Object.hash(
    headerHeight,
    identitySize,
    identityRadius,
    listPadding,
    messageGap,
    bubblePadding,
    bubbleRadius,
    bubbleWidthFactor,
    flatAssistantBubble,
    showsUserLabel,
    composerPadding,
    composerInnerPadding,
    sendSize,
    cardPadding,
    listMaxWidth,
    showsHeaderDelete,
  );
}

/// Hands the chat's density to every widget inside it.
class AsystantMetricsScope extends InheritedWidget {
  const AsystantMetricsScope({
    super.key,
    required this.metrics,
    required super.child,
  });

  final AsystantMetrics metrics;

  @override
  bool updateShouldNotify(AsystantMetricsScope oldWidget) =>
      metrics != oldWidget.metrics;
}
