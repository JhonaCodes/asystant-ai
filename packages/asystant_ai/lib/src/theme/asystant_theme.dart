import 'package:flutter/material.dart';

/// Override through ThemeData.extensions. Defaults follow the host color scheme.
@immutable
/// Theme extension controlling chat spacing, widths and minimum action sizes.
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
  });
  final double radius,
      spacing,
      padding,
      iconSize,
      maxContentWidth,
      panelWidth,
      compactBreakpoint,
      actionHeight;
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
  }) => AsystantTheme(
    radius: radius ?? this.radius,
    spacing: spacing ?? this.spacing,
    padding: padding ?? this.padding,
    iconSize: iconSize ?? this.iconSize,
    maxContentWidth: maxContentWidth ?? this.maxContentWidth,
    panelWidth: panelWidth ?? this.panelWidth,
    compactBreakpoint: compactBreakpoint ?? this.compactBreakpoint,
    actionHeight: actionHeight ?? this.actionHeight,
  );
  @override
  AsystantTheme lerp(covariant AsystantTheme? other, double t) =>
      t < .5 ? this : other ?? this;
}
