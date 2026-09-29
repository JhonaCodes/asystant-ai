part of 'strings.dart';

abstract final class RecommendationStrings {
  static const title = 'Recomendación';
  static const none =
      'Aún no hay recomendación para esta consulta. Se calcula con los datos '
      'guardados y el catálogo de plantas.';
  static const compute = 'Calcular recomendación';
  static const update = 'Actualizar';
  static const computing = 'Calculando…';
  static const outdated =
      'Los datos cambiaron desde el último cálculo. Actualiza la recomendación.';
  static const recommended = 'Plantas sugeridas';
  static const seeDoctor = 'Consulta a un médico';
  static const seeDoctorBody =
      'Hay señales que necesitan atención profesional. Por eso no se '
      'recomiendan plantas para esta consulta.';
  static const needsInformation = 'Faltan datos para recomendar con seguridad';
  static const allExcluded =
      'Ninguna planta del catálogo es segura para ti con estos datos.';
  static const noMatch =
      'No hay plantas en el catálogo para estos síntomas u objetivos.';
  static const uncovered = 'Sin respaldo en el catálogo';
  static const excluded = 'Plantas descartadas por seguridad';
  static const helpsWith = 'Ayuda con';
  static const cautionWith = 'Precaución con';
  static const viewPlant = 'Ver ficha';
  static const missingAge = 'Tu edad';
  static const missingPregnancy = 'Si estás embarazada';
  static const missingLactation = 'Si estás dando lactancia';
  static const missingSymptoms = 'Qué síntomas u objetivos tienes';
  static const reasonAge = 'Por tu edad';
  static const reasonPregnancy = 'No es segura en el embarazo';
  static const reasonLactation = 'No es segura en la lactancia';
  static const reasonCondition = 'Por tu condición';
  static const reasonAllergy = 'Por tu alergia';
  static const reasonInteraction = 'Por tu medicamento';
  static const reasonNotCurated =
      'Agregada por ti, sin datos de seguridad verificados';

  static String minAge(String years) => 'Solo desde los $years años';
  static String calculatedOn(String date) => 'Calculada el $date';
}
