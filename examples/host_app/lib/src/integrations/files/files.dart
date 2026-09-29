/// Files the app keeps on the device, such as photos.
///
/// Bytes live on disk under the app's support directory; records keep only
/// a [StoredFileRef], never an absolute path, because the container path can
/// change between installs and restores.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:logger_rs/logger_rs.dart';
import 'package:path_provider/path_provider.dart';
import 'package:reactive_notifier/reactive_notifier.dart';
import 'package:result_controller/result_controller.dart';
import 'package:uuid/uuid.dart';

part 'file_vault.dart';
part 'file_vault_failure.dart';
part 'files_service.dart';
part 'stored_file_ref.dart';
