part of 'ui.dart';

/// The assistant's button at the end of an app bar.
class AssistantAppBarAction extends StatelessWidget {
  const AssistantAppBarAction({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(right: AppSpacing.sm),
    child: AiAssistantButton(),
  );
}
