import 'package:asystant_core/src/model/assistant_value.dart';

/// One labeled measurement; labels and units belong to the host domain.
class ChartPoint extends AssistantValue {
  const ChartPoint({required this.label, required this.value});

  final String label;

  final double value;

  ChartPoint copyWith({String? label, double? value}) =>
      ChartPoint(label: label ?? this.label, value: value ?? this.value);

  factory ChartPoint.fromJson(Map<String, Object?> json) => ChartPoint(
    label: json['label'] as String,
    value: (json['value'] as num).toDouble(),
  );

  @override
  Map<String, Object?> toJson() => {'label': label, 'value': value};
}
