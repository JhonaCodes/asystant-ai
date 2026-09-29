import 'package:flutter/widgets.dart';

/// Screen class from the window's shortest side, so a phone in landscape is
/// still a phone: mobile below 600, tablet from 600 to 899, desktop from 900.
enum AsystantDeviceType {
  mobile,
  tablet,
  desktop;

  static AsystantDeviceType fromShortestSide(double side) => switch (side) {
    < 600 => AsystantDeviceType.mobile,
    < 900 => AsystantDeviceType.tablet,
    _ => AsystantDeviceType.desktop,
  };
}

extension AsystantDeviceTypeOf on BuildContext {
  AsystantDeviceType get asystantDeviceType =>
      AsystantDeviceType.fromShortestSide(MediaQuery.sizeOf(this).shortestSide);
}
