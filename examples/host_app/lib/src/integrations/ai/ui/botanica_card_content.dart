part of '../ai.dart';

/// What Botánica draws inside the chat's gen-ui cards, per card type.
abstract final class _BotanicaCardContent {
  /// The content for [card], or null to leave the card as the library draws it.
  static Widget? of(BuildContext context, AssistantCard card) => switch (card) {
    final _PlantListCard plants => _PlantGallery(card: plants),
    final _RecommendationCard recommendation => _RecommendationDigest(
      card: recommendation,
    ),
    _ => null,
  };
}
