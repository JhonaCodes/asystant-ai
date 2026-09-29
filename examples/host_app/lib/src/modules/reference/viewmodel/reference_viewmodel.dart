import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:host_app/src/core/services/loaded_state.dart';

import 'package:host_app/src/modules/reference/model/reference_data.dart';
import 'package:host_app/src/modules/reference/model/term_kind.dart';
import 'package:host_app/src/modules/reference/model/vocabulary_term.dart';
import 'package:host_app/src/modules/reference/repository/reference_repository.dart';

/// The vocabulary and warning-sign rules, loaded once.
class ReferenceViewModel extends AsyncViewModelImpl<ReferenceData>
    with LoadedState<ReferenceData> {
  ReferenceViewModel() : super(AsyncState.initial());

  ReferenceRepository get _repository => const ReferenceRepository();

  @override
  Future<ReferenceData> init() async {
    final loaded = await _repository.fetch();
    return loaded.when(ok: (data) => data, err: (failure) => throw failure);
  }

  /// The loaded data, or empty while loading or after a failure.
  ReferenceData get current =>
      hasData ? data ?? const ReferenceData() : const ReferenceData();

  List<VocabularyTerm> termsOf(TermKind kind) => current.termsOf(kind);

  VocabularyTerm? termFor(String tag) => current.termFor(tag);

  VocabularyTerm? termMatching(TermKind kind, String text) =>
      current.termMatching(kind, text);

  String labelOf(String tag) => current.labelOf(tag);
}

mixin ReferenceService {
  static final ReactiveNotifier<ReferenceViewModel> reference =
      ReactiveNotifier<ReferenceViewModel>(ReferenceViewModel.new);

  static ReferenceViewModel get notifier => reference.notifier;
}
