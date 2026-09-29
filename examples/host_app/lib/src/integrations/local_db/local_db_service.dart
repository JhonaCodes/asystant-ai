part of 'local_db.dart';

/// The one local database of the app.
mixin LocalDbService {
  static final ReactiveNotifier<LocalStore> store =
      ReactiveNotifier<LocalStore>(LocalStore.new);
}
