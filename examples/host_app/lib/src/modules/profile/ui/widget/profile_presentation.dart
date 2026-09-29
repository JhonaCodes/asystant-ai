import 'package:host_app/src/modules/profile/model/biological_sex.dart';
import 'package:host_app/src/modules/profile/model/habits.dart';
import 'package:host_app/src/shared/shared.dart';

extension BiologicalSexLabel on BiologicalSex {
  String get label => switch (this) {
    BiologicalSex.female => ProfileStrings.female,
    BiologicalSex.male => ProfileStrings.male,
    BiologicalSex.intersex => ProfileStrings.intersex,
    BiologicalSex.unspecified => ProfileStrings.unspecified,
  };
}

extension AnswerLabel on bool? {
  String get answer => switch (this) {
    true => ProfileStrings.yes,
    false => ProfileStrings.no,
    null => ProfileStrings.unknown,
  };
}

extension HabitsFacts on Habits {
  /// The habits the assistant recorded, as (label, value) pairs.
  List<(String, String)> get facts => [
    for (final (label, value) in [
      (ProfileStrings.smoking, smoking),
      (ProfileStrings.alcohol, alcohol),
      (ProfileStrings.caffeine, caffeine),
      (ProfileStrings.activity, activity),
      (ProfileStrings.sleep, sleep),
      (ProfileStrings.diet, diet),
    ])
      if (value.isNotEmpty) (label, value),
  ];
}
