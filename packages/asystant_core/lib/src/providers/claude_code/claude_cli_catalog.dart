import 'dart:convert';

import 'package:asystant_core/src/model/asystant_model_catalog.dart';
import 'package:asystant_core/src/model/asystant_provider_status.dart';

/// Reading what the installed `claude` declares about itself, with no
/// inference.
///
/// The CLI has no model-listing command, but its `--help` states which
/// effort levels `--effort` accepts and gives the model aliases as examples
/// (checked against 2.1.232 and 2.1.280):
///
/// ```text
///   --effort <level>   Effort level for the current session
///                      (low, medium, high, xhigh, max)
///   --model <model>    Model for the current session. Provide an alias for
///                      the latest model (e.g. 'fable', 'opus', or 'sonnet')
///                      or a model's full name (e.g. 'claude-fable-5').
/// ```
///
/// Since the aliases are examples, not the whole list, the catalog is marked
/// [AsystantModelCatalog.isOpenList]: any full model name is accepted too.
abstract final class ClaudeCliCatalog {
  /// Used when the CLI cannot be asked or its help changed shape.
  static const bundledModels = ['sonnet', 'opus', 'haiku'];

  /// Used with [bundledModels]: the levels of `--effort` as of 2.1.280.
  static const bundledEfforts = ['low', 'medium', 'high', 'xhigh', 'max'];

  static const bundled = AsystantModelCatalog(
    models: bundledModels,
    efforts: bundledEfforts,
    isOpenList: true,
    source: AsystantCatalogSource.bundled,
  );

  /// The catalog in `claude --help`, or null when it declares neither
  /// models nor effort levels in the known format.
  static AsystantModelCatalog? parseHelp(String help) {
    // The help wraps long descriptions over indented lines.
    final flat = help.replaceAll(RegExp(r'\s+'), ' ');
    final efforts = RegExp(
      r'--effort <level>\s*Effort level for the current session \(([^)]+)\)',
    ).firstMatch(flat)?.group(1);
    final aliases = RegExp(
      r'--model <model>.*?an alias for the latest model \(([^)]+)\)',
    ).firstMatch(flat)?.group(1);
    final models = [
      for (final match in RegExp("'([^']+)'").allMatches(aliases ?? ''))
        if (match.group(1) case final String alias when alias.isNotEmpty) alias,
    ];
    final levels = [
      for (final level in (efforts ?? '').split(','))
        if (level.trim() case final String name when name.isNotEmpty) name,
    ];
    if (models.isEmpty && levels.isEmpty) {
      return null;
    }
    return AsystantModelCatalog(
      models: List.unmodifiable(models.isEmpty ? bundledModels : models),
      efforts: List.unmodifiable(levels),
      isOpenList: true,
      source: AsystantCatalogSource.live,
    );
  }

  /// The status from `claude --version` and `claude auth status --json`.
  ///
  /// [authStatus] is null when that command failed, as on an older CLI; the
  /// sign-in state is then unknown. The account keeps only the sign-in
  /// method and the plan: never the email or organization.
  static AsystantProviderStatus status({
    required String version,
    String? authStatus,
  }) {
    final Object? decoded;
    try {
      decoded = authStatus == null ? null : jsonDecode(authStatus);
    } on FormatException {
      return AsystantProviderStatus(
        provider: 'Claude Code',
        version: _version(version),
      );
    }
    return switch (decoded) {
      {'loggedIn': final bool loggedIn} && final Map<String, Object?> auth =>
        AsystantProviderStatus(
          provider: 'Claude Code',
          version: _version(version),
          signedIn: loggedIn,
          account: [
            if (auth['authMethod'] case final String method) method,
            if (auth['subscriptionType'] case final String plan) plan,
          ].join(' · '),
        ),
      _ => AsystantProviderStatus(
        provider: 'Claude Code',
        version: _version(version),
      ),
    };
  }

  /// `2.1.280 (Claude Code)` becomes `2.1.280`.
  static String _version(String output) =>
      output.trim().split(RegExp(r'\s+')).first;
}
