import 'dart:async';

import 'package:logger_rs/logger_rs.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

/// Lets a change wait for the data it builds on.
///
/// A change must never start from an empty state that only means "not
/// loaded yet": saving it would overwrite what is stored. [loaded] waits for
/// a load in progress, starts one (or retries a failed one) when there is
/// none, and returns null only when the data really is not available.
mixin LoadedState<T> on AsyncViewModelImpl<T> {
  static const _patience = Duration(seconds: 15);

  Future<T?> loaded() async {
    if (hasData) {
      return data;
    }
    if (!isLoading) {
      await reload();
      return hasData ? data : null;
    }
    final settled = Completer<void>();
    void onChange() {
      if (!isLoading && !settled.isCompleted) {
        settled.complete();
      }
    }

    addListener(onChange);
    try {
      await settled.future.timeout(_patience);
    } on TimeoutException {
      Log.w('$runtimeType is still loading after ${_patience.inSeconds}s');
    } finally {
      removeListener(onChange);
    }
    return hasData ? data : null;
  }
}
