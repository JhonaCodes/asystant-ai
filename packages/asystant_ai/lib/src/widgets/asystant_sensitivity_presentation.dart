import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/asystant_action_policy.dart';

/// The label a sensitivity badge reads out.
extension AsystantSensitivityPresentation on AsystantSensitivity {
  /// A known level is translated; a host-defined one keeps its own name.
  String toLabel(AsystantStrings strings) => switch (level) {
    final AsystantSensitivityLevel known => strings.sensitivityLevel(known),
    null => name,
  };
}
