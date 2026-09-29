import 'package:flutter/material.dart';
import 'package:reactive_notifier/reactive_notifier.dart';

import 'package:host_app/src/integrations/device/device.dart';
import 'package:host_app/src/modules/assessment/model/assessment_log.dart';
import 'package:host_app/src/modules/assessment/ui/mobile/assessment_list_mobile_view.dart';
import 'package:host_app/src/modules/assessment/ui/tablet/assessment_list_tablet_view.dart';
import 'package:host_app/src/modules/assessment/viewmodel/assessment_viewmodel.dart';
import 'package:host_app/src/shared/shared.dart';

class AssessmentListScreen extends StatelessWidget {
  const AssessmentListScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      ReactiveAsyncBuilder<AssessmentViewModel, AssessmentLog>(
        notifier: AssessmentService.notifier,
        onLoading: () => const LoadingView(),
        onError: (_, _) =>
            ErrorView(onRetry: AssessmentService.notifier.reload),
        onData: (log, viewModel, keep) => DeviceLayout(
          mobile: AssessmentListMobileView(log: log),
          tablet: AssessmentListTabletView(log: log, viewModel: viewModel),
        ),
      );
}
