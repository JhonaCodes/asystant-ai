part of 'strings.dart';

/// What the assistant's tools show inside the chat.
abstract final class AssistantToolStrings {
  static const readingCatalog = 'Consultar el catálogo de plantas';
  static const previousPlants = 'Plantas anteriores';
  static const nextPlants = 'Siguientes plantas';
  static const savingProfile = 'Guardar en tu perfil';
  static const savedToProfile = 'Guardado en tu perfil';
  static const lookingForPlants = 'Buscar plantas para ti';
  static const openConsultation = 'Ver consulta';

  /// "1–6 de 13", or "13 de 13" when the page has one plant.
  static String range(int first, int last, int total) =>
      first == last ? '$first de $total' : '$first–$last de $total';

  static String plantsFound(int count, String query) =>
      switch ((count, query.isEmpty)) {
        (1, true) => '1 planta del catálogo',
        (_, true) => '$count plantas del catálogo',
        (1, false) => '1 planta para «$query»',
        (_, false) => '$count plantas para «$query»',
      };

  static String age(int years) => '${ProfileStrings.age}: $years años';

  static String sex(String label) => '${ProfileStrings.sex}: $label';

  static String pregnant(bool value) =>
      '${ProfileStrings.pregnant}: ${_yesNo(value)}';

  static String lactating(bool value) =>
      '${ProfileStrings.lactating}: ${_yesNo(value)}';

  static String condition(String label) => 'Condición: $label';

  static String allergy(String label) => 'Alergia: $label';

  static String medication(String name) => 'Medicamento: $name';

  static String recommendationFor(String reason) => 'Recomendación: $reason';

  static String _yesNo(bool value) =>
      value ? ProfileStrings.yes : ProfileStrings.no;
}
