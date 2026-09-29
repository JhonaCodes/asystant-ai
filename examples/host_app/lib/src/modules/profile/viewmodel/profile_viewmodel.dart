import 'package:logger_rs/logger_rs.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'package:result_controller/result_controller.dart';
import 'package:uuid/uuid.dart';

import 'package:host_app/src/core/network/api_failure.dart';
import 'package:host_app/src/core/services/loaded_state.dart';
import 'package:host_app/src/modules/profile/model/biological_sex.dart';
import 'package:host_app/src/modules/profile/model/habits.dart';
import 'package:host_app/src/modules/profile/model/person_profile.dart';
import 'package:host_app/src/modules/profile/model/profile_entries.dart';
import 'package:host_app/src/modules/profile/repository/profile_repository.dart';

/// The person's history. The assistant fills it through these methods; the
/// app only shows it and lets the person erase it.
///
/// Every change starts from the loaded profile ([loaded]); a change that
/// arrives while it is still loading waits for it instead of saving on top
/// of an empty one.
class ProfileViewModel extends AsyncViewModelImpl<PersonProfile>
    with LoadedState<PersonProfile> {
  ProfileViewModel() : super(AsyncState.initial());

  ProfileRepository get _repository => const ProfileRepository();

  @override
  Future<PersonProfile> init() async {
    final loaded = await _repository.fetch();
    return loaded.when(
      ok: (profile) => profile,
      err: (failure) => throw failure,
    );
  }

  /// The profile on screen, or empty while loading or after a failure.
  PersonProfile get current =>
      hasData ? data ?? PersonProfile.empty : PersonProfile.empty;

  /// The person's age today, when the birth date is known.
  int? get age => current.ageAt(DateTime.now());

  Future<Result<PersonProfile, ApiFailure>> savePersonalData({
    String? displayName,
    DateTime? birthDate,
    BiologicalSex? sex,
    double? weightKg,
    double? heightCm,
  }) => _commit(
    (profile) => profile.copyWith(
      displayName: displayName,
      birthDate: birthDate,
      sex: sex,
      weightKg: weightKg,
      heightCm: heightCm,
    ),
  );

  /// What the person told the assistant, saved at once: all of it is kept
  /// or none of it. What is already recorded stays as it is.
  Future<Result<PersonProfile, ApiFailure>> record({
    int? age,
    BiologicalSex? sex,
    bool? isPregnant,
    bool? isLactating,
    List<HealthCondition> conditions = const [],
    List<Allergy> allergies = const [],
  }) => _commit(
    (profile) => profile.withFacts(
      today: DateTime.now(),
      age: age,
      sex: sex,
      isPregnant: isPregnant,
      isLactating: isLactating,
      conditions: [
        for (final condition in conditions)
          condition.copyWith(id: _idOr(condition.id)),
      ],
      allergies: [
        for (final allergy in allergies)
          allergy.copyWith(id: _idOr(allergy.id)),
      ],
    ),
  );

  Future<Result<PersonProfile, ApiFailure>> removeCondition(String id) =>
      _commit(
        (profile) => profile.copyWith(
          conditions: profile.conditions
              .where((item) => item.id != id)
              .toList(),
        ),
      );

  Future<Result<PersonProfile, ApiFailure>> addMedication(
    Medication medication,
  ) => _commit(
    (profile) => profile.hasMedication(medication)
        ? profile
        : profile.copyWith(
            medications: [
              ...profile.medications,
              medication.copyWith(id: _idOr(medication.id)),
            ],
          ),
  );

  Future<Result<PersonProfile, ApiFailure>> removeMedication(String id) =>
      _commit(
        (profile) => profile.copyWith(
          medications: profile.medications
              .where((item) => item.id != id)
              .toList(),
        ),
      );

  Future<Result<PersonProfile, ApiFailure>> removeAllergy(String id) => _commit(
    (profile) => profile.copyWith(
      allergies: profile.allergies.where((item) => item.id != id).toList(),
    ),
  );

  Future<Result<PersonProfile, ApiFailure>> saveHabits(Habits habits) =>
      _commit((profile) => profile.copyWith(habits: habits));

  Future<Result<PersonProfile, ApiFailure>> saveFamilyHistory(
    List<String> items,
  ) => _commit((profile) => profile.copyWith(familyHistory: items));

  /// Erases everything recorded about the person.
  Future<Result<bool, ApiFailure>> deleteProfile() async {
    final removed = await _repository.remove();
    return removed.when(
      ok: (_) {
        updateState(PersonProfile.empty);
        return Ok(true);
      },
      err: (failure) {
        // Nothing saved yet is not an error for the person.
        if (failure.title == 'not_found') {
          updateState(PersonProfile.empty);
          return Ok(true);
        }
        Log.w('Deleting the profile failed: ${failure.msm}');
        return Err(failure);
      },
    );
  }

  Future<Result<PersonProfile, ApiFailure>> _commit(
    PersonProfile Function(PersonProfile profile) change,
  ) async {
    final base = await loaded();
    if (base == null) {
      return Err(AppFailures.notReady('The profile'));
    }
    final saved = await _repository.save(change(base));
    return saved.when(
      ok: (profile) {
        updateState(profile);
        return Ok(profile);
      },
      err: (failure) {
        Log.w('Saving the profile failed: ${failure.msm}');
        return Err(failure);
      },
    );
  }

  static String _idOr(String id) => id.isEmpty ? const Uuid().v4() : id;
}

mixin ProfileService {
  static final ReactiveNotifier<ProfileViewModel> profile =
      ReactiveNotifier<ProfileViewModel>(ProfileViewModel.new);

  static ProfileViewModel get notifier => profile.notifier;
}
