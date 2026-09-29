import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:host_app/src/integrations/device/device.dart';
import 'package:host_app/src/modules/profile/model/person_profile.dart';
import 'package:host_app/src/modules/profile/ui/view/profile_view.dart';
import 'package:host_app/src/modules/profile/viewmodel/profile_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      ReactiveAsyncBuilder<ProfileViewModel, PersonProfile>(
        notifier: ProfileService.notifier,
        onLoading: () => const LoadingView(),
        onError: (_, _) => ErrorView(onRetry: ProfileService.notifier.reload),
        onData: (profile, viewModel, keep) => DeviceLayout(
          mobile: ProfileView(profile: profile, viewModel: viewModel),
        ),
      );
}
