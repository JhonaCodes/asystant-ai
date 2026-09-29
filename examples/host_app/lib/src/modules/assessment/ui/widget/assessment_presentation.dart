import 'package:flutter/material.dart';

import 'package:host_app/src/modules/assessment/model/assessment_status.dart';
import 'package:host_app/src/modules/assessment/model/symptom.dart';
import 'package:host_app/src/shared/shared.dart';

extension AssessmentStatusLabel on AssessmentStatus {
  String get label => switch (this) {
    AssessmentStatus.inProgress => AssessmentStrings.inProgress,
    AssessmentStatus.completed => AssessmentStrings.completed,
  };

  Color colorIn(BuildContext context) => switch (this) {
    AssessmentStatus.inProgress => BotanicaColors.of(context).caution,
    AssessmentStatus.completed => BotanicaColors.of(context).safe,
  };
}

extension SymptomDetails on Symptom {
  /// The facts of the symptom as short lines, skipping what is unknown.
  List<String> get details => [
    if (intensity case final value?) AssessmentStrings.intensity(value),
    if (durationDays case final value?) AssessmentStrings.days(value),
    if (onset.isNotEmpty) '${AssessmentStrings.since}: $onset',
    if (location.isNotEmpty) '${AssessmentStrings.where}: $location',
    if (aggravating.isNotEmpty)
      '${AssessmentStrings.worseWith}: ${aggravating.join(', ')}',
    if (relieving.isNotEmpty)
      '${AssessmentStrings.betterWith}: ${relieving.join(', ')}',
  ];
}
