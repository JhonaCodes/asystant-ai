part of 'device.dart';

/// The class of window the app is rendering into.
///
/// Derived from the window's shortest side so that rotating a device never
/// reclassifies it.
enum DeviceType {
  mobile,
  tablet,
  desktop;

  /// Classifies a window by its shortest side.
  factory DeviceType.fromSize(Size size) => switch (size.shortestSide) {
    < DeviceBreakpoints.tablet => DeviceType.mobile,
    < DeviceBreakpoints.desktop => DeviceType.tablet,
    _ => DeviceType.desktop,
  };

  bool get isMobile => this == DeviceType.mobile;
  bool get isTablet => this == DeviceType.tablet;
  bool get isDesktop => this == DeviceType.desktop;

  /// Outer page margin for this window class.
  double get pageMargin => switch (this) {
    DeviceType.mobile => 16,
    DeviceType.tablet => 24,
    DeviceType.desktop => 32,
  };

  /// Whether navigation destinations belong in a bottom bar rather than a
  /// side rail or sidebar.
  bool get usesBottomNavigation => this == DeviceType.mobile;
}
