import 'package:flutter/material.dart';

/// Content supplied by the host for the library's control-center welcome.
@immutable
class AsystantDashboardModule {
  const AsystantDashboardModule({required this.label, required this.prompts});

  final String label;
  final List<String> prompts;
}

/// One capability the host highlights on the control-center welcome, with
/// the prompt that triggers it when the person taps the card.
@immutable
class AsystantDashboardCapability {
  const AsystantDashboardCapability({
    required this.icon,
    required this.title,
    required this.summary,
    required this.detail,
    required this.prompt,
  });

  final IconData icon;
  final String title;
  final String summary;
  final String detail;
  final String prompt;
}
