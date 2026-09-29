part of 'device.dart';

/// Reads the window classification off a [BuildContext].
///
/// This is the only sanctioned way for presentation code to ask what it is
/// rendering on.
extension DeviceContext on BuildContext {
  /// The class of window this subtree is being laid out in.
  DeviceType get deviceType => DeviceType.fromSize(MediaQuery.sizeOf(this));

  bool get isMobile => deviceType.isMobile;
  bool get isTablet => deviceType.isTablet;
  bool get isDesktop => deviceType.isDesktop;

  /// True when the window is wider than it is tall.
  bool get isLandscape => MediaQuery.sizeOf(this).aspectRatio > 1;

  /// True when the window is too short to stack two panels, regardless of its
  /// classification. A phone in landscape hits this.
  bool get isCompactHeight =>
      MediaQuery.sizeOf(this).height < DeviceBreakpoints.compactHeight;

  /// Outer page margin for this window class.
  double get pageMargin => deviceType.pageMargin;
}
