import 'package:flutter/material.dart';

import 'package:asystant_ai/src/asystant_ai.dart';
import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/service/asystant_provider_settings.dart';

/// Library-owned settings for the primary chat provider and model.
Future<void> showAsystantProviderSettings(
  BuildContext context, {
  required AsystantAI assistant,
  AsystantStrings? strings,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) =>
      _ProviderSettingsSheet(assistant: assistant, strings: strings),
);

class _ProviderSettingsSheet extends StatefulWidget {
  const _ProviderSettingsSheet({required this.assistant, this.strings});

  final AsystantAI assistant;
  final AsystantStrings? strings;

  @override
  State<_ProviderSettingsSheet> createState() => _ProviderSettingsSheetState();
}

class _ProviderSettingsSheetState extends State<_ProviderSettingsSheet> {
  final _key = TextEditingController();
  final _model = TextEditingController();
  final _baseUrl = TextEditingController();
  final _name = TextEditingController();
  AsystantProviderKind _kind = .backend;
  bool _loading = true;
  bool _saving = false;
  bool _hasKey = false;
  String? _error;
  String? _connection;
  AsystantStrings get _strings => widget.strings ?? AsystantStrings.of(context);

  String _formatError(FormatException error) =>
      _strings.providerFormatError(error.message);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = widget.assistant.providerSettings;
    if (settings == null) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = _strings.providerSettingsUnavailable;
        });
      return;
    }
    try {
      final selected = await settings.load();
      final hasKey = await settings.hasKey(selected.kind);
      if (!mounted) return;
      setState(() {
        _kind = selected.kind;
        _model.text = selected.model;
        _baseUrl.text = selected.baseUrl;
        _name.text = selected.name;
        _hasKey = hasKey;
        _loading = false;
      });
    } on Object {
      if (mounted)
        setState(() {
          _loading = false;
          _error = _strings.providerSecureStorageReadFailed;
        });
    }
  }

  Future<void> _select(AsystantProviderKind kind) async {
    final settings = widget.assistant.providerSettings!;
    setState(() {
      _kind = kind;
      _hasKey = false;
      _error = null;
      _connection = null;
      _key.clear();
      _model.clear();
    });
    final hasKey = await settings.hasKey(kind);
    if (mounted && _kind == kind) setState(() => _hasKey = hasKey);
  }

  Future<void> _save() async {
    if (_saving) return;
    final settings = widget.assistant.providerSettings!;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await settings.save(
        AsystantProviderSelection(
          kind: _kind,
          model: _model.text.trim(),
          baseUrl: _baseUrl.text.trim(),
          name: _name.text.trim(),
        ),
        apiKey: _key.text,
      );
      _key.clear();
      await widget.assistant.refreshProvider();
      if (mounted) Navigator.of(context).pop();
    } on Object catch (error) {
      if (mounted)
        setState(() {
          _error = error is FormatException
              ? _formatError(error)
              : _strings.providerApplyFailed;
        });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _verify() async {
    if (_saving || _kind == .backend) return;
    setState(() {
      _saving = true;
      _error = null;
      _connection = null;
    });
    try {
      final selection = AsystantProviderSelection(
        kind: _kind,
        model: _model.text.trim(),
        baseUrl: _baseUrl.text.trim(),
        name: _name.text.trim(),
      );
      final provider = await widget.assistant.providerSettings!.provider(
        selection,
        keyOverride: _key.text,
      );
      final result = await provider.verify();
      if (mounted) {
        setState(() {
          _connection = result.when(
            ok: (_) => _strings.providerConnectionVerified,
            err: (_) => _strings.providerVerificationRejected,
          );
        });
      }
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = _formatError(error));
    } on Object {
      if (mounted) setState(() => _error = _strings.providerCheckFailed);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _removeKey() async {
    if (_saving || _kind == .backend) return;
    setState(() => _saving = true);
    try {
      final settings = widget.assistant.providerSettings!;
      await settings.save(const AsystantProviderSelection());
      await settings.deleteKey(_kind);
      _key.clear();
      await widget.assistant.refreshProvider();
      if (mounted) Navigator.of(context).pop();
    } on Object {
      if (mounted) {
        setState(() => _error = _strings.providerDeleteKeyFailed);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _key.clear();
    _key.dispose();
    _model.dispose();
    _baseUrl.dispose();
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = keyboard > 0
        ? 0.0
        : MediaQueryData.fromView(View.of(context)).viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, keyboard + safeBottom + 20),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .stretch,
                children: [
                  Text(
                    _strings.providerSettingsTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _strings.providerSettingsDescription,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<AsystantProviderKind>(
                    initialValue: _kind,
                    decoration: InputDecoration(
                      labelText: _strings.providerLabel,
                    ),
                    items: [
                      for (final kind
                          in widget.assistant.providerSettings!.availableKinds)
                        DropdownMenuItem(
                          value: kind,
                          child: Text(switch (kind) {
                            .backend => _strings.providerAppAccount,
                            .openAi => _strings.providerOpenAi,
                            .openRouter => _strings.providerOpenRouter,
                            .gemini => _strings.providerGemini,
                            .anthropic => _strings.providerAnthropic,
                            .compatible => _strings.providerCompatible,
                          }),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (kind) {
                            if (kind != null) _select(kind);
                          },
                  ),
                  if (_kind == .backend) ...[
                    const SizedBox(height: 14),
                    Builder(
                      builder: (context) {
                        final available =
                            widget.assistant.conversation.notifier.state.models;
                        if (available.isEmpty) {
                          return TextField(
                            controller: _model,
                            decoration: InputDecoration(
                              labelText: _strings.primaryModelOptional,
                              helperText: _strings.primaryModelAllowedHint,
                            ),
                          );
                        }
                        return DropdownButtonFormField<String>(
                          initialValue: available.contains(_model.text)
                              ? _model.text
                              : '',
                          decoration: InputDecoration(
                            labelText: _strings.primaryModel,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: '',
                              child: Text(_strings.automatic),
                            ),
                            for (final id in available)
                              DropdownMenuItem(
                                value: id,
                                child: Text(
                                  id,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _saving
                              ? null
                              : (id) => _model.text = id ?? '',
                        );
                      },
                    ),
                  ],
                  if (_kind != .backend) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _model,
                      decoration: InputDecoration(
                        labelText: _strings.primaryModelId,
                        hintText: switch (_kind) {
                          .openAi => 'gpt-…',
                          .openRouter => 'openai/gpt-…',
                          .gemini => 'gemini-…',
                          .anthropic => 'claude-…',
                          _ => 'provider/model',
                        },
                      ),
                    ),
                    if (_kind == .compatible) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: _name,
                        decoration: InputDecoration(
                          labelText: _strings.providerName,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _baseUrl,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: _strings.providerBaseUrl,
                          hintText: _strings.providerBaseUrlHint,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    TextField(
                      controller: _key,
                      obscureText: true,
                      enableSuggestions: false,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: _strings.providerApiKey,
                        helperText: _hasKey
                            ? _strings.providerSavedKeyHint
                            : null,
                      ),
                    ),
                    if (_kind == .anthropic) ...[
                      const SizedBox(height: 8),
                      Text(
                        _strings.providerClaudeApiHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: colors.error)),
                  ],
                  if (_connection != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _connection!,
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (_kind != .backend)
                    OutlinedButton(
                      onPressed: _saving ? null : _verify,
                      child: Text(_strings.providerTestConnection),
                    ),
                  if (_kind != .backend) const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(
                      _saving
                          ? _strings.providerSaving
                          : _strings.providerSaveAndUse,
                    ),
                  ),
                  if (_kind != .backend &&
                      _hasKey &&
                      widget.assistant.providerSettings!.availableKinds
                          .contains(AsystantProviderKind.backend))
                    TextButton(
                      onPressed: _saving ? null : _removeKey,
                      child: Text(_strings.providerDeleteLocalKey),
                    ),
                ],
              ),
            ),
    );
  }
}
