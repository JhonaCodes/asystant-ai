import 'package:flutter/material.dart';

/// The Material color for content of a control that cannot be used now.
extension AsystantDisabledColors on ColorScheme {
  Color get disabledContent => onSurface.withValues(alpha: .38);
}
