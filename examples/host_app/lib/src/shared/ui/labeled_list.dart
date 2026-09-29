part of 'ui.dart';

/// A bulleted list of short texts; nothing when empty.
class LabeledList extends StatelessWidget {
  const LabeledList(this.items, {super.key});

  final List<String> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final item in items)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text('• $item'),
        ),
    ],
  );
}
