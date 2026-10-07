import 'package:flutter/material.dart';

/// An action from the host app in the chat's conversation menu.
class AsystantMenuAction {
  const AsystantMenuAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;

  final IconData icon;

  final VoidCallback? onPressed;
}
