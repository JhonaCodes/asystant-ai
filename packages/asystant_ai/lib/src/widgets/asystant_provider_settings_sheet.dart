import 'dart:async';

import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:asystant_ai/src/asystant_ai.dart';
import 'package:asystant_ai/src/l10n/asystant_strings.dart';
import 'package:asystant_ai/src/model/provider_settings_state.dart';
import 'package:asystant_ai/src/service/asystant_provider_settings.dart';
import 'package:asystant_ai/src/viewmodel/provider_settings_view_model.dart';

/// Library-owned settings for the primary chat provider and model.
Future<void> showAsystantProviderSettings(
  BuildContext context, {
  required AsystantAI assistant,
  AsystantStrings? strings,
}) {
  // Opening is the user's command, so the reset and load start here, before
  // the sheet's first frame, and never again on a rebuild of the sheet.
  unawaited(
    ProviderSettingsViewModel.of(
      assistant,
    ).open(assistant, strings ?? AsystantStrings.of(context)),
  );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) =>
        _ProviderSettingsSheet(assistant: assistant, strings: strings),
  );
}

extension _ProviderKindPresentation on AsystantProviderKind {
  String toLabel(AsystantStrings strings) => switch (this) {
    .backend => strings.providerAppAccount,
    .openAi => strings.providerOpenAi,
    .openRouter => strings.providerOpenRouter,
    .gemini => strings.providerGemini,
    .anthropic => strings.providerAnthropic,
    .compatible => strings.providerCompatible,
  };

  String toModelIdHint() => switch (this) {
    .openAi => 'gpt-…',
    .openRouter => 'openai/gpt-…',
    .gemini => 'gemini-…',
    .anthropic => 'claude-…',
    .backend || .compatible => 'provider/model',
  };
}

class _ProviderSettingsSheet extends StatelessWidget {
  const _ProviderSettingsSheet({required this.assistant, this.strings});

  final AsystantAI assistant;
  final AsystantStrings? strings;

  @override
  Widget build(BuildContext context) {
    final strings = this.strings ?? AsystantStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = keyboard > 0
        ? 0.0
        : MediaQueryData.fromView(View.of(context)).viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, keyboard + safeBottom + 20),
      child:
          ReactiveViewModelBuilder<
            ProviderSettingsViewModel,
            ProviderSettingsState
          >(
            viewmodel: ProviderSettingsViewModel.of(assistant),
            build: (state, viewModel, keep) => switch (state) {
              ProviderSettingsState(isLoading: true) => const Center(
                child: CircularProgressIndicator(),
              ),
              // No settings backend configured: an error state, not a crash.
              ProviderSettingsState(isAvailable: false) => Center(
                child: Text(
                  state.error ?? strings.providerSettingsUnavailable,
                  style: TextStyle(color: colors.error),
                ),
              ),
              _ => _ProviderSettingsForm(
                state: state,
                viewModel: viewModel,
                strings: strings,
              ),
            },
          ),
    );
  }
}

class _ProviderSettingsForm extends StatefulWidget {
  const _ProviderSettingsForm({
    required this.state,
    required this.viewModel,
    required this.strings,
  });

  final ProviderSettingsState state;
  final ProviderSettingsViewModel viewModel;
  final AsystantStrings strings;

  @override
  State<_ProviderSettingsForm> createState() => _ProviderSettingsFormState();
}

class _ProviderSettingsFormState extends State<_ProviderSettingsForm> {
  final _key = TextEditingController();
  late final _model = TextEditingController(text: widget.state.model);
  late final _baseUrl = TextEditingController(text: widget.state.baseUrl);
  late final _name = TextEditingController(text: widget.state.name);

  void _select(AsystantProviderKind kind) {
    _key.clear();
    _model.clear();
    unawaited(widget.viewModel.select(kind));
  }

  void _discardKey() {
    if (mounted) _key.clear();
  }

  Future<void> _save() async {
    final isApplied = await widget.viewModel.save(
      apiKey: _key.text,
      model: _model.text,
      baseUrl: _baseUrl.text,
      name: _name.text,
      onKeyStored: _discardKey,
    );
    if (isApplied && mounted) Navigator.of(context).pop();
  }

  Future<void> _verify() => widget.viewModel.verify(
    keyOverride: _key.text,
    model: _model.text,
    baseUrl: _baseUrl.text,
    name: _name.text,
  );

  Future<void> _removeKey() async {
    final isRemoved = await widget.viewModel.removeKey(
      onKeyRemoved: _discardKey,
    );
    if (isRemoved && mounted) Navigator.of(context).pop();
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
    final state = widget.state;
    final strings = widget.strings;
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Text(
            strings.providerSettingsTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            strings.providerSettingsDescription,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<AsystantProviderKind>(
            initialValue: state.kind,
            decoration: InputDecoration(labelText: strings.providerLabel),
            items: state.availableKinds
                .map(
                  (kind) => DropdownMenuItem(
                    value: kind,
                    child: Text(kind.toLabel(strings)),
                  ),
                )
                .toList(),
            onChanged: state.isSaving
                ? null
                : (kind) {
                    if (kind != null) _select(kind);
                  },
          ),
          const SizedBox(height: 14),
          if (state.usesHostProvider)
            _HostModelField(
              models: state.hostModels,
              controller: _model,
              isSaving: state.isSaving,
              strings: strings,
            )
          else
            _LocalProviderFields(
              state: state,
              keyController: _key,
              modelController: _model,
              baseUrlController: _baseUrl,
              nameController: _name,
              strings: strings,
            ),
          if (state.error case final error?) ...[
            const SizedBox(height: 12),
            Text(error, style: TextStyle(color: colors.error)),
          ],
          if (state.connection case final connection?) ...[
            const SizedBox(height: 12),
            Text(connection, style: TextStyle(color: colors.onSurfaceVariant)),
          ],
          const SizedBox(height: 20),
          _ProviderSettingsActions(
            state: state,
            strings: strings,
            onVerify: _verify,
            onSave: _save,
            onRemoveKey: _removeKey,
          ),
        ],
      ),
    );
  }
}

/// Model choice for the app account: the allowed list, or free text.
class _HostModelField extends StatelessWidget {
  const _HostModelField({
    required this.models,
    required this.controller,
    required this.isSaving,
    required this.strings,
  });

  final List<String> models;
  final TextEditingController controller;
  final bool isSaving;
  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) {
      return TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: strings.primaryModelOptional,
          helperText: strings.primaryModelAllowedHint,
        ),
      );
    }
    return DropdownButtonFormField<String>(
      initialValue: models.contains(controller.text) ? controller.text : '',
      decoration: InputDecoration(labelText: strings.primaryModel),
      items: [
        DropdownMenuItem(value: '', child: Text(strings.automatic)),
        ...models.map(
          (id) => DropdownMenuItem(
            value: id,
            child: Text(id, overflow: .ellipsis),
          ),
        ),
      ],
      onChanged: isSaving ? null : (id) => controller.text = id ?? '',
    );
  }
}

/// Model, endpoint and key fields for a provider the person configures.
class _LocalProviderFields extends StatelessWidget {
  const _LocalProviderFields({
    required this.state,
    required this.keyController,
    required this.modelController,
    required this.baseUrlController,
    required this.nameController,
    required this.strings,
  });

  final ProviderSettingsState state;
  final TextEditingController keyController;
  final TextEditingController modelController;
  final TextEditingController baseUrlController;
  final TextEditingController nameController;
  final AsystantStrings strings;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      TextField(
        controller: modelController,
        decoration: InputDecoration(
          labelText: strings.primaryModelId,
          hintText: state.kind.toModelIdHint(),
        ),
      ),
      if (state.kind == .compatible) ...[
        const SizedBox(height: 14),
        TextField(
          controller: nameController,
          decoration: InputDecoration(labelText: strings.providerName),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: baseUrlController,
          keyboardType: .url,
          decoration: InputDecoration(
            labelText: strings.providerBaseUrl,
            hintText: strings.providerBaseUrlHint,
          ),
        ),
      ],
      const SizedBox(height: 14),
      TextField(
        controller: keyController,
        obscureText: true,
        enableSuggestions: false,
        autocorrect: false,
        decoration: InputDecoration(
          labelText: strings.providerApiKey,
          helperText: state.hasKey ? strings.providerSavedKeyHint : null,
        ),
      ),
      if (state.kind == .anthropic) ...[
        const SizedBox(height: 8),
        Text(
          strings.providerClaudeApiHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ],
  );
}

class _ProviderSettingsActions extends StatelessWidget {
  const _ProviderSettingsActions({
    required this.state,
    required this.strings,
    required this.onVerify,
    required this.onSave,
    required this.onRemoveKey,
  });

  final ProviderSettingsState state;
  final AsystantStrings strings;
  final VoidCallback onVerify;
  final VoidCallback onSave;
  final VoidCallback onRemoveKey;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    crossAxisAlignment: .stretch,
    children: [
      if (!state.usesHostProvider) ...[
        OutlinedButton(
          onPressed: state.isSaving ? null : onVerify,
          child: Text(strings.providerTestConnection),
        ),
        const SizedBox(height: 8),
      ],
      FilledButton(
        onPressed: state.isSaving ? null : onSave,
        child: Text(
          state.isSaving ? strings.providerSaving : strings.providerSaveAndUse,
        ),
      ),
      if (state.canDeleteKey)
        TextButton(
          onPressed: state.isSaving ? null : onRemoveKey,
          child: Text(strings.providerDeleteLocalKey),
        ),
    ],
  );
}
