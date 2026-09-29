import 'package:collection/collection.dart';

import 'package:host_app/src/modules/assessment/model/assessment.dart';

/// Every assessment, newest first, and the one selected.
class AssessmentLog {
  const AssessmentLog({this.items = const [], this.selectedId});

  factory AssessmentLog.fromJson(Map<String, Object?> json) => AssessmentLog(
    items: List.unmodifiable(
      (json['items'] as List<Object?>? ?? const []).map(
        (item) => Assessment.fromJson(item as Map<String, Object?>),
      ),
    ),
    selectedId: json['selectedId'] as String?,
  );

  final List<Assessment> items;

  final String? selectedId;

  Assessment? get selected =>
      items.firstWhereOrNull((item) => item.id == selectedId);

  Assessment? get latest => items.firstOrNull;

  Assessment? byId(String id) =>
      items.firstWhereOrNull((item) => item.id == id);

  AssessmentLog copyWith({
    List<Assessment>? items,
    String? selectedId,
    bool clearSelection = false,
  }) => AssessmentLog(
    items: List.unmodifiable(items ?? this.items),
    selectedId: clearSelection ? null : selectedId ?? this.selectedId,
  );

  Map<String, Object?> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'selectedId': selectedId,
  };

  @override
  bool operator ==(Object other) =>
      other is AssessmentLog &&
      const ListEquality<Assessment>().equals(items, other.items) &&
      selectedId == other.selectedId;

  @override
  int get hashCode => Object.hash(Object.hashAll(items), selectedId);

  @override
  String toString() => 'AssessmentLog(${items.length})';
}
