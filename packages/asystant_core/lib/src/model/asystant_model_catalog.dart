import 'package:asystant_core/src/model/assistant_value.dart';

/// Where the entries of an [AsystantModelCatalog] come from.
enum AsystantCatalogSource {
  /// Asked of the provider, or of the installed program, just now.
  live,

  /// A list shipped with the SDK, used when the provider could not say.
  bundled,
}

/// The models, and the reasoning effort levels, a provider offers.
///
/// The same shape for every provider, so a model picker does not depend on
/// which one is configured. Ids are what `AssistantTransport.infer` accepts
/// as `model`.
class AsystantModelCatalog extends AssistantValue {
  const AsystantModelCatalog({
    required this.models,
    required this.source,
    this.efforts = const [],
    this.isOpenList = false,
  });

  /// Model ids in the provider's order, e.g. `sonnet` or
  /// `openai/gpt-oss-120b`.
  final List<String> models;

  /// Reasoning effort levels the provider declares, lowest first; empty
  /// when it declares none.
  final List<String> efforts;

  /// Whether ids outside [models] are accepted too, so a picker should also
  /// offer free text. True when [models] are examples, not the whole list.
  final bool isOpenList;

  final AsystantCatalogSource source;

  AsystantModelCatalog copyWith({
    List<String>? models,
    List<String>? efforts,
    bool? isOpenList,
    AsystantCatalogSource? source,
  }) => AsystantModelCatalog(
    models: List.unmodifiable(models ?? this.models),
    efforts: List.unmodifiable(efforts ?? this.efforts),
    isOpenList: isOpenList ?? this.isOpenList,
    source: source ?? this.source,
  );

  factory AsystantModelCatalog.fromJson(Map<String, Object?> json) =>
      AsystantModelCatalog(
        models: List.unmodifiable(
          (json['models'] as List<Object?>? ?? const []).cast<String>(),
        ),
        efforts: List.unmodifiable(
          (json['efforts'] as List<Object?>? ?? const []).cast<String>(),
        ),
        isOpenList: json['is_open_list'] as bool? ?? false,
        source: AsystantCatalogSource.values.byName(json['source'] as String),
      );

  @override
  Map<String, Object?> toJson() => {
    'models': models,
    'efforts': efforts,
    'is_open_list': isOpenList,
    'source': source.name,
  };

  @override
  String toString() =>
      'AsystantModelCatalog(${source.name}, ${models.length} models)';
}
