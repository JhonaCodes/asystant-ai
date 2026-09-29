/// Daily habits, in the person's own words.
class Habits {
  const Habits({
    this.smoking = '',
    this.alcohol = '',
    this.caffeine = '',
    this.activity = '',
    this.sleep = '',
    this.diet = '',
  });

  factory Habits.fromJson(Map<String, Object?> json) => Habits(
    smoking: json['smoking'] as String? ?? '',
    alcohol: json['alcohol'] as String? ?? '',
    caffeine: json['caffeine'] as String? ?? '',
    activity: json['activity'] as String? ?? '',
    sleep: json['sleep'] as String? ?? '',
    diet: json['diet'] as String? ?? '',
  );

  final String smoking;

  final String alcohol;

  final String caffeine;

  final String activity;

  final String sleep;

  final String diet;

  bool get isEmpty => [
    smoking,
    alcohol,
    caffeine,
    activity,
    sleep,
    diet,
  ].every((value) => value.isEmpty);

  Habits copyWith({
    String? smoking,
    String? alcohol,
    String? caffeine,
    String? activity,
    String? sleep,
    String? diet,
  }) => Habits(
    smoking: smoking ?? this.smoking,
    alcohol: alcohol ?? this.alcohol,
    caffeine: caffeine ?? this.caffeine,
    activity: activity ?? this.activity,
    sleep: sleep ?? this.sleep,
    diet: diet ?? this.diet,
  );

  Map<String, Object?> toJson() => {
    'smoking': smoking,
    'alcohol': alcohol,
    'caffeine': caffeine,
    'activity': activity,
    'sleep': sleep,
    'diet': diet,
  };

  @override
  bool operator ==(Object other) =>
      other is Habits &&
      smoking == other.smoking &&
      alcohol == other.alcohol &&
      caffeine == other.caffeine &&
      activity == other.activity &&
      sleep == other.sleep &&
      diet == other.diet;

  @override
  int get hashCode =>
      Object.hash(smoking, alcohol, caffeine, activity, sleep, diet);

  @override
  String toString() => 'Habits(${isEmpty ? 'empty' : 'set'})';
}
