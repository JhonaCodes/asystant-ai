/// The local key-value database, wrapped.
///
/// The only place in the app that imports `flutter_local_db`. It opens the
/// database once, mirrors every record in memory (the package has no
/// queries, only lookups by key and a full read), and writes through to disk.
library;

import 'package:flutter_local_db/flutter_local_db.dart' as db;
import 'package:logger_rs/logger_rs.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'package:result_controller/result_controller.dart';

part 'key_index.dart';
part 'local_db_service.dart';
part 'local_store.dart';
part 'local_store_failure.dart';
