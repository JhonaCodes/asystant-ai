import 'package:flutter/material.dart';

import 'package:host_app/src/core/navigation/app_route.dart';
import 'package:host_app/src/shared/shared.dart';

class BotanicaApp extends StatelessWidget {
  const BotanicaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: CommonStrings.appName,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    darkTheme: AppTheme.dark,
    routerConfig: AppRoute.router,
  );
}
