import 'package:flutter/material.dart';

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
  );

  @override
  AsystantTheme lerp(covariant AsystantTheme? other, double t) =>
      t < .5 ? this : other ?? this;
}
