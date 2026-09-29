import 'package:flutter/material.dart';

import 'package:host_app/src/modules/assessment/model/assessment.dart';
import 'package:host_app/src/modules/assessment/ui/widget/assessment_presentation.dart';
import 'package:host_app/src/shared/shared.dart';

/// One consultation in the list.
class AssessmentTile extends StatelessWidget {
  const AssessmentTile({
    super.key,
    required this.assessment,
    required this.onTap,
    this.selected = false,
  });

  final Assessment assessment;

  final VoidCallback onTap;

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? colors.secondaryContainer
            : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: onTap,
          title: Text(
            assessment.reason,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${assessment.createdAt.shortDate} · '
            '${AssessmentStrings.counts(assessment.symptoms.length, assessment.goals.length)}',
          ),
          trailing: StatusBadge(
            label: assessment.status.label,
            color: assessment.status.colorIn(context),
          ),
        ),
      ),
    );
  }
}
