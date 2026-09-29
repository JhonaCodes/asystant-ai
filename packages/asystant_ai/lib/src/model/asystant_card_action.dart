import 'package:flutter/foundation.dart';

/// A button of an [AsystantHostCard]: what it says and what the host does
/// when the person presses it.
///
/// ```dart
/// AsystantCardAction(label: 'Approve', onPressed: approve, isPrimary: true)
/// ```
@immutable
class AsystantCardAction {
  const AsystantCardAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String label;

  /// Runs only after an explicit press; null draws the button disabled,
  /// e.g. while a turn is running.
  final VoidCallback? onPressed;

  /// The action the card leads to, drawn filled; the others are outlined.
  final bool isPrimary;

  AsystantCardAction copyWith({
    String? label,
    VoidCallback? onPressed,
    bool? isPrimary,
  }) => AsystantCardAction(
    label: label ?? this.label,
    onPressed: onPressed ?? this.onPressed,
    isPrimary: isPrimary ?? this.isPrimary,
  );

  @override
  bool operator ==(Object other) =>
      other is AsystantCardAction &&
      label == other.label &&
      onPressed == other.onPressed &&
      isPrimary == other.isPrimary;

  @override
  int get hashCode => Object.hash(label, onPressed, isPrimary);
}
