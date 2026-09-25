import 'package:flutter/material.dart';

import '../model/chat_state.dart';
import '../viewmodel/chat_view_model.dart';
import '../l10n/asystant_strings.dart';

extension ModelDisplayName on String {
  String get displayModelName => split('/').last;
}

class ChatModelPicker extends StatelessWidget {
  const ChatModelPicker({
    super.key,
    required this.state,
    required this.viewModel,
    required this.strings,
  });
  final ChatState state;
  final ChatViewModel viewModel;
  final AsystantStrings strings;
  @override
  Widget build(BuildContext context) =>
      switch (state.allowModelSelection && state.models.length > 1) {
        true => DropdownButton<String>(
          value: state.model,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          hint: Text(strings.model),
          items: state.models
              .map(
                (model) => DropdownMenuItem(
                  value: model,
                  child: Text(
                    model,
                    overflow: .ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              )
              .toList(),
          onChanged: state.busy
              ? null
              : (model) {
                  if (model case final selected?) {
                    viewModel.selectModel(selected);
                  }
                },
        ),
        false => Text(
          state.model.displayModelName,
          overflow: .ellipsis,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      };
}
