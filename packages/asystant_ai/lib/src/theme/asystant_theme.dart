import 'package:flutter/material.dart';

import 'package:asystant_ai/src/theme/asystant_metrics.dart';

/// Theme extension controlling chat spacing, widths and minimum action sizes.
/// Override through ThemeData.extensions. Defaults follow the host color scheme.
@immutable
class AsystantTheme extends ThemeExtension<AsystantTheme> {
  const AsystantTheme({
    this.radius = 20,
    this.spacing = 12,
    this.padding = 20,
    this.iconSize = 20,
    this.maxContentWidth = 760,
    this.panelWidth = 460,
    this.compactBreakpoint = 600,
    this.actionHeight = 48,
    this.transitionDuration = const Duration(milliseconds: 180),
    this.progressStrokeWidth = 2,
    this.timelineFollowThreshold = 100,
    this.sheetHeightFactor = .92,
    this.permissionBorderOpacity = .4,
    this.chartHeight = 180,
    this.headerHeight = 72,
    this.identitySize = 36,
    this.composerRadius = 16,
    this.panelMinWidth = 380,
    this.panelMaxWidth = 560,
    this.panelWidthFactor = .42,
    this.panelExpandedFactor = 1.6,
    this.bubbleMaxWidth = 440,
    this.success,
    this.warning,
    this.compact = AsystantMetrics.compact,
    this.regular = AsystantMetrics.regular,
    this.compactBelowWidth = 480,
    this.sideListFromWidth = 640,
    this.sideListWidth = 280,
    this.stepImageHeight = 120,
  });

  final double radius;

  final double spacing;

  final double padding;

  final double iconSize;

  final double maxContentWidth;

  final double panelWidth;

  final double compactBreakpoint;

  final double actionHeight;

  final Duration transitionDuration;

  final double progressStrokeWidth;

  final double timelineFollowThreshold;

  final double sheetHeightFactor;

  final double permissionBorderOpacity;

  final double chartHeight;

  final double headerHeight;

  final double identitySize;

  final double composerRadius;

  /// Side panel width on tablets and desktops: a share of the window,
  /// clamped between the minimum and the maximum.
  final double panelMinWidth;

  final double panelMaxWidth;

  final double panelWidthFactor;

  /// How much wider the panel gets when expanded.
  final double panelExpandedFactor;

  final double bubbleMaxWidth;

  /// Completed steps; a green that reads on light and dark surfaces by default.
  final Color? success;

  /// Long-conversation notice.
  final Color? warning;

  /// Sizes when the chat is narrower than [compactBelowWidth].
  final AsystantMetrics compact;

  /// Sizes when the chat is at least [compactBelowWidth] wide.
  final AsystantMetrics regular;

  /// Chat width below which [compact] applies.
  final double compactBelowWidth;

  /// An expanded chat at least this wide shows the conversation list as a
  /// column beside the messages.
  final double sideListFromWidth;

  final double sideListWidth;

  /// Height of the images a tool returned, under its step.
  final double stepImageHeight;

  AsystantMetrics metricsFor(double chatWidth) =>
      chatWidth < compactBelowWidth ? compact : regular;

  /// Resolved [success] for the current brightness.
  Color successColor(BuildContext context) =>
      success ??
      switch (Theme.of(context).brightness) {
        Brightness.light => const Color(0xFF1D6F5C),
        Brightness.dark => const Color(0xFF7FD1B9),
      };

  /// Resolved [warning] for the current brightness.
  Color warningColor(BuildContext context) =>
      warning ??
      switch (Theme.of(context).brightness) {
        Brightness.light => const Color(0xFF8A6100),
        Brightness.dark => const Color(0xFFE9C46A),
      };

  /// A readable color on [background], chosen from its brightness, so an icon
  /// on a filled button stays visible with any host theme.
  static Color contrastOn(Color background) =>
      switch (ThemeData.estimateBrightnessForColor(background)) {
        Brightness.dark => const Color(0xFFFFFFFF),
        Brightness.light => const Color(0xFF111111),
      };

  static AsystantTheme of(BuildContext context) =>
      Theme.of(context).extension<AsystantTheme>() ?? const AsystantTheme();

  @override
  AsystantTheme copyWith({
    double? radius,
    double? spacing,
    double? padding,
    double? iconSize,
    double? maxContentWidth,
    double? panelWidth,
    double? compactBreakpoint,
    double? actionHeight,
    Duration? transitionDuration,
    double? progressStrokeWidth,
    double? timelineFollowThreshold,
    double? sheetHeightFactor,
    double? permissionBorderOpacity,
    double? chartHeight,
    double? headerHeight,
    double? identitySize,
    double? composerRadius,
    double? panelMinWidth,
    double? panelMaxWidth,
    double? panelWidthFactor,
    double? panelExpandedFactor,
    double? bubbleMaxWidth,
    Color? success,
    Color? warning,
    AsystantMetrics? compact,
    AsystantMetrics? regular,
    double? compactBelowWidth,
    double? sideListFromWidth,
    double? sideListWidth,
    double? stepImageHeight,
  }) => AsystantTheme(
    radius: radius ?? this.radius,
    spacing: spacing ?? this.spacing,
    padding: padding ?? this.padding,
    iconSize: iconSize ?? this.iconSize,
    maxContentWidth: maxContentWidth ?? this.maxContentWidth,
    panelWidth: panelWidth ?? this.panelWidth,
    compactBreakpoint: compactBreakpoint ?? this.compactBreakpoint,
    actionHeight: actionHeight ?? this.actionHeight,
    transitionDuration: transitionDuration ?? this.transitionDuration,
    progressStrokeWidth: progressStrokeWidth ?? this.progressStrokeWidth,
    timelineFollowThreshold:
        timelineFollowThreshold ?? this.timelineFollowThreshold,
    sheetHeightFactor: sheetHeightFactor ?? this.sheetHeightFactor,
    permissionBorderOpacity:
        permissionBorderOpacity ?? this.permissionBorderOpacity,
    chartHeight: chartHeight ?? this.chartHeight,
    headerHeight: headerHeight ?? this.headerHeight,
    identitySize: identitySize ?? this.identitySize,
    composerRadius: composerRadius ?? this.composerRadius,
    panelMinWidth: panelMinWidth ?? this.panelMinWidth,
    panelMaxWidth: panelMaxWidth ?? this.panelMaxWidth,
    panelWidthFactor: panelWidthFactor ?? this.panelWidthFactor,
    panelExpandedFactor: panelExpandedFactor ?? this.panelExpandedFactor,
    bubbleMaxWidth: bubbleMaxWidth ?? this.bubbleMaxWidth,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    compact: compact ?? this.compact,
    regular: regular ?? this.regular,
    compactBelowWidth: compactBelowWidth ?? this.compactBelowWidth,
    sideListFromWidth: sideListFromWidth ?? this.sideListFromWidth,
    sideListWidth: sideListWidth ?? this.sideListWidth,
    stepImageHeight: stepImageHeight ?? this.stepImageHeight,
  );

  @override
  AsystantTheme lerp(covariant AsystantTheme? other, double t) =>
      t < .5 ? this : other ?? this;
}
