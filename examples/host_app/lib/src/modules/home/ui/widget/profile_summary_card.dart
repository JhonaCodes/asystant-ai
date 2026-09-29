import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:host_app/src/core/navigation/route_screen.dart';
import 'package:host_app/src/modules/home/ui/widget/summary_card.dart';
import 'package:host_app/src/modules/profile/model/person_profile.dart';
import 'package:host_app/src/modules/profile/viewmodel/profile_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({super.key});

  @override
  Widget build(BuildContext context) =>
      ReactiveAsyncBuilder<ProfileViewModel, PersonProfile>(
        notifier: ProfileService.notifier,
        onLoading: () => const SizedBox.shrink(),
        onError: (_, _) => const SizedBox.shrink(),
        onData: (profile, _, keep) => SummaryCard(
          icon: Icons.person_outline,
          title: HomeStrings.profile,
          value: switch (profile.displayName) {
            '' => HomeStrings.profileEmpty,
            final name => name,
          },
          onTap: () => context.go(RouteScreen.profile.path),
        ),
      );
}
