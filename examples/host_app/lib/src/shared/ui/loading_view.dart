part of 'ui.dart';

/// A thin progress bar at the top while something loads.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Align(
    alignment: Alignment.topCenter,
    child: LinearProgressIndicator(minHeight: 2),
  );
}
