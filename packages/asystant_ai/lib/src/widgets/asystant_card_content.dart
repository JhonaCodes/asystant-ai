import 'package:flutter/widgets.dart';

import 'package:asystant_core/asystant_core.dart';

/// Builds optional host-owned content beneath a completed local tool card.
///
/// Return null for unsupported cards. Builders must be side-effect free: network,
/// file exports and navigation belong in explicit user callbacks. This extension
/// is never used for pending permission cards and cannot replace approval controls.
/// A host may subclass [AssistantCard] with typed domain data; override its JSON
/// codec when that data participates in equality or host persistence.
typedef AsystantCardContentBuilder = Widget? Function(
  BuildContext context,
  AssistantCard card,
);
