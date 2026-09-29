part of 'strings.dart';

abstract final class AssessmentStrings {
  static const title = 'Consultas';
  static const empty =
      'Todavía no hay consultas. El asistente las crea cuando le cuentas cómo '
      'te sientes.';
  static const choose = 'Elige una consulta para ver sus detalles.';
  static const detail = 'Consulta';
  static const inProgress = 'En curso';
  static const completed = 'Completada';
  static const reason = 'Motivo';
  static const symptoms = 'Síntomas';
  static const goals = 'Objetivos';
  static const redFlags = 'Señales de alarma';
  static const redFlagsBody =
      'Estas señales necesitan atención médica antes que cualquier planta.';
  static const photos = 'Fotos';
  static const summary = 'Resumen';
  static const noSymptoms = 'Sin síntomas registrados.';
  static const noGoals = 'Sin objetivos registrados.';
  static const viewRecommendation = 'Ver recomendación';
  static const deleteAssessment = 'Eliminar consulta';
  static const deleteTitle = '¿Eliminar esta consulta?';
  static const deleteBody =
      'Se borran la consulta, sus fotos y su recomendación de este teléfono.';
  static const removePhoto = 'Quitar foto';
  static const removePhotoBody = 'La foto se borra de este teléfono.';
  static const worseWith = 'Empeora con';
  static const betterWith = 'Mejora con';
  static const since = 'Desde';
  static const where = 'Dónde';

  static String intensity(int value) => 'Intensidad $value/10';
  static String days(int value) => value == 1 ? '1 día' : '$value días';
  static String counts(int symptoms, int goals) =>
      '$symptoms síntomas · $goals objetivos';
}
