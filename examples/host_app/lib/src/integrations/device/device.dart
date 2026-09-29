/// Device classification and adaptive layout.
///
/// Single import point for the whole app. Nothing else in the project may
/// read `MediaQuery` or use `LayoutBuilder` to decide which platform it is
/// rendering for: that question is answered here and only here.
library;

import 'package:flutter/widgets.dart';

part 'device_breakpoints.dart';
part 'device_type.dart';
part 'device_context.dart';
part 'device_layout.dart';
