part of 'device.dart';

/// Picks the view that belongs to the current window class.
///
/// A screen calls this exactly once, at its root. [tablet] and [desktop] fall
/// back to the next narrower layout when a feature does not need a distinct
/// one, so a screen only names the variants it actually has.
class DeviceLayout extends StatelessWidget {
  const DeviceLayout({
    required this.mobile,
    this.tablet,
    this.desktop,
    super.key,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) => switch (context.deviceType) {
    DeviceType.mobile => mobile,
    DeviceType.tablet => tablet ?? mobile,
    DeviceType.desktop => desktop ?? tablet ?? mobile,
  };
}
