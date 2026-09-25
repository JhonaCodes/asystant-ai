import 'package:reactive_notifier/reactive_notifier.dart';

import 'workspace_view_model.dart';

mixin WorkspaceService {
  static final drafts =
      ReactiveNotifierViewModel<WorkspaceViewModel, List<String>>(
        WorkspaceViewModel.new,
      );
}
