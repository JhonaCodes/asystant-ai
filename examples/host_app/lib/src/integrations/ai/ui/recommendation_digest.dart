part of '../ai.dart';

/// A recommendation inside the chat: what the recommendation screen shows,
/// the reminder that it is guidance, and the way to the saved consultation.
class _RecommendationDigest extends StatelessWidget {
  const _RecommendationDigest({required this.card});

  final _RecommendationCard card;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      RecommendationSnapshotContent(snapshot: card.snapshot),
      const DisclaimerNote(),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => context.push(
            RouteScreen.assessmentDetail.pathFor(card.consultationId),
          ),
          child: const Text(AssistantToolStrings.openConsultation),
        ),
      ),
    ],
  );
}
