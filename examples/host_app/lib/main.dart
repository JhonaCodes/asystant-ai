import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:logger_rs/logger_rs.dart';

import 'package:host_app/src/core/navigation/botanica_app.dart';
import 'package:host_app/src/core/services/infra_service.dart';
import 'package:host_app/src/modules/reference/viewmodel/reference_viewmodel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Log.init(level: kDebugMode ? Level.ALL : Level.WARNING);
  final opened = await InfraService.open();
  if (opened.errorOrNull case final failure?) {
    // The screens show their own error and a retry; the app still starts.
    Log.e('The backend did not open: ${failure.msm}');
  }
  // Labels of symptoms, conditions and medicines only change with the seed,
  // so the vocabulary is read once before any screen shows it.
  await ReferenceService.notifier.loaded();
  runApp(const BotanicaApp());
}
