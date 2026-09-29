part of 'ui.dart';

/// A colored notice with a title, an optional body and items.
class NoticeCard extends StatelessWidget {
  const NoticeCard({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.body = '',
    this.items = const [],
  });

  final IconData icon;

  final Color color;

  final String title;

  final String body;

  final List<String> items;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .08),
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleSmall),
            ),
          ],
        ),
        if (body.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(body),
        ],
        if (items.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          LabeledList(items),
        ],
      ],
    ),
  );
}
