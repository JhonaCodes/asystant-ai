import 'package:flutter/material.dart';

import 'package:asystant_ai/src/model/asystant_action_policy.dart';
import 'package:asystant_ai/src/l10n/asystant_strings.dart';

/// Compact and accessible sensitivity label shared by approvals and activity.
class AsystantSensitivityBadge extends StatelessWidget {
  const AsystantSensitivityBadge({
    super.key,
    required this.sensitivity,
    required this.strings,
    this.compact = false,
  });

  final AsystantSensitivity sensitivity;

  final AsystantStrings strings;

  /// Shows a small ticket icon for a dense activity row.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = sensitivity.color;
    final label = switch (sensitivity.level) {
      final AsystantSensitivityLevel level => strings.sensitivityLevel(level),
      null => sensitivity.name,
    };
    if (compact) {
      return Tooltip(
        message: label,
        child: Semantics(
          label: label,
          child: Container(
            width: 22,
            height: 22,
            alignment: .center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              border: Border.all(color: color.withValues(alpha: .65)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(Icons.local_offer_outlined, size: 14, color: color),
          ),
        ),
      );
    }
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .13),
          border: Border.all(color: color.withValues(alpha: .65)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: .circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
