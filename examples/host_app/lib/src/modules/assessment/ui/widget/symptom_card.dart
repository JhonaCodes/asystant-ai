import 'package:flutter/material.dart';

import 'package:host_app/src/modules/assessment/model/symptom.dart';
import 'package:host_app/src/modules/assessment/ui/widget/assessment_presentation.dart';
import 'package:host_app/src/shared/shared.dart';

class SymptomCard extends StatelessWidget {
  const SymptomCard({super.key, required this.symptom});

  final Symptom symptom;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: SizedBox(
      width: double.infinity,
      child: BotanicaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              symptom.description,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            LabeledList(symptom.details),
          ],
        ),
      ),
    ),
  );
}
