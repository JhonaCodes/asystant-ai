/// Which assessment is being evaluated right now, if any.
class RecommendationRun {
  const RecommendationRun({this.computingId});

  factory RecommendationRun.fromJson(Map<String, Object?> json) =>
      RecommendationRun(computingId: json['computingId'] as String?);

  final String? computingId;

  bool isComputing(String assessmentId) => computingId == assessmentId;

  RecommendationRun copyWith({String? computingId, bool clear = false}) =>
      RecommendationRun(
        computingId: clear ? null : computingId ?? this.computingId,
      );

  Map<String, Object?> toJson() => {'computingId': computingId};

  @override
  bool operator ==(Object other) =>
      other is RecommendationRun && computingId == other.computingId;

  @override
  int get hashCode => computingId.hashCode;

  @override
  String toString() => 'RecommendationRun($computingId)';
}
