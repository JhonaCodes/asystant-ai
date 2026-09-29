import 'package:flutter_test/flutter_test.dart';

import 'package:host_app/src/modules/profile/model/biological_sex.dart';
import 'package:host_app/src/modules/profile/model/person_profile.dart';
import 'package:host_app/src/modules/profile/model/profile_entries.dart';

void main() {
  final today = DateTime(2026, 9, 28);

  PersonProfile told(PersonProfile profile, {required DateTime on}) =>
      profile.withFacts(
        today: on,
        age: 35,
        sex: BiologicalSex.female,
        isPregnant: false,
        conditions: const [
          HealthCondition(id: 'a', description: 'Reflujo', tag: 'gerd'),
          HealthCondition(id: 'b', description: 'agruras', tag: 'gerd'),
        ],
        allergies: const [Allergy(id: 'c', description: 'Polen')],
      );

  test('what the person says is recorded once, with an exact age', () {
    final profile = told(PersonProfile.empty, on: today);

    expect(profile.ageAt(today), 35);
    expect(profile.sex, BiologicalSex.female);
    expect(profile.isPregnant, isFalse);
    expect(profile.conditions.map((item) => item.tag), ['gerd']);
    expect(profile.allergies.map((item) => item.description), ['Polen']);
  });

  test('saying it again, even days later, changes nothing', () {
    final first = told(PersonProfile.empty, on: today);

    final again = told(first, on: today.add(const Duration(days: 3)));

    expect(again.birthDate, first.birthDate);
    expect(again.conditions, first.conditions);
    expect(again.allergies, first.allergies);
  });
}
