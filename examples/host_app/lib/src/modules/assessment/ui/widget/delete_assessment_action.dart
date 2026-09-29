import 'package:flutter/material.dart';

import 'package:host_app/src/modules/assessment/viewmodel/assessment_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

/// Deletes the consultation after asking; [onDeleted] runs when it is gone.
class DeleteAssessmentAction extends StatelessWidget {
  const DeleteAssessmentAction({
    super.key,
    required this.assessmentId,
    required this.viewModel,
    this.onDeleted,
  });

  final String assessmentId;

  final AssessmentViewModel viewModel;

  final VoidCallback? onDeleted;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await ConfirmDialog.ask(
      context,
      title: AssessmentStrings.deleteTitle,
      body: AssessmentStrings.deleteBody,
    );
    if (!confirmed) {
      return;
    }
    final deleted = await viewModel.deleteAssessment(assessmentId);
    if (deleted.isOk) {
      onDeleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AssessmentStrings.deleteAssessment,
    icon: const Icon(Icons.delete_outline),
    onPressed: () => _delete(context),
  );
}
