part of 'files.dart';

/// The one file vault of the app.
mixin FilesService {
  static final ReactiveNotifier<FileVault> vault = ReactiveNotifier<FileVault>(
    FileVault.new,
  );
}
