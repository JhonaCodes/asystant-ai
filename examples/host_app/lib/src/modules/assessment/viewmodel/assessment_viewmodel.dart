import 'dart:typed_data';

import 'package:logger_rs/logger_rs.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'package:result_controller/result_controller.dart';

import 'package:host_app/src/core/network/api_failure.dart';
import 'package:uuid/uuid.dart';

import 'package:host_app/src/core/network/file_transfer.dart';
import 'package:host_app/src/core/services/loaded_state.dart';
import 'package:host_app/src/core/network/file_upload.dart';
import 'package:host_app/src/modules/assessment/model/assessment.dart';
import 'package:host_app/src/modules/assessment/model/assessment_log.dart';
import 'package:host_app/src/modules/assessment/model/assessment_status.dart';
import 'package:host_app/src/modules/assessment/model/clinical_photo.dart';
import 'package:host_app/src/modules/assessment/model/goal.dart';
import 'package:host_app/src/modules/assessment/model/recommendation_snapshot.dart';
import 'package:host_app/src/modules/assessment/model/symptom.dart';
import 'package:host_app/src/modules/assessment/repository/assessment_repository.dart';
import 'package:host_app/src/modules/reference/viewmodel/reference_viewmodel.dart';

/// Every consultation. The assistant records them through these methods; the
/// app shows them and lets the person delete them.
class AssessmentViewModel extends AsyncViewModelImpl<AssessmentLog>
    with LoadedState<AssessmentLog> {
  AssessmentViewModel() : super(AsyncState.initial());

  AssessmentRepository get _repository => const AssessmentRepository();

  FileTransfer get _files => const FileTransfer();

  @override
  Future<AssessmentLog> init() async {
    final loaded = await _repository.fetchAll();
    return loaded.when(
      ok: (items) => AssessmentLog(items: _newestFirst(items)),
      err: (failure) => throw failure,
    );
  }

  AssessmentLog get current =>
      hasData ? data ?? const AssessmentLog() : const AssessmentLog();

  /// The readable name of a symptom or goal tag.
  String labelOf(String tag) => ReferenceService.notifier.labelOf(tag);

  /// The readable name of a recorded warning sign.
  String redFlagLabel(String ruleId) =>
      ReferenceService.notifier.current.ruleFor(ruleId)?.label ?? ruleId;

  void select(String? id) =>
      updateState(current.copyWith(selectedId: id, clearSelection: id == null));

  Future<Result<Assessment, ApiFailure>> startAssessment({
    required String reason,
  }) async {
    // Written after the list loaded, so the load cannot drop it afterwards.
    if (await _notReady() case final ApiFailure failure) {
      return Err(failure);
    }
    final created = await _repository.create(reason: reason);
    return created.when(
      ok: (assessment) {
        _put(assessment);
        return Ok(assessment);
      },
      err: _logged,
    );
  }

  Future<Result<Assessment, ApiFailure>> updateReason(
    String id,
    String reason,
  ) => _change(id, (item) => item.copyWith(reason: reason));

  Future<Result<Assessment, ApiFailure>> saveSummary(
    String id,
    String summary,
  ) => _change(id, (item) => item.copyWith(summary: summary));

  Future<Result<Assessment, ApiFailure>> complete(String id) =>
      _change(id, (item) => item.copyWith(status: AssessmentStatus.completed));

  /// Recorded once: the same symptom said again changes nothing.
  Future<Result<Assessment, ApiFailure>> addSymptom(
    String id,
    Symptom symptom,
  ) => _change(
    id,
    (item) => item.hasSymptom(symptom)
        ? item
        : item.copyWith(
            symptoms: [
              ...item.symptoms,
              symptom.copyWith(id: _idOr(symptom.id)),
            ],
          ),
  );

  Future<Result<Assessment, ApiFailure>> updateSymptom(
    String id,
    Symptom symptom,
  ) => _change(
    id,
    (item) => item.copyWith(
      symptoms: [
        for (final existing in item.symptoms)
          existing.id == symptom.id ? symptom : existing,
      ],
    ),
  );

  Future<Result<Assessment, ApiFailure>> removeSymptom(
    String id,
    String symptomId,
  ) => _change(
    id,
    (item) => item.copyWith(
      symptoms: item.symptoms.where((s) => s.id != symptomId).toList(),
    ),
  );

  Future<Result<Assessment, ApiFailure>> addGoal(String id, Goal goal) =>
      _change(
        id,
        (item) => item.hasGoal(goal)
            ? item
            : item.copyWith(
                goals: [
                  ...item.goals,
                  goal.copyWith(id: _idOr(goal.id)),
                ],
              ),
      );

  Future<Result<Assessment, ApiFailure>> removeGoal(String id, String goalId) =>
      _change(
        id,
        (item) => item.copyWith(
          goals: item.goals.where((g) => g.id != goalId).toList(),
        ),
      );

  Future<Result<Assessment, ApiFailure>> recordRedFlag(
    String id,
    String ruleId,
  ) => _change(
    id,
    (item) => item.copyWith(redFlagIds: {...item.redFlagIds, ruleId}.toList()),
  );

  Future<Result<Assessment, ApiFailure>> removeRedFlag(
    String id,
    String ruleId,
  ) => _change(
    id,
    (item) => item.copyWith(
      redFlagIds: item.redFlagIds.where((flag) => flag != ruleId).toList(),
    ),
  );

  Future<Result<Assessment, ApiFailure>> saveRecommendation(
    String id,
    RecommendationSnapshot snapshot,
  ) => _change(id, (item) => item.copyWith(recommendation: snapshot));

  /// Stores a photo for the assessment, e.g. of the affected skin.
  Future<Result<Assessment, ApiFailure>> attachPhoto(
    String id, {
    required Uint8List bytes,
    required String filename,
    String mimeType = 'image/jpeg',
    String caption = '',
    String bodyArea = '',
  }) async {
    if (await _notReady() case final ApiFailure failure) {
      return Err(failure);
    }
    if (current.byId(id) == null) {
      return Err(_missing(id));
    }
    final uploaded = await _files.upload(
      FileUpload(bytes: bytes, filename: filename, mimeType: mimeType),
    );
    final file = uploaded.when(ok: (file) => file, err: (_) => null);
    if (file == null) {
      return Err(uploaded.errorOrNull ?? _missing(id));
    }
    final photo = ClinicalPhoto(
      id: file.id,
      ref: file.ref,
      takenAt: DateTime.now().toUtc(),
      caption: caption,
      bodyArea: bodyArea,
    );
    final updated = await _change(
      id,
      (item) => item.copyWith(photos: [...item.photos, photo]),
    );
    if (updated.isErr) {
      // The record did not take the photo; do not leave the file behind.
      await _files.remove(file.id);
    }
    return updated;
  }

  Future<Result<Assessment, ApiFailure>> removePhoto(
    String id,
    String photoId,
  ) async {
    final updated = await _change(
      id,
      (item) => item.copyWith(
        photos: item.photos.where((photo) => photo.id != photoId).toList(),
      ),
    );
    if (updated.isOk) {
      await _files.remove(photoId);
    }
    return updated;
  }

  /// Deletes the assessment and its photos.
  Future<Result<bool, ApiFailure>> deleteAssessment(String id) async {
    if (await _notReady() case final ApiFailure failure) {
      return Err(failure);
    }
    final assessment = current.byId(id);
    if (assessment == null) {
      return Err(_missing(id));
    }
    final removed = await _repository.remove(id);
    if (removed.errorOrNull case final ApiFailure failure) {
      Log.w('Deleting assessment $id failed: ${failure.msm}');
      return Err(failure);
    }
    for (final photo in assessment.photos) {
      await _files.remove(photo.id);
    }
    updateState(
      current.copyWith(
        items: current.items.where((item) => item.id != id).toList(),
        clearSelection: current.selectedId == id,
      ),
    );
    return Ok(true);
  }

  Future<Result<Assessment, ApiFailure>> _change(
    String id,
    Assessment Function(Assessment assessment) change,
  ) async {
    if (await _notReady() case final ApiFailure failure) {
      return Err(failure);
    }
    final assessment = current.byId(id);
    if (assessment == null) {
      return Err(_missing(id));
    }
    final replaced = await _repository.replace(change(assessment));
    return replaced.when(
      ok: (saved) {
        _put(saved);
        return Ok(saved);
      },
      err: _logged,
    );
  }

  /// Null once the list is loaded; the failure when it cannot load.
  Future<ApiFailure?> _notReady() async =>
      await loaded() == null ? AppFailures.notReady('The assessments') : null;

  void _put(Assessment assessment) => updateState(
    current.copyWith(
      items: _newestFirst([
        ...current.items.where((item) => item.id != assessment.id),
        assessment,
      ]),
    ),
  );

  static List<Assessment> _newestFirst(List<Assessment> items) =>
      [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  static String _idOr(String id) => id.isEmpty ? const Uuid().v4() : id;

  static ApiFailure _missing(String id) =>
      ApiErr(title: 'not_found', msm: 'No assessment $id.');

  static Result<Assessment, ApiFailure> _logged(ApiFailure failure) {
    Log.w('Assessment change failed: ${failure.title} ${failure.msm}');
    return Err(failure);
  }
}

mixin AssessmentService {
  static final ReactiveNotifier<AssessmentViewModel> log =
      ReactiveNotifier<AssessmentViewModel>(AssessmentViewModel.new);

  static AssessmentViewModel get notifier => log.notifier;
}
