part of '../ai.dart';

/// The plants of a [_PlantListCard], six at a time, in equal-height tiles.
///
/// The page is this card's own view state. It is kept alive so scrolling the
/// conversation does not send the card back to its first page.
class _PlantGallery extends StatefulWidget {
  const _PlantGallery({required this.card});

  final _PlantListCard card;

  @override
  State<_PlantGallery> createState() => _PlantGalleryState();
}

class _PlantGalleryState extends State<_PlantGallery>
    with AutomaticKeepAliveClientMixin {
  int _page = 0;

  @override
  bool get wantKeepAlive => true;

  void _show(int page) => setState(() => _page = page);

  /// The chat reuses this state when another conversation puts a different
  /// card in the same place; that card starts on its own first page.
  @override
  void didUpdateWidget(covariant _PlantGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card != widget.card) {
      _page = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final card = widget.card;
    return Column(
      spacing: AppSpacing.sm,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              spacing: AppSpacing.sm,
              children: [
                for (final row in card.rows(
                  _PlantListCard.columnsFor(constraints.maxWidth),
                  _page,
                ))
                  IntrinsicHeight(
                    child: Row(
                      spacing: AppSpacing.sm,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final plant in row)
                          Expanded(
                            child: switch (plant) {
                              final plant? => _PlantTile(plant: plant),
                              null => const SizedBox.shrink(),
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (card.isPaged)
          _PlantPager(
            label: card.rangeOf(_page),
            onPrevious: card.hasPrevious(_page) ? () => _show(_page - 1) : null,
            onNext: card.hasNext(_page) ? () => _show(_page + 1) : null,
          ),
      ],
    );
  }
}

/// Back and forward through the pages, with where the person is.
class _PlantPager extends StatelessWidget {
  const _PlantPager({required this.label, this.onPrevious, this.onNext});

  /// "1–6 de 13".
  final String label;

  /// Null on the first page.
  final VoidCallback? onPrevious;

  /// Null on the last page.
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconButton(
        tooltip: AssistantToolStrings.previousPlants,
        onPressed: onPrevious,
        icon: const Icon(Icons.chevron_left),
      ),
      Expanded(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge,
        ),
      ),
      IconButton(
        tooltip: AssistantToolStrings.nextPlants,
        onPressed: onNext,
        icon: const Icon(Icons.chevron_right),
      ),
    ],
  );
}

/// One plant: its photo on top, then its names and what it is used for.
/// Tapping it opens the plant's screen over the chat; back returns to it.
class _PlantTile extends StatelessWidget {
  const _PlantTile({required this.plant});

  final _PlantCardItem plant;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RouteScreen.plantDetail.pathFor(plant.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: BotanicaPhoto(ref: plant.photoRef, radius: 0),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall,
                  ),
                  if (plant.scientificName.isNotEmpty)
                    Text(
                      plant.scientificName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  if (plant.uses.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      plant.uses,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall,
                    ),
                  ],
                  if (plant.addedByPerson) ...[
                    const SizedBox(height: AppSpacing.xs),
                    const OriginBadge(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
