part of 'ui.dart';

/// A bordered card with padding; tappable when [onTap] is set.
class BotanicaCard extends StatelessWidget {
  const BotanicaCard({super.key, required this.child, this.onTap});

  final Widget child;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    ),
  );
}
