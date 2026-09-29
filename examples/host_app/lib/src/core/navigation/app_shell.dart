import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:host_app/src/core/navigation/route_screen.dart';
import 'package:host_app/src/integrations/device/device.dart';
import 'package:host_app/src/shared/shared.dart';

/// The tabs around every top-level screen: a bottom bar on phones, a rail
/// on tablets and desktops.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});

  final String location;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tab = ShellTab.fromLocation(location);
    return DeviceLayout(
      mobile: Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab.index,
          onDestinationSelected: (index) =>
              context.go(ShellTab.values[index].route.path),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: CommonStrings.home,
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              label: CommonStrings.assessments,
            ),
            NavigationDestination(
              icon: Icon(Icons.local_florist_outlined),
              label: CommonStrings.plants,
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: CommonStrings.profile,
            ),
          ],
        ),
      ),
      tablet: Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: tab.index,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (index) =>
                  context.go(ShellTab.values[index].route.path),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  label: Text(CommonStrings.home),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.assignment_outlined),
                  label: Text(CommonStrings.assessments),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.local_florist_outlined),
                  label: Text(CommonStrings.plants),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  label: Text(CommonStrings.profile),
                ),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
