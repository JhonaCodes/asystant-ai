import 'package:reactive_notifier/reactive_notifier.dart';

class WorkspaceViewModel extends ViewModel<List<String>> {
  WorkspaceViewModel() : super(const []);
  final Set<String> _applied = {};
  @override
  void init() {}
  void create(String title, String idempotencyKey) {
    if (_applied.add(idempotencyKey))
      updateState(List.unmodifiable([...data, title]));
  }
}
