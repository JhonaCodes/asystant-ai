part of 'device.dart';

/// Screen-size cut points, in logical pixels.
///
/// These are the Material 3 / Android width qualifiers. They are applied to
/// the window's **shortest side**, never to its width: a phone held in
/// landscape has a wide window but is still a phone.
abstract final class DeviceBreakpoints {
  /// Below this, the window is a phone. Equivalent to Android `sw600dp`.
  static const double tablet = 600;

  /// At or above this, the window earns a desktop layout.
  static const double desktop = 900;

  /// Widest content column on a desktop layout.
  static const double maxContentWidth = 1280;

  /// Fixed sidebar width on a desktop layout.
  static const double sidebarWidth = 224;

  /// A window shorter than this never shows two stacked panels, because it is
  /// a phone lying on its side.
  static const double compactHeight = 480;
}
