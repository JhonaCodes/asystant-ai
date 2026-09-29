part of 'ui.dart';

/// A scrolling page with a title, the device's margin and a width limit.
class BotanicaPage extends StatelessWidget {
  const BotanicaPage({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.showsBack = false,
  });

  final String title;

  final List<Widget> children;

  final List<Widget> actions;

  /// Shows a back arrow for pages opened on top of a tab.
  final bool showsBack;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      automaticallyImplyLeading: showsBack,
      actions: [...actions, const AssistantAppBarAction()],
    ),
    body: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            context.pageMargin,
            AppSpacing.sm,
            context.pageMargin,
            AppSpacing.xl,
          ),
          children: children,
        ),
      ),
    ),
  );
}
