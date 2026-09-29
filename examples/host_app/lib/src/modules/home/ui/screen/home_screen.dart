import 'package:flutter/material.dart';

import 'package:host_app/src/integrations/device/device.dart';
import 'package:host_app/src/modules/home/ui/view/home_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => const DeviceLayout(mobile: HomeView());
}
